# Share Lib

재사용 가능한 Flutter 공유 기능 라이브러리

## 기능

- 카카오톡 공유 (SDK 사용)
- 기본 공유 (텍스트, 이미지 포함)
- 클립보드 복사
- 카카오톡 설치 여부 확인

## 설치

### 현재 프로젝트에서 사용 (path dependency)

```yaml
dependencies:
  share_lib:
    path: ../packages/share_lib
```

### Git 저장소에서 사용

```yaml
dependencies:
  share_lib:
    git:
      url: https://github.com/smartcompany/flutter_share_lib.git
      ref: main
```

### pub.dev에서 사용 (배포 후)

```yaml
dependencies:
  share_lib: ^1.0.0
```

## 사용법

```dart
import 'package:share_lib/share_lib.dart';

// 카카오톡 공유
await ShareService.shareToKakao(
  '공유할 텍스트',
  onSuccess: () => print('성공'),
  onError: (error) => print('에러: $error'),
  onKakaoNotInstalled: () => print('카카오톡 미설치'),
);

// 기본 공유 (텍스트)
await ShareService.shareText('공유할 텍스트');

// 기본 공유 (이미지 포함)
await ShareService.shareWithImage(
  '공유할 텍스트',
  imageBytes,
  subject: '제목',
);

// 클립보드 복사
await ShareService.copyToClipboard('복사할 텍스트');

// 카카오톡 설치 여부 확인
final isAvailable = await ShareService.isKakaoTalkAvailable();
```

## 의존성

- `share_plus`: 기본 공유 기능
- `kakao_flutter_sdk`: 카카오톡 공유
- `url_launcher`: URL 실행
- `path_provider`: 임시 파일 저장

