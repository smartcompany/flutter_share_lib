# pub.dev 배포 가이드

## 1. 사전 준비

### 1.1 pub.dev 계정 생성
1. https://pub.dev 접속
2. "Sign in" 클릭
3. Google 계정으로 로그인 (또는 GitHub 계정)

### 1.2 패키지 이름 확인
- `pubspec.yaml`의 `name` 필드가 고유한지 확인
- pub.dev에서 이미 사용 중인 이름인지 검색: https://pub.dev/packages/share_lib
- 이미 사용 중이면 다른 이름으로 변경 필요

### 1.3 Git 저장소 준비
```bash
# packages/share_lib 디렉토리에서
cd packages/share_lib

# Git 초기화 (아직 안 했다면)
git init

# GitHub에 새 저장소 생성 후
git remote add origin https://github.com/yourusername/share_lib.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

## 2. pubspec.yaml 수정

다음 정보를 실제 값으로 수정:
- `homepage`: GitHub 저장소 URL
- `repository`: GitHub 저장소 URL
- `issue_tracker`: GitHub Issues URL

## 3. 배포 전 체크리스트

### 필수 파일 확인
- [x] `pubspec.yaml` - 패키지 정보
- [x] `LICENSE` - 라이선스 파일 (MIT, Apache 2.0 등)
- [x] `README.md` - 사용법 문서
- [x] `CHANGELOG.md` - 변경 이력 (선택사항이지만 권장)
- [x] `.gitignore` - Git 무시 파일

### 코드 검증
```bash
cd packages/share_lib

# 의존성 확인
flutter pub get

# 분석 실행
flutter analyze

# 테스트 실행 (테스트 파일이 있다면)
flutter test
```

## 4. 배포 실행

### 4.1 pub.dev 로그인
```bash
# 터미널에서 실행
dart pub login
```
- 브라우저가 열리면 pub.dev에서 인증
- 또는 토큰을 직접 입력

### 4.2 배포 전 최종 확인
```bash
# 배포 전 미리보기 (실제 배포는 안 됨)
dart pub publish --dry-run
```

### 4.3 실제 배포
```bash
# 실제 배포
dart pub publish
```

배포 시 확인 사항:
- 패키지 이름이 고유한지
- 버전이 올바른지
- 모든 파일이 포함되는지

## 5. 배포 후

### 5.1 확인
- https://pub.dev/packages/share_lib 에서 패키지 확인
- 몇 분 후 검색 결과에 나타남

### 5.2 다른 앱에서 사용
```yaml
# pubspec.yaml
dependencies:
  share_lib: ^1.0.0
```

```bash
flutter pub get
```

```dart
import 'package:share_lib/share_lib.dart';
```

## 6. 버전 업데이트

새 버전 배포 시:
1. `pubspec.yaml`의 `version` 업데이트 (예: 1.0.0 → 1.0.1)
2. `CHANGELOG.md`에 변경 사항 추가
3. `dart pub publish` 실행

## 주의사항

- 패키지 이름은 한 번 배포하면 변경 불가
- 버전은 항상 증가해야 함 (1.0.0 → 1.0.1 → 1.1.0 등)
- 삭제된 패키지는 복구 불가
- pub.dev는 무료이지만, 스팸 방지를 위해 검토 과정이 있을 수 있음

