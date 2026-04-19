import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/explore_url_parser.dart';
import 'package:inkpage_reader/core/models/book_source.dart';

void main() {
  group('ExploreUrlParser', () {
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
  });
}
