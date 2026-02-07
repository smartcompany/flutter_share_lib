import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'auth_localizations_en.dart';
import 'auth_localizations_ja.dart';
import 'auth_localizations_ko.dart';
import 'auth_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AuthLocalizations
/// returned by `AuthLocalizations.of(context)`.
///
/// Applications need to include `AuthLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/auth_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AuthLocalizations.localizationsDelegates,
///   supportedLocales: AuthLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AuthLocalizations.supportedLocales
/// property.
abstract class AuthLocalizations {
  AuthLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AuthLocalizations? of(BuildContext context) {
    return Localizations.of<AuthLocalizations>(context, AuthLocalizations);
  }

  static const LocalizationsDelegate<AuthLocalizations> delegate =
      _AuthLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// 로그인 화면 타이틀
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginTitle;

  /// 카카오 로그인 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'카카오로 시작하기'**
  String get kakaoLoginText;

  /// Apple 로그인 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'Apple로 시작하기'**
  String get appleLoginText;

  /// Google 로그인 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'Google로 시작하기'**
  String get googleLoginText;

  /// 이메일 입력 필드 레이블
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get emailLabel;

  /// 이메일 입력 필드 힌트
  ///
  /// In ko, this message translates to:
  /// **'example@email.com'**
  String get emailHint;

  /// 비밀번호 입력 필드 레이블
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get passwordLabel;

  /// 비밀번호 입력 필드 힌트
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력하세요'**
  String get passwordHint;

  /// 이메일 로그인 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get emailLoginButtonText;

  /// 로그인 필요 화면 제목
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요합니다'**
  String get loginRequiredTitle;

  /// 로그인 필요 화면 설명
  ///
  /// In ko, this message translates to:
  /// **'로그인하여 계속 이용하세요'**
  String get loginRequiredDescription;

  /// 로그인하기 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'로그인하기'**
  String get loginButtonText;

  /// 구분선 텍스트
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get orDividerText;

  /// 이메일과 비밀번호가 입력되지 않았을 때 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'이메일과 비밀번호를 입력해주세요'**
  String get emailPasswordRequired;

  /// 서버 연결 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.'**
  String get serverConnectionError;

  /// 이메일 또는 비밀번호가 잘못되었을 때 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'이메일 또는 비밀번호가 올바르지 않습니다.'**
  String get invalidEmailPassword;

  /// 소셜 로그인이 필요할 때 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'이 이메일은 소셜 로그인으로 가입되었습니다. 소셜 로그인을 사용해주세요.'**
  String get socialLoginRequired;

  /// Apple 로그인 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'Apple 로그인에 실패했습니다. 시뮬레이터 설정에서 Apple ID에 로그인되어 있는지 확인해주세요.'**
  String get appleLoginError;

  /// 카카오 SDK 미설정 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'카카오 SDK가 설정되지 않았습니다. main.dart에서 카카오 앱 키를 설정해주세요.'**
  String get kakaoSdkNotConfigured;

  /// 플러그인 미등록 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)'**
  String get pluginNotRegistered;

  /// 계정이 없을 때 회원가입 안내 메시지
  ///
  /// In ko, this message translates to:
  /// **'등록되지 않은 이메일입니다. 회원가입하시겠습니까?'**
  String get accountNotFoundMessage;

  /// 비밀번호가 틀렸을 때 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 올바르지 않습니다.'**
  String get wrongPassword;

  /// 이메일이 이미 사용 중일 때 안내 메시지
  ///
  /// In ko, this message translates to:
  /// **'이 이메일은 이미 사용 중입니다.\n\n• 이메일/비밀번호로 가입하셨다면 비밀번호를 확인해주세요.\n• 소셜 로그인(구글, 애플, 카카오)으로 가입하셨다면 해당 방법으로 로그인해주세요.'**
  String get emailAlreadyInUse;

  /// 이메일 형식이 잘못되었을 때 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'이메일 형식이 올바르지 않습니다.'**
  String get invalidEmail;

  /// 로그인 실패 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'로그인에 실패했습니다: {message}'**
  String loginFailed(String message);

