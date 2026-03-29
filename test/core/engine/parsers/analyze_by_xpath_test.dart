import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/engine/parsers/analyze_by_xpath.dart';

void main() {
  group('AnalyzeByXPath Tests', () {
    const html = '''
      <html>
        <body>
          <div id="test">
            <ul class="list">
              <li>Item 1</li>
              <li>Item 2</li>
            </ul>
            <a href="https://example.com" title="Example">Link</a>
          </div>
        </body>
      </html>
    ''';

    test('getElements - select nodes', () {
      final analyzer = AnalyzeByXPath(html);
      final elements = analyzer.getElements('//li');
      expect(elements.length, 2);
      expect(elements[0].text, 'Item 1');
    });

    test('getStringList - select attributes', () {
      final analyzer = AnalyzeByXPath(html);
      final hrefs = analyzer.getStringList('//a/@href');
      expect(hrefs, ['https://example.com']);
    });

    test('getStringList - select text', () {
      final analyzer = AnalyzeByXPath(html);
      final texts = analyzer.getStringList('//li/text()');
      expect(texts, ['Item 1', 'Item 2']);
    });

    test('getString - join with newline', () {
      final analyzer = AnalyzeByXPath(html);
      final result = analyzer.getString('//li/text()');
      expect(result, 'Item 1\nItem 2');
    });

    test('getStringList - returns outerHtml for element nodes', () {
      final analyzer = AnalyzeByXPath(html);
      final result = analyzer.getStringList('//li');
      expect(result.first, '<li>Item 1</li>');
    });

    test('Logical && operator', () {
      final analyzer = AnalyzeByXPath(html);
      final result = analyzer.getString('//li[1]/text() && //li[2]/text()');
      expect(result, 'Item 1\nItem 2');
    });

    test('Table tag auto-completion', () {
      // Test the _prepareHtml logic
      const tableFragment = '<td>Data</td>';
      final analyzer = AnalyzeByXPath(tableFragment);
      final result = analyzer.getString('//td/text()');
      expect(result, 'Data');
    });

    test('custom functions allText/textNodes/ownText/html', () {
      const richHtml = '<div class="content">Direct <span>Nested</span> Tail</div>';
      final analyzer = AnalyzeByXPath(richHtml);

      expect(analyzer.getString('//div/allText()'), 'Direct Nested Tail');
      expect(analyzer.getString('//div/textNodes()'), 'Direct\nTail');
      expect(analyzer.getString('//div/ownText()'), 'Direct Tail');
      expect(analyzer.getString('//div/html()'), '<div class="content">Direct <span>Nested</span> Tail</div>');
      expect(analyzer.getString('//div/outerHtml()'), '<div class="content">Direct <span>Nested</span> Tail</div>');
    });
  });
}
