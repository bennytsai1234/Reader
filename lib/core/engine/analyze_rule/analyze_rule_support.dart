import 'dart:convert';
import 'package:html/dom.dart';
import '../parsers/analyze_by_css.dart';
import '../parsers/analyze_by_json_path.dart';
import '../parsers/analyze_by_xpath.dart';
import 'analyze_rule_base.dart';

enum Mode { xpath, json, defaultMode, js, regex }

/// SourceRule 輔助類
/// (原 Android model/analyzeRule/AnalyzeRule.kt) 內部的私有類
class SourceRule {
  String rule;
  Mode mode;
  String replaceRegex = '';
  String replacement = '';
  bool replaceFirst = false;
  Map<String, String> putMap = {};
  bool isDynamic = false;
  List<String> ruleParam = [];
  List<int> ruleType = [];

  static const int jsonPartRuleType = -3;
  static const int getRuleType = -2;
  static const int jsRuleType = -1;
  static const int defaultRuleType = 0;

  SourceRule(this.rule, {this.mode = Mode.defaultMode}) {
    // 處理 ##regex##replacement 與 ### replaceFirst
    if (rule.contains('##')) {
      final rawParts = rule.split('##');
      final parts = <String>[];
      for (var i = 0; i < rawParts.length; i++) {
        final part = rawParts[i];
        if (i == rawParts.length - 1 && part.endsWith('#')) {
          replaceFirst = true;
          parts.add(part.substring(0, part.length - 1));
        } else {
          parts.add(part);
        }
      }

      if (rule.startsWith('##')) {
        mode = Mode.regex;
        rule = ''; // 提取規則為空，表示對全文進行正則替換
        if (parts.length > 1) replaceRegex = parts[1];
        if (parts.length > 2) replacement = parts[2];
      } else {
        rule = parts[0];
        if (parts.length > 1) replaceRegex = parts[1];
        if (parts.length > 2) replacement = parts[2];
      }
    }

    if (mode == Mode.defaultMode) {
      final normalizedRule = rule.toUpperCase();
      if (normalizedRule.startsWith('@CSS:')) {
        mode = Mode.defaultMode;
      } else if (rule.startsWith('@@')) {
        mode = Mode.defaultMode;
        rule = rule.substring(2);
      } else if (normalizedRule.startsWith('@JSON:')) {
        mode = Mode.json;
        rule = rule.substring(6);
      } else if (normalizedRule.startsWith('@XPATH:')) {
        mode = Mode.xpath;
        rule = rule.substring(7);
      } else if (rule.startsWith('/')) {
        mode = Mode.xpath;
      } else if (rule.startsWith(r'$.') || rule.startsWith(r'$[')) {
        mode = Mode.json;
      }
    }
    final putPattern = RegExp(r'@put:(\{.*?\})', caseSensitive: false);
    var vRuleStr = rule;
    final putMatches = putPattern.allMatches(rule);
    for (final putMatch in putMatches) {
      vRuleStr = vRuleStr.replaceFirst(putMatch.group(0)!, '');
      try {
        final jsonStr = putMatch.group(1)!;
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        map.forEach((k, v) => putMap[k] = v.toString());
      } catch (_) {}
    }
    rule = vRuleStr;
    final evalPattern = RegExp(
      r'@get:\{[^}]+?\}|\{\{[\w\W]*?\}\}|\{\$.*?\}',
      caseSensitive: false,
    );
    var start = 0;
    final evalMatches = evalPattern.allMatches(rule);
    if (evalMatches.isNotEmpty) isDynamic = true;
    for (final match in evalMatches) {
      if (match.start > start) _splitRegex(rule.substring(start, match.start));
      final tmp = match.group(0)!;
      if (tmp.toLowerCase().startsWith('@get:')) {
        ruleType.add(getRuleType);
        ruleParam.add(tmp.substring(6, tmp.length - 1));
      } else if (tmp.startsWith('{{')) {
        ruleType.add(jsRuleType);
        ruleParam.add(tmp.substring(2, tmp.length - 2));
      } else if (tmp.startsWith('{\$')) {
        ruleType.add(jsonPartRuleType);
        ruleParam.add(tmp.substring(1, tmp.length - 1));
      }
      start = match.end;
    }
    if (rule.length > start) _splitRegex(rule.substring(start));
  }

  void _splitRegex(String ruleStr) {
    var start = 0;
    final regexPattern = RegExp(r'\$\d{1,2}');
    final matches = regexPattern.allMatches(ruleStr);
    if (matches.isNotEmpty) {
      isDynamic = true;
      if (mode != Mode.js) {
        mode = Mode.regex;
      }
    }
    for (final match in matches) {
      if (match.start > start) {
        ruleType.add(defaultRuleType);
        ruleParam.add(ruleStr.substring(start, match.start));
      }
      ruleType.add(int.parse(match.group(0)!.substring(1)));
      ruleParam.add(match.group(0)!);
      start = match.end;
    }
    if (ruleStr.length > start) {
      ruleType.add(defaultRuleType);
      ruleParam.add(ruleStr.substring(start));
    }
  }

