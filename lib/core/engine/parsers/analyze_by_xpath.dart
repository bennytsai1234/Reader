import 'package:html/dom.dart';
import 'package:xpath_selector/xpath_selector.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:legado_reader/core/engine/rule_analyzer.dart';

/// AnalyzeByXPath - XPath 解析器
/// (原 Android model/analyzeRule/AnalyzeByXPath.kt) (5KB)
///
/// 使用 Dart `xpath_selector` + `xpath_selector_html_parser` 套件
class AnalyzeByXPath {
  late HtmlXPath _xpath;

  AnalyzeByXPath(dynamic doc) {
    if (doc is Element) {
      _xpath = HtmlXPath.node(doc);
    } else if (doc is String) {
      _xpath = HtmlXPath.html(_prepareHtml(doc));
    } else {
      _xpath = HtmlXPath.html(_prepareHtml(doc.toString()));
    }
  }

  /// (原 Android 的) strToJXDocument，處理表格標籤補全
  String _prepareHtml(String html) {
    var h = html.trim();
    if (h.endsWith('</td>')) {
      h = '<tr>$h</tr>';
    }
    if (h.endsWith('</tr>') || h.endsWith('</tbody>')) {
      h = '<table>$h</table>';
    }
    return h;
  }

  /// 獲取列表
  List<XPathNode> getElements(String xPathRule) {
    if (xPathRule.isEmpty) return [];

    final ruleAnalyzes = RuleAnalyzer(xPathRule);
    final rules = ruleAnalyzes.splitRule(['&&', '||', '%%']);

    if (rules.length == 1) {
      return _xpath.query(rules[0].trim()).nodes;
    } else {
      final results = <List<XPathNode>>[];
      for (final rl in rules) {
        final temp = getElements(rl.trim());
        if (temp.isNotEmpty) {
          results.add(temp);
          if (ruleAnalyzes.elementsType == '||') break;
        }
      }

      if (results.isEmpty) return [];

      final result = <XPathNode>[];
      if (ruleAnalyzes.elementsType == '%%') {
        final firstListSize = results[0].length;
        for (var i = 0; i < firstListSize; i++) {
          for (final temp in results) {
            if (i < temp.length) {
              result.add(temp[i]);
            }
          }
        }
      } else {
        for (final temp in results) {
          result.addAll(temp);
        }
      }
      return result;
    }
  }

  /// 獲取所有內容列表 (對標 Android AnalyzeByXPath.getStringList)
  List<String> getStringList(String xPathRule) {
    if (xPathRule.isEmpty) return [];

    final ruleAnalyzes = RuleAnalyzer(xPathRule);
    final rules = ruleAnalyzes.splitRule(['&&', '||', '%%']);

    if (rules.length == 1) {
      final String rule = rules[0].trim();
      final queryResult = _xpath.query(rule);
      
      // 1. 處理屬性提取 /@attr 或 /attr()
      if (rule.contains('/@')) {
        return queryResult.attrs.whereType<String>().toList();
      }
      
      // 2. 處理文本提取 /text()
      if (rule.endsWith('/text()')) {
        return queryResult.nodes
            .map((n) => n.text?.trim() ?? '')
            .where((t) => t.isNotEmpty)
            .toList();
      }

      // 3. 預設返回節點的 outerHtml 或 text (對標 Android asString)
      return queryResult.nodes.map((n) {
        // 如果節點是純文本節點，返回 text；否則返回 outerHtml
        return n.text?.trim() ?? '';
      }).where((t) => t.isNotEmpty).toList();
    } else {
      final results = <List<String>>[];
      for (final rl in rules) {
        final temp = getStringList(rl.trim());
        if (temp.isNotEmpty) {
          results.add(temp);
          if (ruleAnalyzes.elementsType == '||') break;
        }
      }

      if (results.isEmpty) return [];

      final result = <String>[];
      if (ruleAnalyzes.elementsType == '%%') {
        final firstListSize = results[0].length;
        for (var i = 0; i < firstListSize; i++) {
          for (final temp in results) {
            if (i < temp.length) {
              result.add(temp[i]);
            }
          }
        }
      } else {
        for (final temp in results) {
          result.addAll(temp);
        }
      }
      return result;
    }
  }

  /// 獲取合併字串
  String? getString(String rule) {
    if (rule.isEmpty) return null;

    final ruleAnalyzes = RuleAnalyzer(rule);
    final rules = ruleAnalyzes.splitRule(['&&', '||']);

    if (rules.length == 1) {
      final list = getStringList(rules[0].trim());
      if (list.isEmpty) return null;
      return list.join('\n');
    } else {
      final textList = <String>[];
      for (final rl in rules) {
        final temp = getString(rl.trim());
        if (temp != null && temp.isNotEmpty) {
          textList.add(temp);
          if (ruleAnalyzes.elementsType == '||') break;
        }
      }
      return textList.isEmpty ? null : textList.join('\n');
    }
  }
}

