import 'dart:async';
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
  String? _bannerAdId;
  String? _downloadUrl;

  // ios_ads 또는 android_ads 설정 파싱 결과
  Map<String, int> _adsConfig = {}; // {"initial_ad": 10, "rewarded_ad": 1}
  bool _useAdsConfig = false;

  // 순차 반복을 위한 현재 광고 타입과 카운터 (SharedPreferences에 저장)
  String? _currentAdType; // 현재 표시 중인 광고 타입
  int _currentAdCount = 0; // 현재 광고 타입의 표시 횟수 (메모리 캐시)

  // Preload 캐시 (다음에 보여줄 광고를 미리 로드)
  RewardedAd? _preloadedRewarded;
  InterstitialAd? _preloadedInterstitial;
  String? _preloadedType;
  bool _isPreloading = false;
  Completer<bool>? _preloadCompleter;

  String? get rewardedAdId => _rewardedAdId;
  String? get initialAdId => _initialAdId;
  /// `ios_banner_ad` / `android_banner_ad` → `ref` 필드명 → 실제 유닛 ID (USDTSignal 동일)
  String? get bannerAdId => _bannerAdId;
  String? get downloadUrl => _downloadUrl;

  /// 다음에 쓸 광고가 이미 로드되어 있으면 true.
  bool get isAdReady =>
      _preloadedRewarded != null || _preloadedInterstitial != null;

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
      _bannerAdId = null;
      final ref = data['ref'] as Map<String, dynamic>?;
      if (ref != null) {
        final platformRef = io.Platform.isIOS
            ? ref['ios'] as Map<String, dynamic>?
            : ref['android'] as Map<String, dynamic>?;

        if (platformRef != null) {
          // USDTSignal 과 동일: 최상위 `ios_banner_ad` / `android_banner_ad` 가
          // `ref.{ios|android}` 안의 필드명을 가리킴 (예: "banner_ad").
          String? bannerRefKey;
          if (io.Platform.isIOS) {
            final k = data['ios_banner_ad'];
            if (k is String && k.trim().isNotEmpty) {
              bannerRefKey = k.trim();
            }
          } else if (io.Platform.isAndroid) {
            final k = data['android_banner_ad'];
            if (k is String && k.trim().isNotEmpty) {
              bannerRefKey = k.trim();
            }
          }
          final dynamic bannerRaw = bannerRefKey != null
              ? platformRef[bannerRefKey]
              : platformRef['banner_ad'];
          if (bannerRaw is String && bannerRaw.trim().isNotEmpty) {
            _bannerAdId = bannerRaw.trim();
          }

          if (_useAdsConfig) {
            // ios_ads/android_ads 사용 시: 모든 광고 타입의 ID를 동적으로 가져오기
            // _adsConfig에 있는 모든 키에 대해 ID를 가져옴
            _initialAdId = platformRef['initial_ad'] as String?;
            _rewardedAdId = platformRef['rewarded_ad'] as String?;

            // _adsConfig에 있는 다른 광고 타입들도 지원 (예: rewarded_test)
            for (final adType in _adsConfig.keys) {
              if (adType == 'initial_ad') {
                _initialAdId = platformRef['initial_ad'] as String?;
              } else if (adType == 'rewarded_ad') {
                _rewardedAdId = platformRef['rewarded_ad'] as String?;
              } else if (adType == 'rewarded_test') {
                // rewarded_test는 rewarded_ad ID로 사용
                _rewardedAdId =
                    platformRef['rewarded_test'] as String? ?? _rewardedAdId;
              } else if (adType == 'interstitial_ad') {
                _initialAdId =
                    platformRef['interstitial_ad'] as String? ?? _initialAdId;
              }
            }
          } else {
            // 기존 방식: _adsType에 따라 하나만 가져오기
            _rewardedAdId = platformRef[_adsType] as String?;
          }
        }
      }

      _downloadUrl = () {
        final top = data['down_load_url'];
        if (top is String && top.trim().isNotEmpty) {
          return top.trim();
        }
        final nested = data['min_version'];
        if (nested is Map) {
          final fromBlock = nested['down_load_url'];
          if (fromBlock is String && fromBlock.trim().isNotEmpty) {
            return fromBlock.trim();
          }
        }
        return null;
      }();

      debugPrint('🔍 [AdService] 설정 로드 완료:');
      debugPrint('  - down_load_url: $_downloadUrl');
      debugPrint('  - useAdsConfig: $_useAdsConfig');
      debugPrint('  - adsConfig: $_adsConfig');
      debugPrint('  - initialAdId: $_initialAdId');
      debugPrint('  - rewardedAdId: $_rewardedAdId');
      debugPrint('  - adsType: $_adsType');

      final hasAdId = _rewardedAdId != null && _rewardedAdId!.isNotEmpty ||
          _initialAdId != null && _initialAdId!.isNotEmpty ||
          _bannerAdId != null && _bannerAdId!.isNotEmpty;
      debugPrint('🔍 [AdService] 광고 ID 존재 여부: $hasAdId');
      debugPrint('  - bannerAdId: $_bannerAdId');

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

    // threshold에 도달했는지 확인 (카운트 증가 전에 확인)
    // _currentAdCount는 이미 표시한 횟수이므로, threshold와 같거나 크면 다음 타입으로 이동
    if (_currentAdCount >= threshold) {
      // 현재 타입의 표시 횟수 완료 -> 다음 타입으로 이동
      final adTypes = _adsConfig.keys.toList();
      final currentIndex = adTypes.indexOf(_currentAdType!);
      final nextIndex = (currentIndex + 1) % adTypes.length;
      _currentAdType = adTypes[nextIndex];
      _currentAdCount = 0; // 다음 타입 카운트 초기화
      await _saveAdState();

      debugPrint('🔄 [AdService] 타입 전환: 다음 타입=$_currentAdType (카운트 리셋)');

      // 다음 타입의 threshold 다시 가져오기
      final nextThreshold = _adsConfig[_currentAdType]!;
      debugPrint('🔍 [AdService] 다음 타입 threshold: $nextThreshold');
    }

    // 카운트 증가 (이번에 표시할 광고이므로 증가)
    _currentAdCount++;
    final resultType = _currentAdType;
    await _saveAdState();

    final currentThreshold = _adsConfig[resultType]!;
    debugPrint(
        '✅ [AdService] 광고 표시 결정: $resultType ($_currentAdCount/$currentThreshold)');

    return resultType;
  }

  /// 카운트를 올리지 않고 다음에 나올 광고 타입만 확인.
  Future<String?> _peekNextAdType() async {
    if (!_useAdsConfig || _adsConfig.isEmpty) {
      return _adsType;
    }

    var type = _currentAdType;
    var count = _currentAdCount;
    if (type == null || !_adsConfig.containsKey(type)) {
      type = _adsConfig.keys.first;
      count = 0;
    }

    final threshold = _adsConfig[type]!;
    if (count >= threshold) {
      final adTypes = _adsConfig.keys.toList();
      final currentIndex = adTypes.indexOf(type);
      type = adTypes[(currentIndex + 1) % adTypes.length];
    }
    return type;
  }

  void _clearPreloadedAds() {
    _preloadedRewarded?.dispose();
    _preloadedInterstitial?.dispose();
    _preloadedRewarded = null;
    _preloadedInterstitial = null;
    _preloadedType = null;
  }

  ({String? adUnitId, bool isRewarded}) _resolveAdUnit(String? adType) {
    if (_useAdsConfig) {
      if (adType == 'rewarded_ad' || adType == 'rewarded_test') {
        return (adUnitId: _rewardedAdId, isRewarded: true);
      }
      if (adType == 'initial_ad' || adType == 'interstitial_ad') {
        return (adUnitId: _initialAdId, isRewarded: false);
      }
      return (adUnitId: null, isRewarded: false);
    }
    return (
      adUnitId: _rewardedAdId,
      isRewarded: _adsType == 'rewarded_ad',
    );
  }

  /// 다음에 보여줄 광고를 백그라운드에서 미리 로드합니다.
  ///
  /// 앱 시작 직·광고 종료 후 호출하면, 분석 진입 시 대기 시간을 줄일 수 있습니다.
  Future<bool> preloadAd() async {
    if (_isPreloading) {
      return _preloadCompleter?.future ?? Future.value(isAdReady);
    }
    if (isAdReady) {
      debugPrint('ℹ️ [AdService] 이미 preloaded: $_preloadedType');
      return true;
    }

    final peekType = await _peekNextAdType();
    if (peekType == null) {
      debugPrint('ℹ️ [AdService] preload 스킵 (다음 타입 없음)');
      return false;
    }

    final resolved = _resolveAdUnit(peekType);
    final adUnitId = resolved.adUnitId;
    if (adUnitId == null || adUnitId.isEmpty) {
      debugPrint('❌ [AdService] preload 실패: 광고 ID 없음 ($peekType)');
      return false;
    }

    _isPreloading = true;
    _preloadCompleter = Completer<bool>();
    debugPrint(
      '⏳ [AdService] preload 시작: type=$peekType adUnitId=$adUnitId',
    );

    try {
      if (resolved.isRewarded) {
        await RewardedAd.load(
          adUnitId: adUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              _clearPreloadedAds();
              _preloadedRewarded = ad;
              _preloadedType = peekType;
              debugPrint('✅ [AdService] rewarded preload 완료');
              _finishPreload(true);
            },
            onAdFailedToLoad: (error) {
              debugPrint('❌ [AdService] rewarded preload 실패: $error');
              _finishPreload(false);
            },
          ),
        );
      } else {
        await InterstitialAd.load(
          adUnitId: adUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              _clearPreloadedAds();
              _preloadedInterstitial = ad;
              _preloadedType = peekType;
              debugPrint('✅ [AdService] interstitial preload 완료');
              _finishPreload(true);
            },
            onAdFailedToLoad: (error) {
              debugPrint('❌ [AdService] interstitial preload 실패: $error');
              _finishPreload(false);
            },
          ),
        );
      }

      return await _preloadCompleter!.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          debugPrint('⏱️ [AdService] preload 타임아웃');
          _finishPreload(false);
          return false;
        },
      );
    } catch (e) {
      debugPrint('❌ [AdService] preload 예외: $e');
      _finishPreload(false);
      return false;
    }
  }

  void _finishPreload(bool success) {
    _isPreloading = false;
    final completer = _preloadCompleter;
    _preloadCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
  }

  void _scheduleNextPreload() {
    // 표시 직 다음 광고를 백그라운드에서 준비
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      unawaited(preloadAd());
    });
  }

  /// 전면 광고 표시 (내부 전용)
  ///
  /// ios_ads/android_ads 설정이 있으면 자동으로 전면 광고를
  /// 설정된 횟수에 따라 표시합니다.
  ///
  /// [onAdDismissed] 광고가 닫힌 후 호출되는 콜백
  /// [onAdFailedToShow] 광고 표시 실패 시 호출되는 콜백 (선택사항)
  Future<void> _showInterstitialAd({
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    debugPrint('🔍 [AdService] _showInterstitialAd 호출');
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

    if (_useAdsConfig) {
      // ios_ads/android_ads 설정 사용
      if (nextAdType == 'initial_ad' || nextAdType == 'interstitial_ad') {
        adUnitId = _initialAdId;
      } else {
        // 보상형 광고 타입이면 showRewardedAd를 호출해야 함
        debugPrint(
            '⚠️ [AdService] _showInterstitialAd 호출되었지만 보상형 광고 타입입니다: $nextAdType');
        debugPrint('⚠️ [AdService] _showRewardedAd를 호출해야 합니다.');
        onAdDismissed();
        return;
      }
    } else {
      // 기존 방식: _adsType이 rewarded_ad가 아니면 전면 광고
      if (_adsType == 'rewarded_ad') {
        debugPrint('⚠️ [AdService] _showInterstitialAd 호출되었지만 보상형 광고 타입입니다.');
        debugPrint('⚠️ [AdService] _showRewardedAd를 호출해야 합니다.');
        onAdDismissed();
        return;
      }
      adUnitId = _initialAdId;
    }

    if (adUnitId == null || adUnitId.isEmpty) {
      // If no ad ID, just proceed
      debugPrint('❌ [AdService] 광고 ID가 없습니다. adUnitId: $adUnitId');
      onAdDismissed();
      return;
    }

    debugPrint('🔍 [AdService] 전면 광고 로드 시작: adUnitId=$adUnitId');

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

  /// 보상형 광고 표시 (내부 전용)
  ///
  /// ios_ads/android_ads 설정이 있으면 자동으로 보상형 광고를
  /// 설정된 횟수에 따라 표시합니다.
  ///
  /// [onAdDismissed] 광고가 닫힌 후 호출되는 콜백
  /// [onAdFailedToShow] 광고 표시 실패 시 호출되는 콜백 (선택사항)
  /// [onUserEarnedReward] 사용자가 보상을 획득했을 때 호출되는 콜백 (선택사항)
  Future<void> _showRewardedAd({
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
    Function(RewardItem)? onUserEarnedReward,
  }) async {
    debugPrint('🔍 [AdService] _showRewardedAd 호출');
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

    if (_useAdsConfig) {
      // ios_ads/android_ads 설정 사용
      if (nextAdType == 'rewarded_ad' || nextAdType == 'rewarded_test') {
        adUnitId = _rewardedAdId;
      } else {
        // 전면 광고 타입이면 showInterstitialAd를 호출해야 함
        debugPrint(
            '⚠️ [AdService] showRewardedAd 호출되었지만 전면 광고 타입입니다: $nextAdType');
        debugPrint('⚠️ [AdService] showInterstitialAd를 호출해야 합니다.');
        onAdDismissed();
        return;
      }
    } else {
      // 기존 방식: _adsType이 rewarded_ad여야 함
      if (_adsType != 'rewarded_ad') {
        debugPrint('⚠️ [AdService] _showRewardedAd 호출되었지만 보상형 광고 타입이 아닙니다.');
        debugPrint('⚠️ [AdService] _showInterstitialAd를 호출해야 합니다.');
        onAdDismissed();
        return;
      }
      adUnitId = _rewardedAdId;
    }

    if (adUnitId == null || adUnitId.isEmpty) {
      // If no ad ID, just proceed
      debugPrint('❌ [AdService] 광고 ID가 없습니다. adUnitId: $adUnitId');
      onAdDismissed();
      return;
    }

    debugPrint('🔍 [AdService] 보상형 광고 로드 시작: adUnitId=$adUnitId');

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
              debugPrint(
                  '🎁 [AdService] 보상 획득: ${reward.amount} ${reward.type}');
              onUserEarnedReward?.call(reward);
            },
          );
        },
        onAdFailedToLoad: (error) {
          // If ad fails to load, proceed anyway
          onAdFailedToShow?.call();
        },
      ),
    );
  }

  bool _isCompatiblePreload(String nextAdType) {
    final preloaded = _preloadedType;
    if (preloaded == null) return false;
    if (preloaded == nextAdType) return true;
    final rewarded = {'rewarded_ad', 'rewarded_test'};
    final interstitial = {'initial_ad', 'interstitial_ad'};
    return (rewarded.contains(preloaded) && rewarded.contains(nextAdType)) ||
        (interstitial.contains(preloaded) && interstitial.contains(nextAdType));
  }

  void _attachAndShowRewarded(
    RewardedAd ad, {
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
    Function(RewardItem)? onUserEarnedReward,
  }) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdDismissed();
        _scheduleNextPreload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onAdFailedToShow?.call();
        _scheduleNextPreload();
      },
    );
    ad.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('🎁 [AdService] 보상 획득: ${reward.amount} ${reward.type}');
        onUserEarnedReward?.call(reward);
      },
    );
  }

  void _attachAndShowInterstitial(
    InterstitialAd ad, {
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdDismissed();
        _scheduleNextPreload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onAdFailedToShow?.call();
        _scheduleNextPreload();
      },
    );
    ad.show();
  }

  /// 광고 타입에 따라 자동으로 전면 광고 또는 보상형 광고 표시
  ///
  /// [preloadAd]로 미리 로드된 광고가 있으면 즉시 표시하고,
  /// 없으면 그 시점에 로드합니다. 닫힌 뒤에는 다음 광고를 preload합니다.
  ///
  /// [onAdDismissed] 광고가 닫힌 후 호출되는 콜백
  /// [onAdFailedToShow] 광고 표시 실패 시 호출되는 콜백 (선택사항)
  /// [onUserEarnedReward] 보상형 광고 시 사용자가 보상을 획득했을 때 호출되는 콜백 (선택사항)
  Future<void> showAd({
    required VoidCallback onAdDismissed,
    VoidCallback? onAdFailedToShow,
    Function(RewardItem)? onUserEarnedReward,
  }) async {
    debugPrint('🔍 [AdService] showAd 호출 (자동 타입 결정)');

    // preload 중이면 잠시 기다려 캐시를 우선 사용
    if (_isPreloading && _preloadCompleter != null) {
      debugPrint('⏳ [AdService] preload 완료 대기…');
      try {
        await _preloadCompleter!.future.timeout(const Duration(seconds: 8));
      } catch (_) {}
    }

    final nextAdType = await _getNextAdType();
    debugPrint('🔍 [AdService] 결정된 광고 타입: $nextAdType');

    if (nextAdType == null) {
      debugPrint('ℹ️ [AdService] 광고 표시 안 함 (nextAdType이 null)');
      onAdDismissed();
      return;
    }

    final resolved = _resolveAdUnit(nextAdType);
    final adUnitId = resolved.adUnitId;
    final isRewarded = resolved.isRewarded;

    if (adUnitId == null || adUnitId.isEmpty) {
      debugPrint('❌ [AdService] 광고 ID가 없습니다. adUnitId: $adUnitId');
      onAdDismissed();
      return;
    }

    // Preloaded 광고가 타입에 맞으면 즉시 표시
    if (_isCompatiblePreload(nextAdType)) {
      if (isRewarded && _preloadedRewarded != null) {
        final ad = _preloadedRewarded!;
        _preloadedRewarded = null;
        _preloadedType = null;
        debugPrint('⚡ [AdService] preloaded rewarded 즉시 표시');
        _attachAndShowRewarded(
          ad,
          onAdDismissed: onAdDismissed,
          onAdFailedToShow: onAdFailedToShow,
          onUserEarnedReward: onUserEarnedReward,
        );
        return;
      }
      if (!isRewarded && _preloadedInterstitial != null) {
        final ad = _preloadedInterstitial!;
        _preloadedInterstitial = null;
        _preloadedType = null;
        debugPrint('⚡ [AdService] preloaded interstitial 즉시 표시');
        _attachAndShowInterstitial(
          ad,
          onAdDismissed: onAdDismissed,
          onAdFailedToShow: onAdFailedToShow,
        );
        return;
      }
    } else if (isAdReady) {
      debugPrint(
        '⚠️ [AdService] preload 타입 불일치 '
        '(cached=$_preloadedType, need=$nextAdType) → 폐기 후 로드',
      );
      _clearPreloadedAds();
    }

    debugPrint(
      '🔍 [AdService] 광고 로드 시작: adUnitId=$adUnitId, isRewarded=$isRewarded',
    );

    if (isRewarded) {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _attachAndShowRewarded(
              ad,
              onAdDismissed: onAdDismissed,
              onAdFailedToShow: onAdFailedToShow,
              onUserEarnedReward: onUserEarnedReward,
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ [AdService] rewarded 로드 실패: $error');
            onAdFailedToShow?.call();
            _scheduleNextPreload();
          },
        ),
      );
    } else {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _attachAndShowInterstitial(
              ad,
              onAdDismissed: onAdDismissed,
              onAdFailedToShow: onAdFailedToShow,
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ [AdService] interstitial 로드 실패: $error');
            onAdFailedToShow?.call();
            _scheduleNextPreload();
          },
        ),
      );
    }
  }
}
