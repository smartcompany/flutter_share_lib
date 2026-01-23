import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'auth_config.dart';
import 'generated/auth_localizations.dart';

/// 공통 인증 화면
/// 설정에 따라 소셜 로그인 및 이메일 로그인을 제공합니다.
class AuthScreen<T> extends StatefulWidget {
  final AuthConfig config;

  const AuthScreen({super.key, required this.config});

  @override
  State<AuthScreen<T>> createState() => _AuthScreenState<T>();
}

class _AuthScreenState<T> extends State<AuthScreen<T>> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSocialLoading = false;
  bool _isEmailLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runSocialLogin(Future<void> Function() action) async {
    debugPrint(
        '🟡 [AuthScreen] _runSocialLogin 시작, 현재 로딩 상태: $_isSocialLoading, $_isEmailLoading');
    if (_isSocialLoading || _isEmailLoading) {
      debugPrint('⚠️ [AuthScreen] 이미 로딩 중이므로 스킵');
      return;
    }
    debugPrint('🟡 [AuthScreen] 로딩 상태 true로 설정');
    setState(() {
      _isSocialLoading = true;
    });
    try {
      debugPrint('🟡 [AuthScreen] action 실행 시작');
      await action();
      debugPrint('✅ [AuthScreen] action 실행 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ [AuthScreen] _runSocialLogin 에러: $e');
      debugPrint('❌ [AuthScreen] 스택 트레이스: $stackTrace');
      rethrow;
    } finally {
      if (!mounted) {
        debugPrint('⚠️ [AuthScreen] 위젯이 dispose되어 로딩 상태 복구 안함');
        return;
      }
      debugPrint('🟡 [AuthScreen] 로딩 상태 false로 복구');
      setState(() {
        _isSocialLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error, AuthLocalizations localizations) {
    final errorString = error.toString();

    // 커스텀 에러 메시지 빌더가 있으면 사용
    if (widget.config.errorMessageBuilder != null) {
      return widget.config.errorMessageBuilder!(errorString);
    }

    // 로컬라이즈된 에러 메시지 처리
    if (errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('Connection refused')) {
      return localizations.serverConnectionError;
    } else if (errorString.contains('Invalid email or password') ||
        errorString.contains('wrong-password') ||
        errorString.contains('user-not-found')) {
      return localizations.invalidEmailPassword;
    } else if (errorString.contains('social login')) {
      return localizations.socialLoginRequired;
    } else if (errorString.contains('AuthorizationErrorCode.unknown') ||
        errorString.contains('AuthorizationError error 1000') ||
        errorString.contains('error 1000')) {
      return localizations.appleLoginError;
    } else if (errorString.contains('YOUR_KAKAO')) {
      return localizations.kakaoSdkNotConfigured;
    } else if (errorString.contains('channel-error') ||
        errorString.contains('Unable to establish connection')) {
      return localizations.pluginNotRegistered;
    }
    return errorString;
  }

  Future<void> _handleEmailLogin() async {
    final localizations = widget.config.getLocalizations(context);

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.emailPasswordRequired)),
      );
      return;
    }

    if (_isEmailLoading || _isSocialLoading) return;
    setState(() {
      _isEmailLoading = true;
    });
    try {
      final authProvider = context.read<AuthProvider<T>>();
      await authProvider.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final user = authProvider.user;

      // 프로필 설정 화면으로 이동 여부 확인
      if (user != null &&
          widget.config.shouldShowProfileSetup != null &&
          widget.config.shouldShowProfileSetup!(user)) {
        if (widget.config.profileSetupScreenBuilder != null) {
          final profileScreen = widget.config.profileSetupScreenBuilder!(
            context,
          );
          if (profileScreen != null) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => profileScreen));
            return;
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      final localizations = widget.config.getLocalizations(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e, localizations)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isEmailLoading = false;
      });
    }
  }

  Future<void> _handleSocialLogin(
    Future<void> Function() loginAction,
    String providerName,
  ) async {
    debugPrint(
        '🟡 [AuthScreen] _handleSocialLogin 함수 시작, provider: $providerName');
    await _runSocialLogin(() async {
      try {
        debugPrint('🟡 [AuthScreen] _runSocialLogin 내부, loginAction 실행 시작');
        await loginAction();
        debugPrint('🟡 [AuthScreen] loginAction 완료');
        if (!mounted) {
          debugPrint('⚠️ [AuthScreen] 위젯이 dispose됨');
          return;
        }
        debugPrint('🟡 [AuthScreen] 사용자 정보 확인 중...');
        final authProvider = context.read<AuthProvider<T>>();
        final user = authProvider.user;
        debugPrint('🟡 [AuthScreen] 사용자: $user');

        // 프로필 설정 화면으로 이동 여부 확인
        if (user != null &&
            widget.config.shouldShowProfileSetup != null &&
            widget.config.shouldShowProfileSetup!(user)) {
          if (widget.config.profileSetupScreenBuilder != null) {
            final profileScreen = widget.config.profileSetupScreenBuilder!(
              context,
            );
            if (profileScreen != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => profileScreen),
              );
              return;
            }
          }
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (!mounted) return;
        final localizations = widget.config.getLocalizations(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e, localizations)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final localizations = config.getLocalizations(context);
    return Scaffold(
      backgroundColor: config.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          localizations.loginTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: config.textPrimaryColor,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: config.textPrimaryColor,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 소셜 로그인 버튼들
                  Column(
                    children: [
                      // 카카오 로그인
                      if (config.enableKakaoLogin)
                        _SocialLoginButton(
                          icon: '🟡',
                          text: localizations.kakaoLoginText,
                          backgroundColor: const Color(0xFFFEE500),
                          textColor: const Color(0xFF000000),
                          isLoading: _isSocialLoading,
                          onPressed: () {
                            try {
                              debugPrint('🟡 [AuthScreen] 카카오 로그인 버튼 클릭됨');
                              debugPrint('🟡 [AuthScreen] context 확인 중...');
                              final authProvider =
                                  context.read<AuthProvider<T>>();
                              debugPrint(
                                  '🟡 [AuthScreen] AuthProvider 가져옴: ${authProvider.runtimeType}');
                              debugPrint(
                                  '🟡 [AuthScreen] _handleSocialLogin 호출 전...');
                              _handleSocialLogin(
                                () {
                                  debugPrint(
                                      '🟡 [AuthScreen] _handleSocialLogin 콜백 실행 시작');
                                  return authProvider.loginWithKakao();
                                },
                                '카카오',
                              );
                              debugPrint(
                                  '🟡 [AuthScreen] _handleSocialLogin 호출 완료');
                            } catch (e, stackTrace) {
                              debugPrint('❌ [AuthScreen] 버튼 핸들러 에러: $e');
                              debugPrint('❌ [AuthScreen] 스택 트레이스: $stackTrace');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('에러 발생: $e'),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      if (config.enableKakaoLogin) const SizedBox(height: 12),

                      // 애플 로그인 (iOS만)
                      if (config.enableAppleLogin &&
                          Theme.of(context).platform == TargetPlatform.iOS)
                        _SocialLoginButton(
                          icon: '⚫',
                          text: localizations.appleLoginText,
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                          isLoading: _isSocialLoading,
                          onPressed: () {
                            try {
                              debugPrint('🟡 [AuthScreen] 애플 로그인 버튼 클릭됨');
                              debugPrint('🟡 [AuthScreen] context 확인 중...');
                              final authProvider =
                                  context.read<AuthProvider<T>>();
                              debugPrint(
                                  '🟡 [AuthScreen] AuthProvider 가져옴: ${authProvider.runtimeType}');
                              debugPrint(
                                  '🟡 [AuthScreen] _handleSocialLogin 호출 전...');
                              _handleSocialLogin(
                                () {
                                  debugPrint(
                                      '🟡 [AuthScreen] _handleSocialLogin 콜백 실행 시작');
                                  return authProvider.loginWithApple();
                                },
                                'Apple',
                              );
                              debugPrint(
                                  '🟡 [AuthScreen] _handleSocialLogin 호출 완료');
                            } catch (e, stackTrace) {
                              debugPrint('❌ [AuthScreen] 버튼 핸들러 에러: $e');
                              debugPrint('❌ [AuthScreen] 스택 트레이스: $stackTrace');
                              rethrow;
                            }
                          },
                        ),
                      if (config.enableAppleLogin &&
                          Theme.of(context).platform == TargetPlatform.iOS)
                        const SizedBox(height: 12),

                      // 구글 로그인
                      if (config.enableGoogleLogin)
                        _SocialLoginButton(
                          icon: '🔵',
                          text: localizations.googleLoginText,
                          backgroundColor: Colors.white,
                          textColor: config.textPrimaryColor,
                          borderColor: config.dividerColor,
                          isLoading: _isSocialLoading,
                          onPressed: () {
                            try {
                              debugPrint('🟡 [AuthScreen] 구글 로그인 버튼 클릭됨');
                              debugPrint('🟡 [AuthScreen] context 확인 중...');
                              final authProvider =
                                  context.read<AuthProvider<T>>();
                              debugPrint(
                                  '🟡 [AuthScreen] AuthProvider 가져옴: ${authProvider.runtimeType}');
                              debugPrint(
                                  '🟡 [AuthScreen] _handleSocialLogin 호출 전...');
                              _handleSocialLogin(
                                () {
                                  debugPrint(
                                      '🟡 [AuthScreen] _handleSocialLogin 콜백 실행 시작');
                                  return authProvider.loginWithGoogle();
                                },
                                'Google',
                              );
                              debugPrint(
                                  '🟡 [AuthScreen] _handleSocialLogin 호출 완료');
                            } catch (e, stackTrace) {
                              debugPrint('❌ [AuthScreen] 버튼 핸들러 에러: $e');
                              debugPrint('❌ [AuthScreen] 스택 트레이스: $stackTrace');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('에러 발생: $e'),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                    ],
                  ),
                  if (config.enableEmailLogin) ...[
                    const SizedBox(height: 32),
                    // 구분선
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: config.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            localizations.orDividerText,
                            style: TextStyle(
                              fontSize: 14,
                              color: config.textSecondaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: config.dividerColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // 이메일 로그인
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: localizations.emailLabel,
                        hintText: localizations.emailHint,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: config.textSecondaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: config.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: config.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: config.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isEmailLoading && !_isSocialLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: localizations.passwordLabel,
                        hintText: localizations.passwordHint,
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: config.textSecondaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: config.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: config.dividerColor.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: config.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enabled: !_isEmailLoading && !_isSocialLoading,
                      onSubmitted: (_) => _handleEmailLogin(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isEmailLoading || _isSocialLoading)
                            ? null
                            : _handleEmailLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isEmailLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                localizations.emailLoginButtonText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isSocialLoading || _isEmailLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String icon;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: borderColor ?? backgroundColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
