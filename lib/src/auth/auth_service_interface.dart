/// 인증 서비스 인터페이스
/// 각 앱에서 구현해야 하는 API 서비스 인터페이스입니다.
abstract class AuthServiceInterface {
  /// 인증 토큰 설정
  void setToken(String token);

  /// 현재 사용자 정보 가져오기
  /// 각 앱의 User 모델 타입을 반환합니다.
  Future<dynamic> getCurrentUser();

  /// 카카오 로그인 후 UID와 kakao_id 받기
  /// [accessToken] 카카오 액세스 토큰
  /// UID와 kakao_id를 반환합니다.
  Future<Map<String, String>> loginWithKakao(String accessToken);

  /// 사용자 정보 업데이트
  Future<dynamic> updateUser({
    String? fullName,
    String? gender,
    String? bio,
    String? profileImageUrl,
    String? backgroundImageUrl,
    List<String>? interests,
    String? kakaoId, // 카카오 로그인인 경우
  });
}
