import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/chapter.dart';

import '../../tool/source_validation_support.dart';

void main() {
  group('source validation support', () {
    test(
      'content probes prefer unlocked chapters and include tail fallback',
      () {
        final chapters = <BookChapter>[
          BookChapter(title: '🔒最新章', url: '/1'),
          BookChapter(title: '🔒次新章', url: '/2'),
          BookChapter(title: '中间章', url: '/3'),
          BookChapter(title: '尾章一', url: '/4'),
          BookChapter(title: '尾章二', url: '/5'),
        ];

        final indexes = buildContentProbeIndexes(chapters, 2);

        expect(indexes, [3, 4, 0, 1]);
      },
    );

    test(
      'neighbor probes prefer adjacent unlocked chapters before locked ones',
      () {
        final chapters = <BookChapter>[
          BookChapter(title: '第1章', url: '/1'),
          BookChapter(title: '🔒第2章', url: '/2'),
          BookChapter(title: '第3章', url: '/3'),
          BookChapter(title: '第4章', url: '/4'),
          BookChapter(title: '🔒第5章', url: '/5'),
        ];

        final indexes = buildNeighborProbeIndexes(chapters, 2, 2);

        expect(indexes, [3, 0, 4, 1]);
      },
    );

    test('locked chapter heuristic matches vip markers', () {
      expect(
        isLikelyLockedChapter(BookChapter(title: '🔒章节', url: '/1')),
        isTrue,
      );
      expect(
        isLikelyLockedChapter(
          BookChapter(title: '普通章节', url: '/2', isVip: true),
        ),
        isTrue,
      );
      expect(
        isLikelyLockedChapter(BookChapter(title: '普通章节', url: '/3')),
        isFalse,
      );
    });

    test(
      'keyword candidates split normalized book names into searchable terms',
      () {
        final keywords = buildKeywordCandidates('《我的徒儿，竟然全是反派！》');

        expect(
          keywords,
          containsAll(<String>[
            '《我的徒儿，竟然全是反派！》',
            '我的徒儿 竟然全是反派',
            '我的徒儿竟然全是反派',
            '我的徒儿',
            '我的徒儿竟然',
          ]),
        );
      },
    );

    test('decodeSourcesPayload accepts a single source object', () {
      final sources = decodeSourcesPayload('''
      {
        "bookSourceName": "八叉书库",
        "bookSourceUrl": "https://bcshuku.com/",
        "ruleSearch": {
          "bookList": ".item",
          "name": ".title@text",
          "bookUrl": ".title@href"
        }
      }
      ''');

      expect(sources, hasLength(1));
      expect(sources.first.bookSourceName, '八叉书库');
      expect(sources.first.bookSourceUrl, 'https://bcshuku.com/');
    });

    test(
      'normalizeSourcesPayload extracts trailing JSON after html error page',
      () {
        final payload = normalizeSourcesPayload('''
      <!DOCTYPE html>
      <html><body><h1>Gateway Timeout</h1></body></html>
      [
        {
          "bookSourceName": "八叉书库",
          "bookSourceUrl": "https://bcshuku.com/"
        }
      ]
      ''');

        expect(payload.trimLeft(), startsWith('['));
        final sources = decodeSourcesPayload(payload);
        expect(sources, hasLength(1));
        expect(sources.first.bookSourceName, '八叉书库');
      },
    );

    test('normalizeSourcesPayload rejects non-json payloads', () {
      expect(
        () => normalizeSourcesPayload('<html><body>bad gateway</body></html>'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
