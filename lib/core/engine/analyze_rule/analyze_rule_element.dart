import 'analyze_rule_base.dart';
import 'analyze_rule_support.dart';
import 'analyze_rule_regex_helper.dart';
import '../parsers/analyze_by_regex.dart';
import '../parsers/analyze_by_css.dart';
import '../parsers/css/analyze_by_css_core.dart';

/// AnalyzeRule 的元素解析擴展
mixin AnalyzeRuleElement on AnalyzeRuleBase, AnalyzeRuleRegexHelper {
  String getString(String ruleStr, {bool isUrl = false, bool unescape = true});

  /// 獲取單個元素
  dynamic getElement(String ruleStr) {
    if (ruleStr.isEmpty) {
      return null;
    }

    log('⇒ 執行 getElement: $ruleStr');
    var result = content;
    final ruleList = splitSourceRuleCacheString(ruleStr);

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

        final rule = sourceRule.makeUpRule(result, this);
        log('  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule');

        dynamic tempResult;
        switch (sourceRule.mode) {
          case Mode.regex:
            final elements = AnalyzeByRegex.getElement(
              result.toString(),
              rule.split('&&').where((s) => s.isNotEmpty).toList(),
            );
            tempResult = elements?.join('');
            break;
          case Mode.json:
            tempResult = sourceRule.getAnalyzeByJSonPath(this, result).getObject(rule);
            break;
          case Mode.xpath:
            final elements = sourceRule.getAnalyzeByXPath(this, result).getElements(rule);
            tempResult = elements.isNotEmpty ? elements.first : null;
            break;
          case Mode.js:
            tempResult = evalJS(rule, result);
            break;
          default:
            final elements = sourceRule.getAnalyzeByJSoup(this, result).getElements(rule);
            tempResult = elements.isNotEmpty ? elements.first : null;
        }

        if (sourceRule.isDynamic && (tempResult == null || tempResult.toString().isEmpty)) {
          result = rule;
        } else {
          result = tempResult;
        }

        if (result != null && sourceRule.replaceRegex.isNotEmpty) {
          log('  ◇ 正則替換: ${sourceRule.replaceRegex} -> ${sourceRule.replacement}');
          result = replaceRegexLogic(result.toString(), sourceRule);
        }

        final preview = result?.toString() ?? 'null';
        log('  └ 結果類型: ${result?.runtimeType}, 預覽: ${preview.length > 500 ? preview.substring(0, 500) : preview}');
      }
    }
    return result;
  }

  /// 獲取列表
  List<dynamic> getElements(String ruleStr) {
    if (ruleStr.isEmpty) {
      return [];
    }

    log('⇒ 執行 getElements: $ruleStr');
    var result = content;
    final ruleList = splitSourceRuleCacheString(ruleStr);

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

        final rule = sourceRule.makeUpRule(result, this);
        log('  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule');

        dynamic tempResult;
        switch (sourceRule.mode) {
          case Mode.regex:
            tempResult = AnalyzeByRegex.getElements(
              result.toString(),
              rule.split('&&').where((s) => s.isNotEmpty).toList(),
            );
            break;
          case Mode.json:
            tempResult = sourceRule.getAnalyzeByJSonPath(this, result).getElements(rule);
            break;
          case Mode.xpath:
            tempResult = sourceRule.getAnalyzeByXPath(this, result).getElements(rule);
            break;
          case Mode.js:
            tempResult = evalJS(rule, result);
            break;
          default:
            tempResult = sourceRule.getAnalyzeByJSoup(this, result).getElements(rule);
        }

        if (sourceRule.isDynamic &&
            (tempResult == null ||
                (tempResult is List && tempResult.isEmpty) ||
                (tempResult is String && tempResult.isEmpty))) {
          result = rule;
        } else {
          result = tempResult;
        }

        if (result != null && sourceRule.replaceRegex.isNotEmpty) {
          log('  ◇ 正則替換列表元素: ${sourceRule.replaceRegex}');
          if (result is List) {
            result = result.map((e) => replaceRegexLogic(e.toString(), sourceRule)).toList();
          } else {
            result = replaceRegexLogic(result.toString(), sourceRule);
          }
        }
        log('  └ 列表長度: ${result is List ? result.length : (result == null ? 0 : 1)}');
      }
    }

    if (result is List) {
      return result;
    }
    if (result == null) {
      return [];
    }
    return [result];
  }
}
