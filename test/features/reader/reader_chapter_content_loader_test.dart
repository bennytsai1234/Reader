import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_loader.dart';

class _FakeChapterDao extends Fake implements ChapterDao {
  _FakeChapterDao({Map<String, String> contents = const {}})
    : _contents = Map<String, String>.from(contents);

  final Map<String, String> _contents;
  int getContentCallCount = 0;

  @override
  Future<String?> getContent(String url) async {
    getContentCallCount++;
    return _contents[url];
  }
}

class _FakeReplaceRuleDao extends Fake implements ReplaceRuleDao {
  @override
  Future<List<ReplaceRule>> getEnabled() async => const <ReplaceRule>[];
}

class _FakeBookSourceDao extends Fake implements BookSourceDao {
  _FakeBookSourceDao(this.source);

  final BookSource? source;
  int lookupCount = 0;

  @override
  Future<BookSource?> getByUrl(String url) async {
    lookupCount++;
    return source;
  }
}

class _FakeBookSourceService extends BookSourceService {
  _FakeBookSourceService(this.response);

  final String response;
  int getContentCallCount = 0;

  @override
  Future<String> getContent(
    BookSource source,
    Book book,
    BookChapter chapter, {
    String? nextChapterUrl,
  }) async {
    getContentCallCount++;
    return response;
  }
}

void main() {
  group('ReaderChapterContentLoader', () {
    test(
      'prefers chapter dao cache before source lookup and remote fetch',
      () async {
        final chapterDao = _FakeChapterDao(
          contents: <String, String>{'https://example.com/c1': '快取正文'},
        );
        final sourceDao = _FakeBookSourceDao(
          BookSource(
            bookSourceUrl: 'https://source.example.com',
            bookSourceName: '測試書源',
          ),
        );
        final service = _FakeBookSourceService('遠端正文');
        final loader = ReaderChapterContentLoader(
          book: Book(
            bookUrl: 'https://example.com/book',
            origin: 'https://source.example.com',
            name: '測試書籍',
          ),
          chapterDao: chapterDao,
          replaceDao: _FakeReplaceRuleDao(),
          sourceDao: sourceDao,
          service: service,
          currentChineseConvert: () => 0,
          getSource: () => null,
          setSource: (_) {},
        );

        final result = await loader.load(
          0,
          BookChapter(
            url: 'https://example.com/c1',
            bookUrl: 'https://example.com/book',
            title: '第1章',
            index: 0,
          ),
        );

        expect(result.content, contains('快取正文'));
        expect(chapterDao.getContentCallCount, 1);
        expect(sourceDao.lookupCount, 0);
        expect(service.getContentCallCount, 0);
      },
    );

    test('falls back to remote source when cache is missing', () async {
      final chapterDao = _FakeChapterDao();
      final sourceDao = _FakeBookSourceDao(
        BookSource(
          bookSourceUrl: 'https://source.example.com',
          bookSourceName: '測試書源',
        ),
      );
      final service = _FakeBookSourceService('遠端正文');
      final loader = ReaderChapterContentLoader(
        book: Book(
          bookUrl: 'https://example.com/book',
          origin: 'https://source.example.com',
          name: '測試書籍',
        ),
        chapterDao: chapterDao,
        replaceDao: _FakeReplaceRuleDao(),
        sourceDao: sourceDao,
        service: service,
        currentChineseConvert: () => 0,
        getSource: () => null,
        setSource: (_) {},
      );

      final result = await loader.load(
        0,
        BookChapter(
          url: 'https://example.com/c1',
          bookUrl: 'https://example.com/book',
          title: '第1章',
          index: 0,
        ),
      );

      expect(result.content, contains('遠端正文'));
      expect(chapterDao.getContentCallCount, 1);
      expect(sourceDao.lookupCount, 1);
      expect(service.getContentCallCount, 1);
    });
  });
}
