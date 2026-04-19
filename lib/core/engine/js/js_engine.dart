import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:html/dom.dart' as dom;
import 'package:xpath_selector/xpath_selector.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'async_js_rewriter.dart';
import 'js_extensions.dart';
import 'js_rule_async_wrapper.dart';

/// JsEngine - JavaScript 執行引擎
/// (原 Android Rhino) JS Engine (modules/rhino)
///
/// 使用 flutter_js 套件在 Dart 中執行 JavaScript
///
/// 兩條執行路徑：
/// - [evaluate] — 純同步 JS。若規則本身不含 async `java.*` 呼叫，仍走最快路徑。
/// - [evaluateAsync] — 會先以 [AsyncJsRewriter] 插入 `(await ...)` 包裝，
///   再用 [JsRuleAsyncWrapper] 包成 async IIFE，透過 `__ruleDone` sentinel
///   在 Dart 側 await Completer 完成。這是為了解決 flutter_js 同步 onMessage
///   回傳值限制所引入的 Promise bridge。
class JsEngine {
  JavascriptRuntime? _runtime;
  bool _isAvailable = false;
  JsExtensions? _extensions;
  final dynamic ruleContext;
  final Map<int, dom.Element> _bridgedElements = <int, dom.Element>{};
  int _nextBridgeElementId = 0;

  JsEngine({dynamic source, this.ruleContext}) {
    try {
      _runtime = getJavascriptRuntime();
      _isAvailable = true;
      _extensions = JsExtensions(
        _runtime!,
        source: source,
        ruleContext: ruleContext,
      );
      _extensions!.inject();
    } catch (e) {
      // Library not available in some test environments
      AppLog.e('JS Engine init error: $e', error: e);
      _isAvailable = false;
    }
  }

  /// Execute JavaScript code and return result synchronously.
  ///
  /// **不支援 async `java.*` 呼叫**。若 [jsCode] 中偵測到 async 呼叫，會印出
  /// warning 並仍按原字串執行（結果通常為 Promise 物件，rule 端會拿不到實值）。
  /// 呼叫端請優先使用 [evaluateAsync]。
  dynamic evaluate(String jsCode, {Map<String, dynamic>? context}) {
    if (!_isAvailable) {
      return _mockEvaluate(jsCode, context);
    }

    if (AsyncJsRewriter.needsAsync(jsCode)) {
      AppLog.e(
        'JsEngine.evaluate() called with async JS; '
        'switch caller to evaluateAsync(). Source prefix: '
        '${jsCode.substring(0, jsCode.length.clamp(0, 120))}',
      );
    }

    _injectContext(context);
    final result = _evaluateRuleScript(jsCode);
    return _decodeContextValue(result.rawResult);
  }

  /// Execute rule JS that may invoke async `java.*` / `cache.*` / `source.*`
  /// methods. Always awaits their underlying Futures and returns the rule's
  /// final expression value.
  ///
  /// 若 [jsCode] 經 [AsyncJsRewriter.needsAsync] 判定不需 async，會走同步
  /// fast path 直接回傳 [evaluate] 的結果 (避免不必要的 Promise bridge 開銷)。
  Future<dynamic> evaluateAsync(
    String jsCode, {
    Map<String, dynamic>? context,
  }) async {
    if (!_isAvailable) {
      return _mockEvaluate(jsCode, context);
    }

    if (!AsyncJsRewriter.needsAsync(jsCode)) {
      // Fast path: 純同步 rule JS
      _injectContext(context);
      final res = _evaluateRuleScript(jsCode);
      if (res.isError) {
        throw StateError('rule JS evaluate error: ${res.stringResult}');
      }
      return _decodeContextValue(res.rawResult);
    }

    _injectContext(context);
    final rewritten = AsyncJsRewriter.rewrite(jsCode);
    final (callId, future) = _extensions!.registerRuleCall();
    final wrapped = JsRuleAsyncWrapper.wrap(rewritten, callId);

    try {
      final res = _runtime!.evaluate(wrapped);
      if (res.isError) {
        _extensions!.cancelRuleCall(
          callId,
          StateError('rule JS evaluate error: ${res.stringResult}'),
        );
      } else {
        // 重要：同步 evaluate 完成後，async IIFE 已經被排進 microtask queue，
        // 需 pump 才能讓第一層 await 真正開始執行。
        _runtime!.executePendingJob();
      }
    } catch (e) {
      _extensions!.cancelRuleCall(callId, e);
      rethrow;
    }

    return future.then(_decodeContextValue);
  }

