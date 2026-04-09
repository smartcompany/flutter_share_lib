import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

/// 공유 기능을 제공하는 서비스 클래스
/// 다른 앱에서도 재사용 가능하도록 UI와 분리된 순수 로직만 포함
class ShareService {
  static Uri? _extractFirstHttpUrl(String text) {
    final regex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final m = regex.firstMatch(text);
    if (m == null) return null;
    final raw = m.group(0);
    if (raw == null || raw.isEmpty) return null;
    return Uri.tryParse(raw);
  }

  /// 카카오톡 공유
  ///
  /// [shareText] 공유할 텍스트
  /// [onSuccess] 성공 시 콜백 (선택사항)
  /// [onError] 에러 시 콜백 (선택사항)
  /// [onKakaoNotInstalled] 카카오톡 미설치 시 콜백 (선택사항)
  static Future<bool> shareToKakao(
    String shareText, {
    Uri? linkUrl,
    VoidCallback? onSuccess,
    Function(String error)? onError,
    VoidCallback? onKakaoNotInstalled,
  }) async {
    debugPrint('🔍 [카카오톡 공유] SDK 방식 시작');

    // 카카오톡 설치 여부 확인
    if (await ShareClient.instance.isKakaoTalkSharingAvailable() == false) {
      debugPrint('❌ [카카오톡 공유] 카카오톡 미설치');
      onKakaoNotInstalled?.call();
      return false;
    }

    try {
      debugPrint('🔍 [카카오톡 공유] TextTemplate 생성 중...');
      final resolvedLinkUrl = linkUrl ?? _extractFirstHttpUrl(shareText);

      final template = TextTemplate(
        text: shareText,
        // URL이 있으면 카카오 템플릿 링크에 실어 전달한다.
        // 텍스트만 넣으면 카카오 인앱 웹뷰로 열리며 UL이 덜 타는 경우가 있어 web/mobileWebUrl 모두 설정.
        link: resolvedLinkUrl != null
            ? Link(
                webUrl: resolvedLinkUrl,
                mobileWebUrl: resolvedLinkUrl,
              )
            : Link(),
      );

      debugPrint('🔍 [카카오톡 공유] shareDefault 호출 중...');
      final uri = await ShareClient.instance.shareDefault(template: template);
      debugPrint('🔍 [카카오톡 공유] shareDefault 완료, URI: $uri');

      if (await canLaunchUrl(uri)) {
        debugPrint('🔍 [카카오톡 공유] launchUrl 실행 중...');
        await launchUrl(uri);
        debugPrint('✅ [카카오톡 공유] 성공');
      }

      onSuccess?.call();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [카카오톡 공유] 에러: $e');
      debugPrint('❌ [카카오톡 공유] 스택 트레이스: $stackTrace');
      onError?.call(e.toString());
      return false;
    }
  }

  /// 기본 공유 (텍스트만)
  ///
  /// [shareText] 공유할 텍스트
  /// [subject] 제목 (선택사항)
  /// [onSuccess] 성공 시 콜백 (선택사항)
  /// [onError] 에러 시 콜백 (선택사항)
  static Future<bool> shareText(
    String shareText, {
    String? subject,
    Rect? sharePositionOrigin,
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    try {
      debugPrint('🔍 [기본 공유] 텍스트 공유 시작');
      await Share.share(
        shareText,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );
      debugPrint('✅ [기본 공유] 공유 완료');
      onSuccess?.call();
      return true;
    } catch (e) {
      debugPrint('❌ [기본 공유] 에러: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  /// 이미지와 함께 기본 공유
  ///
  /// [shareText] 공유할 텍스트
  /// [imageBytes] 공유할 이미지 바이트
  /// [subject] 제목 (선택사항)
  /// [onSuccess] 성공 시 콜백 (선택사항)
  /// [onError] 에러 시 콜백 (선택사항)
  static Future<bool> shareWithImage(
    String shareText,
    Uint8List imageBytes, {
    String? subject,
    Rect? sharePositionOrigin,
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    try {
      debugPrint('🔍 [기본 공유] 이미지 포함 공유 시작');
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      // Write image bytes to file
      await file.writeAsBytes(imageBytes);
      debugPrint('✅ [기본 공유] 이미지 파일 생성: ${file.path}');

      // Share with image and text
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: shareText,
        subject: subject ?? '공유',
        sharePositionOrigin: sharePositionOrigin,
      );
      debugPrint('✅ [기본 공유] 공유 완료');

      // Clean up: delete temporary file after a delay
      Future.delayed(Duration(seconds: 5), () async {
        try {
          if (await file.exists()) {
            await file.delete();
            debugPrint('✅ [기본 공유] 임시 파일 삭제 완료');
          }
        } catch (e) {
          debugPrint('⚠️ [기본 공유] 파일 삭제 실패: $e');
        }
      });

      onSuccess?.call();
      return true;
    } catch (e) {
      debugPrint('❌ [기본 공유] 에러: $e');
      // Fallback to text-only share if image sharing fails
      try {
        await Share.share(
          shareText,
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        );
        onSuccess?.call();
        return true;
      } catch (fallbackError) {
        onError?.call(fallbackError.toString());
        return false;
      }
    }
  }

  /// 클립보드에 복사
  ///
  /// [text] 복사할 텍스트
  /// [onSuccess] 성공 시 콜백 (선택사항)
  /// [onError] 에러 시 콜백 (선택사항)
  static Future<bool> copyToClipboard(
    String text, {
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      debugPrint('✅ [클립보드] 복사 완료');
      onSuccess?.call();
      return true;
    } catch (e) {
      debugPrint('❌ [클립보드] 에러: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  /// 카카오톡 설치 여부 확인
  static Future<bool> isKakaoTalkAvailable() async {
    return await ShareClient.instance.isKakaoTalkSharingAvailable();
  }
}
