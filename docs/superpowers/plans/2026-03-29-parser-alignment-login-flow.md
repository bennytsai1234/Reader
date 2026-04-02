# Parser Alignment & Login Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Align Dart parsers with Legado 3.0 Android reference implementation and complete the login flow.

**Architecture:** Fix critical behavioral differences in CSS/XPath/JsonPath parsers, AnalyzeRule orchestration, and JS bridge; then implement the missing login flow building on existing UI scaffolding.

**Tech Stack:** Dart/Flutter, xpath_selector, html package, flutter_js, webview_flutter, Drift (SQLite)

---

## File Map

### Task Group A: CSS Parser Fixes
- Modify: `lib/core/engine/parsers/css/analyze_by_css_support.dart` (exclusion bug)
- Modify: `lib/core/engine/parsers/css/analyze_by_css_helper.dart` (html stripping, textNodes join)
- Test: `test/core/engine/parsers/css/analyze_by_css_test.dart`

### Task Group B: AnalyzeRule / SourceRule Critical Fixes
- Modify: `lib/core/engine/analyze_rule/analyze_rule_support.dart` (mode detection, replaceFirst, ## timing)
- Modify: `lib/core/engine/analyze_rule/analyze_rule_string.dart` (@put timing)
- Modify: `lib/core/engine/analyze_rule/analyze_rule_element.dart` (@put in getElement/getElements)
- Modify: `lib/core/engine/analyze_rule/analyze_rule_base.dart` (special keys)
- Test: `test/core/engine/analyze_rule/analyze_rule_test.dart`

### Task Group C: XPath Custom Functions
- Modify: `lib/core/engine/parsers/analyze_by_xpath.dart` (allText, textNodes, ownText, html, outerHtml, XML detection)
- Test: `test/core/engine/parsers/analyze_by_xpath_test.dart`

### Task Group D: JsExtensions Bridge Fixes
- Modify: `lib/core/engine/js/extensions/js_java_object.dart` (wire missing methods)
- Modify: `lib/core/engine/js/js_extensions.dart` (register missing handlers)
- Test: `test/core/engine/js/js_extensions_test.dart`

### Task Group E: Login Flow
- Modify: `lib/core/models/base_source.dart` (add login methods)
- Modify: `lib/core/models/source/book_source_base.dart` (implement login methods)
- Modify: `lib/features/source_manager/source_login_page.dart` (wire form + WebView)
- Modify: `lib/core/engine/js/extensions/js_java_object.dart` (source bindings)
- Test: `test/features/source_manager/source_login_test.dart`

---

## Task 1: Fix CSS Exclusion Bug (`!` split)

**Files:**
- Modify: `lib/core/engine/parsers/css/analyze_by_css_support.dart:112-121`
- Test: `test/core/engine/parsers/css/analyze_by_css_test.dart`

The `ElementsSingle` class treats `!` (exclude) identically to `.` (select). In Legado, `!` means "remove these indices from the full list, return everything else."

- [x] **Step 1: Write failing test**

```dart
// test/core/engine/parsers/css/analyze_by_css_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:legado_reader/core/engine/parsers/css/analyze_by_css_support.dart';

void main() {
  group('ElementsSingle exclusion mode', () {
    test('! split excludes specified indices', () {
      final doc = html_parser.parse('<div><p>A</p><p>B</p><p>C</p><p>D</p></div>');
      final container = doc.querySelector('div')!;
      final single = ElementsSingle();
      // p!0 means "all <p> except index 0"
      final result = single.getElementsSingle(container, 'tag.p!0');
      expect(result.length, 3);
      expect(result.map((e) => e.text).toList(), ['B', 'C', 'D']);
    });

    test('. split selects specified indices', () {
      final doc = html_parser.parse('<div><p>A</p><p>B</p><p>C</p><p>D</p></div>');
      final container = doc.querySelector('div')!;
      final single = ElementsSingle();
      // p.0 means "only <p> at index 0"
      final result = single.getElementsSingle(container, 'tag.p.0');
      expect(result.length, 1);
      expect(result[0].text, 'A');
    });

    test('bracket exclusion [!0,2] excludes indices 0 and 2', () {
      final doc = html_parser.parse('<div><p>A</p><p>B</p><p>C</p><p>D</p></div>');
      final container = doc.querySelector('div')!;
      final single = ElementsSingle();
      final result = single.getElementsSingle(container, 'tag.p[!0,2]');
      expect(result.length, 2);
      expect(result.map((e) => e.text).toList(), ['B', 'D']);
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/parsers/css/analyze_by_css_test.dart -v`
Expected: FAIL - exclusion returns selected elements instead of excluded

- [x] **Step 3: Fix exclusion logic in ElementsSingle**

In `lib/core/engine/parsers/css/analyze_by_css_support.dart`, replace lines 112-121:

```dart
    if (split == '!') {
      // Exclusion mode: return all elements EXCEPT those in indexSet
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
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/parsers/css/analyze_by_css_test.dart -v`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add lib/core/engine/parsers/css/analyze_by_css_support.dart test/core/engine/parsers/css/analyze_by_css_test.dart
git commit -m "fix(css): fix exclusion mode (!) returning selected instead of excluded elements"
```

---

## Task 2: Fix CSS `html` Keyword to Strip `<script>` and `<style>`

**Files:**
- Modify: `lib/core/engine/parsers/css/analyze_by_css_helper.dart:45-51`
- Test: `test/core/engine/parsers/css/analyze_by_css_test.dart`

Legado strips `<script>` and `<style>` tags when returning `html`. The Dart version returns them as-is.

- [x] **Step 1: Add failing test**

```dart
  group('getResultLast html keyword', () {
    test('html strips script and style tags', () {
      final doc = html_parser.parse(
        '<div><p>Hello</p><script>alert(1)</script><style>.x{}</style><span>World</span></div>'
      );
      final elements = doc.querySelectorAll('div');
      final helper = AnalyzeByCssBase();
      helper.setContent(doc.documentElement!.outerHtml);
      // Use the helper extension method
      final result = helper.getResultLast(elements.toList(), 'html');
      expect(result.length, 1);
      expect(result[0].contains('<script>'), false);
      expect(result[0].contains('<style>'), false);
      expect(result[0].contains('Hello'), true);
      expect(result[0].contains('World'), true);
    });
  });
```

(Import `analyze_by_css_base.dart` and `analyze_by_css_helper.dart` at the top.)

- [x] **Step 2: Run test to verify it fails**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/parsers/css/analyze_by_css_test.dart -v`
Expected: FAIL - html output contains `<script>` and `<style>`

- [x] **Step 3: Fix html case to strip script/style**

In `lib/core/engine/parsers/css/analyze_by_css_helper.dart`, replace the `html` / `outerHtml` case (lines 45-51):

```dart
      case 'html':
      case 'outerHtml':
        for (final el in elements) {
          // Clone element to avoid modifying the DOM tree
          final clone = el.clone(true);
          clone.querySelectorAll('script').forEach((s) => s.remove());
          clone.querySelectorAll('style').forEach((s) => s.remove());
          textS.add(clone.outerHtml);
        }
        break;
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/parsers/css/analyze_by_css_test.dart -v`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add lib/core/engine/parsers/css/analyze_by_css_helper.dart test/core/engine/parsers/css/analyze_by_css_test.dart
git commit -m "fix(css): strip script/style tags from html keyword output to match Legado"
```

---

## Task 3: Fix CSS `textNodes` to Join Per-Element with `\n`

**Files:**
- Modify: `lib/core/engine/parsers/css/analyze_by_css_helper.dart:26-33`
- Test: `test/core/engine/parsers/css/analyze_by_css_test.dart`

Legado joins all textNodes of each element into one `\n`-separated string. Dart adds each node separately.

- [x] **Step 1: Add failing test**

```dart
    test('textNodes joins per-element text nodes with newline', () {
      final doc = html_parser.parse(
        '<div>First<br>Second<span>Skip</span>Third</div>'
      );
      final elements = doc.querySelectorAll('div');
      final helper = AnalyzeByCssBase();
      helper.setContent(doc.documentElement!.outerHtml);
      final result = helper.getResultLast(elements.toList(), 'textNodes');
      // Legado: one entry per element, text nodes joined by \n
      expect(result.length, 1);
      expect(result[0], 'First\nSecond\nThird');
    });
```

- [x] **Step 2: Run test to verify it fails**

Expected: FAIL - returns 3 separate entries instead of 1 joined entry

- [x] **Step 3: Fix textNodes to join per element**

In `lib/core/engine/parsers/css/analyze_by_css_helper.dart`, replace the `textNodes` case (lines 26-33):

```dart
      case 'textNodes':
        for (final el in elements) {
          final joined = el.nodes
              .where((n) => n.nodeType == Node.TEXT_NODE)
              .map((n) => n.text?.trim() ?? '')
              .where((t) => t.isNotEmpty)
              .join('\n');
          if (joined.isNotEmpty) textS.add(joined);
        }
        break;
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/parsers/css/analyze_by_css_test.dart -v`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add lib/core/engine/parsers/css/analyze_by_css_helper.dart test/core/engine/parsers/css/analyze_by_css_test.dart
git commit -m "fix(css): join textNodes per-element with newline to match Legado behavior"
```

---

## Task 4: Fix SourceRule Mode Detection (`@CSS:`, `@@`, Case-Insensitive)

**Files:**
- Modify: `lib/core/engine/analyze_rule/analyze_rule_support.dart:27-55`
- Test: `test/core/engine/analyze_rule/analyze_rule_test.dart`

Missing: `@CSS:` mode detection, `@@` prefix handling, case-insensitive prefix matching.

- [x] **Step 1: Write failing test**

```dart
// test/core/engine/analyze_rule/analyze_rule_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/analyze_rule/analyze_rule_support.dart';

void main() {
  group('SourceRule mode detection', () {
    test('@CSS: prefix sets default mode and keeps full string', () {
      final rule = SourceRule('@CSS:div.class > a');
      expect(rule.mode, Mode.defaultMode);
      expect(rule.rule, '@CSS:div.class > a');
    });

    test('@css: prefix is case-insensitive', () {
      final rule = SourceRule('@css:div.class');
      expect(rule.mode, Mode.defaultMode);
      expect(rule.rule, '@css:div.class');
    });

    test('@@ prefix forces default mode and strips prefix', () {
      final rule = SourceRule('@@div.class > a@href');
      expect(rule.mode, Mode.defaultMode);
      expect(rule.rule, 'div.class > a@href');
    });

    test('@Json: is case-insensitive', () {
      final rule = SourceRule('@json:\$.data');
      expect(rule.mode, Mode.json);
    });

    test('@XPath: is case-insensitive', () {
      final rule = SourceRule('@xpath://div');
      expect(rule.mode, Mode.xpath);
    });

    test('replaceFirst flag set when rule has ###', () {
      final rule = SourceRule('div.text##\\d+##NUM###');
      expect(rule.replaceFirst, true);
      expect(rule.replaceRegex, '\\d+');
      expect(rule.replacement, 'NUM');
    });

    test('replaceFirst false for normal ##', () {
      final rule = SourceRule('div.text##\\d+##NUM');
      expect(rule.replaceFirst, false);
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/analyze_rule/analyze_rule_test.dart -v`
Expected: FAIL - @CSS: not recognized, @@ not handled, replaceFirst never true

- [x] **Step 3: Fix SourceRule constructor**

Replace the SourceRule constructor in `lib/core/engine/analyze_rule/analyze_rule_support.dart` (lines 27-55) with:

```dart
  SourceRule(this.rule, {this.mode = Mode.defaultMode}) {
    // Handle ## regex replacement - must happen at parse time for the rule portion,
    // but the actual splitting needs to respect ### for replaceFirst
    if (rule.contains('##')) {
      final parts = rule.split('##');
      if (rule.startsWith('##')) {
        mode = Mode.regex;
        rule = '';
        if (parts.length > 1) replaceRegex = parts[1];
        if (parts.length > 2) replacement = parts[2];
        if (parts.length > 3) replaceFirst = true;
      } else {
        rule = parts[0];
        if (parts.length > 1) replaceRegex = parts[1];
        if (parts.length > 2) replacement = parts[2];
        if (parts.length > 3) replaceFirst = true;
      }
    }

    if (mode == Mode.defaultMode) {
      final ruleUpper = rule.toUpperCase();
      if (ruleUpper.startsWith('@CSS:')) {
        // @CSS: keeps the full string including prefix (parsed by CSS parser)
        mode = Mode.defaultMode;
      } else if (rule.startsWith('@@')) {
        // @@ forces default mode, strip prefix
        mode = Mode.defaultMode;
        rule = rule.substring(2);
      } else if (ruleUpper.startsWith('@JSON:')) {
        mode = Mode.json;
        rule = rule.substring(6);
      } else if (ruleUpper.startsWith('@XPATH:')) {
        mode = Mode.xpath;
        rule = rule.substring(7);
      } else if (rule.startsWith('/')) {
        mode = Mode.xpath;
      } else if (rule.startsWith(r'$.') || rule.startsWith(r'$[')) {
        mode = Mode.json;
      }
    }
```

(The rest of the constructor after mode detection stays the same - @put, evalPattern, _splitRegex.)

- [x] **Step 4: Run test to verify it passes**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/analyze_rule/analyze_rule_test.dart -v`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add lib/core/engine/analyze_rule/analyze_rule_support.dart test/core/engine/analyze_rule/analyze_rule_test.dart
git commit -m "fix(analyze_rule): add @CSS:, @@ prefix, case-insensitive detection, replaceFirst (###)"
```

---

## Task 5: Fix `@put` Timing - Execute Before Rule Evaluation

**Files:**
- Modify: `lib/core/engine/analyze_rule/analyze_rule_string.dart:21-75`
- Modify: `lib/core/engine/analyze_rule/analyze_rule_element.dart:21-58`
- Test: `test/core/engine/analyze_rule/analyze_rule_test.dart`

In Android, `@put` is processed BEFORE `makeUpRule()` and rule evaluation. In Flutter, it happens AFTER. Also, `@put` is missing from `getElement`/`getElements`/`getStringList`.

- [x] **Step 1: Add failing test**

```dart
  group('@put timing', () {
    test('@put processes before rule evaluation in getString', () {
      // This tests that @put values are available for subsequent rules
      // We verify the putMap is processed by checking the SourceRule structure
      final rule = SourceRule('@put:{"myKey":"testVal"}div.text');
      expect(rule.putMap, {'myKey': 'testVal'});
      expect(rule.rule, 'div.text');
    });
  });
```

- [x] **Step 2: Move @put processing before rule evaluation in getString**

In `lib/core/engine/analyze_rule/analyze_rule_string.dart`, move the `@put` block (lines 65-75) to BEFORE `makeUpRule` (after line 21, before line 26):

```dart
    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) {
          break;
        }

        // Process @put BEFORE makeUpRule (matches Android behavior)
        if (sourceRule.putMap.isNotEmpty) {
          sourceRule.putMap.forEach((key, valueRule) {
            final val = getString(valueRule);
            if (val.isNotEmpty) {
              put(key, val);
              log('  \u25C7 \u4FDD\u5B58\u8B8A\u6578: $key = $val');
            }
          });
        }

        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        log('  \u25C7 \u6A21\u5F0F: ${sourceRule.mode.name}, \u898F\u5247: $rule');
```

And remove the old @put block (the one that was after replaceRegex).

- [x] **Step 3: Add @put processing to getElement and getElements**

In `lib/core/engine/analyze_rule/analyze_rule_element.dart`, add after line 25 (before `sourceRule.makeUpRule`):

```dart
        // Process @put BEFORE makeUpRule
        if (sourceRule.putMap.isNotEmpty) {
          sourceRule.putMap.forEach((key, valueRule) {
            final val = getString(valueRule);
            if (val.isNotEmpty) {
              put(key, val);
              log('  \u25C7 \u4FDD\u5B58\u8B8A\u6578: $key = $val');
            }
          });
        }
```

Add the same block in `getElements` after line 88 (before `sourceRule.makeUpRule`).

Note: `getString` is available via `AnalyzeRuleString` mixin which is mixed in alongside `AnalyzeRuleElement` in the final `AnalyzeRule` class.

- [x] **Step 4: Add @put processing to getStringList**

In `lib/core/engine/analyze_rule/analyze_rule_string.dart`, in the `getStringList` method, add after line 107 (before `sourceRule.makeUpRule`):

```dart
        // Process @put BEFORE makeUpRule
        if (sourceRule.putMap.isNotEmpty) {
          sourceRule.putMap.forEach((key, valueRule) {
            final val = getString(valueRule);
            if (val.isNotEmpty) {
              put(key, val);
              log('  \u25C7 \u4FDD\u5B58\u8B8A\u6578: $key = $val');
            }
          });
        }
```

- [x] **Step 5: Run tests**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/analyze_rule/ -v`
Expected: PASS

- [x] **Step 6: Commit**

```bash
git add lib/core/engine/analyze_rule/analyze_rule_string.dart lib/core/engine/analyze_rule/analyze_rule_element.dart test/core/engine/analyze_rule/analyze_rule_test.dart
git commit -m "fix(analyze_rule): move @put before makeUpRule, add to getElement/getElements/getStringList"
```

---

## Task 6: Fix `{{}}` to Detect Rule-Like Content

**Files:**
- Modify: `lib/core/engine/analyze_rule/analyze_rule_support.dart:116-117`
- Test: `test/core/engine/analyze_rule/analyze_rule_test.dart`

In Android, when `{{}}` content starts with `@`, `$.`, `$[`, or `//`, it is evaluated as a rule via `getString()` instead of as JavaScript. Flutter always evaluates it as JS.

- [x] **Step 1: Add test**

```dart
  group('makeUpRule {{}} detection', () {
    test('{{}} with rule-like content detected as rule type', () {
      // Content starting with $. should be jsonPartRuleType, not jsRuleType
      // This is handled during SourceRule construction via evalPattern
      final rule = SourceRule(r'{{$.data.title}}');
      // Should detect {$.xxx} as jsonPartRuleType
      expect(rule.ruleType.contains(SourceRule.jsonPartRuleType), true);
    });
  });
```

- [x] **Step 2: Update makeUpRule to handle rule-like {{}} content**

In `lib/core/engine/analyze_rule/analyze_rule_support.dart`, modify the `makeUpRule` method (around line 116-117). Change the JS evaluation to check for rule-like patterns first:

```dart
      } else if (type == jsRuleType) {
        // Check if content is rule-like (starts with @, $., $[, //)
        // In Android, these are evaluated as rules, not JS
        final trimmed = param.trim();
        if (trimmed.startsWith('@') || trimmed.startsWith(r'$.') ||
            trimmed.startsWith(r'$[') || trimmed.startsWith('//')) {
          buffer.write(analyzer.getString(trimmed));
        } else {
          buffer.write(analyzer.evalJS(param, result));
        }
```

- [x] **Step 3: Run tests**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/analyze_rule/ -v`
Expected: PASS

- [x] **Step 4: Commit**

```bash
git add lib/core/engine/analyze_rule/analyze_rule_support.dart test/core/engine/analyze_rule/analyze_rule_test.dart
git commit -m "fix(analyze_rule): detect rule-like content in {{}} and eval as rule instead of JS"
```

---

## Task 7: Add Special Keys `bookName`/`title` in `get()`

**Files:**
- Modify: `lib/core/engine/analyze_rule/analyze_rule_base.dart:88-107`
- Test: `test/core/engine/analyze_rule/analyze_rule_test.dart`

Android returns `book.name` for key `"bookName"` and `chapter.title` for key `"title"`.

- [x] **Step 1: Add special key handling**

In `lib/core/engine/analyze_rule/analyze_rule_base.dart`, modify the `get` method to add special key handling at the top:

```dart
  String get(String key) {
    // Special keys (matches Android behavior)
    if (key == 'bookName') {
      try {
        final name = ruleData?.getVariable('bookName');
        if (name != null && name.isNotEmpty) return name;
        // Try accessing the name property directly
        final dynamic rd = ruleData;
        if (rd != null) {
          try { return rd.name ?? ''; } catch (_) {}
        }
      } catch (_) {}
    }
    if (key == 'title') {
      try {
        final dynamic ch = chapter;
        if (ch != null) {
          try { return ch.title ?? ''; } catch (_) {}
        }
      } catch (_) {}
    }

    String? val;

    if (chapter != null && chapter is RuleDataInterface) {
      val = (chapter as RuleDataInterface).getVariable(key);
    }
    val ??= ruleData?.getVariable(key);
    if (val == null || val.isEmpty) {
      if (source != null && source is RuleDataInterface) {
        val = (source as RuleDataInterface).getVariable(key);
      }
    }

    return val ?? '';
  }
```

- [x] **Step 2: Run tests**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/analyze_rule/ -v`
Expected: PASS

- [x] **Step 3: Commit**

```bash
git add lib/core/engine/analyze_rule/analyze_rule_base.dart
git commit -m "fix(analyze_rule): add special key handling for bookName and title in get()"
```

---

## Task 8: Add XPath Custom Functions (allText, textNodes, ownText, html, outerHtml)

**Files:**
- Modify: `lib/core/engine/parsers/analyze_by_xpath.dart`
- Test: `test/core/engine/parsers/analyze_by_xpath_test.dart`

The Dart xpath_selector library doesn't support JsoupXpath's custom functions. We need to intercept these patterns and handle them manually before they reach the XPath engine.

- [x] **Step 1: Write failing test**

```dart
// test/core/engine/parsers/analyze_by_xpath_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/parsers/analyze_by_xpath.dart';

void main() {
  final html = '<div class="content"><p>First <b>bold</b></p><p>Second</p></div>';

  group('AnalyzeByXPath custom functions', () {
    test('allText returns all text including descendants', () {
      final xpath = AnalyzeByXPath(html);
      final result = xpath.getStringList('//div[@class="content"]/allText()');
      expect(result.isNotEmpty, true);
      expect(result[0], 'First bold Second');
    });

    test('textNodes returns direct text only', () {
      final innerHtml = '<div>Direct text<p>Nested</p>More direct</div>';
      final xpath = AnalyzeByXPath(innerHtml);
      final result = xpath.getStringList('//div/textNodes()');
      expect(result.length, 1);
      expect(result[0].contains('Direct text'), true);
      expect(result[0].contains('More direct'), true);
      expect(result[0].contains('Nested'), false);
    });

    test('ownText returns element own text', () {
      final innerHtml = '<div>Own text<span>child</span> more own</div>';
      final xpath = AnalyzeByXPath(innerHtml);
      final result = xpath.getStringList('//div/ownText()');
      expect(result.isNotEmpty, true);
      expect(result[0].contains('Own text'), true);
      expect(result[0].contains('child'), false);
    });

    test('html() returns outer HTML', () {
      final xpath = AnalyzeByXPath(html);
      final result = xpath.getStringList('//p/html()');
      expect(result.length, 2);
      expect(result[0], '<p>First <b>bold</b></p>');
    });

    test('outerHtml() returns outer HTML', () {
      final xpath = AnalyzeByXPath(html);
      final result = xpath.getStringList('//p/outerHtml()');
      expect(result.length, 2);
      expect(result[0], '<p>First <b>bold</b></p>');
    });
  });

  group('AnalyzeByXPath XML detection', () {
    test('handles XML content with <?xml declaration', () {
      final xml = '<?xml version="1.0"?><root><item>Hello</item></root>';
      final xpath = AnalyzeByXPath(xml);
      final result = xpath.getStringList('//item/text()');
      expect(result, ['Hello']);
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/parsers/analyze_by_xpath_test.dart -v`
Expected: FAIL

- [x] **Step 3: Implement custom function handling**

Replace `lib/core/engine/parsers/analyze_by_xpath.dart` entirely:

```dart
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector/xpath_selector.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:legado_reader/core/engine/rule_analyzer.dart';

/// Custom XPath function suffixes that JsoupXpath supports but xpath_selector doesn't
final _customFuncPattern = RegExp(r'/(allText|textNodes|ownText|html|outerHtml)\(\)\s*$');

class AnalyzeByXPath {
  late HtmlXPath _xpath;
  late Document _document;

  AnalyzeByXPath(dynamic doc) {
    if (doc is Element) {
      _document = doc.ownerDocument ?? Document.html(doc.outerHtml);
      _xpath = HtmlXPath.node(doc);
    } else if (doc is String) {
      final prepared = _prepareHtml(doc);
      _document = html_parser.parse(prepared);
      _xpath = HtmlXPath.html(prepared);
    } else {
      final prepared = _prepareHtml(doc.toString());
      _document = html_parser.parse(prepared);
      _xpath = HtmlXPath.html(prepared);
    }
  }

  String _prepareHtml(String html) {
    var h = html.trim();
    if (h.endsWith('</td>')) {
      h = '<tr>$h</tr>';
    }
    if (h.endsWith('</tr>') || h.endsWith('</tbody>')) {
      h = '<table>$h</table>';
    }
    // XML detection: use HTML parser but preserve structure
    // Note: html package parses XML reasonably well
    return h;
  }

  /// Handle custom XPath function by splitting it from the base xpath
  /// Returns (baseXPath, functionName) or null if no custom function
  (String, String)? _extractCustomFunc(String rule) {
    final match = _customFuncPattern.firstMatch(rule);
    if (match == null) return null;
    final funcName = match.group(1)!;
    final baseXPath = rule.substring(0, match.start);
    return (baseXPath, funcName);
  }

  /// Apply custom function to elements
  List<String> _applyCustomFunc(List<XPathNode> nodes, String funcName) {
    final results = <String>[];
    for (final node in nodes) {
      final element = node.element;
      if (element == null) continue;
      switch (funcName) {
        case 'allText':
          final text = element.text.trim();
          if (text.isNotEmpty) results.add(text);
          break;
        case 'textNodes':
          final textNodes = element.nodes
              .where((n) => n.nodeType == Node.TEXT_NODE)
              .map((n) => n.text?.trim() ?? '')
              .where((t) => t.isNotEmpty)
              .join('\n');
          if (textNodes.isNotEmpty) results.add(textNodes);
          break;
        case 'ownText':
          final ownText = element.nodes
              .where((n) => n.nodeType == Node.TEXT_NODE)
              .map((n) => n.text?.trim() ?? '')
              .where((t) => t.isNotEmpty)
              .join(' ');
          if (ownText.isNotEmpty) results.add(ownText);
          break;
        case 'html':
        case 'outerHtml':
          results.add(element.outerHtml);
          break;
      }
    }
    return results;
  }

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

  List<String> getStringList(String xPathRule) {
    if (xPathRule.isEmpty) return [];

    final ruleAnalyzes = RuleAnalyzer(xPathRule);
    final rules = ruleAnalyzes.splitRule(['&&', '||', '%%']);

    if (rules.length == 1) {
      final String rule = rules[0].trim();

      // Check for custom functions first
      final customFunc = _extractCustomFunc(rule);
      if (customFunc != null) {
        final (baseXPath, funcName) = customFunc;
        final nodes = baseXPath.isEmpty
            ? _xpath.queryAll('//*').nodes
            : _xpath.query(baseXPath).nodes;
        return _applyCustomFunc(nodes, funcName);
      }

      final queryResult = _xpath.query(rule);

      // Handle attribute extraction /@attr
      if (rule.contains('/@')) {
        return queryResult.attrs.whereType<String>().toList();
      }

      // Handle text() nodes
      if (rule.endsWith('/text()')) {
        return queryResult.nodes
            .map((n) => n.text?.trim() ?? '')
            .where((t) => t.isNotEmpty)
            .toList();
      }

      // Default: return text for text nodes, outerHtml for elements (like Android asString)
      return queryResult.nodes.map((n) {
        final el = n.element;
        if (el != null) return el.outerHtml;
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
```

- [x] **Step 4: Run test**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/parsers/analyze_by_xpath_test.dart -v`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add lib/core/engine/parsers/analyze_by_xpath.dart test/core/engine/parsers/analyze_by_xpath_test.dart
git commit -m "feat(xpath): add allText/textNodes/ownText/html/outerHtml custom functions, fix asString"
```

---

## Task 9: Fix Broken JS Bridge Handlers (cookie/cache)

**Files:**
- Modify: `lib/core/engine/js/js_extensions.dart`
- Modify: `lib/core/engine/js/extensions/js_java_object.dart`
- Test: `test/core/engine/js/js_extensions_test.dart`

The `cookie` and `cache` JS objects call `sendMessage` with handler names that have no Dart-side `onMessage` registration. Also, ~10 handlers are registered but not wired into the `java` object.

- [x] **Step 1: Write failing test**

```dart
// test/core/engine/js/js_extensions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:legado_reader/core/engine/js/js_extensions.dart';
import 'package:legado_reader/core/engine/js/js_engine.dart';

void main() {
  group('JsExtensions bridge completeness', () {
    late JavascriptRuntime runtime;

    setUp(() {
      runtime = getJavascriptRuntime();
    });

    tearDown(() {
      runtime.dispose();
    });

    test('java.base64Decode is callable', () {
      final ext = JsExtensions(runtime);
      ext.inject();
      final result = runtime.evaluate('typeof java.base64Decode');
      expect(result.stringResult, 'function');
    });

    test('java.md5Encode16 is callable', () {
      final ext = JsExtensions(runtime);
      ext.inject();
      final result = runtime.evaluate('typeof java.md5Encode16');
      expect(result.stringResult, 'function');
    });

    test('java.hexEncodeToString is callable', () {
      final ext = JsExtensions(runtime);
      ext.inject();
      final result = runtime.evaluate('typeof java.hexEncodeToString');
      expect(result.stringResult, 'function');
    });

    test('cookie.set is callable and has handler', () {
      final ext = JsExtensions(runtime);
      ext.inject();
      final result = runtime.evaluate('typeof cookie.set');
      expect(result.stringResult, 'function');
    });

    test('cache.get is callable and has handler', () {
      final ext = JsExtensions(runtime);
      ext.inject();
      final result = runtime.evaluate('typeof cache.get');
      expect(result.stringResult, 'function');
    });
  });
}
```

- [x] **Step 2: Run test to verify baseline**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/js/js_extensions_test.dart -v`

- [x] **Step 3: Register missing handlers in js_extensions.dart**

In `lib/core/engine/js/js_extensions.dart`, add to `_injectCoreHandlers()`:

```dart
  void _injectCoreHandlers() {
    runtime.onMessage('put', (args) { if (args is List && args.length >= 2) JsExtensionsBase.sharedScope[args[0].toString()] = args[1]; });
    runtime.onMessage('get', (args) => JsExtensionsBase.sharedScope[args.toString()]);
    runtime.onMessage('log', (args) => debugPrint('JS_LOG: $args'));
    runtime.onMessage('toast', (args) => debugPrint('JS_TOAST: $args'));
    runtime.onMessage('cacheFile', (args) => cacheFile(args[0].toString(), args.length > 1 ? args[1] as int : 0));

    // Cookie handlers
    runtime.onMessage('setCookie', (args) {
      if (args is List && args.length >= 2) {
        CookieStore().setCookie(args[0].toString(), args[1].toString());
      }
    });
    runtime.onMessage('removeCookie', (args) {
      CookieStore().removeCookie(args.toString());
    });
    runtime.onMessage('allCookies', (args) {
      return ''; // CookieStore doesn't have a getAllCookies method yet
    });

    // Cache handlers
    runtime.onMessage('getCache', (args) async {
      return await cacheManager.get(args.toString()) ?? '';
    });
    runtime.onMessage('putCache', (args) async {
      if (args is List && args.length >= 2) {
        await cacheManager.put(args[0].toString(), args[1].toString());
      }
    });
    runtime.onMessage('deleteCache', (args) async {
      await cacheManager.delete(args.toString());
    });
  }
```

Add import at the top:
```dart
import 'package:legado_reader/core/services/cookie_store.dart';
```

- [x] **Step 4: Wire missing methods into java object**

In `lib/core/engine/js/extensions/js_java_object.dart`, add the missing methods to the `java` object literal:

```dart
        base64Decode: function(str) { return sendMessage('_base64Decode', JSON.stringify(str)); },
        md5Encode16: function(str) { return sendMessage('_md5Encode16', JSON.stringify(str)); },
        hexEncodeToString: function(str) { return sendMessage('_hexEncode', JSON.stringify(str)); },
        hexDecodeToString: function(hex) { return sendMessage('_hexDecode', JSON.stringify(hex)); },
        randomUUID: function() { return sendMessage('_randomUUID', ''); },
        timeFormat: function(time) { return sendMessage('_timeFormat', JSON.stringify(time)); },
        timeFormatUTC: function(time, format, sh) { return sendMessage('timeFormatUTC', JSON.stringify([time, format, sh])); },
```

- [x] **Step 5: Run tests**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/core/engine/js/js_extensions_test.dart -v`
Expected: PASS

- [x] **Step 6: Commit**

```bash
git add lib/core/engine/js/js_extensions.dart lib/core/engine/js/extensions/js_java_object.dart test/core/engine/js/js_extensions_test.dart
git commit -m "fix(js): register cookie/cache handlers, wire missing methods into java object"
```

---

## Task 10: Add Login Methods to BaseSource

**Files:**
- Modify: `lib/core/models/base_source.dart`
- Modify: `lib/core/models/source/book_source_base.dart`
- Test: `test/features/source_manager/source_login_test.dart`

Android's BaseSource has `getLoginJs()`, `login()`, `getLoginInfo()`, `putLoginInfo()`, `getLoginInfoMap()`. These are all missing.

- [x] **Step 1: Write tests**

```dart
// test/features/source_manager/source_login_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/models/base_source.dart';

void main() {
  group('BaseSource login methods', () {
    test('getLoginJs strips @js: prefix', () {
      // Test via a concrete implementation
      expect(BaseSourceLoginHelper.extractLoginJs('@js:function login(){return true}'),
          'function login(){return true}');
    });

    test('getLoginJs strips <js> tags', () {
      expect(BaseSourceLoginHelper.extractLoginJs('<js>function login(){}</js>'),
          'function login(){}');
    });

    test('getLoginJs returns null for plain URL', () {
      expect(BaseSourceLoginHelper.extractLoginJs('https://example.com/login'),
          null);
    });

    test('getLoginJs returns null for null input', () {
      expect(BaseSourceLoginHelper.extractLoginJs(null), null);
    });
  });
}
```

- [x] **Step 2: Add login helper to BaseSource**

Replace `lib/core/models/base_source.dart`:

```dart
import 'dart:convert';
import 'package:legado_reader/core/services/cache_manager.dart';
import 'package:legado_reader/core/services/cookie_store.dart';

/// BaseSource - resource source interface
/// (Android: data/entities/BaseSource.kt)
abstract class BaseSource {
  String? get jsLib;
  bool? get enabledCookieJar;
  String? get concurrentRate;
  String? get header;
  String? get loginUrl;
  String? get loginUi;

  String getTag();
  String getKey();

  /// Extract JS code from loginUrl (strips @js: or <js> prefix)
  /// Returns null if loginUrl is a plain URL (for WebView login)
  String? getLoginJs() {
    return BaseSourceLoginHelper.extractLoginJs(loginUrl);
  }

  /// Get parsed loginUi as list of maps
  List<Map<String, dynamic>>? loginUiConfig() {
    if (loginUi == null || loginUi!.isEmpty) return null;
    try {
      final decoded = jsonDecode(loginUi!);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  /// Store login info (JSON string of form data)
  Future<void> putLoginInfo(String info) async {
    await CacheManager().put('userInfo_${getKey()}', info);
  }

  /// Retrieve stored login info
  Future<String?> getLoginInfo() async {
    return await CacheManager().get('userInfo_${getKey()}');
  }

  /// Retrieve stored login info as Map
  Future<Map<String, String>?> getLoginInfoMap() async {
    final info = await getLoginInfo();
    if (info == null || info.isEmpty) return null;
    try {
      final decoded = jsonDecode(info);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return null;
  }

  /// Remove stored login info
  Future<void> removeLoginInfo() async {
    await CacheManager().delete('userInfo_${getKey()}');
  }

  /// Store login header
  Future<void> putLoginHeader(String header) async {
    await CacheManager().put('loginHeader_${getKey()}', header);
    // Extract cookies from header and store them
    try {
      final headerMap = jsonDecode(header) as Map<String, dynamic>;
      final cookie = headerMap['cookie'] ?? headerMap['Cookie'];
      if (cookie != null && cookie.toString().isNotEmpty) {
        await CookieStore().setCookie(getKey(), cookie.toString());
      }
    } catch (_) {}
  }

  /// Get stored login header
  Future<String?> getLoginHeader() async {
    return await CacheManager().get('loginHeader_${getKey()}');
  }

  /// Remove login header
  Future<void> removeLoginHeader() async {
    await CacheManager().delete('loginHeader_${getKey()}');
  }
}

/// Static helper for login JS extraction (testable without instance)
class BaseSourceLoginHelper {
  static String? extractLoginJs(String? loginUrl) {
    if (loginUrl == null || loginUrl.isEmpty) return null;
    if (loginUrl.startsWith('@js:')) {
      return loginUrl.substring(4);
    }
    if (loginUrl.startsWith('<js>')) {
      final endIdx = loginUrl.lastIndexOf('</');
      return endIdx > 4 ? loginUrl.substring(4, endIdx) : loginUrl.substring(4);
    }
    return null; // Plain URL - use WebView
  }
}
```

- [x] **Step 3: Run tests**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test test/features/source_manager/source_login_test.dart -v`
Expected: PASS

- [x] **Step 4: Commit**

```bash
git add lib/core/models/base_source.dart test/features/source_manager/source_login_test.dart
git commit -m "feat(login): add getLoginJs, putLoginInfo, getLoginInfo to BaseSource"
```

---

## Task 11: Add `loginCheckJs` to BaseSource and BookSourceBase

**Files:**
- Modify: `lib/core/models/base_source.dart`
- Modify: `lib/core/models/source/book_source_base.dart`

- [x] **Step 1: Add loginCheckJs to BaseSource interface**

In `lib/core/models/base_source.dart`, add to the abstract class:

```dart
  String? get loginCheckJs;
```

- [x] **Step 2: Verify BookSourceBase already has loginCheckJs**

Check `lib/core/models/source/book_source_base.dart` already declares `loginCheckJs`. If not, add it. It should already exist based on research.

- [x] **Step 3: Run flutter analyze**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter analyze`
Expected: No new errors

- [x] **Step 4: Commit**

```bash
git add lib/core/models/base_source.dart lib/core/models/source/book_source_base.dart
git commit -m "feat(login): add loginCheckJs to BaseSource interface"
```

---

## Task 12: Wire Dynamic Login Form Submission

**Files:**
- Modify: `lib/features/source_manager/source_login_page.dart`

This is the biggest login task. We need to:
1. Replace the stub `_handleDynamicAction` with real JS execution
2. Add a submit action that collects form data, stores it, and calls login JS
3. Re-capture cookies on WebView "done"

- [x] **Step 1: Rewrite source_login_page.dart**

Replace `lib/features/source_manager/source_login_page.dart`:

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/services/cookie_store.dart';
import 'package:legado_reader/core/engine/js/js_engine.dart';
import 'package:legado_reader/core/engine/js/js_extensions.dart';
import 'dynamic_form_builder.dart';

class SourceLoginPage extends StatefulWidget {
  final BookSource source;
  const SourceLoginPage({super.key, required this.source});

  @override
  State<SourceLoginPage> createState() => _SourceLoginPageState();
}

class _SourceLoginPageState extends State<SourceLoginPage> {
  late final WebViewController? _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  bool _isLoading = true;
  bool _useDynamicUi = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _useDynamicUi = widget.source.loginUi != null && widget.source.loginUi!.isNotEmpty;

    if (!_useDynamicUi) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() => _isLoading = true);
              // Capture cookies on page start too (matches Android)
              _captureCookies(url);
            },
            onPageFinished: (url) async {
              setState(() => _isLoading = false);
              await _captureCookies(url);
            },
          ),
        );

      // Set User-Agent from headers
      if (widget.source.header != null && widget.source.header!.contains('User-Agent')) {
        final uaMatch = RegExp(r'User-Agent[:\s]+([^|\n]+)').firstMatch(widget.source.header!);
        if (uaMatch != null) {
          _controller?.setUserAgent(uaMatch.group(1)?.trim());
        }
      }

      _controller?.loadRequest(Uri.parse(widget.source.loginUrl ?? widget.source.bookSourceUrl));
    } else {
      _controller = null;
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _captureCookies(String url) async {
    if (_controller == null) return;

    try {
      final jsCookies = await _controller.runJavaScriptReturningResult('document.cookie') as String;
      final cleanJsCookies = jsCookies.replaceAll('"', '');

      if (cleanJsCookies.isNotEmpty) {
        await CookieStore().replaceCookie(url, cleanJsCookies);
      }

      debugPrint('Captured Cookies for $url: $cleanJsCookies');
    } catch (e) {
      debugPrint('Capture Cookie error: $e');
    }
  }

  Future<void> _clearCookies() async {
    await _cookieManager.clearCookies();
    await CookieStore().removeCookie(widget.source.bookSourceUrl);
    _controller?.reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除 Cookie')));
    }
  }

  /// Collect form data from dynamic UI
  Map<String, String> _collectFormData() {
    final data = <String, String>{};
    for (final entry in _controllers.entries) {
      data[entry.key] = entry.value.text;
    }
    return data;
  }

  /// Execute login JS with form data
  Future<void> _executeLogin() async {
    final loginJs = widget.source.getLoginJs();
    if (loginJs == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此書源不支援 JS 登入')),
        );
      }
      return;
    }

    final formData = _collectFormData();

    // Store login info
    await widget.source.putLoginInfo(jsonEncode(formData));

    try {
      final engine = JsEngine();
      final ext = JsExtensions(engine.runtime, source: widget.source);
      ext.inject();

      // Inject source and form data as result
      engine.runtime.evaluate('var source = ${jsonEncode(_sourceToMap())};');
      engine.runtime.evaluate('var result = ${jsonEncode(formData)};');
      engine.runtime.evaluate('var baseUrl = "${widget.source.bookSourceUrl}";');

      // Execute: loginJs followed by login() call
      final js = '''
        $loginJs
        if(typeof login === 'function') {
          login.apply(this);
        } else {
          throw('Function login not implemented!');
        }
      ''';

      engine.evaluate(js);
      engine.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登入成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登入失敗: $e')),
        );
      }
    }
  }

  /// Handle button action from dynamic form
  void _handleDynamicAction(String action, Map<String, String> data) async {
    if (action.isEmpty) return;

    // If action is a URL, open it (e.g., captcha URL)
    if (action.startsWith('http://') || action.startsWith('https://')) {
      // Could open in browser or load captcha image
      debugPrint('Login action URL: $action');
      return;
    }

    // Otherwise treat as JS to execute
    try {
      final loginJs = widget.source.getLoginJs() ?? '';
      final engine = JsEngine();
      final ext = JsExtensions(engine.runtime, source: widget.source);
      ext.inject();

      engine.runtime.evaluate('var source = ${jsonEncode(_sourceToMap())};');
      engine.runtime.evaluate('var result = ${jsonEncode(data)};');
      engine.runtime.evaluate('var baseUrl = "${widget.source.bookSourceUrl}";');

      // Prepend loginJs so button action can reference login functions
      final js = '$loginJs\n$action';
      engine.evaluate(js);
      engine.dispose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('執行失敗: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _sourceToMap() {
    return {
      'bookSourceUrl': widget.source.bookSourceUrl,
      'bookSourceName': widget.source.bookSourceName,
      'loginUrl': widget.source.loginUrl,
    };
  }

  /// Handle WebView done: re-capture cookies then pop
  Future<void> _handleDone() async {
    if (!_useDynamicUi && _controller != null) {
      final url = await _controller.currentUrl();
      if (url != null) {
        await _captureCookies(url);
      }
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.source.bookSourceName} 登入'),
        actions: [
          if (!_useDynamicUi)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller?.reload(),
              tooltip: '重新整理',
            ),
          if (_useDynamicUi)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _executeLogin,
              tooltip: '登入',
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearCookies,
            tooltip: '清除 Cookie',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _handleDone,
            tooltip: '完成',
          ),
        ],
      ),
      body: _useDynamicUi
          ? DynamicFormBuilder(
              loginUiJson: widget.source.loginUi!,
              controllers: _controllers,
              onAction: _handleDynamicAction,
            )
          : Stack(
              children: [
                if (_controller != null) WebViewWidget(controller: _controller),
                if (_isLoading) const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
```

- [x] **Step 2: Run flutter analyze**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter analyze`
Expected: No errors in source_login_page.dart

- [x] **Step 3: Commit**

```bash
git add lib/features/source_manager/source_login_page.dart
git commit -m "feat(login): implement dynamic form submission and JS login execution"
```

---

## Task 13: Inject `source` Object into JS Context

**Files:**
- Modify: `lib/core/engine/js/extensions/js_java_object.dart`
- Modify: `lib/core/engine/analyze_rule/analyze_rule_script.dart`

Android injects a `source` object that JS code can call `source.getLoginInfo()`, `source.putLoginInfo()`, `source.put()`, `source.get()` on.

- [x] **Step 1: Add source object injection to js_java_object.dart**

In `lib/core/engine/js/extensions/js_java_object.dart`, add after the `cache` object (before the closing `'''`):

```dart
      var source = source || {};
      source.getLoginInfo = function() { return sendMessage('sourceGetLoginInfo', ''); };
      source.putLoginInfo = function(info) { return sendMessage('sourcePutLoginInfo', JSON.stringify(info)); };
      source.getLoginInfoMap = function() {
        var info = sendMessage('sourceGetLoginInfo', '');
        try { return JSON.parse(info); } catch(e) { return {}; }
      };
      source.put = function(key, value) { return sendMessage('sourcePut', JSON.stringify([key, value])); };
      source.get = function(key) { return sendMessage('sourceGet', JSON.stringify(key)); };
```

- [x] **Step 2: Register source handlers in js_extensions.dart**

In `lib/core/engine/js/js_extensions.dart`, add to `_injectCoreHandlers()`:

```dart
    // Source variable storage
    runtime.onMessage('sourcePut', (args) {
      if (args is List && args.length >= 2 && source != null) {
        final key = args[0].toString();
        final value = args[1].toString();
        CacheManager().put('v_${source!.getKey()}_$key', value);
        return value;
      }
    });
    runtime.onMessage('sourceGet', (args) async {
      if (source != null) {
        return await CacheManager().get('v_${source!.getKey()}_${args.toString()}') ?? '';
      }
      return '';
    });
    runtime.onMessage('sourceGetLoginInfo', (args) async {
      if (source != null) {
        return await source!.getLoginInfo() ?? '';
      }
      return '';
    });
    runtime.onMessage('sourcePutLoginInfo', (args) async {
      if (source != null) {
        await source!.putLoginInfo(args.toString());
      }
    });
```

- [x] **Step 3: Run flutter analyze**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter analyze`
Expected: No errors

- [x] **Step 4: Commit**

```bash
git add lib/core/engine/js/extensions/js_java_object.dart lib/core/engine/js/js_extensions.dart
git commit -m "feat(js): inject source object with getLoginInfo/put/get into JS context"
```

---

## Task 14: Run Full Test Suite and Static Analysis

**Files:** None (verification only)

- [x] **Step 1: Run flutter analyze**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter analyze`
Expected: No errors

- [x] **Step 2: Run all tests**

Run: `cd /home/benny/.openclaw/workspace/projects/reader && flutter test`
Expected: All tests pass

- [x] **Step 3: Fix any issues found**

If any tests fail or analysis errors appear, fix them before committing.

- [x] **Step 4: Final commit if needed**

```bash
git add -A
git commit -m "fix: resolve remaining analysis warnings and test failures"
```

---

## Priority Summary

| Task | Area | Severity | Description |
|------|------|----------|-------------|
| 1 | CSS | Critical | Fix `!` exclusion bug |
| 2 | CSS | High | Strip script/style from `html` keyword |
| 3 | CSS | Medium | Fix textNodes per-element join |
| 4 | AnalyzeRule | Critical | Fix mode detection (@CSS:, @@, case, replaceFirst) |
| 5 | AnalyzeRule | Critical | Fix @put timing (before not after) |
| 6 | AnalyzeRule | High | Fix {{}} rule-like content detection |
| 7 | AnalyzeRule | Medium | Add special keys bookName/title |
| 8 | XPath | High | Add custom functions (allText, textNodes, etc.) |
| 9 | JsExtensions | Critical | Fix broken cookie/cache handlers, wire methods |
| 10 | Login | High | Add login methods to BaseSource |
| 11 | Login | Medium | Add loginCheckJs to BaseSource interface |
| 12 | Login | High | Wire dynamic form submission + JS execution |
| 13 | Login | High | Inject source object into JS context |
| 14 | All | Required | Final verification |

## Known Deferred Items (Not in This Plan)

These gaps were identified but are lower priority:
- JsonPath `getString` returning null vs empty string
- `isJSON` auto-detection from content type in AnalyzeRule
- AllInOne `:` prefix for regex mode in splitSourceRule
- Persistent `isRegex` flag across rule evaluations
- `##` splitting at runtime vs parse-time (complex refactor)
- XML parser detection in CSS parser
- `element.data()` fallback when CSS rule is empty
- Path sandboxing for JS file operations
- Missing JS methods: importScript, webViewGetSource, encodeURI, deleteFile, etc.
- AES encryption for putLoginInfo (currently plaintext)
- `book`/`rssArticle` JS bindings
- WebView HttpOnly cookie capture improvement