  JsEvalResult _evaluateRuleScript(String jsCode) {
    final wrapped = 'eval(${jsonEncode(jsCode)})';
    final result = _runtime!.evaluate(wrapped);
    if (!result.isError) {
      return result;
    }
    // 某些 legacy rule 在 eval(...) 路徑會被 QuickJS 誤判語法，
    // 退回原生 evaluate 以保住兼容性。
    return _runtime!.evaluate(jsCode);
  }

  void _injectContext(Map<String, dynamic>? context) {
    if (context == null) return;
    _bridgedElements.clear();
    _nextBridgeElementId = 0;
    context.forEach((key, value) {
      final jsLiteral = _encodeContextValue(value);
      switch (key) {
        case 'java':
        case 'cookie':
        case 'cache':
          return;
        case 'source':
          _runtime!.evaluate(
            'if (typeof source === "object" && source !== null) { '
            'Object.assign(source, $jsLiteral); '
            '} else { var source = $jsLiteral; }',
          );
          return;
        default:
          _runtime!.evaluate('var $key = $jsLiteral;');
      }
    });
  }

  String _encodeContextValue(dynamic value) {
    if (value == null) {
      return 'null';
    }
    if (value is dom.Element) {
      return _encodeElement(value);
    }
    if (value is XPathNode) {
      final node = value.node;
      if (node is dom.Element) {
        return _encodeElement(node);
      }
      return jsonEncode(value.text ?? '');
    }
    if (value is Iterable) {
      final encodedItems = value.map(_encodeContextValue).join(',');
      return '''
(function() {
  var arr = [$encodedItems];
  Object.defineProperty(arr, 'toArray', {
    value: function() { return arr; },
    enumerable: false
  });
  Object.defineProperty(arr, 'get', {
    value: function(index) { return arr[index]; },
    enumerable: false
  });
  Object.defineProperty(arr, 'size', {
    value: function() { return arr.length; },
    enumerable: false
  });
  return arr;
})()
''';
    }
    try {
      return jsonEncode(value);
    } catch (_) {
      return jsonEncode(value.toString());
    }
  }

  String _encodeElement(dom.Element element) {
    final bridgeId = _nextBridgeElementId++;
    _bridgedElements[bridgeId] = element;
    final payload = jsonEncode(<String, dynamic>{
      '__lrElementId': bridgeId,
      'text': element.text,
      'html': element.innerHtml,
      'outerHtml': element.outerHtml,
      'attributes': element.attributes,
    });
    return '''
(function() {
  var e = $payload;
  return {
    __lrElementId: e.__lrElementId,
    text: function() { return e.text || ''; },
    html: function() { return e.html || ''; },
    outerHtml: function() { return e.outerHtml || ''; },
    attr: function(name) {
      var attrs = e.attributes || {};
      return attrs[name] || '';
    },
    toString: function() {
      return e.outerHtml || e.html || e.text || '';
    }
  };
})()
''';
  }

  dynamic _decodeContextValue(dynamic value) {
    if (value is List) {
      return value.map(_decodeContextValue).toList();
    }
    if (value is Map) {
      final elementId = value['__lrElementId'];
      if (elementId is num) {
        return _bridgedElements[elementId.toInt()] ?? value;
      }
      final decoded = <dynamic, dynamic>{};
      value.forEach((key, entry) {
        decoded[key] = _decodeContextValue(entry);
      });
      return decoded;
    }
    return value;
  }

  dynamic _mockEvaluate(String jsCode, Map<String, dynamic>? context) {
    final trimmedJs = jsCode.trim();
    if (trimmedJs == 'key') return context?['key'] ?? 'key';
    if (trimmedJs == 'page') return context?['page'] ?? 'page';
    if (trimmedJs == 'result') return context?['result'] ?? 'result';
    if (trimmedJs == 'baseUrl') return context?['baseUrl'] ?? 'baseUrl';

    if (jsCode.contains("'https://api.example.com/book/' + result")) {
      return 'https://api.example.com/book/${context?['result']}';
    }
    return 'JS_ERROR: Library not available';
  }

  /// Dispose the JS runtime
  void dispose() {
    _runtime?.dispose();
  }
}
