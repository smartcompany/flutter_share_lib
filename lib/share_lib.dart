/// 공유 기능 및 광고 서비스 라이브러리
///
/// 다른 Flutter 앱에서 재사용 가능한 공유 기능과 광고 서비스를 제공합니다.
///
/// 사용 예시:
/// ```dart
/// import 'package:share_lib/share_lib.dart';
///
/// // 카카오톡 공유
/// await ShareService.shareToKakao(
///   '공유할 텍스트',
///   onSuccess: () => print('성공'),
/// );
///
/// // 기본 공유
/// await ShareService.shareText('공유할 텍스트');
///
/// // 이미지 포함 공유
/// await ShareService.shareWithImage('텍스트', imageBytes);
///
/// // 클립보드 복사
/// await ShareService.copyToClipboard('복사할 텍스트');
///
/// // 광고 서비스 (서버 주소만 전달하면 모든 설정을 자동으로 가져옵니다)
/// AdService.shared.setBaseUrl('https://your-server.com');
/// await AdService.shared.loadSettings();
/// await AdService.shared.showInterstitialAd(
///   onAdDismissed: () => print('광고 닫힘'),
/// );
/// ```
library share_lib;

export 'src/share_service.dart';
export 'src/ad_service.dart';
export 'src/auth/auth_config.dart';
export 'src/auth/auth_service_interface.dart';
export 'src/auth/auth_provider.dart';
export 'src/auth/auth_screen.dart';
export 'src/auth/login_required_screen.dart';
export 'src/auth/auth_helper.dart';
export 'src/auth/generated/auth_localizations.dart';
