import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/explore_url_parser.dart';
import 'package:inkpage_reader/core/models/book_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExploreUrlParser', () {
    test('parseAsync caches js explore results per source', () async {
      const exploreRule = '''
        <js>
        JSON.stringify([
          {"title":"最新","url":"https://example.com/new"}
        ])
        </js>
      ''';
      final source = BookSource(
        bookSourceUrl: 'https://cache.example.com',
        bookSourceName: '快取測試源',
        exploreUrl: exploreRule,
      );
      await ExploreUrlParser.clearCache(source, exploreUrl: exploreRule);
      addTearDown(
        () => ExploreUrlParser.clearCache(source, exploreUrl: exploreRule),
      );

      var jsCalls = 0;
      final first = await ExploreUrlParser.parseAsync(
        exploreRule,
        source: source,
        jsExecutor: (_) async {
          jsCalls++;
          return '[{"title":"最新","url":"https://example.com/new"}]';
        },
      );

      final second = await ExploreUrlParser.parseAsync(
        exploreRule,
        source: source,
        jsExecutor: (_) async {
          jsCalls++;
          return '[{"title":"熱門","url":"https://example.com/hot"}]';
        },
      );

      expect(jsCalls, 1);
      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(second.first.title, '最新');
      expect(second.first.url, 'https://example.com/new');
    });

    test('parseAsync supports static explore definitions', () async {
      final kinds = await ExploreUrlParser.parseAsync('''
        最新::https://example.com/new
        熱門::https://example.com/hot
      ''');

      expect(kinds, hasLength(2));
      expect(kinds[0].title, '最新');
      expect(kinds[0].url, 'https://example.com/new');
      expect(kinds[1].title, '熱門');
      expect(kinds[1].url, 'https://example.com/hot');
    });

    test('parseAsync awaits js explore definitions', () async {
      final source = BookSource(
        bookSourceUrl: 'https://bbxxxx.com',
        bookSourceName: 'BB成人小说',
      );

      final kinds = await ExploreUrlParser.parseAsync(
        '''
        <js>
        let html = java.ajax("https://bbxxxx.com/");
        JSON.stringify([
          {"title":"最新","url":"https://bbxxxx.com/rank/new/{{page}}.html"},
          {"title":"熱門","url":"https://bbxxxx.com/rank/hot/{{page}}.html"}
        ])
        </js>
        ''',
        source: source,
        jsExecutor: (jsSource) async {
          expect(jsSource, contains('java.ajax("https://bbxxxx.com/")'));
          return '''
          [
            {"title":"最新","url":"https://bbxxxx.com/rank/new/{{page}}.html"},
            {"title":"熱門","url":"https://bbxxxx.com/rank/hot/{{page}}.html"}
          ]
          ''';
        },
      );

      expect(kinds, hasLength(2));
      expect(kinds[0].title, '最新');
      expect(kinds[0].url, 'https://bbxxxx.com/rank/new/{{page}}.html');
      expect(kinds[1].title, '熱門');
      expect(kinds[1].url, 'https://bbxxxx.com/rank/hot/{{page}}.html');
    });

    test('parseAsync parses JSON object strings returned by js rules', () async {
      final kinds = await ExploreUrlParser.parseAsync(
        '@js: JSON.stringify({"title":"推薦","url":"https://example.com/recommend"})',
        jsExecutor:
            (_) async => '{"title":"推薦","url":"https://example.com/recommend"}',
      );

      expect(kinds, hasLength(1));
      expect(kinds.first.title, '推薦');
      expect(kinds.first.url, 'https://example.com/recommend');
    });

    test('parseAsync flattens mixed lists returned by js rules', () async {
      final kinds = await ExploreUrlParser.parseAsync(
        '@js: ""',
        jsExecutor:
            (_) async => <dynamic>[
              {'title': '最新', 'url': 'https://example.com/new'},
              '{"title":"排行","url":"https://example.com/rank"}',
            ],
      );

      expect(kinds, hasLength(2));
      expect(kinds[0].title, '最新');
      expect(kinds[1].title, '排行');
    });

    test('parseAsync surfaces js runtime errors as error kinds', () async {
      final kinds = await ExploreUrlParser.parseAsync(
        '@js: java.ajax("https://example.com/explore")',
        source: BookSource(
          bookSourceUrl: 'https://error.example.com',
          bookSourceName: '錯誤源',
        ),
        jsExecutor: (_) async => 'JS_ERROR: Library not available',
      );

      expect(kinds, hasLength(1));
      expect(kinds.first.title, startsWith('ERROR:'));
      expect(kinds.first.url, contains('JS_ERROR:'));
    });
  });
}
