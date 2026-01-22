# 인증 모듈 사용 가이드

이 인증 모듈은 Firebase Authentication을 사용하여 소셜 로그인(카카오, Apple, Google) 및 이메일 로그인을 제공하는 공통 모듈입니다.

## i18n (국제화) 지원

이 모듈은 **Flutter의 표준 i18n 방식**을 사용하여 시스템의 preferred language 설정에 따라 자동으로 언어를 선택합니다.

### 1. MaterialApp에 Localizations 설정

각 앱의 `main.dart`에서 `MaterialApp`에 `localizationsDelegates`와 `supportedLocales`를 추가합니다:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_lib/share_lib.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AuthLocalizationsDelegate(), // 인증 모듈의 로컬라이제이션
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어
        // 추가 로케일...
      ],
      // ...
    );
  }
}
```

### 2. AuthConfig 설정 (로컬라이제이션 자동 감지)

`AuthConfig`를 생성할 때 `localizations` 파라미터를 생략하면, 시스템의 preferred language에 따라 자동으로 언어가 선택됩니다:

```dart
final authConfig = AuthConfig(
  primaryColor: AppTheme.primaryColor,
  // localizations를 설정하지 않으면 시스템 로케일에 맞춰 자동 선택
  shouldShowProfileSetup: (user) => user.nickname.isEmpty,
  profileSetupScreenBuilder: (context) => ProfileSetupScreen(),
);
```

시스템이 한국어로 설정되어 있으면 한국어, 영어로 설정되어 있으면 영어가 자동으로 표시됩니다.

### 3. 커스텀 로컬라이제이션

특정 로케일을 강제로 사용하고 싶다면 `localizations` 파라미터에 명시적으로 지정할 수 있습니다:

```dart
final authConfig = AuthConfig(
  primaryColor: AppTheme.primaryColor,
  localizations: AuthLocalizations.en, // 항상 영어 사용
  // 또는
  localizations: AuthLocalizations.ko, // 항상 한국어 사용
);
```

### 4. 새로운 언어 추가

새로운 언어를 추가하려면 `AuthLocalizations` 클래스를 확장하거나, `AuthLocalizations.of()` 메서드를 수정하여 새로운 로케일을 지원하도록 할 수 있습니다. 또는 각 앱에서 커스텀 `AuthLocalizations` 인스턴스를 만들어 사용할 수 있습니다:

```dart
final customLocalizations = AuthLocalizations(
  loginTitle: 'Connexion', // 프랑스어
  kakaoLoginText: 'Continuer avec Kakao',
  // ...
);

final authConfig = AuthConfig(
  localizations: customLocalizations,
);
```

## 사용자가 직접 해야 할 작업

### 1. pubspec.yaml에 의존성 추가

각 앱의 `pubspec.yaml`에 다음을 추가합니다:

```yaml
dependencies:
  share_lib:
    path: ../flutter_share_lib  # 또는 실제 경로
  firebase_core: ^4.3.0
  firebase_auth: ^6.1.3
  provider: ^6.1.2
  flutter_localizations:  # i18n 지원
    sdk: flutter
```

### 2. Firebase 초기화

`main.dart`에서 Firebase를 초기화합니다:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // flutterfire configure로 생성

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

### 3. 카카오 SDK 초기화

`main.dart`에서 카카오 SDK를 초기화합니다:

```dart
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'dart:io' show Platform;

void main() async {
  // ...
  
  KakaoSdk.init(
    nativeAppKey: Platform.isIOS
        ? 'YOUR_IOS_KAKAO_NATIVE_APP_KEY'
        : 'YOUR_ANDROID_KAKAO_NATIVE_APP_KEY',
    javaScriptAppKey: 'YOUR_KAKAO_JAVASCRIPT_APP_KEY',
  );
  
  runApp(MyApp());
}
```

### 4. AuthServiceInterface 구현

각 앱의 API 서비스가 `AuthServiceInterface`를 구현해야 합니다:

```dart
import 'package:share_lib/share_lib.dart';
import '../models/user.dart'; // 각 앱의 User 모델

class ApiService implements AuthServiceInterface {
  String? _token;
  
  @override
  void setToken(String token) {
    _token = token;
  }
  
  @override
  Future<User> getCurrentUser() async {
    // 서버에서 현재 사용자 정보 가져오기
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return User.fromJson(jsonDecode(response.body));
  }
  
  @override
  Future<String> loginWithKakaoFirebase(String accessToken) async {
    // 서버에 카카오 액세스 토큰 전송, Firebase 커스텀 토큰 받기
    final response = await http.post(
      Uri.parse('$baseUrl/auth/kakao/firebase'),
      body: jsonEncode({'access_token': accessToken}),
    );
    final data = jsonDecode(response.body);
    return data['custom_token'] as String;
  }
  
  @override
  Future<User> updateUser({
    String? nickname,
    String? profileImageUrl,
    List<String>? interests,
  }) async {
    // 서버에 사용자 정보 업데이트
    // ...
  }
}
```

### 5. AuthProvider 설정

`main.dart` 또는 적절한 위치에서 `AuthProvider`를 Provider로 등록합니다:

```dart
import 'package:provider/provider.dart';
import 'package:share_lib/share_lib.dart';
import 'services/api_service.dart';
import 'models/user.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider<User>(
            authService: ApiService(), // AuthServiceInterface 구현체
          ),
        ),
        // 다른 providers...
      ],
      child: MaterialApp(
        // i18n 설정
        localizationsDelegates: const [
          AuthLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        // ...
      ),
    );
  }
}
```

### 6. AuthConfig 설정

인증 화면과 관련 설정을 정의합니다:

```dart
import 'package:share_lib/share_lib.dart';
import 'theme/app_theme.dart'; // 각 앱의 테마

