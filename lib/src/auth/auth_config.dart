import 'package:flutter/material.dart';
import 'generated/auth_localizations.dart';
import 'generated/auth_localizations_ko.dart';
import 'generated/auth_localizations_en.dart';

/// 인증 모듈 설정 클래스
/// 각 앱에서 사용자 정의 설정을 주입할 수 있습니다.
class AuthConfig {
  /// 강제할 로케일 (선택 사항)
  /// null이면 시스템 로케일을 사용합니다 (Localizations.of(context)를 통해 가져옴)
  final Locale? forcedLocale;

  /// 테마 색상 설정
  final Color primaryColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color textTertiaryColor;
  final Color dividerColor;
  final Color backgroundColor;

  /// 로그인 화면 타이틀 (deprecated: localizations 사용 권장)
  @Deprecated('Use localizations instead')
  final String? loginTitle;

  /// 소셜 로그인 버튼 텍스트 (deprecated: localizations 사용 권장)
  @Deprecated('Use localizations instead')
  final String? kakaoLoginText;
  @Deprecated('Use localizations instead')
  final String? appleLoginText;
  @Deprecated('Use localizations instead')
  final String? googleLoginText;

  /// 이메일 로그인 필드 레이블 (deprecated: localizations 사용 권장)
  @Deprecated('Use localizations instead')
  final String? emailLabel;
  @Deprecated('Use localizations instead')
  final String? passwordLabel;
  @Deprecated('Use localizations instead')
  final String? emailLoginButtonText;

  /// 로그인 필요 화면 설정 (deprecated: localizations 사용 권장)
  @Deprecated('Use localizations instead')
  final String? loginRequiredTitle;
  @Deprecated('Use localizations instead')
  final String? loginRequiredDescription;
  @Deprecated('Use localizations instead')
  final String? loginButtonText;

  /// 에러 메시지 커스터마이징 함수
  final String Function(String error)? errorMessageBuilder;

  /// 프로필이 완전하지 않을 때 이동할 화면을 생성하는 빌더
  /// null을 반환하면 프로필 설정 화면으로 이동하지 않음
  final Widget? Function(BuildContext context)? profileSetupScreenBuilder;

  /// 사용자가 로그인 성공 후 프로필이 완전한지 확인하는 함수
  /// true를 반환하면 프로필 설정 화면으로 이동
  final bool Function(dynamic user)? shouldShowProfileSetup;

  /// 소셜 로그인 활성화 여부
  final bool enableKakaoLogin;
  final bool enableAppleLogin;
  final bool enableGoogleLogin;
  final bool enableEmailLogin;

  const AuthConfig({
    this.forcedLocale,
    this.primaryColor = const Color(0xFF2196F3),
    this.textPrimaryColor = const Color(0xFF212121),
    this.textSecondaryColor = const Color(0xFF757575),
    this.textTertiaryColor = const Color(0xFF9E9E9E),
    this.dividerColor = const Color(0xFFE0E0E0),
    this.backgroundColor = const Color(0xFFF5F7FA),
    @Deprecated('Use localizations instead') this.loginTitle,
    @Deprecated('Use localizations instead') this.kakaoLoginText,
    @Deprecated('Use localizations instead') this.appleLoginText,
    @Deprecated('Use localizations instead') this.googleLoginText,
    @Deprecated('Use localizations instead') this.emailLabel,
    @Deprecated('Use localizations instead') this.passwordLabel,
    @Deprecated('Use localizations instead') this.emailLoginButtonText,
    @Deprecated('Use localizations instead') this.loginRequiredTitle,
    @Deprecated('Use localizations instead') this.loginRequiredDescription,
    @Deprecated('Use localizations instead') this.loginButtonText,
    this.errorMessageBuilder,
    this.profileSetupScreenBuilder,
    this.shouldShowProfileSetup,
    this.enableKakaoLogin = true,
    this.enableAppleLogin = true,
    this.enableGoogleLogin = true,
    this.enableEmailLogin = true,
  });

