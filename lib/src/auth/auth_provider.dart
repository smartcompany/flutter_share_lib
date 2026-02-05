import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service_interface.dart';

/// 계정이 없을 때 발생하는 예외
/// UI에서 회원가입 여부를 확인하기 위해 사용
class AccountNotFoundException implements Exception {
  final String message;
  AccountNotFoundException(this.message);

  @override
  String toString() => message;
}

/// 로컬라이징 키를 포함하는 예외
/// UI에서 로컬라이징을 적용하기 위해 사용
class LocalizedException implements Exception {
  final String localizationKey;
  final Map<String, String>? parameters;
  LocalizedException(this.localizationKey, {this.parameters});

  @override
  String toString() => localizationKey;
}

/// 공통 인증 Provider
/// Firebase Authentication을 사용하여 인증 상태를 관리합니다.
class AuthProvider<T> with ChangeNotifier {
  final FirebaseAuth _firebaseAuth;
  final AuthServiceInterface _authService;
  T? _user;
  bool _isLoading = false;
  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _kakaoId; // 카카오 로그인 시 저장

  /// 현재 사용자 정보
  T? get user => _user;

  /// 인증 여부
  bool get isAuthenticated => _user != null;

  /// 로딩 상태
  bool get isLoading => _isLoading;

  /// 초기화 중 여부
  bool get isInitializing => _isInitializing;

  /// 초기화 완료 여부
  bool get isInitialized => _isInitialized;

  AuthProvider({
    FirebaseAuth? firebaseAuth,
    required AuthServiceInterface authService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _authService = authService {
    // Firebase Auth 상태 변화 감지
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        try {
          final idToken = await firebaseUser.getIdToken();
          if (idToken != null && idToken.isNotEmpty) {
            _authService.setToken(idToken);
            _user = await _authService.getCurrentUser() as T?;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Failed to get user info: $e');
        }
      } else {
        _user = null;
        _authService.setToken('');
        notifyListeners();
      }
    });
  }

