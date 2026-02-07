// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AuthLocalizationsZh extends AuthLocalizations {
  AuthLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get loginTitle => '登录';

  @override
  String get kakaoLoginText => '使用Kakao开始';

  @override
  String get appleLoginText => '使用Apple开始';

  @override
  String get googleLoginText => '使用Google开始';

  @override
  String get emailLabel => '电子邮件';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordLabel => '密码';

  @override
  String get passwordHint => '请输入密码';

  @override
  String get emailLoginButtonText => '使用电子邮件开始';

  @override
  String get loginRequiredTitle => '需要登录';

  @override
  String get loginRequiredDescription => '请登录以继续';

  @override
  String get loginButtonText => '登录';

  @override
  String get orDividerText => '或';

  @override
  String get emailPasswordRequired => '请输入您的电子邮件和密码';

  @override
  String get serverConnectionError => '无法连接到服务器。请检查服务器是否正在运行。';

  @override
  String get invalidEmailPassword => '电子邮件或密码不正确。';

  @override
  String get socialLoginRequired => '此电子邮件已通过社交登录注册。请使用社交登录。';

  @override
  String get appleLoginError => 'Apple登录失败。请检查模拟器设置中是否已登录Apple ID。';

  @override
  String get kakaoSdkNotConfigured => 'Kakao SDK未配置。请在main.dart中设置Kakao应用密钥。';

  @override
  String get pluginNotRegistered => '插件未注册。请完全重新构建应用程序。（停止后再次运行）';

  @override
  String get accountNotFoundMessage => '此电子邮件未注册。您要注册吗？';

  @override
  String get wrongPassword => '密码不正确。';

  @override
  String get emailAlreadyInUse =>
      '此电子邮件已被使用。\n\n• 如果您使用电子邮件/密码注册，请检查您的密码。\n• 如果您使用社交登录（Google、Apple、Kakao）注册，请使用该方法登录。';

  @override
  String get invalidEmail => '电子邮件格式不正确。';

  @override
  String loginFailed(String message) {
    return '登录失败: $message';
  }

  @override
  String get weakPassword => '密码太弱。';

  @override
  String get emailAlreadyInUseSignUp => '此电子邮件已被使用。';

  @override
  String signUpFailed(String message) {
    return '注册失败: $message';
  }

  @override
  String get kakaoPluginNotRegistered => 'Kakao登录插件未注册。请完全重新构建应用程序。（停止后再次运行）';

  @override
  String get kakaoSdkNotInitialized =>
      'Kakao SDK未初始化。请在main.dart中检查KakaoSdk.init。';

  @override
  String get appleLoginNotAvailable => '无法使用Apple登录。需要iOS 13.0或更高版本，请在真实设备上测试。';

  @override
  String get appleLoginTimeout => 'Apple登录超时。请重试。';

  @override
  String get appleLoginFailed => 'Apple登录失败。请检查模拟器设置中是否已登录Apple ID。';

  @override
  String get applePluginNotRegistered => 'Apple登录插件未注册。请完全重新构建应用程序。（停止后再次运行）';

  @override
  String get googleLoginTimeout => 'Google登录超时。请重试。';

  @override
  String get googleAuthTimeout => '获取Google身份验证信息时超时。';

  @override
  String get googleTokenError => '无法获取Google登录令牌。';

  @override
  String get googlePluginNotRegistered => 'Google登录插件未注册。请完全重新构建应用程序。（停止后再次运行）';

  @override
  String get firebaseLoginTimeout => 'Firebase登录超时。';

  @override
  String get passwordResetEmailSent => '已发送密码重置电子邮件。请检查您的电子邮件。';

  @override
  String passwordResetFailed(String message) {
    return '发送密码重置电子邮件失败: $message';
  }

  @override
  String get passwordMismatch => '密码不匹配。';

  @override
  String get signUpTitle => '注册';

  @override
  String get passwordConfirmTitle => '确认密码';

  @override
  String get passwordConfirmMessage => '请再次输入密码。';

  @override
  String get passwordConfirmLabel => '确认密码';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get signUp => '注册';

  @override
  String get send => '发送';

  @override
  String get passwordResetTitle => '重置密码';

  @override
  String get passwordResetMessage => '输入您的电子邮件地址，我们将向您发送密码重置链接。';

  @override
  String get pleaseEnterEmail => '请输入您的电子邮件。';
}
