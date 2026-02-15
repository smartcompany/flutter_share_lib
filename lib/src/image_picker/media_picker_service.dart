import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
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
  /// 기본적으로 이미지를 압축하여 반환합니다 (Vercel 4.5MB 제한 등 대응).
  ///
  /// [context] - 빌드 컨텍스트
  /// [maxCount] - 최대 선택 개수 (기본 9)
  /// [permissionDeniedMessage] - 권한 거부 시 표시할 메시지
  /// [compress] - 압축 적용 여부 (기본 true)
  /// [maxWidth] - 압축 시 최대 너비 (기본 1920)
  /// [maxHeight] - 압축 시 최대 높이 (기본 1080)
  /// [quality] - 압축 품질 1~100 (기본 80)
  /// [compressFailureMessage] - 압축 실패 시 표시할 메시지
  ///
  /// 반환: 선택/촬영된 이미지의 [XFile] 목록. 취소/압축 실패 시 null.
  static Future<List<XFile>?> pickImages(
    BuildContext context, {
    int maxCount = 9,
    String permissionDeniedMessage = '앨범 접근 권한이 필요합니다',
    bool compress = true,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 80,
    String compressFailureMessage = '이미지 압축 실패',
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

    final dir = await getTemporaryDirectory();
    final List<XFile> files = [];
    for (var i = 0; i < result.length; i++) {
      final entity = result[i];
      final file = await entity.file;
      if (file == null) continue;

      if (compress) {
        final targetPath =
            '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: quality,
          minWidth: maxWidth,
          minHeight: maxHeight,
        );
        if (compressed != null) {
          files.add(XFile(compressed.path));
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(compressFailureMessage)),
            );
          }
          return null;
        }
      } else {
        files.add(XFile(file.path));
      }
    }
    return files;
  }
}
