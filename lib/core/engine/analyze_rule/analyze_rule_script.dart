import 'dart:convert';
import 'dart:typed_data';
import 'analyze_rule_base.dart';
import '../js/js_engine.dart';
import 'package:legado_reader/core/services/cookie_store.dart';
import 'package:legado_reader/core/services/cache_manager.dart';
import 'package:legado_reader/core/services/http_client.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/utils/ttf_parser.dart';

/// AnalyzeRule 的腳本執行與異步擴展 (原 Android AnalyzeRule.kt & JsExtensions.kt)
extension AnalyzeRuleScript on AnalyzeRuleBase {
  dynamic evalJS(String jsStr, dynamic result) {
    jsEngine ??= JsEngine(source: source);
    if (AnalyzeRuleBase.scriptCache.containsKey(jsStr) && result == null) return AnalyzeRuleBase.scriptCache[jsStr];
    dynamic sourceMap;
    try { sourceMap = source?.toJson(); } catch (_) { sourceMap = source; }
    dynamic chapterMap;
    try { chapterMap = chapter?.toJson(); } catch (_) { chapterMap = chapter; }

    final context = {
      'java': this,
      'cookie': CookieStore(),
      'cache': CacheManager(),
      'result': result,
      'baseUrl': baseUrl,
      'redirectUrl': redirectUrl,
      'source': sourceMap,
      'chapter': chapterMap,
      'title': chapter?.title,
      'nextChapterUrl': nextChapterUrl,
      'key': key,
      'page': page,
      'src': content,
    };

    final evalResult = jsEngine!.evaluate(jsStr, context: context);
    if (result == null) AnalyzeRuleBase.scriptCache[jsStr] = evalResult;
    return evalResult;
  }

  /// 供 JS 調用的 TTF 解析 (原 Android JsExtensions.queryTTF)
  TtfParser? queryTTF(dynamic data) {
    if (data == null) return null;
    try {
      Uint8List? buffer;
      if (data is String) {
        if (data.startsWith('http')) {
          // 異步下載需處理，這裡暫作同步佔位
          return null;
        } else {
          // 嘗試 Base64 解碼
          buffer = base64Decode(data);
        }
      } else if (data is Uint8List) {
        buffer = data;
      }

      if (buffer != null) {
        return TtfParser(buffer);
      }
    } catch (e) {
      log('  ❌ queryTTF 失敗: $e');
    }
    return null;
  }

  /// 供 JS 調用的 Base64 TTF 解析
  TtfParser? queryBase64TTF(String? data) => queryTTF(data);

  /// 供 JS 調用的異步請求
  Future<String?> ajax(dynamic url) async {
    final urlStr = url is List ? url.first.toString() : url.toString();
    log('  ◇ JS 調用 ajax: $urlStr');
    try {
      final response = await HttpClient().client.get(urlStr);
      return response.data?.toString();
    } catch (e) {
      log('  ❌ ajax 失敗: $e');
      return null;
    }
  }

  /// 執行登入檢查 JS
  Future<void> checkLogin() async {
    final js = source is BookSource ? (source as BookSource).loginCheckJs : null;
    if (js != null && js.isNotEmpty) {
      log('⇒ 執行 loginCheckJs');
      evalJS(js, null);
    }
  }

  /// 執行目錄預整理 JS
  Future<void> preUpdateToc() async {
    final js = source is BookSource ? (source as BookSource).ruleToc?.preUpdateJs : null;
    if (js != null && js.isNotEmpty) {
      log('⇒ 執行 preUpdateJs');
      evalJS(js, null);
    }
  }

  void dispose() { jsEngine?.dispose(); }
}

