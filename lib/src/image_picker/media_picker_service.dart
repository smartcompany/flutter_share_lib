import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import 'korean_camera_picker_text_delegate.dart';

/// 앨범 그리드 + 왼쪽 첫 칸 촬영 아이콘 스타일의 미디어 피커 서비스
///
/// 사용 예시:
/// ```dart
/// final files = await MediaPickerService.pickImages(context, maxCount: 9);
/// if (files != null && files.isNotEmpty) {
///   // 업로드 등 처리
/// }
/// ```
class MediaPickerService {
  MediaPickerService._();

  /// 앨범에서 이미지를 선택하거나 촬영 아이콘을 통해 카메라로 촬영합니다.
  /// 앨범 그리드 왼쪽 첫 칸에 촬영 아이콘이 표시됩니다.
  ///
  /// [context] - 빌드 컨텍스트
  /// [maxCount] - 최대 선택 개수 (기본 9)
  /// [permissionDeniedMessage] - 권한 거부 시 표시할 메시지
  ///
  /// 반환: 선택/촬영된 이미지의 [XFile] 목록. 취소 시 null 또는 빈 목록.
  static Future<List<XFile>?> pickImages(
    BuildContext context, {
    int maxCount = 9,
    String permissionDeniedMessage = '앨범 접근 권한이 필요합니다',
  }) async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(permissionDeniedMessage)),
        );
      }
      return null;
    }

    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: maxCount,
        selectedAssets: const [],
        requestType: RequestType.image,
        textDelegate: const KoreanAssetPickerTextDelegate(),
        specialItemPosition: SpecialItemPosition.prepend,
        specialItemBuilder: (
          BuildContext context,
          AssetPathEntity? path,
          int length,
        ) {
          if (path?.isAll != true) return null;
          return Semantics(
            label: '촬영',
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                Feedback.forTap(context);
                final navigator = Navigator.maybeOf(context);
                final AssetEntity? cameraResult = await CameraPicker.pickFromCamera(
                  context,
                  pickerConfig: CameraPickerConfig(
                    enableRecording: false,
                    textDelegate: const KoreanCameraPickerTextDelegate(),
                  ),
                );
                if (cameraResult != null && navigator != null) {
                  navigator.pop(<AssetEntity>[cameraResult]);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(28.0),
                color: Theme.of(context).dividerColor,
                child: const FittedBox(
                  fit: BoxFit.fill,
                  child: Icon(Icons.camera_enhance),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result == null || result.isEmpty) return null;

    final List<XFile> files = [];
    for (final entity in result) {
      final file = await entity.file;
      if (file != null) files.add(XFile(file.path));
    }
    return files;
  }
}
