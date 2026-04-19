import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/analyze_url.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import '../../test_helper.dart';

void main() {
  setupTestDI();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyzeUrl Tests', () {
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

    test('Basic URL variable substitution', () {
      final analyzer = AnalyzeUrl(
        'https://example.com/search?q={{key}}&p={{page}}',
        key: 'novel',
        page: 2,
      );
      expect(analyzer.url, 'https://example.com/search?q=novel&p=2');
    });

    test('Page list substitution <p1,p2,p3>', () {
      final analyzer1 = AnalyzeUrl(
        'https://example.com/list/<1,2,3>.html',
        page: 1,
      );
      expect(analyzer1.url, 'https://example.com/list/1.html');

      final analyzer2 = AnalyzeUrl(
        'https://example.com/list/<1,2,3>.html',
        page: 3,
      );
      expect(analyzer2.url, 'https://example.com/list/3.html');

      final analyzer3 = AnalyzeUrl(
        'https://example.com/list/<1,2,3>.html',
        page: 5,
      );
      expect(analyzer3.url, 'https://example.com/list/3.html');
    });

    test('Legado options parsing', () {
      const rawUrl =
          'https://example.com/api, {"method":"POST", "body": "q={{key}}", "headers": {"X-Test": "Value"}}';
      final analyzer = AnalyzeUrl(rawUrl, key: 'novel');

      expect(analyzer.url, 'https://example.com/api');
      expect(analyzer.method, 'POST');
      expect(analyzer.body, 'q=novel');
      expect(analyzer.headerMap['X-Test'], 'Value');
    });

    test('Relative URL resolution', () {
      final analyzer = AnalyzeUrl(
        'search.php?q={{key}}',
        key: 'novel',
        baseUrl: 'https://example.com/path/',
      );
      expect(analyzer.url, 'https://example.com/path/search.php?q=novel');
    });

    test('Relative URL resolution falls back to source base url', () {
      final analyzer = AnalyzeUrl(
        '/search?q={{key}}',
        key: 'novel',
        source: BookSource(bookSourceUrl: 'https://example.com/root/'),
      );
      expect(analyzer.url, 'https://example.com/search?q=novel');
    });

    test('Inline @js receives URL prefix as result', () {
      final analyzer = AnalyzeUrl(
        'https://example.com/search?q={{key}}\n@js:result',
        key: 'novel',
      );
      expect(analyzer.url, 'https://example.com/search?q=novel');
    });

    test('WebView flag detection', () {
      final analyzer = AnalyzeUrl('https://example.com, {"webView": true}');
      expect(analyzer.useWebView, true);
    });

    test('Source header supports @js JSON stringify and source.key alias', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final analyzer = AnalyzeUrl(
        'https://example.com/api',
        source: BookSource(
          bookSourceUrl: 'https://source.example.com',
          header: '@js:JSON.stringify({Referer: source.key})',
        ),
      );

      expect(analyzer.headerMap['Referer'], 'https://source.example.com');
    });

    test('Lenient JS-style url options are supported', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final analyzer = AnalyzeUrl(
        '''
https://example.com/api,{
  "method": "POST",
  "body": 'keyword={{key}}&page={{page}}',
  "headers": { "X-Test": "Value" }
}
''',
        key: 'novel',
        page: 2,
      );

      expect(analyzer.url, 'https://example.com/api');
      expect(analyzer.method, 'POST');
      expect(analyzer.body, 'keyword=novel&page=2');
      expect(analyzer.headerMap['X-Test'], 'Value');
    });

    test('POST string body defaults to form content-type', () {
      final analyzer = AnalyzeUrl(
        'https://example.com/search, {"method":"POST", "body":"searchkey={{key}}"}',
        key: '龙族',
      );

      final headers = analyzer.buildRequestHeadersForTesting();
      expect(
        headers['Content-Type'],
        'application/x-www-form-urlencoded; charset=utf-8',
      );
    });
  });
}
