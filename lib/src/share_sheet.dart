import 'package:flutter/material.dart';

import 'share_service.dart';

/// 카카오톡 / 시스템 공유 / 링크 복사 공용 바텀 시트
///
/// Tabata · DopamineAssets 등에서 쓰던 공유 UI를 라이브러리로 공통화.
abstract final class ShareSheet {
  static Rect? shareOriginFromContext(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// [shareText] 시스템 공유·복사에 쓰는 본문 (URL 포함 권장)
  /// [kakaoShareText] 카카오 말풍선 본문. null이면 [shareText]에서 URL을 뺀 텍스트 사용
  /// [linkUrl] 카카오 버튼/미리보기 링크 (Universal Link / applink)
  /// [linkButtonTitle] 카카오 하단 버튼 문구
  static Future<void> show({
    required BuildContext context,
    required String shareText,
    String? kakaoShareText,
    String? subject,
    Uri? linkUrl,
    String linkButtonTitle = '앱에서 열기',
    String title = '공유하기',
    String kakaoLabel = '카카오톡으로 공유',
    String systemLabel = '다른 앱으로 공유',
    String copyLabel = '링크 복사',
    String copiedMessage = '링크를 복사했어요',
    String failedMessage = '공유에 실패했어요',
    bool showCopy = true,
  }) async {
    final shareOrigin = shareOriginFromContext(context);
    final kakaoAvailable = await ShareService.isKakaoTalkAvailable();
    if (!context.mounted) return;

    final resolvedKakaoText =
        kakaoShareText ?? _stripTrailingUrl(shareText, linkUrl);
    final systemText = _mergeTextAndUrl(shareText, linkUrl);

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final textTheme = Theme.of(ctx).textTheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 8),
                if (kakaoAvailable)
                  ListTile(
                    leading: Icon(
                      Icons.chat_bubble_rounded,
                      color: colorScheme.tertiary,
                    ),
                    title: Text(kakaoLabel, style: textTheme.titleMedium),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await ShareService.shareToKakao(
                        resolvedKakaoText,
                        linkUrl: linkUrl,
                        linkButtonTitle: linkButtonTitle,
                        onError: (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(failedMessage)),
                            );
                          }
                        },
                      );
                    },
                  ),
                ListTile(
                  leading: Icon(
                    Icons.share_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(systemLabel, style: textTheme.titleMedium),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final ok = await ShareService.shareText(
                      systemText,
                      subject: subject,
                      sharePositionOrigin: shareOrigin,
                    );
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(failedMessage)),
                      );
                    }
                  },
                ),
                if (showCopy)
                  ListTile(
                    leading: Icon(
                      Icons.copy_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: Text(copyLabel, style: textTheme.titleMedium),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final ok = await ShareService.copyToClipboard(
                        linkUrl?.toString() ?? systemText,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? copiedMessage : failedMessage),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _mergeTextAndUrl(String shareText, Uri? linkUrl) {
    if (linkUrl == null) return shareText;
    final url = linkUrl.toString();
    if (shareText.contains(url)) return shareText;
    return '$shareText\n$url';
  }

  static String _stripTrailingUrl(String shareText, Uri? linkUrl) {
    if (linkUrl == null) return shareText.trim();
    final url = linkUrl.toString();
    var text = shareText.trim();
    if (text.endsWith(url)) {
      text = text.substring(0, text.length - url.length).trim();
    }
    return text.isEmpty ? shareText.trim() : text;
  }
}
