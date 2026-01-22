// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AuthLocalizationsKo extends AuthLocalizations {
  AuthLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get loginTitle => '로그인';

  @override
  String get kakaoLoginText => '카카오로 시작하기';

  @override
  String get appleLoginText => 'Apple로 시작하기';

  @override
  String get googleLoginText => 'Google로 시작하기';

  @override
  String get emailLabel => '이메일';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordLabel => '비밀번호';

  @override
  String get passwordHint => '비밀번호를 입력하세요';

  @override
  String get emailLoginButtonText => '로그인';

  @override
  String get loginRequiredTitle => '로그인이 필요합니다';

  @override
  String get loginRequiredDescription => '로그인하여 계속 이용하세요';

  @override
  String get loginButtonText => '로그인하기';

  @override
  String get orDividerText => '또는';

  @override
  String get emailPasswordRequired => '이메일과 비밀번호를 입력해주세요';

  @override
  String get serverConnectionError => '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';

  @override
  String get invalidEmailPassword => '이메일 또는 비밀번호가 올바르지 않습니다.';

  @override
  String get socialLoginRequired => '이 이메일은 소셜 로그인으로 가입되었습니다. 소셜 로그인을 사용해주세요.';

  @override
  String get appleLoginError =>
      'Apple 로그인에 실패했습니다. 시뮬레이터 설정에서 Apple ID에 로그인되어 있는지 확인해주세요.';

  @override
  String get kakaoSdkNotConfigured =>
      '카카오 SDK가 설정되지 않았습니다. main.dart에서 카카오 앱 키를 설정해주세요.';

  @override
  String get pluginNotRegistered =>
      '플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)';
}
