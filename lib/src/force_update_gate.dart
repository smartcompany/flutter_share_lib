import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:share_lib/src/l10n_helper.dart';

import 'force_update_service.dart';

/// 앱 시작 시 서버 최소 버전을 확인하고, 필요하면 앱을 막는 게이트.
///
/// ```dart
/// MaterialApp(
///   home: ForceUpdateGate(
///     baseUrl: 'https://your-server.com',
///     child: HomeScreen(),
///   ),
/// )
/// ```
///
/// 다운로드 링크는 settings의 `down_load_url`을 사용합니다.
class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({
    super.key,
    required this.baseUrl,
    required this.child,
    this.downloadUrlFallback,
    this.title,
    this.message,
    this.buttonLabel,
  });

  /// 서버 base URL (`/api/settings`에 붙음).
  final String baseUrl;

  final Widget child;

  /// settings에 `down_load_url`이 없을 때 사용하는 폴백.
  final String? downloadUrlFallback;

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
      downloadUrlFallback: widget.downloadUrlFallback,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _checking = false;
    });
  }

  Future<void> _openDownload() async {
    final url = _result?.downloadUrl?.trim();
    if (url == null || url.isEmpty) {
      debugPrint('❌ [ForceUpdate] down_load_url이 없습니다');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      debugPrint('❌ [ForceUpdate] 다운로드 링크 열기 실패: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || _result == null || !_result!.requiresForceUpdate) {
      return widget.child;
    }

    final l10n = shareLibL10n(context);
    final title = widget.title ?? l10n.forceUpdateTitle;
    final message = widget.message ??
        _result!.message ??
        l10n.forceUpdateMessage(
          _result!.currentLabel,
          _result!.requiredLabel ?? '',
        );
    final buttonLabel = widget.buttonLabel ?? l10n.forceUpdateButton;

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
                    onPressed: _openDownload,
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
}