  /// 비밀번호가 약할 때 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 너무 약합니다.'**
  String get weakPassword;

  /// 회원가입 시 이메일이 이미 사용 중일 때 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 이메일입니다.'**
  String get emailAlreadyInUseSignUp;

  /// 회원가입 실패 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'회원가입에 실패했습니다: {message}'**
  String signUpFailed(String message);

  /// 카카오 로그인 플러그인 미등록 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)'**
  String get kakaoPluginNotRegistered;

  /// 카카오 SDK 미초기화 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'카카오 SDK가 초기화되지 않았습니다. main.dart에서 KakaoSdk.init을 확인해주세요.'**
  String get kakaoSdkNotInitialized;

  /// 애플 로그인 사용 불가 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'애플 로그인을 사용할 수 없습니다. iOS 13.0 이상이 필요하며, 실제 기기에서 테스트해주세요.'**
  String get appleLoginNotAvailable;

  /// 애플 로그인 타임아웃 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'애플 로그인이 시간 초과되었습니다. 다시 시도해주세요.'**
  String get appleLoginTimeout;

  /// 애플 로그인 실패 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'Apple 로그인에 실패했습니다. 시뮬레이터 설정에서 Apple ID에 로그인되어 있는지 확인해주세요.'**
  String get appleLoginFailed;

  /// 애플 로그인 플러그인 미등록 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'Apple 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)'**
  String get applePluginNotRegistered;

  /// 구글 로그인 타임아웃 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'구글 로그인이 시간 초과되었습니다. 다시 시도해주세요.'**
  String get googleLoginTimeout;

  /// 구글 인증 정보 가져오기 타임아웃 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'구글 인증 정보를 가져오는 중 시간 초과되었습니다.'**
  String get googleAuthTimeout;

  /// 구글 로그인 토큰 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'Google 로그인 토큰을 가져올 수 없습니다.'**
  String get googleTokenError;

  /// 구글 로그인 플러그인 미등록 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'Google 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)'**
  String get googlePluginNotRegistered;

  /// Firebase 로그인 타임아웃 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'Firebase 로그인이 시간 초과되었습니다.'**
  String get firebaseLoginTimeout;

  /// 비밀번호 재설정 이메일 전송 성공 메시지
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 이메일을 전송했습니다. 이메일을 확인해주세요.'**
  String get passwordResetEmailSent;

  /// 비밀번호 재설정 이메일 전송 실패 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정 이메일 전송에 실패했습니다: {message}'**
  String passwordResetFailed(String message);

  /// 비밀번호 확인 불일치 에러 메시지
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않습니다.'**
  String get passwordMismatch;

  /// 회원가입 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signUpTitle;

  /// 비밀번호 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get passwordConfirmTitle;

  /// 비밀번호 확인 다이얼로그 메시지
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 한 번 더 입력해주세요.'**
  String get passwordConfirmMessage;

  /// 비밀번호 확인 입력 필드 레이블
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get passwordConfirmLabel;

  /// 취소 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// 확인 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// 회원가입 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signUp;

  /// 전송 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'전송'**
  String get send;

  /// 비밀번호 재설정 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정'**
  String get passwordResetTitle;

  /// 비밀번호 재설정 다이얼로그 메시지
  ///
  /// In ko, this message translates to:
  /// **'이메일 주소를 입력하시면 비밀번호 재설정 링크를 보내드립니다.'**
  String get passwordResetMessage;

  /// 이메일 입력 요청 메시지
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요.'**
  String get pleaseEnterEmail;
}

class _AuthLocalizationsDelegate
    extends LocalizationsDelegate<AuthLocalizations> {
  const _AuthLocalizationsDelegate();

  @override
  Future<AuthLocalizations> load(Locale locale) {
    return SynchronousFuture<AuthLocalizations>(
        lookupAuthLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AuthLocalizationsDelegate old) => false;
}

AuthLocalizations lookupAuthLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AuthLocalizationsEn();
    case 'ja':
      return AuthLocalizationsJa();
    case 'ko':
      return AuthLocalizationsKo();
    case 'zh':
      return AuthLocalizationsZh();
  }

  throw FlutterError(
      'AuthLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
