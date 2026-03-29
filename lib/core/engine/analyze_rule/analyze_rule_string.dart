import 'analyze_rule_base.dart';
import 'analyze_rule_support.dart';
import 'analyze_rule_regex_helper.dart';
import '../parsers/analyze_by_regex.dart';
import '../parsers/analyze_by_css.dart';
import '../parsers/css/analyze_by_css_core.dart';

/// AnalyzeRule 的字串解析擴展
mixin AnalyzeRuleString on AnalyzeRuleBase, AnalyzeRuleRegexHelper {
  /// 獲取單個字串
  String getString(String ruleStr, {bool isUrl = false, bool unescape = true}) {
    if (ruleStr.isEmpty) {
      return '';
    }

    log('⇒ 執行 getString: $ruleStr');
    final ruleList = splitSourceRuleCacheString(ruleStr);
    var result = content;

    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) {
          break;
        }

        if (sourceRule.putMap.isNotEmpty) {
          sourceRule.putMap.forEach((key, valueRule) {
            final val = getString(valueRule);
            if (val.isNotEmpty) {
              put(key, val);
              log('  ◇ 保存變數: $key = $val');
            }
          });
        }

        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        log('  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule');

        dynamic tempResult;
        if (rule.isNotEmpty || sourceRule.replaceRegex.isEmpty) {
          switch (sourceRule.mode) {
            case Mode.js:
              tempResult = evalJS(rule, result);
              break;
            case Mode.json:
              tempResult = sourceRule.getAnalyzeByJSonPath(this, result).getString(rule);
              break;
            case Mode.xpath:
              tempResult = sourceRule.getAnalyzeByXPath(this, result).getString(rule);
              break;
            case Mode.regex:
              if (sourceRule.replaceRegex.isEmpty) {
                tempResult = rule;
              } else {
                tempResult = AnalyzeByRegex.getString(result.toString(), rule);
              }
              break;
            default:
              tempResult = sourceRule.getAnalyzeByJSoup(this, result).getString(rule);
          }
        }

        if (sourceRule.isDynamic && (tempResult == null || tempResult.toString().isEmpty)) {
          result = rule;
        } else {
          result = tempResult;
        }

        if (result != null && sourceRule.replaceRegex.isNotEmpty) {
          log('  ◇ 正則替換: ${sourceRule.replaceRegex}');
          result = replaceRegexLogic(result.toString(), sourceRule);
        }

        final preview = result?.toString() ?? 'null';
        log('  └ 字串預覽: ${preview.length > 500 ? preview.substring(0, 500) : preview}');
      }
    }

    var str = result?.toString() ?? '';
    if (unescape && str.contains('&')) {
      str = AnalyzeRuleBase.htmlUnescape.convert(str);
    }
    if (isUrl && str.isEmpty) {
      return baseUrl ?? '';
    }
    return str;
  }

  /// 獲取字串列表
  List<String> getStringList(String ruleStr, {bool isUrl = false}) {
    if (ruleStr.isEmpty) {
      return [];
    }
    log('⇒ 執行 getStringList: $ruleStr');

    final ruleList = splitSourceRuleCacheString(ruleStr);
    var result = content;

    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) {
          break;
        }

        if (sourceRule.putMap.isNotEmpty) {
          sourceRule.putMap.forEach((key, valueRule) {
            final val = getString(valueRule);
            if (val.isNotEmpty) {
              put(key, val);
              log('  ◇ 保存變數: $key = $val');
            }
          });
        }

        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        log('  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule');

        switch (sourceRule.mode) {
          case Mode.js:
            result = evalJS(rule, result);
            break;
          case Mode.json:
            result = sourceRule.getAnalyzeByJSonPath(this, result).getStringList(rule);
            break;
          case Mode.xpath:
            result = sourceRule.getAnalyzeByXPath(this, result).getStringList(rule);
            break;
          case Mode.regex:
            result = [rule];
            break;
          default:
            result = sourceRule.getAnalyzeByJSoup(this, result).getStringList(rule);
        }

        if (sourceRule.replaceRegex.isNotEmpty) {
          log('  ◇ 正則替換列表: ${sourceRule.replaceRegex}');
          if (result is List) {
            result = result.map((e) => replaceRegexLogic(e.toString(), sourceRule)).toList();
          } else {
            result = replaceRegexLogic(result?.toString() ?? '', sourceRule);
          }
        }
      }
    }

    if (result is List) {
      return result.map((e) => e.toString()).toSet().toList();
    }
    if (result == null) {
      return [];
    }
    final str = result.toString();
    return str.split('\n').where((s) => s.isNotEmpty).toSet().toList();
  }
}
