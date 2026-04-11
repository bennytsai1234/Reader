import 'dart:convert';

/// 將 rule JS 原始碼包成 async IIFE，並透過 `__ruleDone` sentinel 把結果
/// 回送給 Dart 側 [JsExtensionsBase] 中的 pending Completer。
///
/// 典型 rule JS 是「最後一行表達式即為回傳值」的 Rhino/QuickJS 語意：
///
/// ```
/// var url = baseUrl + "/api";
/// java.ajax(url)
/// ```
///
/// 我們透過 [injectFinalReturn] 在最後一個 top-level statement 前補上 `return`，
/// 再包進 async IIFE 以便內部可以對 rewriter 產生的 `(await ...)` 正確等待。
///
/// 失敗處理：任何 JS 端例外都透過 sentinel 第 3 欄 (errMsg) 回傳，Dart 端
/// Completer 會 completeError。
class JsRuleAsyncWrapper {
  JsRuleAsyncWrapper._();

  /// 包裝已經經過 AsyncJsRewriter 處理的 JS 原始碼為 async IIFE。
  ///
  /// [callId] 對應 [JsExtensionsBase.registerRuleCall] 配到的 id。
  static String wrap(String rewrittenSource, int callId) {
    final body = injectFinalReturn(rewrittenSource);
    return '''
(async function() {
  try {
    var __lrRuleRes = await (async function() {
${_indent(body, '      ')}
    })();
    sendMessage('__ruleDone', JSON.stringify([$callId, __lrRuleRes === undefined ? null : __lrRuleRes, null]));
  } catch (__lrErr) {
    var __lrMsg = (__lrErr && __lrErr.message) ? String(__lrErr.message) : String(__lrErr);
    sendMessage('__ruleDone', JSON.stringify([$callId, null, __lrMsg]));
  }
})();
''';
  }

  /// 對 JS source 注入 `return`，使最後一個 top-level statement 的結果被回傳。
  ///
  /// 若最後一個 statement 已經以 `return` / `throw` 開頭，或是以變數宣告、
  /// 控制流 keyword 開頭，則不做修改（它們不會產生表達式結果）。
  ///
  /// 對包含在字串字面量、註解、巢狀括號內部的 `;` / `}` 不會誤判為 statement
  /// 邊界。
  static String injectFinalReturn(String code) {
    final stmtStart = _findLastTopLevelStatementStart(code);
    // 取得從 stmtStart 到結尾的「尾段」，扣除尾端空白
    var end = code.length;
    while (end > stmtStart && _isWhitespace(code.codeUnitAt(end - 1))) {
      end--;
    }
    // 若尾端是 `;`，一併 trim（避免 `return <expr>;;` 但也防止空統計）
    var trailingSemi = false;
    if (end > stmtStart && code.codeUnitAt(end - 1) == _semi) {
      end--;
      trailingSemi = true;
      while (end > stmtStart && _isWhitespace(code.codeUnitAt(end - 1))) {
        end--;
      }
    }
    if (end == stmtStart) return code; // 空 tail，不注入

    // tail 起始：跳過 leading whitespace
    var tailStart = stmtStart;
    while (tailStart < end && _isWhitespace(code.codeUnitAt(tailStart))) {
      tailStart++;
    }
    if (tailStart == end) return code;

    final tail = code.substring(tailStart, end);
    if (_startsWithNonReturnableKeyword(tail)) return code;

    final head = code.substring(0, tailStart);
    final rest = code.substring(end);
    // 保留可能被 trim 掉的尾端 `;` 與 whitespace — 統一在表達式後補上 `;`
    return '${head}return $tail;${trailingSemi ? '' : ''}$rest';
  }

