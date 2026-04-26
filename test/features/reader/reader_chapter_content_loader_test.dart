import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/reader_chapter_content.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_loader.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_store.dart';

class _FakeReplaceRuleDao implements ReplaceRuleDao {
  @override
  Future<List<ReplaceRule>> getEnabled() async => const <ReplaceRule>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookSourceDao implements BookSourceDao {
  _FakeBookSourceDao(this.source);

  final BookSource source;

  @override
  Future<BookSource?> getByUrl(String url) async => source;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookSourceService extends Fake implements BookSourceService {
  @override
  Future<String> getContent(
    BookSource source,
    Book book,
    BookChapter chapter, {
    int? pageConcurrency,
    String? nextChapterUrl,
  }) async {
    return '正文第一行\n正文第二行';
  }
}

class _FakeChapterDao implements ChapterDao {
  @override
  Future<void> insertChapters(List<BookChapter> chapterList) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChapterContentDao implements ReaderChapterContentDao {
  final Map<String, ReaderChapterContentEntry> entries =
      <String, ReaderChapterContentEntry>{};

  @override
  Future<ReaderChapterContentEntry?> getEntry({
    required String contentKey,
  }) async {
    return entries[contentKey];
  }

  @override
  Future<void> saveContent({
    required String contentKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required String content,
    required int updatedAt,
    ReaderChapterContentStatus status = ReaderChapterContentStatus.ready,
    String? failureMessage,
  }) async {
    entries[contentKey] = ReaderChapterContentEntry(
      contentKey: contentKey,
      origin: origin,
      bookUrl: bookUrl,
      chapterUrl: chapterUrl,
      chapterIndex: chapterIndex,
      status: status,
      content: content,
      failureMessage: failureMessage,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> saveFailure({
    required String contentKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required String message,
    required int updatedAt,
  }) {
    return saveContent(
      contentKey: contentKey,
      origin: origin,
      bookUrl: bookUrl,
      chapterUrl: chapterUrl,
      chapterIndex: chapterIndex,
      content: message,
      updatedAt: updatedAt,
      status: ReaderChapterContentStatus.failed,
      failureMessage: message,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('ReaderChapterContentLoader', () {
    test('load 不會把 displayTitle 再拼回正文內容', () async {
      final chapter = BookChapter(
        title: '第二章 測試章節',
        index: 1,
        url: 'chapter-1',
        bookUrl: 'book-1',
      );
      final source = BookSource(
        bookSourceUrl: 'remote',
        bookSourceName: 'Remote',
      );
      final book = Book(
        bookUrl: 'book-1',
        name: 'Book',
        author: 'Author',
        origin: 'remote',
      );
      final loader = ReaderChapterContentLoader(
        book: book,
        contentStore: ReaderChapterContentStore(
          chapterDao: _FakeChapterDao(),
          contentDao: _FakeChapterContentDao(),
        ),
        replaceDao: _FakeReplaceRuleDao(),
        sourceDao: _FakeBookSourceDao(source),
        service: _FakeBookSourceService(),
        currentChineseConvert: () => 0,
        getSource: () => null,
        setSource: (_) {},
      );

      final result = await loader.load(1, chapter);

      expect(result.displayTitle, '第二章 測試章節');
      expect(result.content.startsWith('第二章 測試章節\n'), isFalse);
      expect(result.content, contains('正文第一行'));
      expect(result.content, contains('正文第二行'));
    });
  });
}