  /// 動態組合規則字串 (對標 Android SourceRule.makeUpRule)
  ///
  /// 重要：本方法不得 mutate `this.rule`，因為 SourceRule 實例會被
  /// stringRuleCache 靜態快取跨呼叫共用。mutate 後會造成 race condition
  /// 或把動態組合後的字串寫回快取，污染後續使用者。
  String makeUpRule(dynamic result, dynamic analyzer) {
    if (!isDynamic) return rule;
    final buffer = StringBuffer();
    for (var i = 0; i < ruleType.length; i++) {
      final type = ruleType[i];
      final param = ruleParam[i];
      if (type == defaultRuleType) {
        buffer.write(param);
      } else if (type == jsRuleType) {
        final trimmed = param.trimLeft();
        if (trimmed.startsWith('@') ||
            trimmed.startsWith(r'$.') ||
            trimmed.startsWith(r'$[') ||
            trimmed.startsWith('//')) {
          buffer.write(analyzer.getString(trimmed));
        } else {
          buffer.write(analyzer.evalJS(param, result) ?? '');
        }
      } else if (type == getRuleType) {
        buffer.write(analyzer.get(param));
      } else if (type == jsonPartRuleType) {
        final val = getAnalyzeByJSonPath(analyzer, result).getString(param);
        buffer.write(val);
      } else {
        // 反向引用 $1..$N —— 對應 _splitRegex 取出的 `$N` 標記
        // 僅在前一階段結果是 List (regex group) 時有效；對 String 結果
        // 直接寫入空字串，避免把字面 "$1" 寫回造成解析錯亂。
        if (result is List && type > 0 && type <= result.length) {
          buffer.write(result[type - 1]?.toString() ?? '');
        }
      }
    }
    return buffer.toString();
  }

  // 延遲載入解析器
  AnalyzeByXPath getAnalyzeByXPath(AnalyzeRuleBase analyzer, dynamic o) {
    if (o != analyzer.content) return AnalyzeByXPath(o);
    return analyzer.analyzeByXPath ??= AnalyzeByXPath(analyzer.content);
  }

  AnalyzeByCss getAnalyzeByJSoup(AnalyzeRuleBase analyzer, dynamic o) {
    if (o != analyzer.content) return AnalyzeByCss(o);
    return analyzer.analyzeByJSoup ??= AnalyzeByCss(analyzer.content);
  }

  AnalyzeByJsonPath getAnalyzeByJSonPath(AnalyzeRuleBase analyzer, dynamic o) {
    if (o != analyzer.content) return AnalyzeByJsonPath(o);
    return analyzer.analyzeByJSonPath ??= AnalyzeByJsonPath(analyzer.content);
  }
}

String stringifyRuleResult(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is Element) {
    return value.outerHtml;
  }
  if (value is Iterable) {
    return value.map(stringifyRuleResult).join('\n');
  }
  return value.toString();
}

bool isJsonLikeRuleInput(dynamic value) {
  return value is Map || value is List;
}

String? buildJsonFallbackRule(String rule) {
  final trimmed = rule.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith(r'$.') || trimmed.startsWith(r'$[')) {
    return trimmed;
  }

  const operatorPattern = r'&&|\|\||%%';
  final operatorRegex = RegExp(operatorPattern);
  final matches = operatorRegex.allMatches(trimmed).toList();
  if (matches.isEmpty) {
    return _prefixJsonRuleSegment(trimmed);
  }

  final buffer = StringBuffer();
  var lastEnd = 0;
  for (final match in matches) {
    final segment = trimmed.substring(lastEnd, match.start).trim();
    final transformed = _prefixJsonRuleSegment(segment);
    if (transformed == null) {
      return null;
    }
    buffer.write(transformed);
    buffer.write(match.group(0));
    lastEnd = match.end;
  }

  final tail = trimmed.substring(lastEnd).trim();
  final transformedTail = _prefixJsonRuleSegment(tail);
  if (transformedTail == null) {
    return null;
  }
  buffer.write(transformedTail);
  return buffer.toString();
}

String? _prefixJsonRuleSegment(String segment) {
  final trimmed = segment.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed == '*') {
    return r'$[*]';
  }
  if (trimmed.startsWith(r'$.') || trimmed.startsWith(r'$[')) {
    return trimmed;
  }

  final barePathPattern = RegExp(
    r'^[A-Za-z_][A-Za-z0-9_]*(?:\[[^\]]+\]|\.[A-Za-z_][A-Za-z0-9_]*)*$',
  );
  if (barePathPattern.hasMatch(trimmed)) {
    return '\$.$trimmed';
  }

  final indexedPathPattern = RegExp(
    r'^\[[^\]]+\](?:\[[^\]]+\]|\.[A-Za-z_][A-Za-z0-9_]*)*$',
  );
  if (indexedPathPattern.hasMatch(trimmed)) {
    return '\$$trimmed';
  }

  return null;
}
