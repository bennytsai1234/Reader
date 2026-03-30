import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:legado_reader/core/services/app_log_service.dart';

class HeadlessWebViewService {
  static final HeadlessWebViewService _instance = HeadlessWebViewService._internal();
  factory HeadlessWebViewService() => _instance;
  HeadlessWebViewService._internal();

  WebViewController? _controller;
  Completer<void>? _mutex;

  /// 獲取網頁渲染後的 HTML
  Future<String> getRenderedHtml({
    required String url,
    Map<String, String>? headers,
    String? userAgent,
    String? js,
    int delayTime = 0,
  }) async {
    // Serialize concurrent requests
    while (_mutex != null) {
      await _mutex!.future;
    }
    _mutex = Completer<void>();

    final completer = Completer<String>();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String finishedUrl) async {
            // 如果有延遲要求，先等待
            if (delayTime > 0) {
              await Future.delayed(Duration(milliseconds: delayTime));
            }

            // 執行額外的 JS 腳本
            if (js != null && js.isNotEmpty) {
              try {
                await _controller?.runJavaScript(js);
              } catch (e) {
                AppLog.e('WebView JS 執行失敗: $e');
              }
            }

            // 獲取最終 HTML
            try {
              final html = await _controller?.runJavaScriptReturningResult('document.documentElement.outerHTML');
              String result = html?.toString() ?? '';
              // WebView 會將結果包裝成 JSON 字串，需要處理引號
              if (result.startsWith('"') && result.endsWith('"')) {
                result = result.substring(1, result.length - 1);
                // 處理轉義
                result = result.replaceAll('\\u003C', '<').replaceAll('\\"', '"');
              }
              if (!completer.isCompleted) completer.complete(result);
            } catch (e) {
              if (!completer.isCompleted) completer.completeError('獲取 HTML 失敗: $e');
            }
          },
          onWebResourceError: (error) {
            if (!completer.isCompleted) completer.completeError('WebView 加載失敗: ${error.description}');
          },
        ),
      );

    try {
      if (headers != null && headers.isNotEmpty) {
        await _controller?.loadRequest(Uri.parse(url), headers: headers);
      } else {
        await _controller?.loadRequest(Uri.parse(url));
      }
      
      final result = await completer.future.timeout(const Duration(seconds: 30));
      return result;
    } catch (e) {
      AppLog.e('HeadlessWebView Error: $e');
      rethrow;
    } finally {
      _controller = null;
      _mutex?.complete();
      _mutex = null;
    }
  }
}

