import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'auth_localizations_en.dart';
import 'auth_localizations_ko.dart';

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
    Locale('ko')
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AuthLocalizationsDelegate old) => false;
}

AuthLocalizations lookupAuthLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AuthLocalizationsEn();
    case 'ko':
      return AuthLocalizationsKo();
  }

  throw FlutterError(
      'AuthLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
