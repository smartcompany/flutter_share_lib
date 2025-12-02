/// 공유 기능 라이브러리
///
/// 다른 Flutter 앱에서 재사용 가능한 공유 기능을 제공합니다.
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
/// ```
library share_lib;

export 'src/share_service.dart';
