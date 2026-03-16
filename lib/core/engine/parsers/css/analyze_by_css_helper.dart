import 'package:html/dom.dart';
import 'analyze_by_css_base.dart';
import 'analyze_by_css_support.dart';

/// AnalyzeByCss 的私有輔助邏輯擴展
extension AnalyzeByCssHelper on AnalyzeByCssBase {
  List<Element> getElementsSingle(Element temp, String rule) {
    final single = ElementsSingle();
    return single.getElementsSingle(temp, rule);
  }

  List<String> getResultLast(List<Element> elements, String lastRule) {
    final textS = <String>[];
    String attrName = lastRule;
    if (lastRule.startsWith('attr.')) {
      attrName = lastRule.substring(5);
    }

    switch (lastRule) {
      case 'text':
        for (final el in elements) {
          final t = el.text.trim();
          if (t.isNotEmpty) textS.add(t);
        }
        break;
      case 'textNodes':
        for (final el in elements) {
          final nodes = el.nodes
              .where((n) => n.nodeType == Node.TEXT_NODE)
              .map((n) => n.text?.trim() ?? '')
              .where((t) => t.isNotEmpty);
          textS.addAll(nodes);
        }
        break;
      case 'ownText':
        for (final el in elements) {
          final t = el.nodes
              .where((n) => n.nodeType == Node.TEXT_NODE)
              .map((n) => n.text?.trim() ?? '')
              .where((t) => t.isNotEmpty)
              .join(' ');
          if (t.isNotEmpty) textS.add(t);
        }
        break;
      case 'html':
      case 'outerHtml':
        for (final el in elements) {
          // Android 原版在獲取正文 html 時通常不會過濾 script，除非規則有寫
          // 但為了安全，我們可以保持基礎實作
          textS.add(el.outerHtml);
        }
        break;
      case 'innerHtml':
        for (final el in elements) {
          textS.add(el.innerHtml);
        }
        break;
      case 'all':
        for (final el in elements) {
          textS.add(el.outerHtml);
        }
        break;
      default:
        for (final el in elements) {
          final attr = el.attributes[attrName]?.trim();
          if (attr != null && attr.isNotEmpty) {
            textS.add(attr);
          }
        }
    }
    return textS;
  }
}

