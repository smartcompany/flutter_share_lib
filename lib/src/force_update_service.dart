import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// `/api/settings` 기반 강제 업데이트 검사 결과.
class ForceUpdateCheckResult {
  const ForceUpdateCheckResult({
    required this.requiresForceUpdate,
    required this.currentVersion,
    this.minVersion,
    this.storeUrl,
    this.message,
  });

  /// 앱 사용을 막고 스토어로 보내야 할 때 `true`.
  final bool requiresForceUpdate;

  /// 현재 설치된 앱 버전 (예: `1.0.4`).
  final String currentVersion;

  /// 서버가 요구하는 최소 버전.
  final String? minVersion;

  /// 플랫폼별 스토어 URL.
  final String? storeUrl;

  /// 서버에서 내려준 선택적 안내 문구.
  final String? message;

  static const ForceUpdateCheckResult skipped = ForceUpdateCheckResult(
    requiresForceUpdate: false,
    currentVersion: '',
  );
}

/// 서버 `settings.json`의 최소 버전과 현재 앱 버전을 비교합니다.
///
/// 서버 JSON 예시:
/// ```json
/// {
///   "min_version": "1.0.5",
///   "ios_min_version": "1.0.5",
///   "android_min_version": "1.0.5",
///   "force_update": true,
///   "ios_store_url": "https://apps.apple.com/app/idXXXXXXXX",
///   "android_store_url": "https://play.google.com/store/apps/details?id=com.example.app",
///   "update_message": "새로운 기능과 안정성 개선이 포함되어 있습니다."
/// }
/// ```
///
/// - `ios_min_version` / `android_min_version`이 있으면 플랫폼별로 우선 사용
/// - `force_update`가 `true`이고 현재 버전이 최소 버전 미만이면 강제 업데이트
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
    String? iosStoreUrlFallback,
    String? androidStoreUrlFallback,
  }) async {
    if (kIsWeb) {
      return ForceUpdateCheckResult.skipped;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (_settingsEndpoint == null) {
      debugPrint(
        '❌ [ForceUpdate] baseUrl이 없습니다. setBaseUrl()을 먼저 호출하세요.',
      );
      return ForceUpdateCheckResult(
        requiresForceUpdate: false,
        currentVersion: currentVersion,
      );
    }

    try {
      debugPrint('🔍 [ForceUpdate] 설정 로드: $_settingsEndpoint');
      final response = await http.get(Uri.parse(_settingsEndpoint!));
      if (response.statusCode != 200) {
        debugPrint('❌ [ForceUpdate] 설정 로드 실패: ${response.statusCode}');
        return ForceUpdateCheckResult(
          requiresForceUpdate: false,
          currentVersion: currentVersion,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return evaluate(
        settings: data,
        currentVersion: currentVersion,
        iosStoreUrlFallback: iosStoreUrlFallback,
        androidStoreUrlFallback: androidStoreUrlFallback,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ForceUpdate] 검사 중 오류: $e');
      debugPrint('$stackTrace');
      return ForceUpdateCheckResult(
        requiresForceUpdate: false,
        currentVersion: currentVersion,
      );
    }
  }

  /// 이미 로드된 settings 맵으로 검사 (네트워크 재호출 없이).
  ForceUpdateCheckResult evaluate({
    required Map<String, dynamic> settings,
    required String currentVersion,
    String? iosStoreUrlFallback,
    String? androidStoreUrlFallback,
  }) {
    if (kIsWeb) {
      return ForceUpdateCheckResult.skipped;
    }

    final forceUpdate = settings['force_update'] == true;
    final minVersion = _resolveMinVersion(settings);
    final storeUrl = _resolveStoreUrl(
      settings,
      iosStoreUrlFallback: iosStoreUrlFallback,
      androidStoreUrlFallback: androidStoreUrlFallback,
    );
    final message = settings['update_message'] as String?;

    if (minVersion == null || minVersion.isEmpty) {
      debugPrint('ℹ️ [ForceUpdate] min_version 없음 — 스킵');
      return ForceUpdateCheckResult(
        requiresForceUpdate: false,
        currentVersion: currentVersion,
        storeUrl: storeUrl,
        message: message,
      );
    }

    final outdated = compareVersions(currentVersion, minVersion) < 0;
    final requiresForceUpdate = forceUpdate && outdated;

    debugPrint(
      '🔍 [ForceUpdate] current=$currentVersion min=$minVersion '
      'force=$forceUpdate outdated=$outdated → require=$requiresForceUpdate',
    );

    return ForceUpdateCheckResult(
      requiresForceUpdate: requiresForceUpdate,
      currentVersion: currentVersion,
      minVersion: minVersion,
      storeUrl: storeUrl,
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

  String? _resolveMinVersion(Map<String, dynamic> settings) {
    if (_isIOS) {
      final ios = settings['ios_min_version'];
      if (ios is String && ios.trim().isNotEmpty) return ios.trim();
    } else if (_isAndroid) {
      final android = settings['android_min_version'];
      if (android is String && android.trim().isNotEmpty) {
        return android.trim();
      }
    }

    final general = settings['min_version'];
    if (general is String && general.trim().isNotEmpty) {
      return general.trim();
    }
    return null;
  }

  String? _resolveStoreUrl(
    Map<String, dynamic> settings, {
    String? iosStoreUrlFallback,
    String? androidStoreUrlFallback,
  }) {
    if (_isIOS) {
      final fromSettings = settings['ios_store_url'];
      if (fromSettings is String && fromSettings.trim().isNotEmpty) {
        return fromSettings.trim();
      }
      return iosStoreUrlFallback?.trim();
    }
    if (_isAndroid) {
      final fromSettings = settings['android_store_url'];
      if (fromSettings is String && fromSettings.trim().isNotEmpty) {
        return fromSettings.trim();
      }
      return androidStoreUrlFallback?.trim();
    }
    return null;
  }

  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
