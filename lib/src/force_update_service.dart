import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// `/api/settings` 기반 강제 업데이트 검사 결과.
class ForceUpdateCheckResult {
  const ForceUpdateCheckResult({
    required this.requiresForceUpdate,
    required this.currentLabel,
    this.requiredLabel,
    this.downloadUrl,
    this.message,
  });

  /// 앱 사용을 막고 다운로드 링크로 보내야 할 때 `true`.
  final bool requiresForceUpdate;

  /// 현재 앱 식별값 표시용 (iOS: `1.0.4`, Android: 빌드 `41`).
  final String currentLabel;

  /// 서버가 요구하는 최소값 표시용.
  final String? requiredLabel;

  /// settings의 `down_load_url`.
  final String? downloadUrl;

  /// 서버에서 내려준 선택적 안내 문구.
  final String? message;

  static const ForceUpdateCheckResult skipped = ForceUpdateCheckResult(
    requiresForceUpdate: false,
    currentLabel: '',
  );
}

/// 서버 `settings.json`의 최소 버전/빌드와 현재 앱을 비교합니다.
///
/// 서버 JSON 예시:
/// ```json
/// {
///   "down_load_url": "https://your-server.com/applink",
///   "min_version": {
///     "ios": "1.0.4",
///     "android": 55,
///     "force_update": {
///       "ios": true,
///       "android": false
///     },
///     "update_message": "새로운 기능과 안정성 개선이 포함되어 있습니다."
///   }
/// }
/// ```
///
/// - **iOS**: `min_version.ios`를 `CFBundleShortVersionString`(`1.0.4`)과 비교
/// - **Android**: `min_version.android`를 `versionCode`(빌드 넘버)와 비교
/// - **강제 여부**: `min_version.force_update.ios` / `.android` (단일 `true`/`false`도 호환)
/// - 다운로드 링크는 최상위 `down_load_url` (AdService와 동일)
/// - 웹에서는 검사를 건너뜁니다
class ForceUpdateService {
  ForceUpdateService._();
  static final ForceUpdateService shared = ForceUpdateService._();

