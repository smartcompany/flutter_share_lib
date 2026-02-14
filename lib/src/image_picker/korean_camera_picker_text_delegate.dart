import 'package:wechat_camera_picker/wechat_camera_picker.dart'
    show CameraLensDirection, CameraPickerTextDelegate, FlashMode;

/// 카메라 피커 한국어 텍스트
class KoreanCameraPickerTextDelegate extends CameraPickerTextDelegate {
  const KoreanCameraPickerTextDelegate();

  @override
  String get languageCode => 'ko';

  @override
  String get confirm => '확인';

  @override
  String get shootingTips => '탭하여 촬영';

  @override
  String get shootingWithRecordingTips => '탭하여 촬영, 길게 눌러 녹화';

  @override
  String get shootingOnlyRecordingTips => '길게 눌러 녹화';

  @override
  String get shootingTapRecordingTips => '탭하여 녹화';

  @override
  String get loadFailed => '로드 실패';

  @override
  String get loading => '로딩 중...';

  @override
  String get saving => '저장 중...';

  @override
  String get sActionManuallyFocusHint => '수동 초점';

  @override
  String get sActionPreviewHint => '미리보기';

  @override
  String get sActionRecordHint => '녹화';

  @override
  String get sActionShootHint => '촬영';

  @override
  String get sActionShootingButtonTooltip => '촬영 버튼';

  @override
  String get sActionStopRecordingHint => '녹화 중지';

  @override
  String sCameraLensDirectionLabel(CameraLensDirection value) {
    switch (value) {
      case CameraLensDirection.front:
        return '전면';
      case CameraLensDirection.back:
        return '후면';
      case CameraLensDirection.external:
        return '외장';
    }
  }

  @override
  String? sCameraPreviewLabel(CameraLensDirection? value) {
    if (value == null) return null;
    return '${sCameraLensDirectionLabel(value)} 카메라 미리보기';
  }

  @override
  String sFlashModeLabel(FlashMode mode) {
    final String modeString;
    switch (mode) {
      case FlashMode.off:
        modeString = '끄기';
        break;
      case FlashMode.auto:
        modeString = '자동';
        break;
      case FlashMode.always:
        modeString = '촬영 시 플래시';
        break;
      case FlashMode.torch:
        modeString = '항상 켜기';
        break;
    }
    return '플래시: $modeString';
  }

  @override
  String sSwitchCameraLensDirectionLabel(CameraLensDirection value) =>
      '${sCameraLensDirectionLabel(value)} 카메라로 전환';
}
