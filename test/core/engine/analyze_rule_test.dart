import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/analyze_rule.dart';
import 'package:inkpage_reader/core/models/rule_data_interface.dart';

class MockRuleData extends RuleDataInterface {
  @override
  final Map<String, String> variableMap = {};

  @override
  String getVariable(String key) => variableMap[key] ?? '';

  @override
  void putVariable(String key, String? value) {
    if (value == null) {
      variableMap.remove(key);
    } else {
      variableMap[key] = value;
    }
  }
}

void main() {
  group('AnalyzeRule Tests', () {
    const htmlStr = '''
    <html>
      <body>
        <div class="title">Test Title</div>
        <div class="content">Test Content</div>
        <a class="link" href="/book/1">Book 1</a>
        <div class="links">
          <a href="/chapter/1">Chapter 1</a>
          <a href="/chapter/2">Chapter 2</a>
        </div>
      </body>
    </html>
    ''';

    const jsonStr = '''
    {
      "title": "JSON Title",
      "content": "JSON Content"
    }
    ''';

    test('Routing to CSS parser', () {
      final analyzer = AnalyzeRule().setContent(htmlStr);
      expect(analyzer.getString('.title@text'), 'Test Title');
    });

    test('Routing to JsonPath parser', () {
      final analyzer = AnalyzeRule().setContent(jsonStr);
      expect(analyzer.getString(r'$.title'), 'JSON Title');
    });

    test(
      'Default mode falls back to bare JSON field paths and wildcard lists',
      () {
        final analyzer = AnalyzeRule().setContent({
          'title': 'Bare Title',
          'meta': {'author': 'Bare Author'},
        });
        final listAnalyzer = AnalyzeRule().setContent([
          {'name': 'Book A'},
          {'name': 'Book B'},
        ]);

        expect(analyzer.getString('title'), 'Bare Title');
        expect(analyzer.getString('meta.author'), 'Bare Author');
        expect(
          analyzer.getString('title&&meta.author'),
          'Bare Title\nBare Author',
        );
        expect(listAnalyzer.getElements('*'), hasLength(2));
      },
    );

    test(
      'getElementAsync preserves raw JSON object results for init-style rules',
      () async {
        final analyzer = AnalyzeRule().setContent({
          'body': {
            'bookinfo': {'book': 86730, 'v_book': '示例書名'},
          },
        });

        final result = await analyzer.getElementAsync(r'$.body.bookinfo');

        expect(result, isA<Map>());
        expect((result as Map)['book'], 86730);
        expect(result['v_book'], '示例書名');
      },
    );

    test('Routing to XPath parser', () {
      final analyzer = AnalyzeRule().setContent(htmlStr);
      expect(analyzer.getString('//div[@class="title"]/text()'), 'Test Title');
    });

    test('Prefix override @Json:', () {
      // Force JSON mode even if content looks like HTML (though this content IS JSON)
      final analyzer = AnalyzeRule().setContent(jsonStr);
      expect(analyzer.getString(r'@Json:$.title'), 'JSON Title');
    });

    test('Prefix override is case-insensitive and supports @css:', () {
      final htmlAnalyzer = AnalyzeRule().setContent(htmlStr);
      expect(htmlAnalyzer.getString('@css:.title@text'), 'Test Title');
      expect(
        htmlAnalyzer.getString('@XPath://div[@class="title"]/text()'),
        'Test Title',
      );

      final jsonAnalyzer = AnalyzeRule().setContent(jsonStr);
      expect(jsonAnalyzer.getString(r'@json:$.title'), 'JSON Title');
    });

    test('@@ forces default mode', () {
      final analyzer = AnalyzeRule().setContent(htmlStr);
      expect(analyzer.getString('@@.title@text'), 'Test Title');
    });

    test('Regex replacement ##', () {
      final analyzer = AnalyzeRule().setContent(htmlStr);
      // Replace Title with Header
      expect(analyzer.getString('.title@text##Title##Header'), 'Test Header');
    });

    test('Regex replacement ### only replaces first match', () {
      final analyzer = AnalyzeRule().setContent(
        '<div class="title">Title Title</div>',
      );
      expect(
        analyzer.getString('.title@text##Title##Header###'),
        'Header Title',
      );
    });

    test('Variables @get and put', () {
      final mockData = MockRuleData();
      final analyzer = AnalyzeRule(ruleData: mockData).setContent(htmlStr);

      analyzer.put('myVar', 'Hello');
      expect(analyzer.getString('@get:{myVar}'), 'Hello');

      // Test embedded in rule
      expect(analyzer.getString('Prefix: @get:{myVar}'), 'Prefix: Hello');
    });

    test('transient variables work without ruleData or source storage', () {
      final analyzer = AnalyzeRule().setContent(htmlStr);

      analyzer.put('tempVar', 'Hello');

      expect(analyzer.get('tempVar'), 'Hello');
      expect(analyzer.getString('@get:{tempVar}'), 'Hello');
    });

    test('@put runs before rule evaluation in getString', () {
      final analyzer = AnalyzeRule(
        ruleData: MockRuleData(),
      ).setContent(htmlStr);
      final value = analyzer.getString(
        '@put:{"myVar":"@css:.title@text"}Prefix: @get:{myVar}',
      );

      expect(value, 'Prefix: Test Title');
      expect(analyzer.get('myVar'), 'Test Title');
    });

    test('Rule-like content in {{}} is resolved as rule instead of JS', () {
      final analyzer = AnalyzeRule().setContent(jsonStr);
      expect(analyzer.getString(r'{{$.title}}'), 'JSON Title');
    });

    test('isUrl=true resolves relative url to absolute url', () {
      final analyzer = AnalyzeRule().setContent(
        htmlStr,
        baseUrl: 'https://example.com/search?q=test',
      );

      expect(
        analyzer.getString('.link@href', isUrl: true),
        'https://example.com/book/1',
      );
    });

    test('getStringList with isUrl=true resolves relative urls', () {
      final analyzer = AnalyzeRule().setContent(
        htmlStr,
        baseUrl: 'https://example.com/search?q=test',
      );

      expect(analyzer.getStringList('.links@tag.a@href', isUrl: true), [
        'https://example.com/chapter/1',
        'https://example.com/chapter/2',
      ]);
    });

    test(
      'getStringAsync with isUrl=true resolves relative url to absolute url',
      () async {
        final analyzer = AnalyzeRule().setContent(
          htmlStr,
          baseUrl: 'https://example.com/search?q=test',
        );

        expect(
          await analyzer.getStringAsync('.link@href', isUrl: true),
          'https://example.com/book/1',
        );
      },
    );
  });
}
