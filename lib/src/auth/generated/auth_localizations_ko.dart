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
  String get googleLoginText => 'Google 계정으로 로그인';

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
  String get socialLoginRequired =>
      '이메일/비밀번호로 로그인할 수 없습니다.\n\n• Google, Apple, 카카오로 가입하셨다면 해당 버튼으로 로그인해 주세요.\n• 이메일로 가입하셨다면 비밀번호를 확인해 주세요.\n• 소셜로 로그인한 뒤 마이페이지에서 비밀번호를 등록하면 이메일 로그인도 사용할 수 있습니다.';

  @override
  String get emailRequiredForPassword => '이 계정에는 이메일이 없어 비밀번호를 설정할 수 없습니다.';

  @override
  String get requiresRecentLogin => '보안을 위해 다시 로그인한 뒤 비밀번호를 변경해 주세요.';

  @override
  String passwordSetFailed(String message) {
    return '비밀번호 설정에 실패했습니다: $message';
  }

  @override
  String get appleLoginError =>
      'Apple 로그인에 실패했습니다. 시뮬레이터 설정에서 Apple ID에 로그인되어 있는지 확인해주세요.';

  @override
  String get kakaoSdkNotConfigured =>
      '카카오 SDK가 설정되지 않았습니다. main.dart에서 카카오 앱 키를 설정해주세요.';

  @override
  String get pluginNotRegistered =>
      '플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)';

  @override
  String get accountNotFoundMessage => '등록되지 않은 이메일입니다. 회원가입하시겠습니까?';

  @override
  String get wrongPassword => '비밀번호가 올바르지 않습니다.';

  @override
  String get emailAlreadyInUse =>
      '이메일/비밀번호로 로그인할 수 없습니다.\n\n• Google, Apple, 카카오로 가입하셨다면 해당 버튼으로 로그인해 주세요.\n• 이메일로 가입하셨다면 비밀번호를 확인해 주세요.\n• 소셜로 로그인한 뒤 마이페이지에서 비밀번호를 등록하면 이메일 로그인도 사용할 수 있습니다.';

  @override
  String get invalidEmail => '이메일 형식이 올바르지 않습니다.';

  @override
  String loginFailed(String message) {
    return '로그인에 실패했습니다: $message';
  }

  @override
  String get weakPassword => '비밀번호가 너무 약합니다.';

  @override
  String get emailAlreadyInUseSignUp =>
      '이미 사용 중인 이메일입니다. 소셜 로그인으로 가입하셨다면 해당 방법으로 로그인해 주세요.';

  @override
  String signUpFailed(String message) {
    return '회원가입에 실패했습니다: $message';
  }

  @override
  String get kakaoPluginNotRegistered =>
      '카카오 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)';

  @override
  String get kakaoSdkNotInitialized =>
      '카카오 SDK가 초기화되지 않았습니다. main.dart에서 KakaoSdk.init을 확인해주세요.';

  @override
  String get appleLoginNotAvailable =>
      '애플 로그인을 사용할 수 없습니다. iOS 13.0 이상이 필요하며, 실제 기기에서 테스트해주세요.';

  @override
  String get appleLoginTimeout => '애플 로그인이 시간 초과되었습니다. 다시 시도해주세요.';

  @override
  String get appleLoginFailed =>
      'Apple 로그인에 실패했습니다. 시뮬레이터 설정에서 Apple ID에 로그인되어 있는지 확인해주세요.';

  @override
  String get applePluginNotRegistered =>
      'Apple 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)';

  @override
  String get googleLoginTimeout => '구글 로그인이 시간 초과되었습니다. 다시 시도해주세요.';

  @override
  String get googleAuthTimeout => '구글 인증 정보를 가져오는 중 시간 초과되었습니다.';

  @override
  String get googleTokenError => 'Google 로그인 토큰을 가져올 수 없습니다.';

  @override
  String get googlePluginNotRegistered =>
      'Google 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)';

  @override
  String get firebaseLoginTimeout => 'Firebase 로그인이 시간 초과되었습니다.';

  @override
  String get passwordResetEmailSent => '비밀번호 재설정 이메일을 전송했습니다. 이메일을 확인해주세요.';

  @override
  String passwordResetFailed(String message) {
    return '비밀번호 재설정 이메일 전송에 실패했습니다: $message';
  }

  @override
  String get passwordMismatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get signUpTitle => '회원가입';

  @override
  String get passwordConfirmTitle => '비밀번호 확인';

  @override
  String get passwordConfirmMessage => '비밀번호를 한 번 더 입력해주세요.';

  @override
  String get passwordConfirmLabel => '비밀번호 확인';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get signUp => '회원가입';

  @override
  String get send => '전송';

  @override
  String get passwordResetTitle => '비밀번호 재설정';

  @override
  String get passwordResetMessage => '이메일 주소를 입력하시면 비밀번호 재설정 링크를 보내드립니다.';

  @override
  String get pleaseEnterEmail => '이메일을 입력해주세요.';

  @override
  String get photoSelectTitle => '사진 선택';

  @override
  String get photoSelectDone => '완료';

  @override
  String photoSelectDoneCount(int count, int max) {
    return '완료 ($count/$max)';
  }

  @override
  String get photoPermissionDenied => '앨범 접근 권한이 필요합니다';

  @override
  String get photoCompressFailed => '이미지 압축 실패';

  @override
  String get photoCameraUnavailable => '카메라를 사용할 수 없습니다';

  @override
  String photoMaxSelection(int maxCount) {
    return '최대 $maxCount장까지 선택할 수 있습니다';
  }

  @override
  String get photoLoadFailed => '이미지를 불러오지 못했습니다';

  @override
  String get photoIcloudLoadFailed =>
      '사진을 불러오지 못했습니다. 기기에 저장된 사진을 선택하거나 실기기에서 다시 시도해 주세요.';

  @override
  String get photoLimitedAccessBanner =>
      '선택한 사진만 표시됩니다. 보관함 전체를 쓰려면 더 선택하거나 설정에서 「모든 사진」 허용을 선택하세요.';

  @override
  String get photoSelectMore => '더 선택';

  @override
  String get shareSheetTitle => '공유하기';

  @override
  String get shareKakaoLabel => '카카오톡으로 공유';

  @override
  String get shareSystemLabel => '다른 앱으로 공유';

  @override
  String get shareCopyLabel => '링크 복사';

  @override
  String get shareCopiedMessage => '링크를 복사했어요';

  @override
  String get shareFailedMessage => '공유에 실패했어요';

  @override
  String get shareOpenInApp => '앱에서 열기';

  @override
  String get shareSubjectDefault => '공유';

  @override
  String get mapPickerTitle => '지도 앱 선택';

  @override
  String get mapNoAppsAvailable => '사용 가능한 지도 앱이 없습니다.';

  @override
  String get mapKakao => '카카오맵';

  @override
  String get mapNaver => '네이버 지도';

  @override
  String get mapGoogle => '구글 지도';

  @override
  String get mapApple => 'Apple 지도';

  @override
  String get forceUpdateTitle => '업데이트가 필요합니다';

  @override
  String forceUpdateMessage(String current, String required) {
    return '계속 사용하려면 최신 버전으로 업데이트해 주세요.\n(현재 $current → 필요 $required)';
  }

  @override
  String get forceUpdateButton => '업데이트하기';

  @override
  String errorOccurred(String detail) {
    return '에러 발생: $detail';
  }
}