final authConfig = AuthConfig(
  // 테마 색상
  primaryColor: AppTheme.primaryColor,
  textPrimaryColor: AppTheme.textPrimaryColor,
  textSecondaryColor: AppTheme.textSecondaryColor,
  textTertiaryColor: AppTheme.textTertiaryColor,
  dividerColor: AppTheme.dividerColor,
  backgroundColor: AppTheme.backgroundColor,
  
  // localizations를 설정하지 않으면 시스템 로케일에 맞춰 자동 선택됨
  
  // 프로필 설정 확인 함수
  shouldShowProfileSetup: (user) {
    final myUser = user as User;
    return myUser.nickname.isEmpty || myUser.interests.isEmpty;
  },
  
  // 프로필 설정 화면 빌더
  profileSetupScreenBuilder: (context) => ProfileSetupScreen(),
  
  // 에러 메시지 커스터마이징 (선택 사항)
  errorMessageBuilder: (error) {
    if (error.contains('특정 에러')) {
      return '커스텀 에러 메시지';
    }
    return error;
  },
);
```

### 7. AuthScreen 사용

로그인 화면을 표시할 때:

```dart
import 'package:share_lib/share_lib.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AuthScreen(
      config: authConfig,
    ),
    fullscreenDialog: true, // 모달 방식으로 표시
  ),
);
```

### 8. LoginRequiredScreen 사용

로그인이 필요한 화면에서:

```dart
import 'package:share_lib/share_lib.dart';

if (!authProvider.isAuthenticated) {
  return LoginRequiredScreen(
    config: authConfig,
    authScreenBuilder: (context) => AuthScreen(
      config: authConfig,
    ),
  );
}
```

### 9. iOS 설정 (Apple Sign-In)

`ios/Runner/Runner.entitlements` 파일에 다음을 추가:

```xml
<key>com.apple.developer.applesignin</key>
<array>
  <string>Default</string>
</array>
```

### 10. Android 설정 (Google Sign-In)

`android/app/build.gradle`에서 올바른 `applicationId`가 설정되어 있는지 확인하고,
Firebase Console에서 Android 앱을 등록하고 `google-services.json` 파일을 추가합니다.

### 11. 서버 설정

서버에서 다음 API 엔드포인트를 구현해야 합니다:

- `POST /api/auth/kakao/firebase`: 카카오 액세스 토큰을 받아 Firebase 커스텀 토큰 반환
- `GET /api/users/me`: 현재 인증된 사용자 정보 반환 (Firebase ID 토큰 검증 필요)
- `PUT /api/users/me`: 사용자 정보 업데이트 (Firebase ID 토큰 검증 필요)

## 예제: LetsMeet 앱에서 사용

```dart
// lib/main.dart
import 'package:share_lib/share_lib.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/auth_provider.dart' as app;
import 'providers/meeting_provider.dart';
import 'services/api_service.dart';
import 'models/user.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  KakaoSdk.init(
    nativeAppKey: Platform.isIOS
        ? 'YOUR_IOS_KAKAO_NATIVE_APP_KEY'
        : 'YOUR_ANDROID_KAKAO_NATIVE_APP_KEY',
    javaScriptAppKey: 'YOUR_KAKAO_JAVASCRIPT_APP_KEY',
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => app.AuthProvider<User>(
            authService: ApiService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AuthLocalizationsDelegate(), // 인증 모듈 로컬라이제이션
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        // ...
      ),
    );
  }
}

// lib/config/auth_config.dart
import 'package:share_lib/share_lib.dart';
import '../theme/app_theme.dart';
import '../screens/profile_setup_screen.dart';

final authConfig = AuthConfig(
  primaryColor: AppTheme.primaryColor,
  textPrimaryColor: AppTheme.textPrimaryColor,
  textSecondaryColor: AppTheme.textSecondaryColor,
  textTertiaryColor: AppTheme.textTertiaryColor,
  dividerColor: AppTheme.dividerColor,
  backgroundColor: AppTheme.backgroundColor,
  // localizations를 설정하지 않으면 시스템 로케일에 맞춰 자동 선택
  shouldShowProfileSetup: (user) {
    final myUser = user as User;
    return myUser.nickname.isEmpty || myUser.interests.isEmpty;
  },
  profileSetupScreenBuilder: (context) => const ProfileSetupScreen(),
);

// lib/screens/profile_screen.dart 또는 chat_screen.dart
import 'package:share_lib/share_lib.dart';
import '../config/auth_config.dart';
import 'auth_screen.dart' as app;

if (!authProvider.isAuthenticated) {
  return LoginRequiredScreen(
    config: authConfig,
    authScreenBuilder: (context) => app.AuthScreen(config: authConfig),
  );
}
```

## 주의사항

1. **타입 안정성**: `AuthProvider<T>`에서 `T`는 각 앱의 User 모델 타입입니다.
2. **프로필 설정**: `shouldShowProfileSetup`과 `profileSetupScreenBuilder`를 적절히 설정해야 합니다.
3. **에러 처리**: 필요에 따라 `errorMessageBuilder`를 커스터마이징할 수 있습니다.
4. **소셜 로그인 활성화**: `AuthConfig`에서 필요한 소셜 로그인만 활성화할 수 있습니다 (`enableKakaoLogin`, `enableAppleLogin`, `enableGoogleLogin`, `enableEmailLogin`).
5. **i18n**: `localizations`를 설정하지 않으면 시스템의 preferred language에 따라 자동으로 언어가 선택됩니다. `MaterialApp`에 `localizationsDelegates`를 추가하는 것을 잊지 마세요!