  String? _baseUrl;
  String? get _settingsEndpoint =>
      _baseUrl != null ? '$_baseUrl/api/settings' : null;

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');
  }

  /// 서버 설정을 불러와 강제 업데이트가 필요한지 확인합니다.
  Future<ForceUpdateCheckResult> check({
    String? downloadUrlFallback,
  }) async {
    if (kIsWeb) {
      return ForceUpdateCheckResult.skipped;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    if (_settingsEndpoint == null) {
      debugPrint(
        '❌ [ForceUpdate] baseUrl이 없습니다. setBaseUrl()을 먼저 호출하세요.',
      );
      return ForceUpdateCheckResult(
        requiresForceUpdate: false,
        currentLabel: _currentLabel(currentVersion, currentBuild),
      );
    }

    try {
      debugPrint('🔍 [ForceUpdate] 설정 로드: $_settingsEndpoint');
      final response = await http.get(Uri.parse(_settingsEndpoint!));
      if (response.statusCode != 200) {
        debugPrint('❌ [ForceUpdate] 설정 로드 실패: ${response.statusCode}');
        return ForceUpdateCheckResult(
          requiresForceUpdate: false,
          currentLabel: _currentLabel(currentVersion, currentBuild),
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return evaluate(
        settings: data,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        downloadUrlFallback: downloadUrlFallback,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ForceUpdate] 검사 중 오류: $e');
      debugPrint('$stackTrace');
      return ForceUpdateCheckResult(
        requiresForceUpdate: false,
        currentLabel: _currentLabel(currentVersion, currentBuild),
      );
    }
  }

  /// 이미 로드된 settings 맵으로 검사 (네트워크 재호출 없이).
  ForceUpdateCheckResult evaluate({
    required Map<String, dynamic> settings,
    required String currentVersion,
    required int currentBuild,
    String? downloadUrlFallback,
  }) {
    if (kIsWeb) {
      return ForceUpdateCheckResult.skipped;
    }

    final block = _minVersionBlock(settings);
    final forceUpdate = block != null && block.containsKey('force_update')
        ? _resolveForceUpdate(block['force_update'])
        : _resolveForceUpdate(settings['force_update']);
    final downloadUrl = _resolveDownloadUrl(
      settings,
      block: block,
      fallback: downloadUrlFallback,
    );
    final message = _optionalString(block?['update_message']) ??
        _optionalString(settings['update_message']);
    final currentLabel = _currentLabel(currentVersion, currentBuild);

    final requirement = _resolveRequirement(settings, block);
    if (requirement == null) {
      debugPrint('ℹ️ [ForceUpdate] min_version 없음 — 스킵');
      return ForceUpdateCheckResult(
        requiresForceUpdate: false,
        currentLabel: currentLabel,
        downloadUrl: downloadUrl,
        message: message,
      );
    }

    final outdated = requirement.isOutdated(
      currentVersion: currentVersion,
      currentBuild: currentBuild,
    );
    final requiresForceUpdate = forceUpdate && outdated;

    debugPrint(
      '🔍 [ForceUpdate] current=$currentLabel required=${requirement.label} '
      'force=$forceUpdate outdated=$outdated → require=$requiresForceUpdate',
    );

    return ForceUpdateCheckResult(
      requiresForceUpdate: requiresForceUpdate,
      currentLabel: currentLabel,
      requiredLabel: requirement.label,
      downloadUrl: downloadUrl,
      message: message,
    );
  }

  /// `a < b` → 음수, `a == b` → 0, `a > b` → 양수.
  /// `1.0.4+41`처럼 빌드 접미사는 무시하고 숫자 세그먼트만 비교합니다.
  static int compareVersions(String a, String b) {
    final pa = _parseVersion(a);
    final pb = _parseVersion(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final ai = i < pa.length ? pa[i] : 0;
      final bi = i < pb.length ? pb[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }
    return 0;
  }

  static List<int> _parseVersion(String version) {
    final core = version.split('+').first.trim();
    if (core.isEmpty) return const [0];
    return core
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  static String _currentLabel(String version, int build) {
    if (_isAndroid) return '$build';
    return version;
  }

  static Map<String, dynamic>? _minVersionBlock(Map<String, dynamic> settings) {
    final raw = settings['min_version'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  /// `true` / `{ "ios": true, "android": false }` 모두 지원.
  static bool _resolveForceUpdate(dynamic raw) {
    if (raw == true) return true;
    if (raw == false || raw == null) return false;
    if (raw is Map) {
      if (_isIOS) return raw['ios'] == true;
      if (_isAndroid) return raw['android'] == true;
    }
    return false;
  }

  _UpdateRequirement? _resolveRequirement(
    Map<String, dynamic> settings,
    Map<String, dynamic>? block,
  ) {
    // Preferred: min_version: { "ios": "1.0.4", "android": 55, ... }
    if (block != null) {
      if (_isIOS) {
        final ios = _optionalString(block['ios']);
        if (ios != null) {
          return _UpdateRequirement.iosVersion(ios);
        }
      } else if (_isAndroid) {
        final androidBuild = _asInt(block['android']);
        if (androidBuild != null) {
          return _UpdateRequirement.androidBuild(androidBuild);
        }
      }
    }

    // Flat fallbacks (legacy)
    final raw = settings['min_version'];
    if (_isIOS) {
      final ios = _optionalString(settings['ios_min_version']) ??
          (raw is String ? raw.trim() : null);
      if (ios != null && ios.isNotEmpty) {
        return _UpdateRequirement.iosVersion(ios);
      }
    } else if (_isAndroid) {
      final androidBuild = _asInt(settings['android_min_build']) ??
          _asInt(settings['android_min_version']) ??
          (raw is num || raw is String ? _asInt(raw) : null);
      if (androidBuild != null) {
        return _UpdateRequirement.androidBuild(androidBuild);
      }
    }

    return null;
  }

  String? _resolveDownloadUrl(
    Map<String, dynamic> settings, {
    Map<String, dynamic>? block,
    String? fallback,
  }) {
    // 최상위 down_load_url이 canonical (AdService / 공유와 동일)
    final fromSettings = _optionalString(settings['down_load_url']);
    if (fromSettings != null) return fromSettings;
    final fromBlock = _optionalString(block?['down_load_url']);
    if (fromBlock != null) return fromBlock;
    return fallback?.trim().isNotEmpty == true ? fallback!.trim() : null;
  }

  static String? _optionalString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

class _UpdateRequirement {
  const _UpdateRequirement._({
    required this.label,
    required this.isOutdated,
  });

  final String label;
  final bool Function({
    required String currentVersion,
    required int currentBuild,
  }) isOutdated;

  factory _UpdateRequirement.iosVersion(String minVersion) {
    return _UpdateRequirement._(
      label: minVersion,
      isOutdated: ({required currentVersion, required currentBuild}) {
        return ForceUpdateService.compareVersions(currentVersion, minVersion) <
            0;
      },
    );
  }

  factory _UpdateRequirement.androidBuild(int minBuild) {
    return _UpdateRequirement._(
      label: '$minBuild',
      isOutdated: ({required currentVersion, required currentBuild}) {
        return currentBuild < minBuild;
      },
    );
  }
}
