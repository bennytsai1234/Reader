import 'dart:async';
import 'dart:io' as io;
import 'package:webview_flutter/webview_flutter.dart';
import 'network_service.dart';

/// WebViewManager - 處理網頁挑戰與 Cookie 同步
/// 用於解決 Cloudflare 與複雜 JS 驗證
class WebViewManager {
  static final WebViewManager _instance = WebViewManager._internal();
  factory WebViewManager() => _instance;
  WebViewManager._internal();

  WebViewController? _controller;

  /// 靜默解決網頁挑戰並同步 Cookie
  Future<bool> solveChallenge(String url) async {
    final completer = Completer<bool>();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            // 等待一段時間讓 JS 執行完成 (或 Cloudflare 5秒盾結束)
            await Future.delayed(const Duration(seconds: 5));
            
            try {
              // 透過 JS 獲取 Cookie (注意：這只能獲取非 HttpOnly 的 Cookie)
              // 為了獲取完整 Cookie，通常需要插件底層支援，但 webview_flutter 限制較多
              // 這裡盡力而為，或者使用 WebViewCookieManager
              final cookieString = await _controller?.runJavaScriptReturningResult('document.cookie') as String;
              
              if (cookieString.isNotEmpty && cookieString != '""') {
                // 解析 Cookie 字串並同步
                final rawCookies = cookieString.replaceAll('"', '').split(';');
                for (var rawCookie in rawCookies) {
                  if (rawCookie.trim().isEmpty) continue;
                  await NetworkService().cookieJar.saveFromResponse(
                    Uri.parse(url), 
                    [io.Cookie.fromSetCookieValue(rawCookie.trim())]
                  );
                }
                if (!completer.isCompleted) completer.complete(true);
              } else {
                // 如果 JS 拿不到，至少頁面加載完成了
                if (!completer.isCompleted) completer.complete(true);
              }
            } catch (e) {
              if (!completer.isCompleted) completer.complete(false);
            }
          },
          onWebResourceError: (error) {
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      );

    await _controller?.loadRequest(Uri.parse(url));
    return completer.future.timeout(const Duration(seconds: 20), onTimeout: () => false);
  }

  Future<void> dispose() async {
    _controller = null;
  }
}

