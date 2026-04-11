import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import '../js_extensions.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';
import 'package:legado_reader/core/services/http_client.dart';
import 'package:legado_reader/core/services/backstage_webview.dart';
import 'package:legado_reader/core/services/source_verification_service.dart';

/// 網路/WebView/I/O 相關 `java.*` 方法的 Dart 側 handler
///
/// 所有含「真正 async 工作」的 handler 都遵循 Promise bridge 模式：
///
/// ```
/// onMessage 收到 [callId, payload]
///   → 啟動 async Future
///   → 完成時呼叫 resolveJsPending(callId, result) 或 rejectJsPending(callId, err)
///   → handler 本體同步 return null (flutter_js 會丟掉此回傳值)
/// ```
///
/// 純同步 handler 例如 [timeFormatUTC] 則保留同步 return，直接回傳字串。
extension JsNetworkExtensions on JsExtensions {
  void injectNetworkExtensions() {
    // ─── java.ajax(url) — 返回 body 字串 ─────────────────────────
    runtime.onMessage('ajax', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final url = _parseUrlArg(parsed.payload);
      _runAjax(url).then((body) {
        resolveJsPending(parsed.callId, body);
      }).catchError((e) {
        AppLog.e('java.ajax failed: $e');
        rejectJsPending(parsed.callId, e);
      });
      return null;
    });

