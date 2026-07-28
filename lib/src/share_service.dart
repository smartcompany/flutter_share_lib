import 'dart:convert';
import 'dart:io';
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

  static void _logKakaoShareDefaultUri(Uri uri, {Uri? requestedLinkUrl}) {
    final buffer = StringBuffer('[KakaoShare] shareDefault 완료\n');
    buffer.writeln('  template_id: ${uri.queryParameters['template_id'] ?? '-'}');

    final templateArgsRaw = uri.queryParameters['template_args'];
    if (templateArgsRaw == null || templateArgsRaw.isEmpty) {
      buffer.writeln(
        '  linkUrl: ${requestedLinkUrl?.toString() ?? '(없음)'}',
      );
      debugPrint(buffer.toString());
      return;
    }

    try {
      final decoded = jsonDecode(templateArgsRaw) as Map<String, dynamic>;
      String? linkUrl;
      String? buttonTitle;

      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value?.toString() ?? '';
        if (value.isEmpty) continue;

        final isHttpUrl =
            (key.contains('URL') || key.contains('url')) &&
            value.startsWith('http');
        if (isHttpUrl) {
          linkUrl ??= value;
          continue;
        }
        if (key == r'${FIRST_BUTTON_TITLE}') {
          buttonTitle = value;
        }
      }

      buffer.writeln(
        '  linkUrl: ${linkUrl ?? requestedLinkUrl?.toString() ?? '(없음)'}',
      );
      if (buttonTitle != null) {
        buffer.writeln('  buttonTitle: $buttonTitle');
      }
    } catch (error) {
      buffer.writeln('  template_args decode 실패: $error');
      buffer.writeln(
        '  linkUrl(fallback): ${requestedLinkUrl?.toString() ?? '(없음)'}',
      );
    }

    debugPrint(buffer.toString());
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
    /// 카카오 말풍선 하단 링크 버튼 문구. 없으면 URL 미리보기가 노출될 수 있음.
    String? linkButtonTitle,
    void Function(Uri sendUri)? onShareDefaultUri,
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
        buttonTitle: (linkButtonTitle != null && linkButtonTitle.trim().isNotEmpty)
            ? linkButtonTitle.trim()
            : null,
        // 클릭 시 webUrl/mobileWebUrl(Universal Link)로 이동. 본문 text에 URL 넣지 않음.
        link: resolvedLinkUrl != null
            ? Link(
                webUrl: resolvedLinkUrl,
                mobileWebUrl: resolvedLinkUrl,
              )
            : Link(),
      );

      debugPrint('🔍 [카카오톡 공유] linkUrl=$resolvedLinkUrl');

      debugPrint('🔍 [카카오톡 공유] shareDefault 호출 중...');
      final uri = await ShareClient.instance.shareDefault(template: template);
      _logKakaoShareDefaultUri(uri, requestedLinkUrl: resolvedLinkUrl);
      onShareDefaultUri?.call(uri);

      await _openKakaoShareUri(uri);
      debugPrint('✅ [카카오톡 공유] 성공');

      onSuccess?.call();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [카카오톡 공유] 에러: $e');
      debugPrint('❌ [카카오톡 공유] 스택 트레이스: $stackTrace');
      onError?.call(e.toString());
      return false;
    }
  }

  /// 카카오톡으로 이미지 공유.
  ///
  /// Android: 가능하면 **사진 메시지**로 전달(탭 시 전체 사진 보기).
  /// 실패 시·iOS: Kakao [FeedTemplate]으로 친구 선택 UI를 엽니다.
  /// (시스템 공유 시트로 떨어지지 않음)
  static Future<bool> shareToKakaoWithImage({
    required Uint8List imageBytes,
    required String title,
    String? description,
    Uri? linkUrl,
    String? linkButtonTitle,
    void Function(Uri sendUri)? onShareDefaultUri,
    Rect? sharePositionOrigin,
    VoidCallback? onSuccess,
    Function(String error)? onError,
    VoidCallback? onKakaoNotInstalled,
  }) async {
    debugPrint('🔍 [카카오톡 이미지 공유] 시작');

    if (await ShareClient.instance.isKakaoTalkSharingAvailable() == false) {
      debugPrint('❌ [카카오톡 이미지 공유] 카카오톡 미설치');
      onKakaoNotInstalled?.call();
      return false;
    }

    if (Platform.isAndroid) {
      try {
        final sent = await _shareImageFileToKakaoTalk(
          imageBytes: imageBytes,
          title: title,
          description: description,
          linkUrl: linkUrl,
        );
        if (sent) {
          debugPrint('✅ [카카오톡 이미지 공유] 사진 메시지 성공');
          onSuccess?.call();
          return true;
        }
      } catch (e, st) {
        debugPrint('⚠️ [카카오톡 이미지 공유] 사진 메시지 실패 → Feed로 전환: $e');
        debugPrint('$st');
      }
    }

    return _shareToKakaoFeedWithImage(
      imageBytes: imageBytes,
      title: title,
      description: description,
      linkUrl: linkUrl,
      linkButtonTitle: linkButtonTitle,
      onShareDefaultUri: onShareDefaultUri,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  static Future<bool> _shareImageFileToKakaoTalk({
    required Uint8List imageBytes,
    required String title,
    String? description,
    Uri? linkUrl,
  }) async {
    final caption = _buildKakaoImageCaption(
      title: title,
      description: description,
      linkUrl: linkUrl,
    );

    final tempDir = await getTemporaryDirectory();
    final shareDir = Directory('${tempDir.path}/share_lib');
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }
    final file = File(
      '${shareDir.path}/kakao_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(imageBytes, flush: true);
    debugPrint('✅ [카카오톡 사진 공유] 파일: ${file.path} (${imageBytes.length} bytes)');

    const channel = MethodChannel('share_lib/share');
    await channel.invokeMethod<bool>('shareImageToKakaoTalk', {
      'path': file.path,
      'text': caption,
    });

    Future.delayed(const Duration(seconds: 60), () async {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    });
    return true;
  }

  static Future<bool> _shareToKakaoFeedWithImage({
    required Uint8List imageBytes,
    required String title,
    String? description,
    Uri? linkUrl,
    String? linkButtonTitle,
    void Function(Uri sendUri)? onShareDefaultUri,
    VoidCallback? onSuccess,
    Function(String error)? onError,
  }) async {
    try {
      debugPrint('🔍 [카카오톡 Feed] 이미지 업로드 중...');
      final upload = await ShareClient.instance.uploadImage(
        byteData: imageBytes,
      );
      final imageInfo = upload.infos.original;
      final imageUri = Uri.parse(imageInfo.url);
      debugPrint('✅ [카카오톡 Feed] 업로드 완료: $imageUri');

      final appLink = linkUrl != null
          ? Link(webUrl: linkUrl, mobileWebUrl: linkUrl)
          : Link();

      final template = FeedTemplate(
        content: Content(
          title: title,
          description: description,
          imageUrl: imageUri,
          imageWidth: imageInfo.width,
          imageHeight: imageInfo.height,
          // Feed는 이미지 탭 = 항상 링크 이동(전체 사진 보기 불가).
          link: appLink,
        ),
        buttons: linkUrl != null &&
                (linkButtonTitle != null && linkButtonTitle.trim().isNotEmpty)
            ? [
                Button(
                  title: linkButtonTitle.trim(),
                  link: appLink,
                ),
              ]
            : null,
      );

      final uri = await ShareClient.instance.shareDefault(template: template);
      _logKakaoShareDefaultUri(uri, requestedLinkUrl: linkUrl);
      onShareDefaultUri?.call(uri);

      await _openKakaoShareUri(uri);
      debugPrint('✅ [카카오톡 Feed] 공유 성공');
      onSuccess?.call();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [카카오톡 Feed] 에러: $e');
      debugPrint('❌ [카카오톡 Feed] 스택: $stackTrace');
      onError?.call(e.toString());
      return false;
    }
  }

  static String _buildKakaoImageCaption({
    required String title,
    String? description,
    Uri? linkUrl,
  }) {
    final parts = <String>[];
    final t = title.trim();
    final d = description?.trim() ?? '';
    if (t.isNotEmpty) parts.add(t);
    if (d.isNotEmpty && d != t) parts.add(d);
    if (linkUrl != null) parts.add(linkUrl.toString());
    return parts.join('\n\n');
  }

  /// 카카오톡 공유 URI 실행.
  static Future<void> _openKakaoShareUri(Uri uri) async {
    debugPrint('🔍 [카카오톡 공유] open uri=$uri');
    try {
      await ShareClient.instance.launchKakaoTalk(uri);
      debugPrint('✅ [카카오톡 공유] launchKakaoTalk 성공');
      return;
    } catch (e) {
      debugPrint('⚠️ [카카오톡 공유] launchKakaoTalk 실패: $e');
    }

    // kakaolink:// 은 커스텀 스킴 — externalApplication으로 재시도
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        debugPrint('✅ [카카오톡 공유] launchUrl 성공');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ [카카오톡 공유] launchUrl 실패: $e');
    }

    throw Exception('Failed to open KakaoTalk with uri: $uri');
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
  /// [shareText]가 비어 있으면 이미지만 공유합니다.
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
    final trimmedText = shareText.trim();
    final imageOnly = trimmedText.isEmpty;
    try {
      debugPrint(
        imageOnly
            ? '🔍 [기본 공유] 이미지만 공유 시작'
            : '🔍 [기본 공유] 이미지 포함 공유 시작',
      );
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      // Write image bytes to file
      await file.writeAsBytes(imageBytes);
      debugPrint('✅ [기본 공유] 이미지 파일 생성: ${file.path}');

      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: imageOnly ? null : trimmedText,
        subject: imageOnly ? null : (subject ?? '공유'),
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
      if (imageOnly) {
        onError?.call(e.toString());
        return false;
      }
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
