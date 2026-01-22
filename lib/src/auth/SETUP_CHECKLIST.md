# 인증 모듈 설정 체크리스트

각 앱에서 인증 모듈을 사용하기 위해 다음 작업을 완료해야 합니다.

## 필수 작업

- [ ] 1. `pubspec.yaml`에 `share_lib` 의존성 추가 (로컬 경로 또는 pub.dev)
- [ ] 2. `pubspec.yaml`에 Firebase 및 Provider 의존성 확인
- [ ] 3. `main.dart`에서 Firebase 초기화 (`Firebase.initializeApp`)
- [ ] 4. `main.dart`에서 카카오 SDK 초기화 (`KakaoSdk.init`)
- [ ] 5. `AuthServiceInterface` 구현 (API 서비스 클래스)
- [ ] 6. `AuthProvider<T>`를 Provider로 등록 (T는 User 모델 타입)
- [ ] 7. `AuthConfig` 생성 및 설정
- [ ] 8. 로그인 화면에서 `AuthScreen` 사용
- [ ] 9. 로그인 필요 화면에서 `LoginRequiredScreen` 사용

## 플랫폼별 설정

### iOS

- [ ] `ios/Runner/Runner.entitlements`에 Apple Sign-In capability 추가
- [ ] `GoogleService-Info.plist` 파일 추가 (Firebase Console에서 다운로드)
- [ ] `Info.plist`에 카카오 URL Scheme 추가

### Android

- [ ] `google-services.json` 파일 추가 (Firebase Console에서 다운로드)
- [ ] `AndroidManifest.xml`에 카카오 앱 키 설정

## 서버 설정

- [ ] `POST /api/auth/kakao/firebase` 엔드포인트 구현
- [ ] `GET /api/users/me` 엔드포인트 구현 (Firebase ID 토큰 검증)
- [ ] `PUT /api/users/me` 엔드포인트 구현 (Firebase ID 토큰 검증)

## 선택적 설정

- [ ] 에러 메시지 커스터마이징 (`errorMessageBuilder`)
- [ ] 프로필 설정 화면 커스터마이징 (`profileSetupScreenBuilder`)
- [ ] 프로필 완성도 체크 로직 (`shouldShowProfileSetup`)
- [ ] 특정 소셜 로그인 비활성화 (`enableKakaoLogin`, `enableAppleLogin`, etc.)

## 테스트

- [ ] 카카오 로그인 테스트
- [ ] Apple 로그인 테스트 (iOS)
- [ ] Google 로그인 테스트
- [ ] 이메일 로그인 테스트
- [ ] 로그아웃 테스트
- [ ] 프로필 설정 화면 이동 테스트
