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

extension JsNetworkExtensions on JsExtensions {
  void injectNetworkExtensions() {
    // 實作 java.ajax(url) -> 返回 String body
    runtime.onMessage('ajax', (dynamic args) async {
      try {
        final url = parseUrlArg(args);
        final analyzeUrl = AnalyzeUrl(url, source: source as BookSource?);
        return await analyzeUrl.getResponseBody();
      } catch (e) {
        return e.toString();
      }
    });

    // 實作 java.ajaxAll(urlList)
    runtime.onMessage('ajaxAll', (dynamic args) async {
      try {
        if (args is List) {
          final urls = args.map((e) => e.toString()).toList();
          final futures =
              urls.map((url) => AnalyzeUrl(url, source: source as BookSource?).getResponseBody()).toList();
          return await Future.wait(futures);
        }
        return [];
      } catch (e) {
        return [e.toString()];
      }
    });

    // 實作 java.connect(urlStr) -> 返回物件 {body: "...", url: "...", code: 200}
    runtime.onMessage('connect', (dynamic args) async {
      try {
        final url = parseUrlArg(args);
        final analyzeUrl = AnalyzeUrl(url, source: source as BookSource?);
        final body = await analyzeUrl.getResponseBody();
        return {'body': body, 'url': analyzeUrl.url, 'code': 200};
      } catch (e) {
        return {'body': e.toString(), 'url': args.toString(), 'code': 500};
      }
    });

    // 實作 java.get(url, headers)
    runtime.onMessage('get', (dynamic args) async {
      try {
        final url = args[0].toString();
        final headers = Map<String, dynamic>.from(
          args[1] ?? {},
        );
        final response = await HttpClient().client.get(
          url,
          options: Options(headers: headers),
        );
        return {
          'body': response.data.toString(),
          'url': response.requestOptions.uri.toString(),
          'code': response.statusCode,
          'headers': response.headers.map,
        };
      } catch (e) {
        return {'body': e.toString(), 'code': 500};
      }
    });

    // 實作 java.post(url, body, headers)
    runtime.onMessage('post', (dynamic args) async {
      try {
        final url = args[0].toString();
        final body = args[1];
        final headers = Map<String, dynamic>.from(
          args[2] ?? {},
        );
        final response = await HttpClient().client.post(
          url,
          data: body,
          options: Options(headers: headers),
        );
        return {
          'body': response.data.toString(),
          'url': response.requestOptions.uri.toString(),
          'code': response.statusCode,
          'headers': response.headers.map,
        };
      } catch (e) {
        return {'body': e.toString(), 'code': 500};
      }
    });

    // 實作 java.getCookie
    runtime.onMessage('getCookie', (dynamic args) async {
      final tag = args[0].toString();
      final key = args.length > 1 ? args[1]?.toString() : null;
      if (key != null) {
        final cookie = await cookieStore.getCookie(tag);
        return cookieStore.cookieToMap(cookie)[key] ?? '';
      }
      return await cookieStore.getCookie(tag);
    });

    // 實作 java.webView
    runtime.onMessage('webView', (dynamic args) async {
      try {
        final html = args[0]?.toString();
        final url = args.length > 1 ? args[1]?.toString() : null;
        final js = args.length > 2 ? args[2]?.toString() : null;
        
        final webView = BackstageWebView(
          html: html,
          url: url,
          javaScript: js,
        );
        
        final response = await webView.getStrResponse();
        return response['body']?.toString() ?? '';
      } catch (e) {
        AppLog.e('webView error: $e', error: e);
        return e.toString();
      }
    });

    // 實作 java.startBrowserAwait ((原 Android ))
    runtime.onMessage('startBrowserAwait', (dynamic args) async {
      try {
        final url = args[0].toString();
        final title = args.length > 1 ? args[1].toString() : '驗證';
        
        final result = await SourceVerificationService().getVerificationResult(
          sourceKey: source?.getKey() ?? 'unknown',
          url: url,
          title: title,
          useBrowser: true,
        );
        
        return {'body': result, 'url': url, 'code': 200};
      } catch (e) {
        return {'body': e.toString(), 'url': args[0].toString(), 'code': 500};
      }
    });

    // 實作 java.getVerificationCode
    runtime.onMessage('getVerificationCode', (dynamic args) async {
      try {
        final imageUrl = args.toString();
        return await SourceVerificationService().getVerificationResult(
          sourceKey: source?.getKey() ?? 'unknown',
          url: imageUrl,
          title: '請輸入驗證碼',
          useBrowser: false,
        );
      } catch (e) {
        return '';
      }
    });

    // 實作 java.getZipByteArrayContent
    runtime.onMessage('getZipByteArrayContent', (dynamic args) async {
      try {
        final url = args[0].toString();
        final innerPath = args[1].toString();
        
        Uint8List? bytes;
        if (url.startsWith('http')) {
          final analyzeUrl = AnalyzeUrl(url, source: source as BookSource?);
          bytes = await analyzeUrl.getByteArray();
        } else {
          // Note: hex decode might need import if not in scope
          // Using a placeholder or assuming it's available via js_extensions or imports
          return null; 
        }
        final archive = ZipDecoder().decodeBytes(bytes);
        final file = archive.findFile(innerPath);
        return file?.content as List<int>?;
      } catch (_) {
        return null;
      }
    });

    // 實作 java.timeFormatUTC
    runtime.onMessage('timeFormatUTC', (dynamic args) {
      try {
        final time = args[0] as int;
        final format = args[1].toString();
        final offsetMs = args[2] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(time, isUtc: true).add(Duration(milliseconds: offsetMs));
        return DateFormat(format).format(date);
      } catch (_) { return ''; }
    });
  }

  String parseUrlArg(dynamic args) {
    if (args is List && args.isNotEmpty) return args[0].toString();
    return args.toString();
  }
}

