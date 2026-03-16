import 'rule_analyzer_base.dart';
import 'rule_analyzer_match.dart';

/// RuleAnalyzer 的規則切分邏輯擴展
mixin RuleAnalyzerSplit on RuleAnalyzerBase, RuleAnalyzerMatch {
  List<String> splitRule(List<String> split) {
    ruleList = [];
    start = pos;
    startX = pos;

    if (split.length == 1) {
      elementsType = split[0];
      if (!consumeTo(elementsType)) {
        ruleList.add(queue.substring(startX));
        return ruleList;
      }
      step = elementsType.length;
      return _splitRuleRecursive();
    } else if (!consumeToAny(split)) {
      ruleList.add(queue.substring(startX));
      return ruleList;
    }

    final end = pos;
    pos = start;

    while (true) {
      final st = findToAny(['[', '(']);
      if (st == -1 || st > end) {
        ruleList = [queue.substring(startX, end)];
        elementsType = queue.substring(end, end + step);
        pos = end + step;
        
        while (consumeTo(elementsType)) {
          ruleList.add(queue.substring(start, pos));
          pos += step;
        }
        ruleList.add(queue.substring(pos));
        return ruleList;
      }

      pos = st;
      final next = queue[pos] == '[' ? ']' : ')';
      if (!chompBalanced(queue[pos], next)) {
        return [queue];
      }
      
      if (pos >= end) {
        start = pos;
        return splitRule(split);
      }
    }
  }

  List<String> _splitRuleRecursive() {
    final end = pos;
    pos = start;

    while (true) {
      final st = findToAny(['[', '(']);
      if (st == -1 || st > end) {
        ruleList.add(queue.substring(startX, end));
        pos = end + step;
        if (!consumeTo(elementsType)) {
          ruleList.add(queue.substring(pos));
          return ruleList;
        }
        return _splitRuleRecursive();
      }

      pos = st;
      final next = queue[pos] == '[' ? ']' : ')';
      if (!chompBalanced(queue[pos], next)) {
        return [queue];
      }

      if (pos >= end) {
        start = pos;
        if (!consumeTo(elementsType)) {
          ruleList.add(queue.substring(startX));
          return ruleList;
        }
        return _splitRuleRecursive();
      }
    }
  }
}

