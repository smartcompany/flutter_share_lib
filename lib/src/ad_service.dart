import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 광고 서비스 클래스
///
/// 서버에서 설정을 받아와 광고를 관리합니다.
/// baseUrl만 설정하면 서버의 `/api/settings` 엔드포인트에서 모든 설정을 자동으로 가져옵니다.
///
/// iOS와 Android 모두 지원하며, ios_ads/android_ads 설정을 통해
/// 전면 광고와 보상형 광고를 자동으로 관리합니다.
///
/// 사용 예시:
/// ```dart
/// // baseUrl 설정 (서버 주소만 전달)
/// AdService.shared.setBaseUrl('https://your-server.com');
///
/// // 서버에서 설정 로드
/// await AdService.shared.loadSettings();
///
/// // 광고 표시
/// await AdService.shared.showInterstitialAd(
///   onAdDismissed: () {
///     // 광고 닫힘 후 처리
///   },
///   onAdFailedToShow: () {
///     // 광고 표시 실패 시 처리
///   },
/// );
/// ```
class AdService {
  AdService._();
  static final AdService shared = AdService._();

  String? _baseUrl;
  String? get _settingsEndpoint =>
      _baseUrl != null ? '$_baseUrl/api/settings' : null;

  String? _adsType;
  String? _rewardedAdId;
  String? _initialAdId;
  String? _downloadUrl;

  // ios_ads 또는 android_ads 설정 파싱 결과
  Map<String, int> _adsConfig = {}; // {"initial_ad": 10, "rewarded_ad": 1}
  bool _useAdsConfig = false;

  // 순차 반복을 위한 현재 광고 타입과 카운터 (SharedPreferences에 저장)
  String? _currentAdType; // 현재 표시 중인 광고 타입
  int _currentAdCount = 0; // 현재 광고 타입의 표시 횟수 (메모리 캐시)

  String? get rewardedAdId => _rewardedAdId;
  String? get initialAdId => _initialAdId;
  String? get downloadUrl => _downloadUrl;

