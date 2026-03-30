import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'auth_config.dart';
import 'generated/auth_localizations.dart';

// LocalizedException과 AccountNotFoundException을 사용하기 위해 import
// auth_provider.dart에서 export됨

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
  OverlayEntry? _loadingOverlayEntry;
  bool _isOverlayShown = false;

  void _setLoadingOverlay(bool show) {
    if (!mounted) return;
    if (show) {
      if (_loadingOverlayEntry != null) return;
      _loadingOverlayEntry = OverlayEntry(
        builder: (context) => IgnorePointer(
          child: SizedBox.expand(
            child: Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );
      final overlay = Overlay.of(context);
      overlay?.insert(_loadingOverlayEntry!);
      _isOverlayShown = true;
      return;
    }

    if (!show && _loadingOverlayEntry != null) {
      _loadingOverlayEntry!.remove();
      _loadingOverlayEntry = null;
      _isOverlayShown = false;
    }
  }

  @override
  void dispose() {
    _loadingOverlayEntry?.remove();
    _loadingOverlayEntry = null;
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
    // LocalizedException인 경우 직접 처리
    if (error is LocalizedException) {
      switch (error.localizationKey) {
        case 'accountNotFoundMessage':
          return localizations.accountNotFoundMessage;
        case 'wrongPassword':
          return localizations.wrongPassword;
        case 'emailAlreadyInUse':
          return localizations.emailAlreadyInUse;
        case 'invalidEmail':
          return localizations.invalidEmail;
        case 'loginFailed':
          return localizations.loginFailed(error.parameters?['message'] ?? '');
        case 'weakPassword':
          return localizations.weakPassword;
        case 'emailAlreadyInUseSignUp':
          return localizations.emailAlreadyInUseSignUp;
        case 'signUpFailed':
          return localizations.signUpFailed(error.parameters?['message'] ?? '');
        case 'kakaoPluginNotRegistered':
          return localizations.kakaoPluginNotRegistered;
        case 'kakaoSdkNotInitialized':
          return localizations.kakaoSdkNotInitialized;
        case 'appleLoginNotAvailable':
          return localizations.appleLoginNotAvailable;
        case 'appleLoginTimeout':
          return localizations.appleLoginTimeout;
        case 'appleLoginFailed':
          return localizations.appleLoginFailed;
        case 'applePluginNotRegistered':
          return localizations.applePluginNotRegistered;
        case 'googleLoginTimeout':
          return localizations.googleLoginTimeout;
        case 'googleAuthTimeout':
          return localizations.googleAuthTimeout;
        case 'googleTokenError':
          return localizations.googleTokenError;
        case 'googlePluginNotRegistered':
          return localizations.googlePluginNotRegistered;
        case 'firebaseLoginTimeout':
          return localizations.firebaseLoginTimeout;
        case 'passwordResetFailed':
          return localizations
              .passwordResetFailed(error.parameters?['message'] ?? '');
        default:
          return error.localizationKey;
      }
    }

    final errorString = error.toString();

    // 커스텀 에러 메시지 빌더가 있으면 사용
    if (widget.config.errorMessageBuilder != null) {
      return widget.config.errorMessageBuilder!(errorString);
    }

    // AccountNotFoundException인 경우
    if (error is AccountNotFoundException) {
      if (error.message == 'accountNotFoundMessage') {
        return localizations.accountNotFoundMessage;
      }
      return error.message;
    }

    // 로컬라이즈된 에러 메시지 처리
    // 계정이 없을 때
    if (errorString.contains('등록되지 않은 이메일입니다') ||
        errorString.contains('This email is not registered') ||
        errorString.contains('このメールアドレスは登録されていません') ||
        errorString.contains('此电子邮件未注册')) {
      return localizations.accountNotFoundMessage;
    }
    // 비밀번호가 틀렸을 때
    if (errorString.contains('비밀번호가 올바르지 않습니다') ||
        errorString.contains('Incorrect password') ||
        errorString.contains('パスワードが正しくありません') ||
        errorString.contains('密码不正确') ||
        errorString.contains('wrong-password')) {
      return localizations.wrongPassword;
    }
    // 이메일이 이미 사용 중일 때
    if (errorString.contains('이 이메일은 이미 사용 중입니다') ||
        errorString.contains('This email is already in use') ||
        errorString.contains('このメールアドレスは既に使用されています') ||
        errorString.contains('此电子邮件已被使用')) {
      return localizations.emailAlreadyInUse;
    }
    // 이메일 형식이 잘못되었을 때
    if (errorString.contains('이메일 형식이 올바르지 않습니다') ||
        errorString.contains('Invalid email format') ||
        errorString.contains('メールアドレスの形式が正しくありません') ||
        errorString.contains('电子邮件格式不正确') ||
        errorString.contains('invalid-email')) {
      return localizations.invalidEmail;
    }
    // 로그인 실패
    if (errorString.contains('로그인에 실패했습니다') ||
        errorString.contains('Login failed')) {
      // 메시지에서 실제 에러 메시지 추출
      final match = RegExp(r':\s*(.+)$').firstMatch(errorString);
      if (match != null) {
        return localizations.loginFailed(match.group(1) ?? '');
      }
      return localizations.loginFailed('');
    }
    // 비밀번호가 약함
    if (errorString.contains('비밀번호가 너무 약합니다') ||
        errorString.contains('Password is too weak') ||
        errorString.contains('パスワードが弱すぎます') ||
        errorString.contains('密码太弱')) {
      return localizations.weakPassword;
    }
    // 회원가입 실패
    if (errorString.contains('회원가입에 실패했습니다') ||
        errorString.contains('Sign up failed')) {
      final match = RegExp(r':\s*(.+)$').firstMatch(errorString);
      if (match != null) {
        return localizations.signUpFailed(match.group(1) ?? '');
      }
      return localizations.signUpFailed('');
    }
    // 카카오 플러그인 미등록
    if (errorString.contains('카카오 로그인 플러그인이 등록되지 않았습니다') ||
        errorString.contains('Kakao login plugin is not registered')) {
      return localizations.kakaoPluginNotRegistered;
    }
    // 카카오 SDK 미초기화
    if (errorString.contains('카카오 SDK가 초기화되지 않았습니다') ||
        errorString.contains('Kakao SDK is not initialized')) {
      return localizations.kakaoSdkNotInitialized;
    }
    // 애플 로그인 사용 불가
    if (errorString.contains('애플 로그인을 사용할 수 없습니다') ||
        errorString.contains('Apple login is not available')) {
      return localizations.appleLoginNotAvailable;
    }
    // 애플 로그인 타임아웃
    if (errorString.contains('애플 로그인이 시간 초과되었습니다') ||
        errorString.contains('Apple login timed out')) {
      return localizations.appleLoginTimeout;
    }
    // 애플 로그인 실패
    if (errorString.contains('Apple 로그인에 실패했습니다') ||
        errorString.contains('Apple login failed')) {
      return localizations.appleLoginFailed;
    }
    // 애플 플러그인 미등록
    if (errorString.contains('Apple 로그인 플러그인이 등록되지 않았습니다') ||
        errorString.contains('Apple login plugin is not registered')) {
      return localizations.applePluginNotRegistered;
    }
    // 구글 로그인 타임아웃
    if (errorString.contains('구글 로그인이 시간 초과되었습니다') ||
        errorString.contains('Google login timed out')) {
      return localizations.googleLoginTimeout;
    }
    // 구글 인증 정보 타임아웃
    if (errorString.contains('구글 인증 정보를 가져오는 중 시간 초과되었습니다') ||
        errorString
            .contains('Timed out while retrieving Google authentication')) {
      return localizations.googleAuthTimeout;
    }
    // 구글 토큰 에러
    if (errorString.contains('Google 로그인 토큰을 가져올 수 없습니다') ||
        errorString.contains('Unable to retrieve Google login token')) {
      return localizations.googleTokenError;
    }
    // 구글 플러그인 미등록
    if (errorString.contains('Google 로그인 플러그인이 등록되지 않았습니다') ||
        errorString.contains('Google login plugin is not registered')) {
      return localizations.googlePluginNotRegistered;
    }
    // Firebase 로그인 타임아웃
    if (errorString.contains('Firebase 로그인이 시간 초과되었습니다') ||
        errorString.contains('Firebase login timed out')) {
      return localizations.firebaseLoginTimeout;
    }
    // 비밀번호 재설정 실패
    if (errorString.contains('비밀번호 재설정 이메일 전송에 실패했습니다') ||
        errorString.contains('Failed to send password reset email')) {
      final match = RegExp(r':\s*(.+)$').firstMatch(errorString);
      if (match != null) {
        return localizations.passwordResetFailed(match.group(1) ?? '');
      }
      return localizations.passwordResetFailed('');
    }
    // 기타 에러 메시지
    if (errorString.contains('SocketException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('Connection refused')) {
      return localizations.serverConnectionError;
    } else if (errorString.contains('Invalid email or password') ||
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
    debugPrint('🟡 [AuthScreen] 이메일 로그인 버튼 클릭됨');
    final localizations = widget.config.getLocalizations(context);

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      debugPrint('⚠️ [AuthScreen] 이메일 또는 비밀번호가 비어있음');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.emailPasswordRequired)),
      );
      return;
    }

    if (_isEmailLoading || _isSocialLoading) {
      debugPrint('⚠️ [AuthScreen] 이미 로딩 중이므로 스킵');
      return;
    }

    debugPrint('🟡 [AuthScreen] 로딩 상태 true로 설정');
    setState(() {
      _isEmailLoading = true;
    });

    try {
      debugPrint('🟡 [AuthScreen] AuthProvider 가져오기...');
      final authProvider = context.read<AuthProvider<T>>();
      debugPrint('🟡 [AuthScreen] loginWithEmail 호출 전...');
      debugPrint('🟡 [AuthScreen] 이메일: ${_emailController.text.trim()}');

      await authProvider.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      debugPrint('✅ [AuthScreen] loginWithEmail 완료');

      if (!mounted) {
        debugPrint('⚠️ [AuthScreen] 위젯이 dispose됨');
        return;
      }

      debugPrint('🟡 [AuthScreen] 로그인 완료 (프로필 설정은 앱에서 처리)');

      if (mounted) {
        debugPrint('🟡 [AuthScreen] 로그인 화면 닫기...');
        Navigator.of(context).pop(true);
      }
    } on AccountNotFoundException catch (e) {
      // 계정이 없는 경우 회원가입 여부 확인 다이얼로그 표시
      debugPrint('🟡 [AuthScreen] 계정이 없음 - 회원가입 여부 확인 다이얼로그 표시');
      if (!mounted) return;

      final localizations = widget.config.getLocalizations(context);
      final shouldSignUp = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.signUpTitle),
          content: Text(localizations.accountNotFoundMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localizations.signUp),
            ),
          ],
        ),
      );

      if (shouldSignUp == true && mounted) {
        // 비밀번호 확인 다이얼로그 표시
        final passwordConfirmController = TextEditingController();
        final localizations = widget.config.getLocalizations(context);
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.passwordConfirmTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(localizations.passwordConfirmMessage),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordConfirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: localizations.passwordConfirmLabel,
                      border: const OutlineInputBorder(),
                    ),
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => Navigator.pop(context, true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(localizations.confirm),
              ),
            ],
          ),
        );

        if (shouldProceed == true && mounted) {
          final password = _passwordController.text;
          final passwordConfirm = passwordConfirmController.text;

          if (password != passwordConfirm) {
            final localizations = widget.config.getLocalizations(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.passwordMismatch),
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }

          // 회원가입 진행
          try {
            final authProvider = context.read<AuthProvider<T>>();
            await authProvider.signUpWithEmail(
              _emailController.text.trim(),
              password,
            );

            if (!mounted) return;

            if (mounted) {
              Navigator.of(context).pop(true);
            }
          } catch (signUpError) {
            if (!mounted) return;
            final localizations = widget.config.getLocalizations(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_getErrorMessage(signUpError, localizations)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AuthScreen] 이메일 로그인 에러: $e');
      debugPrint('❌ [AuthScreen] 에러 타입: ${e.runtimeType}');
      debugPrint('❌ [AuthScreen] 에러 문자열: ${e.toString()}');
      debugPrint('❌ [AuthScreen] 스택 트레이스: $stackTrace');

      if (!mounted) return;
      final localizations = widget.config.getLocalizations(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e, localizations)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (!mounted) {
        debugPrint('⚠️ [AuthScreen] 위젯이 dispose되어 로딩 상태 복구 안함');
        return;
      }
      debugPrint('🟡 [AuthScreen] 로딩 상태 false로 복구');
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
        debugPrint('🟡 [AuthScreen] 로그인 완료 (프로필 설정은 앱에서 처리)');

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (!mounted) return;
        // 사용자가 구글 계정 선택 화면에서 취소한 경우 → 로그인 화면은 유지, 에러 메시지 없음
        if (e is LocalizedException &&
            e.localizationKey == 'googleLoginCancelled') {
          return;
        }
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
    final isAnyLoading = _isEmailLoading || _isSocialLoading;
    if (isAnyLoading != _isOverlayShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setLoadingOverlay(isAnyLoading);
      });
      _isOverlayShown = isAnyLoading;
    }
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
                      cursorColor: Colors.black,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: localizations.emailLabel,
                        hintText: localizations.emailHint,
                        labelStyle: const TextStyle(color: Colors.black),
                        hintStyle:
                            TextStyle(color: Colors.black.withOpacity(0.55)),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.black,
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
                      enabled: !_isEmailLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      cursorColor: Colors.black,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: localizations.passwordLabel,
                        hintText: localizations.passwordHint,
                        labelStyle: const TextStyle(color: Colors.black),
                        hintStyle:
                            TextStyle(color: Colors.black.withOpacity(0.55)),
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: Colors.black,
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
                      enabled: !_isEmailLoading,
                      onSubmitted: (_) => _handleEmailLogin(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isEmailLoading ? null : _handleEmailLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
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
            // 로딩 딤은 OverlayEntry로 처리 (AppBar/하단까지 전 영역 덮기)
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