  /// 인증 초기화
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) {
      return;
    }
    _isInitializing = true;
    notifyListeners();
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        try {
          final idToken = await firebaseUser.getIdToken();
          if (idToken != null && idToken.isNotEmpty) {
            _authService.setToken(idToken);
            _user = await _authService.getCurrentUser() as T?;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Failed to get current user: $e');
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('AuthProvider initialization error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// 사용자 프로필 업데이트
  Future<void> updateProfile({
    String? fullName,
    String? gender,
    String? bio,
    String? profileImageUrl,
    String? backgroundImageUrl,
    List<String>? interests,
    String? kakaoId, // 카카오 로그인인 경우 (명시적으로 전달하지 않으면 저장된 값 사용)
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // kakaoId가 명시적으로 전달되지 않았으면 저장된 값 사용
      final finalKakaoId = kakaoId ?? _kakaoId;

      final updatedUser = await _authService.updateUser(
        fullName: fullName,
        gender: gender,
        bio: bio,
        profileImageUrl: profileImageUrl,
        backgroundImageUrl: backgroundImageUrl,
        interests: interests,
        kakaoId: finalKakaoId,
      );

      // 카카오 로그인이고 새 사용자인 경우 custom_token이 포함됨
      if (updatedUser is Map && updatedUser['custom_token'] != null) {
        final customToken = updatedUser['custom_token'] as String;
        debugPrint('🔵 [AuthProvider] Firebase 커스텀 토큰으로 로그인...');

        // Firebase 커스텀 토큰으로 로그인
        final userCredential = await _firebaseAuth.signInWithCustomToken(
          customToken,
        );
        debugPrint('✅ [AuthProvider] Firebase 로그인 성공');

        if (userCredential.user != null) {
          final firebaseIdToken = await userCredential.user!.getIdToken();
          if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
            _authService.setToken(firebaseIdToken);
            // 사용자 정보 다시 가져오기
            _user = await _authService.getCurrentUser() as T?;
          }
        }
      } else {
        _user = updatedUser as T?;
      }

      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Firebase 이메일/비밀번호 로그인 (계정이 없으면 자동 회원가입)
  Future<void> loginWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔵 [AuthProvider] 이메일 로그인 시작...');
      debugPrint('🔵 [AuthProvider] 이메일: $email');
      debugPrint(
          '🔵 [AuthProvider] Firebase signInWithEmailAndPassword 호출 전...');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ [AuthProvider] Firebase 로그인 성공');
      debugPrint(
          '🔵 [AuthProvider] userCredential.user: ${userCredential.user != null ? "있음" : "없음"}');

      if (userCredential.user != null) {
        debugPrint('🔵 [AuthProvider] Firebase ID 토큰 가져오기...');
        final idToken = await userCredential.user!.getIdToken();
        debugPrint(
            '🔵 [AuthProvider] idToken: ${idToken != null && idToken.isNotEmpty ? "있음" : "없음"}');

        if (idToken != null && idToken.isNotEmpty) {
          _authService.setToken(idToken);
          debugPrint('✅ [AuthProvider] 토큰 설정 완료');
          try {
            debugPrint('🔵 [AuthProvider] 서버에서 사용자 정보 가져오기...');
            _user = await _authService.getCurrentUser() as T?;
            debugPrint('✅ [AuthProvider] 이메일 로그인 완료');
            debugPrint(
                '🔵 [AuthProvider] 사용자 정보: ${_user != null ? "있음" : "없음"}');
          } catch (e) {
            debugPrint('❌ [AuthProvider] getCurrentUser 에러: $e');
            debugPrint('❌ [AuthProvider] 에러 타입: ${e.runtimeType}');
            debugPrint('❌ [AuthProvider] 에러 문자열: ${e.toString()}');

            // PROFILE_NOT_SETUP 예외인 경우 프로필 설정 필요
            if (e.toString().contains('PROFILE_NOT_SETUP')) {
              debugPrint('✅ [AuthProvider] 이메일 로그인 완료 (프로필 설정 필요)');
              // 사용자 정보는 null로 유지 (프로필 설정 화면 표시를 위해)
            } else {
              debugPrint('❌ [AuthProvider] 사용자 정보 가져오기 실패: $e');
              rethrow;
            }
          }
        } else {
          debugPrint('❌ [AuthProvider] idToken이 null이거나 비어있음');
        }
      } else {
        debugPrint('❌ [AuthProvider] userCredential.user가 null');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthProvider] FirebaseAuthException 발생');
      debugPrint('❌ [AuthProvider] 에러 코드: ${e.code}');
      debugPrint('❌ [AuthProvider] 에러 메시지: ${e.message}');
      debugPrint('❌ [AuthProvider] 에러 스택: ${e.stackTrace}');

      // 계정이 없으면 AccountNotFoundException을 던져서 UI에서 처리
      if (e.code == 'user-not-found') {
        debugPrint('🟡 [AuthProvider] 계정이 없음 - UI에서 회원가입 여부 확인 필요');
        throw AccountNotFoundException('accountNotFoundMessage');
      } else if (e.code == 'wrong-password') {
        debugPrint('❌ [AuthProvider] 비밀번호가 올바르지 않음');
        throw LocalizedException('wrongPassword');
      } else if (e.code == 'invalid-credential') {
        // invalid-credential은 비밀번호가 틀렸거나 계정이 없을 때 발생할 수 있음
        // 계정 존재 여부 확인을 위해 회원가입 시도 (이미 존재하면 에러 발생)
        debugPrint(
            '🟡 [AuthProvider] invalid-credential 발생 - 계정 존재 여부 확인 중...');
        try {
          debugPrint('🟡 [AuthProvider] 계정 존재 여부 확인을 위해 회원가입 시도...');
          await _firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          // 회원가입 성공 = 계정이 없었음
          // 하지만 사용자 확인 없이 계정이 생성되었으므로 삭제해야 함
          debugPrint('✅ [AuthProvider] 계정이 없음 확인 - 임시 계정 삭제 중...');
          final tempUser = _firebaseAuth.currentUser;
          if (tempUser != null) {
            await tempUser.delete();
            debugPrint('✅ [AuthProvider] 임시 계정 삭제 완료');
          }
          throw AccountNotFoundException('accountNotFoundMessage');
        } on FirebaseAuthException catch (checkError) {
          if (checkError.code == 'email-already-in-use') {
            // 이메일이 이미 사용 중인 경우
            // invalid-credential로 이미 실패했으므로, 소셜 로그인으로 가입한 가능성이 높음
            // 하지만 이메일/비밀번호로 가입한 경우도 있을 수 있으므로 두 가지 모두 안내
            debugPrint('❌ [AuthProvider] 이메일이 이미 사용 중');
            throw LocalizedException('emailAlreadyInUse');
          } else if (checkError.code == 'weak-password') {
            // 비밀번호가 약함
            debugPrint('❌ [AuthProvider] 비밀번호가 약함');
            throw LocalizedException('wrongPassword');
          } else {
            // 다른 에러는 계정이 없을 가능성이 높음
            debugPrint('❌ [AuthProvider] 계정 확인 중 에러: ${checkError.code}');
            throw AccountNotFoundException('accountNotFoundMessage');
          }
        }
      } else if (e.code == 'invalid-email') {
        debugPrint('❌ [AuthProvider] 이메일 형식이 올바르지 않음');
        throw LocalizedException('invalidEmail');
      } else {
        debugPrint('❌ [AuthProvider] 기타 FirebaseAuthException: ${e.code}');
        throw LocalizedException('loginFailed',
            parameters: {'message': e.message ?? ''});
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AuthProvider] 이메일 로그인 일반 에러: $e');
      debugPrint('❌ [AuthProvider] 에러 타입: ${e.runtimeType}');
      debugPrint('❌ [AuthProvider] 에러 문자열: ${e.toString()}');
      debugPrint('❌ [AuthProvider] 스택 트레이스: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('🟡 [AuthProvider] 이메일 로그인 완료 (finally)');
    }
  }

  /// Firebase 이메일/비밀번호 회원가입
  Future<void> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔵 [AuthProvider] 이메일 회원가입 시작...');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ [AuthProvider] Firebase 회원가입 성공');

      if (userCredential.user != null) {
        final idToken = await userCredential.user!.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          _authService.setToken(idToken);
          try {
            debugPrint('🔵 [AuthProvider] 서버에서 사용자 정보 가져오기...');
            _user = await _authService.getCurrentUser() as T?;
            debugPrint('✅ [AuthProvider] 이메일 회원가입 완료');
          } catch (e) {
            // PROFILE_NOT_SETUP 예외인 경우 프로필 설정 필요
            if (e.toString().contains('PROFILE_NOT_SETUP')) {
              debugPrint('✅ [AuthProvider] 이메일 회원가입 완료 (프로필 설정 필요)');
              // 사용자 정보는 null로 유지 (프로필 설정 화면 표시를 위해)
            } else {
              debugPrint('❌ [AuthProvider] 사용자 정보 가져오기 실패: $e');
              rethrow;
            }
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw LocalizedException('weakPassword');
      } else if (e.code == 'email-already-in-use') {
        throw LocalizedException('emailAlreadyInUseSignUp');
      } else if (e.code == 'invalid-email') {
        throw LocalizedException('invalidEmail');
      } else {
        throw LocalizedException('signUpFailed',
            parameters: {'message': e.message ?? ''});
      }
    } catch (e) {
      debugPrint('Email signup error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 카카오 로그인
  Future<void> loginWithKakao() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔵 [AuthProvider] 카카오 로그인 시작...');

      // 카카오 로그인 실행 (카카오톡 앱이 없으면 웹 브라우저로 대체)
      OAuthToken token;
      try {
        debugPrint('🔵 [AuthProvider] 카카오톡 앱 로그인 시도...');
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
        debugPrint('✅ [AuthProvider] 카카오톡 앱 로그인 성공');
      } catch (e) {
        debugPrint('⚠️ [AuthProvider] 카카오톡 앱 로그인 실패, 웹 로그인 시도... $e');
        // 카카오톡 앱이 없거나 실패하면 웹 브라우저로 로그인
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
        debugPrint('✅ [AuthProvider] 카카오 웹 로그인 성공');
      }

      debugPrint('🔵 [AuthProvider] 카카오 사용자 정보 가져오기...');
      // 카카오 사용자 정보 가져오기
      kakao.User kakaoUser = await kakao.UserApi.instance.me();
      debugPrint('✅ [AuthProvider] 카카오 사용자 정보: ${kakaoUser.id}');
      debugPrint(
          '🔵 [AuthProvider] kakaoAccount: ${kakaoUser.kakaoAccount?.email ?? "null"}');

      // kakaoAccount가 null이어도 accessToken이 있으면 서버에서 처리 가능
      // 서버에서 카카오 API로 직접 사용자 정보를 가져올 수 있음
      if (kakaoUser.kakaoAccount == null) {
        debugPrint('⚠️ [AuthProvider] kakaoAccount가 null이지만 accessToken으로 진행');
      }

      // 카카오 로그인: 서버에서 UID와 kakao_id 받기
      // 프로필이 이미 있으면 custom_token도 함께 받음
      debugPrint('🔵 [AuthProvider] 서버에서 카카오 로그인 정보 요청...');
      final loginResult = await _authService.loginWithKakao(
        token.accessToken,
      );
      debugPrint('✅ [AuthProvider] 카카오 로그인 정보 받음: ${loginResult['uid']}');

      // kakaoId 저장 (프로필 설정 시 사용)
      _kakaoId = loginResult['kakao_id'];

      // 프로필이 이미 있으면 Firebase 커스텀 토큰으로 로그인
      if (loginResult['custom_token'] != null) {
        final customToken = loginResult['custom_token'] as String;
        debugPrint('🔵 [AuthProvider] 기존 사용자 - Firebase 커스텀 토큰으로 로그인...');

        final userCredential = await _firebaseAuth.signInWithCustomToken(
          customToken,
        );
        debugPrint('✅ [AuthProvider] Firebase 로그인 성공');

        if (userCredential.user != null) {
          final firebaseIdToken = await userCredential.user!.getIdToken();
          if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
            _authService.setToken(firebaseIdToken);
            _user = await _authService.getCurrentUser() as T?;
            debugPrint('✅ [AuthProvider] 카카오 로그인 완료 (기존 사용자)');
          }
        }
      } else {
        // 프로필이 없으면 프로필 설정 필요
        debugPrint('✅ [AuthProvider] 카카오 로그인 완료 (프로필 설정 필요)');
      }
    } catch (e, stackTrace) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ [AuthProvider] 카카오 로그인 에러: $e');
      debugPrint('❌ [AuthProvider] 스택 트레이스: $stackTrace');

      if (e.toString().contains('channel-error') ||
          e.toString().contains('Unable to establish connection')) {
        throw LocalizedException('kakaoPluginNotRegistered');
      }

      // 카카오 SDK 관련 에러 처리
      if (e.toString().contains('PlatformException') ||
          e.toString().contains('KakaoSdkNotInitialized')) {
        throw LocalizedException('kakaoSdkNotInitialized');
      }

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apple 로그인
  Future<void> loginWithApple() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔵 [AuthProvider] 애플 로그인 시작...');

      // 애플 로그인 사용 가능 여부 확인
      debugPrint('🔵 [AuthProvider] 애플 로그인 사용 가능 여부 확인 중...');
      final isAvailable = await SignInWithApple.isAvailable();
      debugPrint('🔵 [AuthProvider] 애플 로그인 사용 가능: $isAvailable');

      if (!isAvailable) {
        throw LocalizedException('appleLoginNotAvailable');
      }

      debugPrint(
          '🔵 [AuthProvider] SignInWithApple.getAppleIDCredential 호출 전...');

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('❌ [AuthProvider] 애플 로그인 타임아웃 (30초)');
          throw LocalizedException('appleLoginTimeout');
        },
      );

      debugPrint('✅ [AuthProvider] 애플 ID 크리덴셜 받음');
      debugPrint(
          '🔵 [AuthProvider] identityToken: ${credential.identityToken != null ? "있음" : "없음"}');
      debugPrint(
          '🔵 [AuthProvider] authorizationCode: ${credential.authorizationCode != null ? "있음" : "없음"}');

      debugPrint('🔵 [AuthProvider] Firebase OAuth 크리덴셜 생성 중...');
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      debugPrint('✅ [AuthProvider] Firebase OAuth 크리덴셜 생성 완료');

      debugPrint('🔵 [AuthProvider] Firebase OAuth로 로그인...');
      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      debugPrint('✅ [AuthProvider] Firebase 로그인 성공');

      if (userCredential.user != null) {
        final idToken = await userCredential.user!.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          _authService.setToken(idToken);
          try {
            debugPrint('🔵 [AuthProvider] 서버에서 사용자 정보 가져오기...');
            _user = await _authService.getCurrentUser() as T?;
            debugPrint('✅ [AuthProvider] 애플 로그인 완료');
          } catch (e) {
            // PROFILE_NOT_SETUP 예외인 경우 프로필 설정 필요
            if (e.toString().contains('PROFILE_NOT_SETUP')) {
              debugPrint('✅ [AuthProvider] 애플 로그인 완료 (프로필 설정 필요)');
              // 사용자 정보는 null로 유지 (프로필 설정 화면 표시를 위해)
            } else {
              debugPrint('❌ [AuthProvider] 사용자 정보 가져오기 실패: $e');
              rethrow;
            }
          }
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ [AuthProvider] 애플 로그인 에러: $e');

      if (e.code == AuthorizationErrorCode.unknown) {
        throw LocalizedException('appleLoginFailed');
      }
      throw LocalizedException('appleLoginFailed');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ [AuthProvider] 애플 로그인 에러: $e');

      if (e.toString().contains('channel-error') ||
          e.toString().contains('Unable to establish connection')) {
        throw LocalizedException('applePluginNotRegistered');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Google 로그인
  Future<void> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint('🔵 [AuthProvider] 구글 로그인 시작...');

      UserCredential userCredential;

      if (kIsWeb) {
        // 웹: google_sign_in은 idToken을 반환하지 않음(Implicit Flow). Firebase signInWithPopup 사용
        debugPrint('🔵 [AuthProvider] 웹 - signInWithPopup 사용');
        final googleProvider = GoogleAuthProvider();
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
        if (userCredential.user == null) {
          _isLoading = false;
          notifyListeners();
          debugPrint('⚠️ [AuthProvider] 구글 로그인 취소됨');
          return;
        }
        debugPrint('✅ [AuthProvider] Firebase signInWithPopup 성공');
      } else {
        // iOS/Android: google_sign_in 사용
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          _isLoading = false;
          notifyListeners();
          debugPrint('⚠️ [AuthProvider] 구글 로그인 취소됨 (사용자 취소)');
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final idToken = googleAuth.idToken;
        if (idToken == null) {
          throw LocalizedException('googleTokenError');
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: idToken,
        );

        userCredential = await _firebaseAuth.signInWithCredential(credential);
        debugPrint('✅ [AuthProvider] Firebase 로그인 성공');
      }

      if (userCredential.user != null) {
        final firebaseIdToken = await userCredential.user!.getIdToken();
        if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
          _authService.setToken(firebaseIdToken);
          try {
            debugPrint('🔵 [AuthProvider] 서버에서 사용자 정보 가져오기...');
            _user = await _authService.getCurrentUser() as T?;
            debugPrint('✅ [AuthProvider] 구글 로그인 완료');
          } catch (e) {
            // PROFILE_NOT_SETUP 예외인 경우 프로필 설정 필요
            if (e.toString().contains('PROFILE_NOT_SETUP')) {
              debugPrint('✅ [AuthProvider] 구글 로그인 완료 (프로필 설정 필요)');
              // 사용자 정보는 null로 유지 (프로필 설정 화면 표시를 위해)
            } else {
              debugPrint('❌ [AuthProvider] 사용자 정보 가져오기 실패: $e');
              rethrow;
            }
          }
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ [AuthProvider] 구글 로그인 에러: $e');
      debugPrint('❌ [AuthProvider] 스택 트레이스: ${StackTrace.current}');

      // 웹: 팝업 닫기 등 사용자 취소
      if (e is FirebaseAuthException &&
          (e.code == 'auth/popup-closed-by-user' ||
              e.code == 'auth/cancelled-popup-request')) {
        debugPrint('⚠️ [AuthProvider] 구글 로그인 취소됨 (팝업 닫힘)');
        return;
      }

      // 채널 연결 에러 처리
      if (e.toString().contains('channel-error') ||
          e.toString().contains('Unable to establish connection')) {
        throw LocalizedException('googlePluginNotRegistered');
      }

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    // 소셜 로그인 로그아웃 처리
    try {
      if (await kakao.AuthApi.instance.hasToken()) {
        await kakao.UserApi.instance.unlink();
      }
    } catch (_) {
      // 카카오 로그인이 아닌 경우 무시
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {
      // Google 로그인이 아닌 경우 무시
    }

    // Firebase 로그아웃
    await _firebaseAuth.signOut();

    _user = null;
    _authService.setToken('');
    notifyListeners();
  }
}
