import 'package:html/dom.dart';

List<Element> querySelectorAllCompat(Element root, String selector) {
  final normalizedSelector = normalizeCssSelectorCompat(selector);
  try {
    return root.querySelectorAll(normalizedSelector);
  } on UnimplementedError {
    return _querySelectorAllUnsupportedCompat(root, normalizedSelector);
  } catch (_) {
    if (normalizedSelector.contains(':contains(') ||
        normalizedSelector.contains(':containsOwn(')) {
      return _querySelectorAllUnsupportedCompat(root, normalizedSelector);
    }
    return [];
  }
}

bool matchesSelectorWithinParentCompat(Element temp, String selector) {
  final parent = temp.parent;
  if (parent == null) return false;
  try {
    return querySelectorAllCompat(parent, selector).contains(temp);
  } catch (_) {
    return false;
  }
}

List<Element> _querySelectorAllUnsupportedCompat(
  Element root,
  String selector,
) {
  if (!selector.contains(':contains(') && !selector.contains(':containsOwn(')) {
    return [];
  }

  final containsPattern = RegExp(r':contains\(([^)]*)\)');
  final containsOwnPattern = RegExp(r':containsOwn\(([^)]*)\)');
  final containsValues =
      containsPattern
          .allMatches(selector)
          .map((match) => _normalizeContainsNeedle(match.group(1) ?? ''))
          .where((value) => value.isNotEmpty)
          .toList();
  final containsOwnValues =
      containsOwnPattern
          .allMatches(selector)
          .map((match) => _normalizeContainsNeedle(match.group(1) ?? ''))
          .where((value) => value.isNotEmpty)
          .toList();

  final baseSelector =
      selector
          .replaceAll(containsPattern, '')
          .replaceAll(containsOwnPattern, '')
          .trim();

  final candidates =
      baseSelector.isEmpty || baseSelector == '*'
          ? root.querySelectorAll('*')
          : root.querySelectorAll(baseSelector);

  return candidates.where((element) {
    final text = element.text;
    final ownText =
        element.nodes
            .where((node) => node.nodeType == Node.TEXT_NODE)
            .map((node) => node.text ?? '')
            .join();
    final containsOk = containsValues.every(text.contains);
    final containsOwnOk = containsOwnValues.every(ownText.contains);
    return containsOk && containsOwnOk;
  }).toList();
}

String normalizeCssSelectorCompat(String selector) {
  return selector.replaceAllMapped(RegExp(r'\[([^\]=~\^\$\*\|]+)=([^\]]+)\]'), (
    match,
  ) {
    final attr = match.group(1)!.trim();
    final value = match.group(2)!.trim();
    if (value.startsWith('"') || value.startsWith("'")) {
      return match.group(0)!;
    }
    return '[$attr="$value"]';
  });
}

