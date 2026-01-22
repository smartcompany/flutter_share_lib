// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AuthLocalizationsEn extends AuthLocalizations {
  AuthLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get kakaoLoginText => 'Continue with Kakao';

  @override
  String get appleLoginText => 'Continue with Apple';

  @override
  String get googleLoginText => 'Continue with Google';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get emailLoginButtonText => 'Login';

  @override
  String get loginRequiredTitle => 'Login Required';

  @override
  String get loginRequiredDescription => 'Please login to continue';

  @override
  String get loginButtonText => 'Login';

  @override
  String get orDividerText => 'or';

  @override
  String get emailPasswordRequired => 'Please enter your email and password';

  @override
  String get serverConnectionError =>
      'Unable to connect to server. Please check if the server is running.';

  @override
  String get invalidEmailPassword => 'Invalid email or password.';

  @override
  String get socialLoginRequired =>
      'This email is registered with social login. Please use social login.';

  @override
  String get appleLoginError =>
      'Apple login failed. Please check if you are logged in with Apple ID in simulator settings.';

  @override
  String get kakaoSdkNotConfigured =>
      'Kakao SDK is not configured. Please set Kakao app keys in main.dart.';

  @override
  String get pluginNotRegistered =>
      'Plugin is not registered. Please rebuild the app completely. (Stop and Run again)';
}