    // ─── java.ajaxAll(urlList) — 返回 body 字串陣列 ──────────────
    runtime.onMessage('ajaxAll', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final payload = parsed.payload;
      if (payload is! List) {
        resolveJsPending(parsed.callId, const <String>[]);
        return null;
      }
      final urls = payload.map((e) => e.toString()).toList();
      Future.wait(urls.map(_runAjax)).then((bodies) {
        resolveJsPending(parsed.callId, bodies);
      }).catchError((e) {
        AppLog.e('java.ajaxAll failed: $e');
        rejectJsPending(parsed.callId, e);
      });
      return null;
    });

    // ─── java.connect(url) — 返回 {body, url, code} ──────────────
    runtime.onMessage('connect', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final url = _parseUrlArg(parsed.payload);
      () async {
        try {
          final analyzeUrl = AnalyzeUrl(url, source: source as BookSource?);
          final body = await analyzeUrl.getResponseBody();
          resolveJsPending(parsed.callId, {
            'body': body,
            'url': analyzeUrl.url,
            'code': 200,
          });
        } catch (e) {
          AppLog.e('java.connect failed: $e');
          resolveJsPending(parsed.callId, {
            'body': e.toString(),
            'url': url,
            'code': 500,
          });
        }
      }();
      return null;
    });

    // ─── java.get(url, headers) — 返回 {body, url, code, headers} ─
    runtime.onMessage('get', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final payload = parsed.payload;
      if (payload is! List || payload.isEmpty) {
        rejectJsPending(
          parsed.callId,
          ArgumentError('java.get requires [url, headers]'),
        );
        return null;
      }
      final url = payload[0].toString();
      final headers = payload.length > 1 && payload[1] is Map
          ? Map<String, dynamic>.from(payload[1] as Map)
          : <String, dynamic>{};
      HttpClient().client.get(url, options: Options(headers: headers)).then((
        response,
      ) {
        resolveJsPending(parsed.callId, {
          'body': response.data?.toString() ?? '',
          'url': response.requestOptions.uri.toString(),
          'code': response.statusCode,
          'headers': response.headers.map,
        });
      }).catchError((e) {
        AppLog.e('java.get failed: $e');
        resolveJsPending(parsed.callId, {
          'body': e.toString(),
          'url': url,
          'code': 500,
          'headers': <String, dynamic>{},
        });
      });
      return null;
    });

    // ─── java.post(url, body, headers) ───────────────────────────
    runtime.onMessage('post', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final payload = parsed.payload;
      if (payload is! List || payload.length < 2) {
        rejectJsPending(
          parsed.callId,
          ArgumentError('java.post requires [url, body, headers]'),
        );
        return null;
      }
      final url = payload[0].toString();
      final body = payload[1];
      final headers = payload.length > 2 && payload[2] is Map
          ? Map<String, dynamic>.from(payload[2] as Map)
          : <String, dynamic>{};
      HttpClient().client
          .post(url, data: body, options: Options(headers: headers))
          .then((response) {
            resolveJsPending(parsed.callId, {
              'body': response.data?.toString() ?? '',
              'url': response.requestOptions.uri.toString(),
              'code': response.statusCode,
              'headers': response.headers.map,
            });
          })
          .catchError((e) {
            AppLog.e('java.post failed: $e');
            resolveJsPending(parsed.callId, {
              'body': e.toString(),
              'url': url,
              'code': 500,
              'headers': <String, dynamic>{},
            });
          });
      return null;
    });

    // ─── java.getCookie(tag, key) ────────────────────────────────
    runtime.onMessage('getCookie', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final payload = parsed.payload;
      if (payload is! List || payload.isEmpty) {
        resolveJsPending(parsed.callId, '');
        return null;
      }
      final tag = payload[0].toString();
      final key = payload.length > 1 ? payload[1]?.toString() : null;
      cookieStore.getCookie(tag).then((cookie) {
        if (key != null && key.isNotEmpty) {
          resolveJsPending(
            parsed.callId,
            cookieStore.cookieToMap(cookie)[key] ?? '',
          );
        } else {
          resolveJsPending(parsed.callId, cookie);
        }
      }).catchError((e) {
        rejectJsPending(parsed.callId, e);
      });
      return null;
    });

    // ─── java.webView(html, url, js) ─────────────────────────────
    runtime.onMessage('webView', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final payload = parsed.payload;
      if (payload is! List) {
        resolveJsPending(parsed.callId, '');
        return null;
      }
      final html = payload.isNotEmpty ? payload[0]?.toString() : null;
      final url = payload.length > 1 ? payload[1]?.toString() : null;
      final js = payload.length > 2 ? payload[2]?.toString() : null;
      () async {
        try {
          final webView = BackstageWebView(
            html: html,
            url: url,
            javaScript: js,
          );
          final response = await webView.getStrResponse();
          resolveJsPending(parsed.callId, response['body']?.toString() ?? '');
        } catch (e) {
          AppLog.e('java.webView failed: $e', error: e);
          rejectJsPending(parsed.callId, e);
        }
      }();
      return null;
    });

    // ─── java.startBrowserAwait(url, title) ──────────────────────
    runtime.onMessage('startBrowserAwait', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final payload = parsed.payload;
      if (payload is! List || payload.isEmpty) {
        resolveJsPending(parsed.callId, {
          'body': '',
          'url': '',
          'code': 500,
        });
        return null;
      }
      final url = payload[0].toString();
      final title = payload.length > 1 ? payload[1].toString() : '驗證';
      SourceVerificationService()
          .getVerificationResult(
            sourceKey: source?.getKey() ?? 'unknown',
            url: url,
            title: title,
            useBrowser: true,
          )
          .then((result) {
            resolveJsPending(parsed.callId, {
              'body': result,
              'url': url,
              'code': 200,
            });
          })
          .catchError((e) {
            resolveJsPending(parsed.callId, {
              'body': e.toString(),
              'url': url,
              'code': 500,
            });
          });
      return null;
    });

    // ─── java.getVerificationCode(imageUrl) ──────────────────────
    runtime.onMessage('getVerificationCode', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final imageUrl = parsed.payload.toString();
      SourceVerificationService()
          .getVerificationResult(
            sourceKey: source?.getKey() ?? 'unknown',
            url: imageUrl,
            title: '請輸入驗證碼',
            useBrowser: false,
          )
          .then((v) {
            resolveJsPending(parsed.callId, v);
          })
          .catchError((_) {
            resolveJsPending(parsed.callId, '');
          });
      return null;
    });

    // ─── java.getZipByteArrayContent(url, innerPath) ─────────────
    runtime.onMessage('getZipByteArrayContent', (dynamic args) {
      final parsed = JsExtensionsBase.parseAsyncCallArgs(args);
      final payload = parsed.payload;
      if (payload is! List || payload.length < 2) {
        resolveJsPending(parsed.callId, null);
        return null;
      }
      final url = payload[0].toString();
      final innerPath = payload[1].toString();
      () async {
        try {
          Uint8List? bytes;
          if (url.startsWith('http')) {
            final analyzeUrl = AnalyzeUrl(url, source: source as BookSource?);
            bytes = await analyzeUrl.getByteArray();
          } else {
            resolveJsPending(parsed.callId, null);
            return;
          }
          final archive = ZipDecoder().decodeBytes(bytes);
          final file = archive.findFile(innerPath);
          resolveJsPending(parsed.callId, file?.content as List<int>?);
        } catch (_) {
          resolveJsPending(parsed.callId, null);
        }
      }();
      return null;
    });

    // ─── java.timeFormatUTC — 真正同步 ───────────────────────────
    runtime.onMessage('timeFormatUTC', (dynamic args) {
      try {
        final time = args[0] as int;
        final format = args[1].toString();
        final offsetMs = args[2] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(
          time,
          isUtc: true,
        ).add(Duration(milliseconds: offsetMs));
        return DateFormat(format).format(date);
      } catch (_) {
        return '';
      }
    });
  }

  /// 內部共用：執行一次 ajax 請求回傳 body 字串
  Future<String> _runAjax(String url) async {
    final analyzeUrl = AnalyzeUrl(url, source: source as BookSource?);
    return analyzeUrl.getResponseBody();
  }

  /// 從 JS payload 解析 URL 字串 (兼容 String / List 兩種來源)
  String _parseUrlArg(dynamic payload) {
    if (payload is List && payload.isNotEmpty) return payload[0].toString();
    return payload.toString();
  }
}