String _normalizeContainsNeedle(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 2 &&
      ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
          (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  return trimmed;
}

class SourceRule {
  bool isCss = false;
  late String elementsRule;

  SourceRule(String ruleStr) {
    if (ruleStr.toUpperCase().startsWith('@CSS:')) {
      isCss = true;
      elementsRule = ruleStr.substring(5).trim();
    } else {
      elementsRule = ruleStr;
    }
  }
}

class ElementsSingle {
  String split = '.';
  String beforeRule = '';
  final List<int> indexDefault = [];
  final List<dynamic> indexes = [];

  List<Element> getElementsSingle(Element temp, String rule) {
    split = '.';
    beforeRule = '';
    indexDefault.clear();
    indexes.clear();
    findIndexSet(rule);

    List<Element> elements;
    if (beforeRule.isEmpty) {
      elements = temp.children;
    } else {
      final rules = beforeRule.split('.');
      if (rules[0] == ':root' || rules[0] == 'root') {
        elements = [temp];
      } else if (rules[0] == 'children') {
        elements = temp.children;
      } else if (rules[0] == 'class' && rules.length > 1) {
        final selector = '.${rules.sublist(1).join('.')}';
        elements = _withSelfIf(
          temp,
          descendants:
              selector.contains(':') || selector.contains('[')
                  ? querySelectorAllCompat(temp, selector)
                  : temp.getElementsByClassName(rules[1]),
          selfMatches:
              selector.contains(':') || selector.contains('[')
                  ? matchesSelectorWithinParentCompat(temp, selector)
                  : temp.classes.contains(rules[1]),
        );
      } else if (rules[0] == 'tag' && rules.length > 1) {
        final selector = rules.sublist(1).join('.');
        elements = _withSelfIf(
          temp,
          descendants:
              selector.contains(':') || selector.contains('[')
                  ? querySelectorAllCompat(temp, selector)
                  : temp.getElementsByTagName(rules[1]),
          selfMatches:
              selector.contains(':') || selector.contains('[')
                  ? matchesSelectorWithinParentCompat(temp, selector)
                  : temp.localName == rules[1],
        );
      } else if (rules[0] == 'id' && rules.length > 1) {
        final el = temp.querySelector('#${rules[1]}');
        elements = temp.id == rules[1] ? [temp] : (el != null ? [el] : []);
      } else if (rules[0] == 'text' && rules.length > 1) {
        final descendants =
            temp.querySelectorAll('*').where((el) {
              return el.nodes.any(
                (n) =>
                    n.nodeType == Node.TEXT_NODE && n.text!.contains(rules[1]),
              );
            }).toList();
        final selfMatches = temp.nodes.any(
          (n) =>
              n.nodeType == Node.TEXT_NODE && (n.text ?? '').contains(rules[1]),
        );
        elements = _withSelfIf(
          temp,
          descendants: descendants,
          selfMatches: selfMatches,
        );
      } else {
        try {
          elements = _withSelfIf(
            temp,
            descendants: querySelectorAllCompat(temp, beforeRule),
            selfMatches: matchesSelectorWithinParentCompat(temp, beforeRule),
          );
        } catch (e) {
          elements = [];
        }
      }
    }

    final len = elements.length;
    if (len == 0) return [];

    final lastIndexes =
        indexDefault.isNotEmpty ? indexDefault.length - 1 : indexes.length - 1;
    final indexSet = <int>{};

    if (indexes.isEmpty) {
      for (var i = lastIndexes; i >= 0; i--) {
        final it = indexDefault[i];
        if (it >= 0 && it < len) {
          indexSet.add(it);
        } else if (it < 0 && len >= -it) {
          indexSet.add(it + len);
        }
      }
    } else {
      for (var i = lastIndexes; i >= 0; i--) {
        final idx = indexes[i];
        if (idx is Triple) {
          var start = idx.first ?? 0;
          if (start < 0) start += len;
          var end = idx.second ?? (len - 1);
          if (end < 0) end += len;

          if ((start < 0 && end < 0) || (start >= len && end >= len)) continue;

          start = start.clamp(0, len - 1);
          end = end.clamp(0, len - 1);

          var step = idx.third;
          if (step == 0) step = 1;
          if (step < 0 && -step < len) step += len;
          if (step <= 0) step = 1;

          if (start <= end) {
            for (var j = start; j <= end; j += step) {
              indexSet.add(j);
            }
          } else {
            for (var j = start; j >= end; j -= step) {
              indexSet.add(j);
            }
          }
        } else if (idx is int) {
          final it = idx;
          if (it >= 0 && it < len) {
            indexSet.add(it);
          } else if (it < 0 && len >= -it) {
            indexSet.add(it + len);
          }
        }
      }
    }

    if (split == '!') {
      final result = <Element>[];
      for (var i = 0; i < len; i++) {
        if (!indexSet.contains(i)) {
          result.add(elements[i]);
        }
      }
      return result;
    } else if (split == '.') {
      final result = <Element>[];
      for (final idx in indexSet) {
        result.add(elements[idx]);
      }
      return result;
    } else {
      return elements;
    }
  }

  List<Element> _withSelfIf(
    Element temp, {
    required Iterable<Element> descendants,
    required bool selfMatches,
  }) {
    final results = <Element>[];
    if (selfMatches) {
      results.add(temp);
    }
    results.addAll(descendants);
    return results;
  }

  void findIndexSet(String rule) {
    final rus = rule.trim();
    final bracketMatch = RegExp(r'^(.*)\[(!?)([-\d:,\s]+)\]$').firstMatch(rus);
    if (bracketMatch != null) {
      beforeRule = bracketMatch.group(1)!.trim();
      split = bracketMatch.group(2) == '!' ? '!' : '.';
      final segments = bracketMatch.group(3)!.split(',');
      for (final rawSegment in segments) {
        final segment = rawSegment.trim();
        if (segment.isEmpty) {
          continue;
        }
        if (segment.contains(':')) {
          final parts = segment.split(':').map((e) => e.trim()).toList();
          int? parsePart(int index) =>
              index < parts.length && parts[index].isNotEmpty
                  ? int.tryParse(parts[index])
                  : null;
          indexes.add(
            Triple(
              parsePart(0),
              parsePart(1),
              parts.length > 2 ? (parsePart(2) ?? 1) : 1,
            ),
          );
        } else {
          final value = int.tryParse(segment);
          if (value != null) {
            indexes.add(value);
          }
        }
      }
      return;
    }

    var len = rus.length;
    var curMinus = false;
    final curList = <int?>[];
    var l = '';

    var head = rus.endsWith(']');

    if (head) {
      len--;
      while (len >= 0) {
        final rl = rus[len];
        if (rl == ' ' || rl == ']') {
          len--;
          continue;
        }

        if (_isDigit(rl)) {
          l = rl + l;
        } else if (rl == '-') {
          curMinus = true;
        } else {
          final curInt = l.isEmpty ? null : int.tryParse(curMinus ? '-$l' : l);
          if (rl == ':') {
            curList.add(curInt);
          } else {
            if (curList.isEmpty) {
              if (curInt == null && rl != '[') break;
              if (curInt != null) indexes.add(curInt);
            } else {
              indexes.add(
                Triple(
                  curInt,
                  curList.last,
                  curList.length == 2 ? (curList.first ?? 1) : 1,
                ),
              );
              curList.clear();
            }

            if (rl == '!') {
              split = '!';
              while (len > 0 && rus[len - 1] == ' ') {
                len--;
              }
            }

            if (rl == '[') {
              beforeRule = rus.substring(0, len);
              return;
            }

            if (rl != ',') break;
          }
          l = '';
          curMinus = false;
          head = false; // reset head if rule is complex
        }
        len--;
      }
    } else {
      while (len > 0) {
        len--;
        final rl = rus[len];
        if (rl == ' ') continue;

        if (_isDigit(rl)) {
          l = rl + l;
        } else if (rl == '-') {
          curMinus = true;
        } else {
          if (rl == '!' || rl == '.' || rl == ':') {
            final val = int.tryParse(curMinus ? '-$l' : l);
            if (val == null) {
              len++;
              break;
            }
            indexDefault.add(val);
            if (rl != ':') {
              split = rl;
              beforeRule = rus.substring(0, len);
              return;
            }
          } else {
            break;
          }
          l = '';
          curMinus = false;
        }
      }
    }
    split = ' ';
    beforeRule = rus;
  }

  bool _isDigit(String s) => RegExp(r'^\d$').hasMatch(s);
}

class Triple {
  final int? first;
  final int? second;
  final int third;
  Triple(this.first, this.second, this.third);
}
