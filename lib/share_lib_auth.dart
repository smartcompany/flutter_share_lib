/// 인증 모듈 전용 라이브러리
///
/// 로그인 관련 기능만 제공합니다. AdService나 ShareService는 포함하지 않습니다.
///
/// 사용 예시:
/// ```dart
/// import 'package:share_lib/share_lib_auth.dart';
///
/// // AuthProvider 사용
/// final authProvider = AuthProvider<User>(
///   authService: ApiService(),
/// );
///
/// // AuthScreen 사용
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => AuthScreen<User>(config: authConfig),
///   ),
/// );
/// ```
library share_lib_auth;

export 'src/auth/auth_config.dart';
export 'src/auth/auth_service_interface.dart';
export 'src/auth/auth_provider.dart';
export 'src/auth/auth_screen.dart';
export 'src/auth/login_required_screen.dart';
export 'src/auth/auth_helper.dart';
export 'src/auth/generated/auth_localizations.dart';
