import 'dart:convert';
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
    final evalPattern = RegExp(r'@get:\{[^}]+?\}|\{\{[\w\W]*?\}\}|\{\$.*?\}', caseSensitive: false);
    var start = 0;
    final evalMatches = evalPattern.allMatches(rule);
    if (evalMatches.isNotEmpty) isDynamic = true;
    for (final match in evalMatches) {
      if (match.start > start) _splitRegex(rule.substring(start, match.start));
      final tmp = match.group(0)!;
      if (tmp.toLowerCase().startsWith('@get:')) { ruleType.add(getRuleType); ruleParam.add(tmp.substring(6, tmp.length - 1)); }
      else if (tmp.startsWith('{{')) { ruleType.add(jsRuleType); ruleParam.add(tmp.substring(2, tmp.length - 2)); }
      else if (tmp.startsWith('{\$')) { ruleType.add(jsonPartRuleType); ruleParam.add(tmp.substring(1, tmp.length - 1)); }
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

  void makeUpRule(dynamic result, dynamic analyzer) {
    if (!isDynamic) return;
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
          buffer.write(analyzer.evalJS(param, result));
        }
      } else if (type == getRuleType) {
        buffer.write(analyzer.get(param));
      } else if (type == jsonPartRuleType) {
        final val = getAnalyzeByJSonPath(analyzer, result).getString(param);
        buffer.write(val);
      } else {
        // Handle regex groups ($1, $2, etc.)
        if (result is List<String> && type < result.length) {
          buffer.write(result[type]);
        } else if (result is String) {
          // If result is string, we might need the groups from AnalyzeByRegex.getElement
          // For now, write the param as is if not a list
          buffer.write(param);
        }
      }
    }
    rule = buffer.toString();
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
