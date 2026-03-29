import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/models/rule_data_interface.dart';

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
      expect(htmlAnalyzer.getString('@XPath://div[@class="title"]/text()'), 'Test Title');

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
      final analyzer = AnalyzeRule().setContent('<div class="title">Title Title</div>');
      expect(analyzer.getString('.title@text##Title##Header###'), 'Header Title');
    });

    test('Variables @get and put', () {
      final mockData = MockRuleData();
      final analyzer = AnalyzeRule(ruleData: mockData).setContent(htmlStr);
      
      analyzer.put('myVar', 'Hello');
      expect(analyzer.getString('@get:{myVar}'), 'Hello');
      
      // Test embedded in rule
      expect(analyzer.getString('Prefix: @get:{myVar}'), 'Prefix: Hello');
    });

    test('@put runs before rule evaluation in getString', () {
      final analyzer = AnalyzeRule(ruleData: MockRuleData()).setContent(htmlStr);
      final value = analyzer.getString('@put:{"myVar":"@css:.title@text"}Prefix: @get:{myVar}');

      expect(value, 'Prefix: Test Title');
      expect(analyzer.get('myVar'), 'Test Title');
    });

    test('Rule-like content in {{}} is resolved as rule instead of JS', () {
      final analyzer = AnalyzeRule().setContent(jsonStr);
      expect(analyzer.getString(r'{{$.title}}'), 'JSON Title');
    });
  });
}
