/// 이미지 피커 모듈
///
/// 앨범 그리드 왼쪽 첫 칸에 촬영 아이콘이 있는 스타일의 이미지 선택기를 제공합니다.
///
/// 사용 예시:
/// ```dart
/// import 'package:share_lib/share_lib_image_picker.dart';
///
/// final files = await MediaPickerService.pickImages(context, maxCount: 9);
/// if (files != null && files.isNotEmpty) {
///   for (final xFile in files) {
///     final file = File(xFile.path);
///     // 업로드 등 처리
///   }
/// }
/// ```
///
/// iOS/Android 권한 설정:
/// - iOS: Info.plist에 NSPhotoLibraryUsageDescription, NSCameraUsageDescription
/// - Android: AndroidManifest에 READ_EXTERNAL_STORAGE, READ_MEDIA_IMAGES, CAMERA
library share_lib_image_picker;

export 'package:cross_file/cross_file.dart' show XFile;
export 'src/image_picker/media_picker_service.dart';
export 'src/image_picker/korean_camera_picker_text_delegate.dart';
