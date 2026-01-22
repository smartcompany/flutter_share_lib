import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'auth_config.dart';

/// 인증 헬퍼 클래스
/// 인증이 필요한 경우 인증 플로우를 시작하는 유틸리티 함수를 제공합니다.
class AuthHelper {
  /// 인증이 필요한 경우 인증 플로우를 시작하고,
  /// 인증이 완료되면 true를 반환합니다.
  /// 이미 인증되어 있으면 true를 반환합니다.
  static Future<bool> requireAuth<T>({
    required BuildContext context,
    required AuthConfig config,
    required AuthProvider<T> authProvider,
    Widget? Function(BuildContext context)? profileSetupScreenBuilder,
  }) async {
    // 이미 로그인되어 있고 개인정보도 있으면 통과
    if (authProvider.isAuthenticated) {
      final user = authProvider.user;

      // 프로필 설정 확인
      if (user != null &&
          config.shouldShowProfileSetup != null &&
          config.shouldShowProfileSetup!(user)) {
        // 프로필 설정 화면으로 이동
        if (profileSetupScreenBuilder != null) {
          final profileScreen = profileSetupScreenBuilder(context);
          if (profileScreen != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => profileScreen),
            );
            return result == true;
          }
        } else if (config.profileSetupScreenBuilder != null) {
          final profileScreen = config.profileSetupScreenBuilder!(context);
          if (profileScreen != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => profileScreen),
            );
            return result == true;
          }
        }
        return true;
      }

      return true;
    }

    // 로그인이 안 되어 있으면 로그인 화면으로 이동
    // authScreenBuilder는 config에서 가져오거나 파라미터로 제공
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          // AuthScreen import는 사용자 앱에서 해야 함
          // 여기서는 동적으로 생성할 수 없으므로
          // 사용자가 authScreenBuilder를 제공해야 함
          throw Exception(
            'AuthHelper.requireAuth를 사용하려면 authScreenBuilder를 제공해야 합니다. '
            '또는 직접 Navigator.push로 AuthScreen을 호출하세요.',
          );
        },
        fullscreenDialog: true,
      ),
    );

    // 로그인 성공 후 개인정보 확인
    if (result == true && context.mounted) {
      final user = authProvider.user;
      if (user != null &&
          config.shouldShowProfileSetup != null &&
          config.shouldShowProfileSetup!(user)) {
        if (profileSetupScreenBuilder != null) {
          final profileScreen = profileSetupScreenBuilder(context);
          if (profileScreen != null) {
            final profileResult = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => profileScreen),
            );
            return profileResult == true;
          }
        } else if (config.profileSetupScreenBuilder != null) {
          final profileScreen = config.profileSetupScreenBuilder!(context);
          if (profileScreen != null) {
            final profileResult = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => profileScreen),
            );
            return profileResult == true;
          }
        }
        return true;
      }
      return true;
    }

    return result == true;
  }
}
