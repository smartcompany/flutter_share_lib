import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// [Sign in with Google](https://developers.google.com/identity/branding-guidelines) — outlined light button, multicolor G mark, no logo distortion.
class ShareLibGoogleSignInButton extends StatelessWidget {
  const ShareLibGoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.borderRadius = 16,
    /// iOS `ASAuthorizationAppleIDButton` 등과 맞추기 위한 외곽 높이 (pt).
    this.height = 56,
    /// 애플 버튼과 동일한 시각적 너비. `null`이면 부모 너비 전체.
    this.maxButtonWidth = 375,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final double borderRadius;
  final double height;
  final double? maxButtonWidth;

  static const _assetPath = 'packages/share_lib/assets/branding/google_g_logo.svg';

  /// Google neutral outline stroke (branding guidelines).
  static const _outline = Color(0xFF747775);

  /// Recommended label color on light background.
  static const _labelColor = Color(0xFF1F1F1F);

  /// Google Identity 브랜딩(웹 버튼 스펙)과 맞춤: 본문 14px, 행간 20px.
  static const _fontSize = 14.0;
  static const _lineHeightPx = 20.0;
  static const _logoSize = 18.0;
  /// 로고 오른쪽·텍스트 간격 (가이드 예시 8–12pt 대역).
  static const _gapLogoText = 10.0;

  @override
  Widget build(BuildContext context) {
    final lineHeight = _lineHeightPx / _fontSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cap = maxButtonWidth;
        final w = cap == null
            ? constraints.maxWidth
            : min(constraints.maxWidth, cap);
        return Center(
          child: SizedBox(
            width: w,
            height: height,
            child: OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _labelColor,
                padding: EdgeInsets.zero,
                minimumSize: Size(w, height),
                maximumSize: Size(w, height),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                side: const BorderSide(color: _outline, width: 1),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: _logoSize,
                        height: _logoSize,
                        child: SvgPicture.asset(
                          _assetPath,
                          fit: BoxFit.contain,
                          semanticsLabel: 'Google',
                        ),
                      ),
                      const SizedBox(width: _gapLogoText),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: _fontSize,
                          fontWeight: FontWeight.w500,
                          color: _labelColor,
                          height: lineHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
