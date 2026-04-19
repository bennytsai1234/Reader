import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/source_type.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/models/source/book_source_rules.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';

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

    test('classification marks search-broken sources as skipped', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: '失效源',
        bookSourceGroup: '搜尋失效',
      );

      final result = classifyValidationFailure(
        StateError('搜尋 "測試" 沒有結果'),
        source: source,
        stage: 'search',
      );

      expect(result.outcome, SourceValidationOutcome.skip);
      expect(result.category, 'source-marked-broken');
    });

    test('classification keeps parser issues actionable', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: '普通源',
      );

      final result = classifyValidationFailure(
        const FormatException('Illegal scheme character'),
        source: source,
        stage: 'toc',
      );

      expect(result.outcome, SourceValidationOutcome.fail);
      expect(result.category, 'app-or-parser');
    });

    test('classification skips certificate and handshake failures', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: '憑證過期源',
      );

      final result = classifyValidationFailure(
        StateError(
          'DioException [unknown]: null HandshakeException: '
          'CERTIFICATE_VERIFY_FAILED',
        ),
        source: source,
        stage: 'keyword',
      );

      expect(result.outcome, SourceValidationOutcome.skip);
      expect(result.category, 'upstream-timeout');
    });

    test('classification skips missing webview platform in test env', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: '需要 WebView 的書源',
      );

      final result = classifyValidationFailure(
        StateError(
          "'package:webview_flutter_platform_interface/src/platform_webview_controller.dart': "
          "Failed assertion: line 27 pos 7: 'WebViewPlatform.instance != null'",
        ),
        source: source,
        stage: 'keyword',
      );

      expect(result.outcome, SourceValidationOutcome.skip);
      expect(result.category, 'env-webview');
    });

    test('classification skips missing path provider plugin in test env', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: '需要 path provider 的書源',
      );

      final result = classifyValidationFailure(
        StateError(
          'RuleJsError: MissingPluginException(No implementation found for '
          'method getTemporaryDirectory on channel plugins.flutter.io/path_provider)',
        ),
        source: source,
        stage: 'keyword',
      );

      expect(result.outcome, SourceValidationOutcome.skip);
      expect(result.category, 'env-path-provider');
    });

    test('classification skips search results that miss the keyword', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: '搜尋錯書源',
      );

      final result = classifyValidationFailure(
        StateError('搜尋結果未命中關鍵詞 "剑来"'),
        source: source,
        stage: 'search',
      );

      expect(result.outcome, SourceValidationOutcome.skip);
      expect(result.category, 'source-search-mismatch');
    });

    test(
      'validation flow skips non-novel sources before network work',
      () async {
        final source = BookSource(
          bookSourceUrl: 'https://audio.example.com',
          bookSourceName: '有聲站',
          bookSourceType: SourceType.audio,
        );

        final result = await validateSourceFlow(
          BookSourceService(),
          source,
          index: 3,
        );

        expect(result.outcome, SourceValidationOutcome.skip);
        expect(result.category, 'non-novel-source');
        expect(result.stage, 'source-filter');
      },
    );

    test('validation keyword matches legado check source behavior', () {
      final sourceWithCheckKeyword = BookSource(
        bookSourceUrl: 'https://example.com/check',
        bookSourceName: '自帶校驗詞',
        ruleSearch: SearchRule(checkKeyWord: '龙王殿'),
      );
      final sourceWithoutCheckKeyword = BookSource(
        bookSourceUrl: 'https://example.com/default',
        bookSourceName: '預設校驗詞',
      );

      expect(resolveValidationKeyword(sourceWithCheckKeyword), '龙王殿');
      expect(
        resolveValidationKeyword(sourceWithoutCheckKeyword),
        legadoValidationDefaultKeyword,
      );
    });

    test(
      'matching search book prefers a keyword hit over the first result',
      () {
        final searchBooks = <SearchBook>[
          SearchBook(
            name: '一念神魔.',
            author: '水泽',
            bookUrl: 'https://example.com/book/1',
            origin: 'https://example.com/source',
          ),
          SearchBook(
            name: '剑来',
            author: '烽火戏诸侯',
            bookUrl: 'https://example.com/book/2',
            origin: 'https://example.com/source',
          ),
        ];

        final matched = selectMatchingSearchBook(searchBooks, '剑来');

        expect(matched?.name, '剑来');
        expect(matched?.bookUrl, 'https://example.com/book/2');
      },
    );

    test(
      'matching search book returns null when no result matches keyword',
      () {
        final searchBooks = <SearchBook>[
          SearchBook(
            name: '一念神魔.',
            author: '水泽',
            bookUrl: 'https://example.com/book/1',
            origin: 'https://example.com/source',
          ),
        ];

        expect(selectMatchingSearchBook(searchBooks, '剑来'), isNull);
      },
    );
  });
}
