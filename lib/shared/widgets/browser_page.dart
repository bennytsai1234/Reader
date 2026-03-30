import 'package:flutter/material.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/services/cookie_store.dart';
import 'base_scaffold.dart';

/// 通用內建瀏覽器 (原 Android BrowserActivity)
class BrowserPage extends StatefulWidget {
  final String url;
  final String title;
  final bool captureCookies;

  const BrowserPage({
    super.key,
    required this.url,
    required this.title,
    this.captureCookies = true,
  });

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            }
          },
          onPageFinished: (url) async {
            if (mounted) setState(() => _isLoading = false);
            if (widget.captureCookies) {
              await _captureCookies(url);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _captureCookies(String url) async {
    try {
      final cookieString = await _controller.runJavaScriptReturningResult('document.cookie') as String;
      final cleanCookie = cookieString.replaceAll('"', '');
      if (cleanCookie.isNotEmpty) {
        await CookieStore().setCookie(url, cleanCookie);
        AppLog.d('Captured Cookies for $url: $cleanCookie');
      }
    } catch (e) {
      AppLog.e('Failed to capture cookies: $e', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: widget.title,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: '重新整理',
          onPressed: () => _controller.reload(),
        ),
        IconButton(
          icon: const Icon(Icons.check),
          tooltip: '完成',
          onPressed: () => Navigator.pop(context, _currentUrl),
        ),
      ],
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

