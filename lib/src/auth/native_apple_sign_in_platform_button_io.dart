import 'dart:io' show Platform;
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS만 [UiKitView] + `ASAuthorizationAppleIDButton` (Apple HIG 시스템 버튼).
class ShareLibNativeAppleSignInButton extends StatefulWidget {
  const ShareLibNativeAppleSignInButton({
    super.key,
    required this.onPressed,
    this.height = 56,
    this.cornerRadius = 16,
    this.style = 0,
    /// HIG 예시는 전체 화면 너비보다 좁은 캡슐에 가깝다. `null`이면 부모 너비 전체.
    this.maxButtonWidth = 375,
  });

  final VoidCallback onPressed;
  final double height;
  final double cornerRadius;

  /// pt. 시스템이 그리는 ·텍스트 절대 크기는 높이에 따르고, 가로를 과하게 쓰면 빈 여백만 넓어져 로고가 작아 보인다.
  final double? maxButtonWidth;

  /// 0=black, 1=white, 2=whiteOutline (iOS 네이티브 enum과 동일)
  final int style;

  @override
  State<ShareLibNativeAppleSignInButton> createState() =>
      _ShareLibNativeAppleSignInButtonState();
}

class _ShareLibNativeAppleSignInButtonState
    extends State<ShareLibNativeAppleSignInButton> {
  MethodChannel? _channel;

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cap = widget.maxButtonWidth;
        final w = cap == null
            ? constraints.maxWidth
            : min(constraints.maxWidth, cap);
        return Center(
          child: SizedBox(
            width: w,
            height: widget.height,
            child: UiKitView(
              viewType: 'share_lib/native_apple_sign_in_button',
              layoutDirection: TextDirection.ltr,
              creationParams: <String, dynamic>{
                'style': widget.style,
                'cornerRadius': widget.cornerRadius,
              },
              creationParamsCodec: const StandardMessageCodec(),
              onPlatformViewCreated: _onPlatformViewCreated,
            ),
          ),
        );
      },
    );
  }

  void _onPlatformViewCreated(int id) {
    _channel?.setMethodCallHandler(null);
    _channel = MethodChannel(
      'share_lib/native_apple_sign_in_button_$id',
    );
    _channel!.setMethodCallHandler((call) async {
      if (call.method == 'tap' && mounted) {
        widget.onPressed();
      }
      return null;
    });
  }
}
