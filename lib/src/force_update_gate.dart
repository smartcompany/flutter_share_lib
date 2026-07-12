import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'force_update_service.dart';

/// 앱 시작 시 서버 최소 버전을 확인하고, 필요하면 앱을 막는 게이트.
///
/// ```dart
/// MaterialApp(
///   home: ForceUpdateGate(
///     baseUrl: 'https://your-server.com',
///     androidStoreUrl: 'https://play.google.com/store/apps/details?id=...',
///     iosStoreUrl: 'https://apps.apple.com/app/id...',
///     child: HomeScreen(),
///   ),
/// )
/// ```
class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({
    super.key,
    required this.baseUrl,
    required this.child,
    this.iosStoreUrl,
    this.androidStoreUrl,
    this.title,
    this.message,
    this.buttonLabel,
  });

  /// 서버 base URL (`/api/settings`에 붙음).
  final String baseUrl;

  final Widget child;

  /// settings에 URL이 없을 때 사용하는 폴백.
  final String? iosStoreUrl;
  final String? androidStoreUrl;

  /// UI 문구 오버라이드 (없으면 locale 기본값).
  final String? title;
  final String? message;
  final String? buttonLabel;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate> {
  ForceUpdateCheckResult? _result;
  var _checking = true;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    ForceUpdateService.shared.setBaseUrl(widget.baseUrl);
    final result = await ForceUpdateService.shared.check(
      iosStoreUrlFallback: widget.iosStoreUrl,
      androidStoreUrlFallback: widget.androidStoreUrl,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _checking = false;
    });
  }

  Future<void> _openStore() async {
    final url = _result?.storeUrl?.trim();
    if (url == null || url.isEmpty) {
      debugPrint('❌ [ForceUpdate] storeUrl이 없습니다');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      debugPrint('❌ [ForceUpdate] 스토어 열기 실패: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 검사 중이거나 강제 업데이트가 아니면 앱 정상 표시
    if (_checking || _result == null || !_result!.requiresForceUpdate) {
      return widget.child;
    }

    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    final title = widget.title ?? _defaultTitle(locale);
    final message = widget.message ??
        _result!.message ??
        _defaultMessage(
          locale,
          current: _result!.currentVersion,
          min: _result!.minVersion ?? '',
        );
    final buttonLabel = widget.buttonLabel ?? _defaultButton(locale);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.system_update,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withValues(alpha: 0.75),
                      ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _openStore,
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _defaultTitle(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '업데이트가 필요합니다';
      case 'ja':
        return 'アップデートが必要です';
      case 'zh':
        return '需要更新';
      default:
        return 'Update required';
    }
  }

  static String _defaultMessage(
    Locale locale, {
    required String current,
    required String min,
  }) {
    switch (locale.languageCode) {
      case 'ko':
        return '계속 사용하려면 최신 버전으로 업데이트해 주세요.\n'
            '(현재 $current → 필요 $min)';
      case 'ja':
        return 'アプリを使い続けるには最新版へのアップデートが必要です。\n'
            '（現在 $current → 必要 $min）';
      case 'zh':
        return '请更新到最新版本以继续使用。\n'
            '（当前 $current → 需要 $min）';
      default:
        return 'Please update to the latest version to continue.\n'
            '(Current $current → Required $min)';
    }
  }

  static String _defaultButton(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '스토어에서 업데이트';
      case 'ja':
        return 'ストアで更新';
      case 'zh':
        return '前往商店更新';
      default:
        return 'Update on Store';
    }
  }
}
