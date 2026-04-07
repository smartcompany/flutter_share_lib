import 'package:flutter/widgets.dart';

/// 웹 등 `dart:io` 없음 — 네이티브 애플 버튼 없음.
class ShareLibNativeAppleSignInButton extends StatelessWidget {
  const ShareLibNativeAppleSignInButton({
    super.key,
    required this.onPressed,
    this.height = 56,
    this.cornerRadius = 16,
    this.style = 0,
    this.maxButtonWidth = 375,
  });

  final VoidCallback onPressed;
  final double height;
  final double cornerRadius;

  /// iOS 전용 (stub에서는 무시)
  final int style;

  /// iOS 전용 (stub에서는 무시)
  final double? maxButtonWidth;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
