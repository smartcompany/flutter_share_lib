import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service_interface.dart';

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
    String? nickname,
    List<String>? interests,
    String? kakaoId, // 카카오 로그인인 경우 (명시적으로 전달하지 않으면 저장된 값 사용)
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // kakaoId가 명시적으로 전달되지 않았으면 저장된 값 사용
      final finalKakaoId = kakaoId ?? _kakaoId;

      final updatedUser = await _authService.updateUser(
        nickname: nickname,
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

  /// Firebase 이메일/비밀번호 로그인
  Future<void> loginWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final idToken = await userCredential.user!.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          _authService.setToken(idToken);
          _user = await _authService.getCurrentUser() as T?;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('등록되지 않은 이메일입니다.');
      } else if (e.code == 'wrong-password') {
        throw Exception('비밀번호가 올바르지 않습니다.');
      } else if (e.code == 'invalid-email') {
        throw Exception('이메일 형식이 올바르지 않습니다.');
      } else {
        throw Exception('로그인에 실패했습니다: ${e.message}');
      }
    } catch (e) {
      debugPrint('Email login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Firebase 이메일/비밀번호 회원가입
  Future<void> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final idToken = await userCredential.user!.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          _authService.setToken(idToken);
          _user = await _authService.getCurrentUser() as T?;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('비밀번호가 너무 약합니다.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('이미 사용 중인 이메일입니다.');
      } else if (e.code == 'invalid-email') {
        throw Exception('이메일 형식이 올바르지 않습니다.');
      } else {
        throw Exception('회원가입에 실패했습니다: ${e.message}');
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
        throw Exception(
          '카카오 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)',
        );
      }

      // 카카오 SDK 관련 에러 처리
      if (e.toString().contains('PlatformException') ||
          e.toString().contains('KakaoSdkNotInitialized')) {
        throw Exception(
          '카카오 SDK가 초기화되지 않았습니다. main.dart에서 KakaoSdk.init을 확인해주세요.',
        );
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
        throw Exception(
            '애플 로그인을 사용할 수 없습니다. iOS 13.0 이상이 필요하며, 실제 기기에서 테스트해주세요.');
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
          throw Exception('애플 로그인이 시간 초과되었습니다. 다시 시도해주세요.');
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
        throw Exception(
          'Apple 로그인에 실패했습니다. 시뮬레이터 설정에서 Apple ID에 로그인되어 있는지 확인해주세요.',
        );
      }
      throw Exception('Apple 로그인에 실패했습니다: ${e.message}');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ [AuthProvider] 애플 로그인 에러: $e');

      if (e.toString().contains('channel-error') ||
          e.toString().contains('Unable to establish connection')) {
        throw Exception(
          'Apple 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)',
        );
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
      debugPrint('🔵 [AuthProvider] GoogleSignIn 인스턴스 생성 중...');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      debugPrint('✅ [AuthProvider] GoogleSignIn 인스턴스 생성 완료');

      debugPrint('🔵 [AuthProvider] GoogleSignIn.signIn() 호출 전...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('❌ [AuthProvider] 구글 로그인 타임아웃 (30초)');
          throw Exception('구글 로그인이 시간 초과되었습니다. 다시 시도해주세요.');
        },
      );
      debugPrint('🔵 [AuthProvider] GoogleSignIn.signIn() 호출 완료');
      
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        debugPrint('⚠️ [AuthProvider] 구글 로그인 취소됨 (사용자 취소)');
        return; // 사용자가 취소한 경우
      }

      debugPrint('✅ [AuthProvider] 구글 사용자 정보 받음: ${googleUser.email}');
      debugPrint('🔵 [AuthProvider] 구글 인증 정보 가져오기...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ [AuthProvider] 구글 인증 정보 가져오기 타임아웃 (10초)');
          throw Exception('구글 인증 정보를 가져오는 중 시간 초과되었습니다.');
        },
      );
      debugPrint('✅ [AuthProvider] 구글 인증 정보 받음');
      
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      debugPrint('🔵 [AuthProvider] idToken: ${idToken != null ? "있음" : "없음"}');
      debugPrint('🔵 [AuthProvider] accessToken: ${accessToken != null ? "있음" : "없음"}');

      if (idToken == null) {
        throw Exception('Google 로그인 토큰을 가져올 수 없습니다.');
      }

      // Firebase에 Google 인증 정보로 로그인
      debugPrint('🔵 [AuthProvider] Firebase OAuth 크리덴셜 생성 중...');
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      debugPrint('✅ [AuthProvider] Firebase OAuth 크리덴셜 생성 완료');

      debugPrint('🔵 [AuthProvider] Firebase OAuth로 로그인...');
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ [AuthProvider] Firebase 로그인 타임아웃 (10초)');
          throw Exception('Firebase 로그인이 시간 초과되었습니다.');
        },
      );
      debugPrint('✅ [AuthProvider] Firebase 로그인 성공');

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

      // 채널 연결 에러 처리
      if (e.toString().contains('channel-error') ||
          e.toString().contains('Unable to establish connection')) {
        throw Exception(
          'Google 로그인 플러그인이 등록되지 않았습니다. 앱을 완전히 재빌드해주세요. (Stop 후 다시 Run)',
        );
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