  /// baseUrl 설정
  ///
  /// [baseUrl] 서버 base URL (예: 'https://your-server.com')
  /// 서버의 `/api/settings` 엔드포인트에서 모든 설정을 가져옵니다.
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  /// 서버에서 설정 로드
  ///
  /// `setBaseUrl()`을 먼저 호출한 후 이 메서드를 호출하세요.
  /// 서버의 `/api/settings` 엔드포인트에서 광고 설정을 가져옵니다.
  ///
  /// 서버 응답 예시:
  /// ```json
  /// {
  ///   "ios_ads": [{"initial_ad": 10}, {"rewarded_ad": 1}],
  ///   "android_ads": [{"initial_ad": 10}, {"rewarded_ad": 1}],
  ///   "ref": {
  ///     "ios": {
  ///       "initial_ad": "ca-app-pub-xxx/xxx",
  ///       "rewarded_ad": "ca-app-pub-xxx/xxx"
  ///     },
  ///     "android": {
  ///       "initial_ad": "ca-app-pub-xxx/xxx",
  ///       "rewarded_ad": "ca-app-pub-xxx/xxx"
  ///     }
  ///   },
  ///   "down_load_url": "https://play.google.com/store/apps/details?id=xxx"
  /// }
  /// ```
  Future<bool> loadSettings() async {
    if (_settingsEndpoint == null) {
      debugPrint('❌ [AdService] baseUrl이 설정되지 않았습니다. setBaseUrl()을 먼저 호출하세요.');
      return false;
    }

    try {
      debugPrint('🔍 [AdService] 설정 로드 시작: $_settingsEndpoint');
      final uri = Uri.parse(_settingsEndpoint!);
      final response = await http.get(uri);
      debugPrint('🔍 [AdService] 응답 상태 코드: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('❌ [AdService] 설정 로드 실패: ${response.statusCode}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // ios_ads 또는 android_ads 설정 확인
      String? adsConfigKey;
      if (io.Platform.isIOS && data['ios_ads'] != null) {
        adsConfigKey = 'ios_ads';
      } else if (io.Platform.isAndroid && data['android_ads'] != null) {
        adsConfigKey = 'android_ads';
      }

      if (adsConfigKey != null) {
        final adsList = data[adsConfigKey] as List<dynamic>;
        _adsConfig = {};
        for (final item in adsList) {
          if (item is Map<String, dynamic>) {
            item.forEach((key, value) {
              if (value is int) {
                _adsConfig[key] = value;
              }
            });
          }
        }
        _useAdsConfig = _adsConfig.isNotEmpty;

        // 순차 반복 초기화 (이미 설정되어 있으면 유지)
        if (_useAdsConfig && _adsConfig.isNotEmpty) {
          await _loadAdState();

          // _currentAdType이 없거나 설정이 변경된 경우에만 초기화
          if (_currentAdType == null ||
              !_adsConfig.containsKey(_currentAdType)) {
            _currentAdType = _adsConfig.keys.first;
            _currentAdCount = 0;
            await _saveAdState();
            debugPrint('🔄 [AdService] 순차 반복 초기화: $_currentAdType');
          } else {
            debugPrint(
                '🔍 [AdService] 순차 반복 상태 유지: $_currentAdType ($_currentAdCount)');
          }
        }
      } else {
        _useAdsConfig = false;
        // 기존 방식으로 전환할 때만 리셋
        if (_currentAdType != null) {
          _currentAdType = null;
          _currentAdCount = 0;
        }
      }

      // 기존 방식 (ios_ads/android_ads가 없을 때)
      if (!_useAdsConfig) {
        _adsType = () {
          if (io.Platform.isIOS) {
            return data['ios_ad'] as String?;
          } else if (io.Platform.isAndroid) {
            return data['android_ad'] as String?;
          }
          return null;
        }();
      }

      // 광고 ID 가져오기
      final ref = data['ref'] as Map<String, dynamic>?;
      if (ref != null) {
        final platformRef = io.Platform.isIOS
            ? ref['ios'] as Map<String, dynamic>?
            : ref['android'] as Map<String, dynamic>?;

        if (platformRef != null) {
          if (_useAdsConfig) {
            // ios_ads/android_ads 사용 시: initial_ad와 rewarded_ad 모두 가져오기
            _initialAdId = platformRef['initial_ad'] as String?;
            _rewardedAdId = platformRef['rewarded_ad'] as String?;
          } else {
            // 기존 방식: _adsType에 따라 하나만 가져오기
            _rewardedAdId = platformRef[_adsType] as String?;
          }
        }
      }

      _downloadUrl = data['down_load_url'] as String?;

      debugPrint('🔍 [AdService] 설정 로드 완료:');
      debugPrint('  - useAdsConfig: $_useAdsConfig');
      debugPrint('  - adsConfig: $_adsConfig');
      debugPrint('  - initialAdId: $_initialAdId');
      debugPrint('  - rewardedAdId: $_rewardedAdId');
      debugPrint('  - adsType: $_adsType');

      final hasAdId = _rewardedAdId != null && _rewardedAdId!.isNotEmpty ||
          _initialAdId != null && _initialAdId!.isNotEmpty;
      debugPrint('🔍 [AdService] 광고 ID 존재 여부: $hasAdId');

      return hasAdId;
    } catch (e, stackTrace) {
      debugPrint('❌ [AdService] 설정 로드 중 오류: $e');
      debugPrint('❌ [AdService] 스택 트레이스: $stackTrace');
      return false;
    }
  }

  // SharedPreferences에서 광고 상태 로드
  Future<void> _loadAdState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final platformPrefix = io.Platform.isIOS ? 'ios_' : 'android_';
      final adTypeKey = '${platformPrefix}ad_current_type';
      final adCountKey = '${platformPrefix}ad_current_count';

      _currentAdType = prefs.getString(adTypeKey);
      _currentAdCount = prefs.getInt(adCountKey) ?? 0;

      debugPrint('🔍 [AdService] 상태 로드: $_currentAdType ($_currentAdCount)');
    } catch (e) {
      debugPrint('❌ [AdService] 상태 로드 실패: $e');
    }
  }

  // SharedPreferences에 광고 상태 저장
  Future<void> _saveAdState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final platformPrefix = io.Platform.isIOS ? 'ios_' : 'android_';
      final adTypeKey = '${platformPrefix}ad_current_type';
      final adCountKey = '${platformPrefix}ad_current_count';

      if (_currentAdType != null) {
        await prefs.setString(adTypeKey, _currentAdType!);
        await prefs.setInt(adCountKey, _currentAdCount);
        debugPrint('💾 [AdService] 상태 저장: $_currentAdType ($_currentAdCount)');
      }
    } catch (e) {
      debugPrint('❌ [AdService] 상태 저장 실패: $e');
    }
  }

  // 다음에 표시할 광고 타입 결정 (순차 반복 방식)
  Future<String?> _getNextAdType() async {
    if (!_useAdsConfig || _adsConfig.isEmpty) {
      // 기존 방식: _adsType 사용
      debugPrint('🔍 [AdService] 기존 방식 사용: _adsType=$_adsType');
      return _adsType;
    }

    // 현재 광고 타입이 없으면 첫 번째 타입으로 시작
    if (_currentAdType == null) {
      _currentAdType = _adsConfig.keys.first;
      _currentAdCount = 0;
      await _saveAdState();
    }

    final threshold = _adsConfig[_currentAdType]!;

    // threshold에 도달했는지 먼저 확인
    if (_currentAdCount >= threshold) {
      // 현재 타입의 표시 횟수 완료 -> 다음 타입으로 이동
      final adTypes = _adsConfig.keys.toList();
      final currentIndex = adTypes.indexOf(_currentAdType!);
      final nextIndex = (currentIndex + 1) % adTypes.length;
      _currentAdType = adTypes[nextIndex];
      _currentAdCount = 0; // 다음 타입 카운트 초기화
      await _saveAdState();

      debugPrint('🔄 [AdService] 타입 전환: 다음 타입=$_currentAdType (카운트 리셋)');
    }

    // 카운트 증가
    _currentAdCount++;
    final resultType = _currentAdType;
    await _saveAdState();

    debugPrint(
        '✅ [AdService] 광고 표시 결정: $resultType ($_currentAdCount/${_adsConfig[resultType]})');

    return resultType;
  }

  /// 전면 광고 또는 보상형 광고 표시
  ///
  /// ios_ads/android_ads 설정이 있으면 자동으로 전면 광고와 보상형 광고를
  /// 설정된 횟수에 따라 표시합니다.
  ///
  /// [onAdDismissed] 광고가 닫힌 후 호출되는 콜백
  /// [onAdFailedToShow] 광고 표시 실패 시 호출되는 콜백 (선택사항)
  Future<void> showInterstitialAd({
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    debugPrint('🔍 [AdService] showInterstitialAd 호출');
    // 다음 광고 타입 결정
    final nextAdType = await _getNextAdType();
    debugPrint('🔍 [AdService] 다음 광고 타입: $nextAdType');

    if (nextAdType == null) {
      // 광고 표시 안 함
      debugPrint('ℹ️ [AdService] 광고 표시 안 함 (nextAdType이 null)');
      onAdDismissed();
      return;
    }

    String? adUnitId;
    bool isRewarded = false;

    if (_useAdsConfig) {
      // ios_ads/android_ads 설정 사용
      if (nextAdType == 'initial_ad') {
        adUnitId = _initialAdId;
        isRewarded = false;
      } else if (nextAdType == 'rewarded_ad') {
        adUnitId = _rewardedAdId;
        isRewarded = true;
      }
    } else {
      // 기존 방식
      adUnitId = _rewardedAdId;
      isRewarded = _adsType == 'rewarded_ad';
    }

    if (adUnitId == null || adUnitId.isEmpty) {
      // If no ad ID, just proceed
      debugPrint('❌ [AdService] 광고 ID가 없습니다. adUnitId: $adUnitId');
      onAdDismissed();
      return;
    }

    debugPrint(
        '🔍 [AdService] 광고 로드 시작: adUnitId=$adUnitId, isRewarded=$isRewarded');

    if (isRewarded) {
      // 보상형 광고
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                onAdDismissed();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                onAdFailedToShow?.call();
              },
            );
            ad.show(
              onUserEarnedReward: (ad, reward) {
                // Reward user if needed
              },
            );
          },
          onAdFailedToLoad: (error) {
            // If ad fails to load, proceed anyway
            onAdFailedToShow?.call();
          },
        ),
      );
    } else {
      // 전면 광고
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                onAdDismissed();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                onAdFailedToShow?.call();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (error) {
            // If ad fails to load, proceed anyway
            onAdFailedToShow?.call();
          },
        ),
      );
    }
  }
}

