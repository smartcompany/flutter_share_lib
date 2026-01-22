import 'package:flutter/material.dart';
import 'auth_config.dart';

/// 로그인이 필요한 경우 표시하는 공통 화면 위젯
class LoginRequiredScreen extends StatelessWidget {
  /// 설정
  final AuthConfig config;

  /// 표시할 아이콘 (선택 사항, 기본값 사용)
  final IconData? icon;

  /// 제목 텍스트 (선택 사항, 기본값 사용)
  final String? title;

  /// 설명 텍스트 (선택 사항, 기본값 사용)
  final String? description;

  /// 로그인 버튼 표시 여부
  final bool showLoginButton;

  /// 로그인 버튼 텍스트
  final String? loginButtonText;

  /// 로그인 화면을 생성하는 빌더
  final Widget Function(BuildContext context)? authScreenBuilder;

  const LoginRequiredScreen({
    super.key,
    required this.config,
    this.icon,
    this.title,
    this.description,
    this.showLoginButton = true,
    this.loginButtonText,
    this.authScreenBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = config.getLocalizations(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  config.primaryColor.withOpacity(0.1),
                  config.primaryColor.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.lock_outline_rounded,
              size: 64,
              color: config.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title ?? localizations.loginRequiredTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: config.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              description ?? localizations.loginRequiredDescription,
              style: TextStyle(fontSize: 14, color: config.textTertiaryColor),
              textAlign: TextAlign.center,
            ),
          ),
          if (showLoginButton) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (authScreenBuilder != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: authScreenBuilder!,
                          fullscreenDialog: true,
                        ),
                      );
                    } else {
                      // 기본 AuthScreen 사용 (import 필요)
                      // 사용자가 authScreenBuilder를 제공해야 함
                      throw Exception(
                        'authScreenBuilder를 제공해야 합니다. LoginRequiredScreen에 authScreenBuilder 파라미터를 설정해주세요.',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ).copyWith(elevation: MaterialStateProperty.all(0)),
                  child: Text(
                    loginButtonText ?? localizations.loginButtonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
