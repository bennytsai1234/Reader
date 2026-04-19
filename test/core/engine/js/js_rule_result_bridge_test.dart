import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart' as dom;
import 'package:inkpage_reader/core/engine/analyze_rule.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';

import '../../../test_helper.dart';

void main() {
  setupTestDI();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyzeRule JS result bridge', () {
    JavascriptRuntime? runtime;
    Object? runtimeError;

    setUp(() {
      runtimeError = null;
      try {
        runtime = getJavascriptRuntime();
      } catch (error) {
        runtime = null;
        runtimeError = error;
      }
    });

    tearDown(() {
      runtime?.dispose();
      runtime = null;
    });

    test('js rules can call toArray and element.text on CSS result lists', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }

      final rule = AnalyzeRule(
        source: BookSource(bookSourceUrl: 'https://example.com'),
      ).setContent('''
        <div class="v-list-item">
          <div class="v-title">我的第一本書</div>
        </div>
        <div class="v-list-item">
          <div class="v-title">別的作品</div>
        </div>
      ''', baseUrl: 'https://example.com');
      rule.key = '我的';

      final result = rule.getElements('''
class.v-list-item
@js:
list=result.toArray();
list1=[];
for(i in list){
  if(list[i].text().indexOf(java.get('key'))>-1){
    list1.push(list[i])
  }
}
list1.map(x=>x)
''');

      expect(result, hasLength(1));
      expect(result.first, isA<dom.Element>());
      expect((result.first as dom.Element).text, contains('我的第一本書'));
      rule.dispose();
    });

    test(
      'getStringAsync preserves final if completion for sync JS rules',
      () async {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }

        final rule = AnalyzeRule(
          source: BookSource(bookSourceUrl: 'https://example.com'),
        ).setContent('{"ok":true}', baseUrl: 'https://example.com');

        final result = await rule.getStringAsync(r'''
<js>
var data = JSON.parse(result);
if (data.ok) {
  "branch:yes";
} else {
  "branch:no";
}
</js>
''');

        expect(result, 'branch:yes');
        rule.dispose();
      },
    );

    test(
      'getStringAsync preserves final if completion when branch declares helper functions',
      () async {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }

        final rule = AnalyzeRule(
          source: BookSource(bookSourceUrl: 'https://example.com'),
        ).setContent('{}', baseUrl: 'https://example.com');

        final result = await rule.getStringAsync(r'''
<js>
if (true) {
  function decode(value) {
    return value + ":ok";
  }
  decode("payload")
} else {
  "branch:no";
}
</js>
''');

        expect(result, 'payload:ok');
        rule.dispose();
      },
    );

    test(
      'getStringAsync preserves final if completion when branch uses with(JavaImporter)',
      () async {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }

        final rule = AnalyzeRule(
          source: BookSource(bookSourceUrl: 'https://example.com'),
        ).setContent('{}', baseUrl: 'https://example.com');

        final result = await rule.getStringAsync(r'''
<js>
if (true) {
  var javaImport = new JavaImporter();
  javaImport.importPackage(Packages.java.lang);
  with (javaImport) {
    function decode(value) {
      return String(value) + ":ok";
    }
  }
  decode("payload")
} else {
  "branch:no";
}
</js>
''');

        expect(result, 'payload:ok');
        rule.dispose();
      },
    );

    test(
      'XPath element results can be reparsed through Jsoup in JS rules',
      () async {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }

        final rule = AnalyzeRule(
          source: BookSource(bookSourceUrl: 'https://example.com'),
        ).setContent('''
        <div class="toc">
          <a href="/chapter/1"><span>第一章</span></a>
        </div>
      ''', baseUrl: 'https://example.com');

        final result = await rule.getStringAsync(r'''
//div[@class="toc"]/a
@js:
var doc = org.jsoup.Jsoup.parse(result);
var link = doc.select("a").first();
link.attr("href");
''');

        expect(result, '/chapter/1');
        rule.dispose();
      },
    );

    test(
      'getStringAsync supports unicode fallback strings in sync JS rules',
      () async {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }

        final rule = AnalyzeRule(
          source: BookSource(bookSourceUrl: 'https://example.com'),
        ).setContent('{}', baseUrl: 'https://example.com');

        final result = await rule.getStringAsync(r'''
<js>
var result = "";
'<br>'+((result)?result:'想要获取更多书籍信息，请点击书籍的书名(・o・)');
</js>
''');

        expect(result, '<br>想要获取更多书籍信息，请点击书籍的书名(・o・)');
        rule.dispose();
      },
    );

    test(
      'book and chapter scoped objects expose fields, variables, and setters',
      () async {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }

        final book = Book(
          bookUrl: 'https://example.com/book',
          name: '示例书',
          author: '作者',
          variable: '{"mode":"day"}',
        );
        final chapter = BookChapter(
          title: '旧章节',
          url: '/chapter/1',
          variable: '{"state":"draft"}',
        );
        final rule = AnalyzeRule(
          source: BookSource(bookSourceUrl: 'https://example.com'),
          ruleData: book,
        ).setContent('{}', baseUrl: 'https://example.com');
        rule.chapter = chapter;

        final result = await rule.getStringAsync(r'''
<js>
book.putVariable("custom", "42");
chapter.putVariable("flag", "ready");
book.type = 8;
chapter.title = "新章节";
chapter.url = "/chapter/2";
book.name + "|" + book.getVariable("custom") + "|" + chapter.getVariable("flag") + "|" + book.type + "|" + chapter.title + "|" + chapter.url;
</js>
''');

        expect(result, '示例书|42|ready|8|新章节|/chapter/2');
        expect(book.getVariable('custom'), '42');
        expect(chapter.getVariable('flag'), 'ready');
        expect(book.type, 8);
        expect(chapter.title, '新章节');
        expect(chapter.url, '/chapter/2');
        rule.dispose();
      },
    );
  });
}