  /// 尋找最後一個 top-level statement 起點的位置。
  ///
  /// 規則：從左到右掃描，追蹤括號/大括號/方括號深度並跳過字串與註解。
  /// 每次在 depth == 0 遇到 `;` 或 `}` 就把「下一個 index」當作候選 statement
  /// 起點。回傳最後一個候選；若從未遇到則回傳 0（整段就是一個 statement）。
  static int _findLastTopLevelStatementStart(String code) {
    final n = code.length;
    var depth = 0;
    var lastStart = 0;
    var i = 0;
    while (i < n) {
      final c = code.codeUnitAt(i);
      if (c == _slash && i + 1 < n) {
        final next = code.codeUnitAt(i + 1);
        if (next == _slash) {
          final end = code.indexOf('\n', i);
          i = end == -1 ? n : end + 1;
          continue;
        }
        if (next == _star) {
          final end = code.indexOf('*/', i + 2);
          i = end == -1 ? n : end + 2;
          continue;
        }
      }
      if (c == _dquote || c == _squote || c == _backtick) {
        i = _skipString(code, i, c);
        continue;
      }
      if (c == _lparen || c == _lbracket) {
        depth++;
        i++;
        continue;
      }
      if (c == _rparen || c == _rbracket) {
        depth--;
        i++;
        continue;
      }
      if (c == _lbrace) {
        depth++;
        i++;
        continue;
      }
      if (c == _rbrace) {
        depth--;
        if (depth == 0) lastStart = i + 1;
        i++;
        continue;
      }
      if (c == _semi && depth == 0) {
        lastStart = i + 1;
        i++;
        continue;
      }
      i++;
    }
    return lastStart;
  }

  static int _skipString(String source, int startIdx, int quote) {
    final n = source.length;
    var i = startIdx + 1;
    while (i < n) {
      final c = source.codeUnitAt(i);
      if (c == _backslash) {
        i += 2;
        continue;
      }
      if (c == quote) return i + 1;
      if (quote == _backtick &&
          c == _dollar &&
          i + 1 < n &&
          source.codeUnitAt(i + 1) == _lbrace) {
        // 跳過 ${...} 插值
        var depth = 1;
        i += 2;
        while (i < n && depth > 0) {
          final cc = source.codeUnitAt(i);
          if (cc == _lbrace) {
            depth++;
          } else if (cc == _rbrace) {
            depth--;
          } else if (cc == _dquote || cc == _squote || cc == _backtick) {
            i = _skipString(source, i, cc);
            continue;
          }
          i++;
        }
        continue;
      }
      i++;
    }
    return n;
  }

  /// 檢查 [tail] 開頭是否為一個不會產生表達式值的 keyword (var/let/const/
  /// if/for/while/do/switch/try/function/class/return/throw/break/continue/
  /// debugger/{/}) — 若是，表示 tail 不適合包 `return`。
  ///
  /// 特別地，`return` / `throw` 已經會把值/例外往外傳播，也不應重複包。
  static bool _startsWithNonReturnableKeyword(String tail) {
    if (tail.isEmpty) return true;
    final c0 = tail.codeUnitAt(0);
    // 如果以 `{` 開頭，可能是 block statement 或 object literal。object
    // literal 在 statement position 幾乎不會發生（rule JS 不會把 object
    // literal 當最後一個 statement），所以視為 block，不注入 return。
    if (c0 == _lbrace || c0 == _rbrace) return true;

    // 抽出開頭 identifier
    var i = 0;
    while (i < tail.length && _isIdentChar(tail.codeUnitAt(i))) {
      i++;
    }
    if (i == 0) return false;
    final word = tail.substring(0, i);
    return _stmtKeywords.contains(word);
  }

  static String _indent(String code, String prefix) {
    final lines = const LineSplitter().convert(code);
    return lines.map((l) => l.isEmpty ? l : '$prefix$l').join('\n');
  }

  static bool _isWhitespace(int cu) =>
      cu == 0x20 || cu == 0x09 || cu == 0x0A || cu == 0x0D;

  static bool _isIdentChar(int cu) {
    return (cu >= 0x30 && cu <= 0x39) ||
        (cu >= 0x41 && cu <= 0x5A) ||
        (cu >= 0x61 && cu <= 0x7A) ||
        cu == 0x5F ||
        cu == 0x24;
  }

  static const Set<String> _stmtKeywords = {
    'var',
    'let',
    'const',
    'if',
    'else',
    'for',
    'while',
    'do',
    'switch',
    'case',
    'default',
    'try',
    'catch',
    'finally',
    'function',
    'class',
    'return',
    'throw',
    'break',
    'continue',
    'debugger',
    'import',
    'export',
  };

  // char codes
  static const int _slash = 0x2F;
  static const int _star = 0x2A;
  static const int _backslash = 0x5C;
  static const int _dquote = 0x22;
  static const int _squote = 0x27;
  static const int _backtick = 0x60;
  static const int _dollar = 0x24;
  static const int _lbrace = 0x7B;
  static const int _rbrace = 0x7D;
  static const int _lparen = 0x28;
  static const int _rparen = 0x29;
  static const int _lbracket = 0x5B;
  static const int _rbracket = 0x5D;
  static const int _semi = 0x3B;
}
