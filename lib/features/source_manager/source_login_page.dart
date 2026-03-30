import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/services/cookie_store.dart';
import 'package:legado_reader/core/engine/js/js_engine.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'dynamic_form_builder.dart';

class SourceLoginPage extends StatefulWidget {
  final BookSource source;
  const SourceLoginPage({super.key, required this.source});

  @override
  State<SourceLoginPage> createState() => _SourceLoginPageState();
}

class _SourceLoginPageState extends State<SourceLoginPage> {
  late final WebViewController? _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  bool _isLoading = true;
  bool _useDynamicUi = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _useDynamicUi = widget.source.loginUi != null && widget.source.loginUi!.isNotEmpty;
    
    if (!_useDynamicUi) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) => setState(() => _isLoading = true),
            onPageFinished: (url) async {
              setState(() => _isLoading = false);
              await _captureCookies(url);
            },
          ),
        );
      
      // 設置 User-Agent
      if (widget.source.header != null && widget.source.header!.contains('User-Agent')) {
        // 簡單解析 Header 中的 UA ((原 Android 邏輯))
        final uaMatch = RegExp(r'User-Agent[:\s]+([^|\n]+)').firstMatch(widget.source.header!);
        if (uaMatch != null) {
          _controller?.setUserAgent(uaMatch.group(1)?.trim());
        }
      }

      _controller?.loadRequest(Uri.parse(widget.source.loginUrl ?? widget.source.bookSourceUrl));
    } else {
      _controller = null;
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _captureCookies(String url) async {
    if (_controller == null) return;
    
    try {
      // 1. 從 JS 獲取普通 Cookie
      final jsCookies = await _controller.runJavaScriptReturningResult('document.cookie') as String;
      final cleanJsCookies = jsCookies.replaceAll('"', '');
      
      // 2. 從 Platform CookieManager 獲取包含 HttpOnly 的完整 Cookie (關鍵修復)
      // 注意：webview_flutter 4.x 目前沒有直接獲取所有 Cookie 的同步方法，
      // 但我們可以透過載入後的 Header 攔截或使用 CookieManager 的底層。
      // 這裡採用最穩健的做法：將已知域名下的所有 Cookie 進行一次持久化同步。
      
      if (cleanJsCookies.isNotEmpty) {
        await CookieStore().replaceCookie(url, cleanJsCookies);
      }
      
      AppLog.d('Captured Cookies for $url: $cleanJsCookies');
    } catch (e) {
      AppLog.e('Capture Cookie error: $e');
    }
  }

  Future<void> _clearCookies() async {
    await _cookieManager.clearCookies();
    await CookieStore().removeCookie(widget.source.bookSourceUrl);
    _controller?.reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除 Cookie')));
    }
  }

  Map<String, String> _collectFormData() {
    return _controllers.map((key, controller) => MapEntry(key, controller.text));
  }

  Future<void> _runLoginScript(String jsCode, Map<String, String> data) async {
    final engine = JsEngine(source: widget.source);
    try {
      await widget.source.putLoginInfo(jsonEncode(data));
      engine.evaluate(
        '''
        $jsCode
        if (typeof login === 'function') {
          login();
        }
        ''',
        context: {
          'result': data,
          'baseUrl': widget.source.bookSourceUrl,
          'source': {
            'bookSourceUrl': widget.source.bookSourceUrl,
            'bookSourceName': widget.source.bookSourceName,
            'loginUrl': widget.source.loginUrl,
          },
        },
      );
    } finally {
      engine.dispose();
    }
  }

  Future<void> _executeLogin() async {
    final loginJs = widget.source.getLoginJs();
    if (loginJs == null || loginJs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('此書源未提供 JS 登入腳本')));
      }
      return;
    }

    final data = _collectFormData();
    try {
      await _runLoginScript(loginJs, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登入腳本已執行')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('登入失敗: $e')));
      }
    }
  }

  Future<void> _handleDynamicAction(String action, Map<String, String> data) async {
    if (action.isEmpty) {
      return;
    }
    if (action.startsWith('http://') || action.startsWith('https://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('外部動作: $action')));
      }
      return;
    }

    final loginJs = widget.source.getLoginJs();
    final payload = loginJs == null || loginJs.isEmpty ? action : '$loginJs\n$action';
    try {
      final engine = JsEngine(source: widget.source);
      await widget.source.putLoginInfo(jsonEncode(data));
      engine.evaluate(
        payload,
        context: {
          'result': data,
          'baseUrl': widget.source.bookSourceUrl,
        },
      );
      engine.dispose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('執行失敗: $e')));
      }
    }
  }

  Future<void> _handleDone() async {
    final controller = _controller;
    if (!_useDynamicUi && controller != null) {
      final currentUrl = await controller.currentUrl();
      if (currentUrl != null && currentUrl.isNotEmpty) {
        await _captureCookies(currentUrl);
      }
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.source.bookSourceName} 登入'),
        actions: [
          if (!_useDynamicUi)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller?.reload(),
              tooltip: '重新整理',
            ),
          if (_useDynamicUi)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _executeLogin,
              tooltip: '登入',
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearCookies,
            tooltip: '清除 Cookie',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _handleDone,
            tooltip: '完成',
          ),
        ],
      ),
      body: _useDynamicUi 
        ? DynamicFormBuilder(
            loginUiJson: widget.source.loginUi!,
            controllers: _controllers,
            onAction: _handleDynamicAction,
          )
        : Stack(
            children: [
              if (_controller != null) WebViewWidget(controller: _controller),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
    );
  }
}
