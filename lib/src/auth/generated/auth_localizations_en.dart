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
  String get emailLoginButtonText => 'Continue with Email';

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

  @override
  String get accountNotFoundMessage =>
      'This email is not registered. Would you like to sign up?';

  @override
  String get wrongPassword => 'Incorrect password.';

  @override
  String get emailAlreadyInUse =>
      'This email is already in use.\n\n• If you signed up with email/password, please check your password.\n• If you signed up with social login (Google, Apple, Kakao), please use that method to log in.';

  @override
  String get invalidEmail => 'Invalid email format.';

  @override
  String loginFailed(String message) => 'Login failed: $message';

  @override
  String get weakPassword => 'Password is too weak.';

  @override
  String get emailAlreadyInUseSignUp => 'This email is already in use.';

  @override
  String signUpFailed(String message) => 'Sign up failed: $message';

  @override
  String get kakaoPluginNotRegistered =>
      'Kakao login plugin is not registered. Please rebuild the app completely. (Stop and Run again)';

  @override
  String get kakaoSdkNotInitialized =>
      'Kakao SDK is not initialized. Please check KakaoSdk.init in main.dart.';

  @override
  String get appleLoginNotAvailable =>
      'Apple login is not available. iOS 13.0 or higher is required, and please test on a real device.';

  @override
  String get appleLoginTimeout => 'Apple login timed out. Please try again.';

  @override
  String get appleLoginFailed =>
      'Apple login failed. Please check if you are logged in with Apple ID in simulator settings.';

  @override
  String get applePluginNotRegistered =>
      'Apple login plugin is not registered. Please rebuild the app completely. (Stop and Run again)';

  @override
  String get googleLoginTimeout => 'Google login timed out. Please try again.';

  @override
  String get googleAuthTimeout =>
      'Timed out while retrieving Google authentication information.';

  @override
  String get googleTokenError => 'Unable to retrieve Google login token.';

  @override
  String get googlePluginNotRegistered =>
      'Google login plugin is not registered. Please rebuild the app completely. (Stop and Run again)';

  @override
  String get firebaseLoginTimeout => 'Firebase login timed out.';

  @override
  String get passwordResetEmailSent =>
      'Password reset email has been sent. Please check your email.';

  @override
  String passwordResetFailed(String message) =>
      'Failed to send password reset email: $message';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get signUpTitle => 'Sign Up';

  @override
  String get passwordConfirmTitle => 'Confirm Password';

  @override
  String get passwordConfirmMessage => 'Please enter your password again.';

  @override
  String get passwordConfirmLabel => 'Confirm Password';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get signUp => 'Sign Up';

  @override
  String get send => 'Send';

  @override
  String get passwordResetTitle => 'Reset Password';

  @override
  String get passwordResetMessage =>
      'Enter your email address and we\'ll send you a password reset link.';

  @override
  String get pleaseEnterEmail => 'Please enter your email.';
}
