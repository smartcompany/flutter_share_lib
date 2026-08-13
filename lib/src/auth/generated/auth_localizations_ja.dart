// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'auth_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AuthLocalizationsJa extends AuthLocalizations {
  AuthLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get loginTitle => 'ログイン';

  @override
  String get kakaoLoginText => 'Kakaoで始める';

  @override
  String get appleLoginText => 'Appleで始める';

  @override
  String get googleLoginText => 'Googleでログイン';

  @override
  String get emailLabel => 'メールアドレス';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get passwordHint => 'パスワードを入力してください';

  @override
  String get emailLoginButtonText => 'メールで始める';

  @override
  String get loginRequiredTitle => 'ログインが必要です';

  @override
  String get loginRequiredDescription => 'ログインして続ける';

  @override
  String get loginButtonText => 'ログイン';

  @override
  String get orDividerText => 'または';

  @override
  String get emailPasswordRequired => 'メールアドレスとパスワードを入力してください';

  @override
  String get serverConnectionError => 'サーバーに接続できません。サーバーが実行中か確認してください。';

  @override
  String get invalidEmailPassword => 'メールアドレスまたはパスワードが正しくありません。';

  @override
  String get socialLoginRequired =>
      'メール/パスワードではログインできません。\n\n• Google、Apple、Kakaoで登録した場合は、そのボタンでログインしてください。\n• メールで登録した場合はパスワードを確認してください。\n• ソーシャルログイン後、マイページでパスワードを登録するとメールログインも使えます。';

  @override
  String get emailRequiredForPassword => 'このアカウントにはメールアドレスがないため、パスワードを設定できません。';

  @override
  String get requiresRecentLogin => 'セキュリティのため、再度ログインしてからパスワードを変更してください。';

  @override
  String passwordSetFailed(String message) {
    return 'パスワードの設定に失敗しました: $message';
  }

  @override
  String get appleLoginError =>
      'Appleログインに失敗しました。シミュレーター設定でApple IDにログインしているか確認してください。';

  @override
  String get kakaoSdkNotConfigured =>
      'Kakao SDKが設定されていません。main.dartでKakaoアプリキーを設定してください。';

  @override
  String get pluginNotRegistered =>
      'プラグインが登録されていません。アプリを完全に再ビルドしてください。（停止して再実行）';

  @override
  String get accountNotFoundMessage => 'このメールアドレスは登録されていません。新規登録しますか？';

  @override
  String get wrongPassword => 'パスワードが正しくありません。';

  @override
  String get emailAlreadyInUse =>
      'メール/パスワードではログインできません。\n\n• Google、Apple、Kakaoで登録した場合は、そのボタンでログインしてください。\n• メールで登録した場合はパスワードを確認してください。\n• ソーシャルログイン後、マイページでパスワードを登録するとメールログインも使えます。';

  @override
  String get invalidEmail => 'メールアドレスの形式が正しくありません。';

  @override
  String loginFailed(String message) {
    return 'ログインに失敗しました: $message';
  }

  @override
  String get weakPassword => 'パスワードが弱すぎます。';

  @override
  String get emailAlreadyInUseSignUp =>
      'このメールアドレスは既に使用されています。ソーシャルログインで登録した場合はその方法でログインしてください。';

  @override
  String signUpFailed(String message) {
    return '新規登録に失敗しました: $message';
  }

  @override
  String get kakaoPluginNotRegistered =>
      'Kakaoログインプラグインが登録されていません。アプリを完全に再ビルドしてください。（停止して再実行）';

  @override
  String get kakaoSdkNotInitialized =>
      'Kakao SDKが初期化されていません。main.dartでKakaoSdk.initを確認してください。';

  @override
  String get appleLoginNotAvailable =>
      'Appleログインを使用できません。iOS 13.0以上が必要で、実機でテストしてください。';

  @override
  String get appleLoginTimeout => 'Appleログインがタイムアウトしました。もう一度お試しください。';

  @override
  String get appleLoginFailed =>
      'Appleログインに失敗しました。シミュレーター設定でApple IDにログインしているか確認してください。';

  @override
  String get applePluginNotRegistered =>
      'Appleログインプラグインが登録されていません。アプリを完全に再ビルドしてください。（停止して再実行）';

  @override
  String get googleLoginTimeout => 'Googleログインがタイムアウトしました。もう一度お試しください。';

  @override
  String get googleAuthTimeout => 'Google認証情報の取得中にタイムアウトしました。';

  @override
  String get googleTokenError => 'Googleログイントークンを取得できません。';

  @override
  String get googlePluginNotRegistered =>
      'Googleログインプラグインが登録されていません。アプリを完全に再ビルドしてください。（停止して再実行）';

  @override
  String get firebaseLoginTimeout => 'Firebaseログインがタイムアウトしました。';

  @override
  String get passwordResetEmailSent => 'パスワードリセットメールを送信しました。メールを確認してください。';

  @override
  String passwordResetFailed(String message) {
    return 'パスワードリセットメールの送信に失敗しました: $message';
  }

  @override
  String get passwordMismatch => 'パスワードが一致しません。';

  @override
  String get signUpTitle => '新規登録';

  @override
  String get passwordConfirmTitle => 'パスワード確認';

  @override
  String get passwordConfirmMessage => 'パスワードをもう一度入力してください。';

  @override
  String get passwordConfirmLabel => 'パスワード確認';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get signUp => '新規登録';

  @override
  String get send => '送信';

  @override
  String get passwordResetTitle => 'パスワードリセット';

  @override
  String get passwordResetMessage => 'メールアドレスを入力すると、パスワードリセットリンクを送信します。';

  @override
  String get pleaseEnterEmail => 'メールアドレスを入力してください。';

  @override
  String get photoSelectTitle => '写真を選択';

  @override
  String get photoSelectDone => '完了';

  @override
  String photoSelectDoneCount(int count, int max) {
    return '完了 ($count/$max)';
  }

  @override
  String get photoPermissionDenied => 'フォトライブラリへのアクセスが必要です。';

  @override
  String get photoCompressFailed => '画像の圧縮に失敗しました。';

  @override
  String get photoCameraUnavailable => 'カメラを使用できません。';

  @override
  String photoMaxSelection(int maxCount) {
    return '最大 $maxCount 枚まで選択できます。';
  }

  @override
  String get photoLoadFailed => '画像を読み込めませんでした。';

  @override
  String get photoIcloudLoadFailed =>
      '写真を読み込めませんでした。端末に保存された写真を選ぶか、実機でもう一度お試しください。';

  @override
  String get photoLimitedAccessBanner =>
      '選択した写真のみ表示されます。ライブラリ全体を使うには、さらに選択するか設定で「すべての写真」を許可してください。';

  @override
  String get photoSelectMore => 'さらに選択';

  @override
  String get shareSheetTitle => '共有';

  @override
  String get shareKakaoLabel => 'カカオトークで共有';

  @override
  String get shareSystemLabel => 'ほかのアプリで共有';

  @override
  String get shareCopyLabel => 'リンクをコピー';

  @override
  String get shareCopiedMessage => 'リンクをコピーしました';

  @override
  String get shareFailedMessage => '共有に失敗しました';

  @override
  String get shareOpenInApp => 'アプリで開く';

  @override
  String get shareSubjectDefault => '共有';

  @override
  String get mapPickerTitle => 'マップアプリを選択';

  @override
  String get mapNoAppsAvailable => '利用できるマップアプリがありません。';

  @override
  String get mapKakao => 'カカオマップ';

  @override
  String get mapNaver => 'NAVERマップ';

  @override
  String get mapGoogle => 'Googleマップ';

  @override
  String get mapApple => 'Appleマップ';

  @override
  String get forceUpdateTitle => 'アップデートが必要です';

  @override
  String forceUpdateMessage(String current, String required) {
    return 'アプリを使い続けるには最新版へのアップデートが必要です。\n（現在 $current → 必要 $required）';
  }

  @override
  String get forceUpdateButton => 'アップデートする';

  @override
  String errorOccurred(String detail) {
    return 'エラー: $detail';
  }
}
