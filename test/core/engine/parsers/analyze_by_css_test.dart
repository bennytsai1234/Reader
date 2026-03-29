import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:legado_reader/core/engine/parsers/analyze_by_css.dart';
import 'package:legado_reader/core/engine/parsers/css/analyze_by_css_support.dart';

void main() {
  group('AnalyzeByCss Tests', () {
    const htmlStr = '''
    <html>
      <body>
        <div id="content">
          <ul class="bookList">
            <li class="item">
              <a href="book1.html" title="Book 1">Chapter 1</a>
              <span class="author">Author A</span>
            </li>
            <li class="item">
              <a href="book2.html" title="Book 2">Chapter 2</a>
              <span class="author">Author B</span>
            </li>
            <li class="item">
              <a href="book3.html" title="Book 3">Chapter 3</a>
              <span class="author">Author C</span>
            </li>
          </ul>
          <div class="footer">Footer Text <!-- hidden comment --> <span>Extra</span></div>
        </div>
      </body>
    </html>
    ''';

    late AnalyzeByCss analyzer;

    setUp(() {
      analyzer = AnalyzeByCss(htmlStr);
    });

    test('1. Standard CSS selector via @CSS:', () {
      final titles = analyzer.getStringList('@CSS:li.item a@text');
      expect(titles, ['Chapter 1', 'Chapter 2', 'Chapter 3']);
    });

    test('2. Legado custom syntax tag.class@attr', () {
      final titles = analyzer.getStringList('li.item@tag.a@text');
      expect(titles, ['Chapter 1', 'Chapter 2', 'Chapter 3']);
      
      final hrefs = analyzer.getStringList('li.item@tag.a@href');
      expect(hrefs, ['book1.html', 'book2.html', 'book3.html']);
    });

    test('3. Index selection using .index', () {
      // First item
      expect(analyzer.getString('li.item.0@tag.a@text'), 'Chapter 1');
      // Last item
      expect(analyzer.getString('li.item.-1@tag.a@text'), 'Chapter 3');
    });

    test('4. Index selection using !index (User requirement: selection)', () {
      expect(analyzer.getStringList('li.item!0@tag.a@text'), ['Chapter 2', 'Chapter 3']);
      expect(analyzer.getStringList('li.item!1@tag.a@text'), ['Chapter 1', 'Chapter 3']);
    });

    test('5. Range selection [start:end]', () {
      final titles = analyzer.getStringList('li.item[0:1]@tag.a@text');
      expect(titles, ['Chapter 1', 'Chapter 2']);
    });

    test('6. Special attributes: text, html, ownText', () {
      // text includes all child text
      expect(analyzer.getString('.footer@text'), 'Footer Text Extra');
      // ownText only includes direct text nodes
      expect(analyzer.getString('.footer@ownText'), 'Footer Text');
      // html includes outer html
      expect(analyzer.getString('.footer@html'), contains('<div class="footer">'));
    });

    test('7. Logical && operator', () {
      final result = analyzer.getString('.author.0@text && .author.1@text');
      expect(result, 'Author A\nAuthor B');
    });

    test('8. Logical || operator (fallback)', () {
      expect(analyzer.getString('.none@text || .footer@ownText'), 'Footer Text');
    });

    test('9. ElementsSingle ! exclusion removes specified indexes', () {
      final doc = html_parser.parse('<div><p>A</p><p>B</p><p>C</p><p>D</p></div>');
      final container = doc.querySelector('div')!;
      final single = ElementsSingle();

      final result = single.getElementsSingle(container, 'tag.p!0');
      expect(result.map((e) => e.text).toList(), ['B', 'C', 'D']);
    });

    test('10. Bracket exclusion [!...] removes multiple indexes', () {
      final doc = html_parser.parse('<div><p>A</p><p>B</p><p>C</p><p>D</p></div>');
      final container = doc.querySelector('div')!;
      final single = ElementsSingle();

      final result = single.getElementsSingle(container, 'tag.p[!0,2]');
      expect(result.map((e) => e.text).toList(), ['B', 'D']);
    });

    test('11. html strips script and style tags', () {
      final doc = html_parser.parse(
        '<div><p>Hello</p><script>alert(1)</script><style>.x{}</style><span>World</span></div>',
      );
      final helper = AnalyzeByCss(doc.documentElement!.outerHtml);
      final result = helper.getResultLast(doc.querySelectorAll('div'), 'html');

      expect(result, hasLength(1));
      expect(result.first.contains('<script>'), false);
      expect(result.first.contains('<style>'), false);
      expect(result.first.contains('Hello'), true);
      expect(result.first.contains('World'), true);
    });

    test('12. textNodes joins direct text nodes per element', () {
      final doc = html_parser.parse('<div>First<br>Second<span>Skip</span>Third</div>');
      final helper = AnalyzeByCss(doc.documentElement!.outerHtml);
      final result = helper.getResultLast(doc.querySelectorAll('div'), 'textNodes');

      expect(result, ['First\nSecond\nThird']);
    });
  });
}