  /// BuildContext에서 로컬라이제이션 가져오기
  /// forcedLocale이 설정되어 있으면 그것을 사용하고,
  /// 없으면 시스템 로케일을 기반으로 가져옵니다.
  AuthLocalizations getLocalizations(BuildContext context) {
    try {
      final locale = forcedLocale ?? Localizations.localeOf(context);
      // Localizations.of(context)를 통해 가져오기 시도
      final localizations = AuthLocalizations.of(context);
      if (localizations != null && forcedLocale == null) {
        return localizations;
      }
      // forcedLocale이 설정되었거나 Localizations.of가 null인 경우 직접 생성
      return _lookupAuthLocalizations(locale);
    } catch (e) {
      // Localizations 위젯이 없는 경우 기본값 반환 (한국어)
      return _lookupAuthLocalizations(const Locale('ko', 'KR'));
    }
  }

  /// 로케일로 AuthLocalizations 인스턴스 생성
  AuthLocalizations _lookupAuthLocalizations(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return AuthLocalizationsKo();
      case 'en':
        return AuthLocalizationsEn();
      default:
        return AuthLocalizationsEn(); // 기본값은 영어
    }
  }

  /// 기본 설정 복사
  AuthConfig copyWith({
    Locale? forcedLocale,
    Color? primaryColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    Color? textTertiaryColor,
    Color? dividerColor,
    Color? backgroundColor,
    @Deprecated('Use localizations instead') String? loginTitle,
    @Deprecated('Use localizations instead') String? kakaoLoginText,
    @Deprecated('Use localizations instead') String? appleLoginText,
    @Deprecated('Use localizations instead') String? googleLoginText,
    @Deprecated('Use localizations instead') String? emailLabel,
    @Deprecated('Use localizations instead') String? passwordLabel,
    @Deprecated('Use localizations instead') String? emailLoginButtonText,
    @Deprecated('Use localizations instead') String? loginRequiredTitle,
    @Deprecated('Use localizations instead') String? loginRequiredDescription,
    @Deprecated('Use localizations instead') String? loginButtonText,
    String Function(String error)? errorMessageBuilder,
    Widget? Function(BuildContext context)? profileSetupScreenBuilder,
    bool Function(dynamic user)? shouldShowProfileSetup,
    bool? enableKakaoLogin,
    bool? enableAppleLogin,
    bool? enableGoogleLogin,
    bool? enableEmailLogin,
  }) {
    return AuthConfig(
      forcedLocale: forcedLocale ?? this.forcedLocale,
      primaryColor: primaryColor ?? this.primaryColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      textTertiaryColor: textTertiaryColor ?? this.textTertiaryColor,
      dividerColor: dividerColor ?? this.dividerColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      loginTitle: loginTitle ?? this.loginTitle,
      kakaoLoginText: kakaoLoginText ?? this.kakaoLoginText,
      appleLoginText: appleLoginText ?? this.appleLoginText,
      googleLoginText: googleLoginText ?? this.googleLoginText,
      emailLabel: emailLabel ?? this.emailLabel,
      passwordLabel: passwordLabel ?? this.passwordLabel,
      emailLoginButtonText: emailLoginButtonText ?? this.emailLoginButtonText,
      loginRequiredTitle: loginRequiredTitle ?? this.loginRequiredTitle,
      loginRequiredDescription:
          loginRequiredDescription ?? this.loginRequiredDescription,
      loginButtonText: loginButtonText ?? this.loginButtonText,
      errorMessageBuilder: errorMessageBuilder ?? this.errorMessageBuilder,
      profileSetupScreenBuilder:
          profileSetupScreenBuilder ?? this.profileSetupScreenBuilder,
      shouldShowProfileSetup:
          shouldShowProfileSetup ?? this.shouldShowProfileSetup,
      enableKakaoLogin: enableKakaoLogin ?? this.enableKakaoLogin,
      enableAppleLogin: enableAppleLogin ?? this.enableAppleLogin,
      enableGoogleLogin: enableGoogleLogin ?? this.enableGoogleLogin,
      enableEmailLogin: enableEmailLogin ?? this.enableEmailLogin,
    );
  }
}
