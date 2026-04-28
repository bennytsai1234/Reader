import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
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
import 'package:inkpage_reader/core/services/reader_chapter_content_store.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';

class _FakeBookDao extends Fake implements BookDao {}

class _FakeChapterDao implements ChapterDao {
  _FakeChapterDao(this.chapterList);

  final List<BookChapter> chapterList;

  @override
  Future<List<BookChapter>> getByBook(String bookUrl) async => chapterList;

  @override
  Future<void> insertChapters(List<BookChapter> chapterList) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSourceDao implements BookSourceDao {
  _FakeSourceDao(this.source);

  final BookSource? source;

  @override
  Future<BookSource?> getByUrl(String url) async => source;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeReplaceRuleDao implements ReplaceRuleDao {
  @override
  Future<List<ReplaceRule>> getEnabled() async => const <ReplaceRule>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeContentDao implements ReaderChapterContentDao {
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
  Future<bool> hasReadyContent({required String contentKey}) async {
    final entry = entries[contentKey];
    return entry != null && entry.isReady && entry.hasDisplayContent;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _QueuedContentDao extends _FakeContentDao {
  _QueuedContentDao(this.getEntryCalls);

  final List<Completer<ReaderChapterContentEntry?>> getEntryCalls;

  @override
  Future<ReaderChapterContentEntry?> getEntry({required String contentKey}) {
    if (getEntryCalls.isEmpty) return super.getEntry(contentKey: contentKey);
    return getEntryCalls.removeAt(0).future;
  }
}

class _FakeBookSourceService extends Fake implements BookSourceService {
  _FakeBookSourceService(this.responses);

  final List<Object> responses;
  int contentCalls = 0;

  @override
  Future<String> getContent(
    BookSource source,
    Book book,
    BookChapter chapter, {
    String? nextChapterUrl,
    int? pageConcurrency,
  }) async {
    final response =
        responses[contentCalls.clamp(0, responses.length - 1).toInt()];
    contentCalls += 1;
    if (response is Future<String>) return response;
    if (response is Exception) throw response;
    return response as String;
  }
}

Book _book() => Book(
  bookUrl: 'book-url',
  origin: 'source-url',
  name: 'Book',
  author: 'Author',
);

BookChapter _chapter() => BookChapter(
  title: 'Chapter 1',
  index: 0,
  bookUrl: 'book-url',
  url: 'chapter-url',
);

ChapterRepository _repository({
  required Book book,
  required List<BookChapter> chapters,
  required _FakeContentDao contentDao,
  required _FakeBookSourceService service,
  BookSource? source,
  bool sourceMissing = false,
}) {
  return ChapterRepository(
    book: book,
    initialChapters: chapters,
    bookDao: _FakeBookDao(),
    chapterDao: _FakeChapterDao(chapters),
    sourceDao: _FakeSourceDao(
      sourceMissing ? null : source ?? BookSource(bookSourceUrl: book.origin),
    ),
    contentDao: contentDao,
    replaceDao: _FakeReplaceRuleDao(),
    service: service,
  );
}

void main() {
  group('ChapterRepository shared content store contract', () {
    test('content store hit does not call remote service', () async {
      final book = _book();
      final chapter = _chapter();
      final contentDao = _FakeContentDao();
      final store = ReaderChapterContentStore(
        chapterDao: _FakeChapterDao(<BookChapter>[chapter]),
        contentDao: contentDao,
      );
      await store.saveRawContent(
        book: book,
        chapter: chapter,
        content: 'downloaded chapter body',
      );
      final service = _FakeBookSourceService(<Object>['remote body']);

      final content = await _repository(
        book: book,
        chapters: <BookChapter>[chapter],
        contentDao: contentDao,
        service: service,
      ).loadContent(0);

      expect(content.plainText, 'downloaded chapter body');
      expect(service.contentCalls, 0);
    });

    test(
      'content store miss loads through storage pipeline and saves',
      () async {
        final book = _book();
        final chapter = _chapter();
        final contentDao = _FakeContentDao();
        final service = _FakeBookSourceService(<Object>['remote chapter body']);

        final content = await _repository(
          book: book,
          chapters: <BookChapter>[chapter],
          contentDao: contentDao,
          service: service,
        ).loadContent(0);

        final key = ReaderChapterContentStore.contentKeyFor(
          book: book,
          chapter: chapter,
        );
        expect(content.plainText, 'remote chapter body');
        expect(contentDao.entries[key]?.content, 'remote chapter body');
        expect(service.contentCalls, 1);
      },
    );

    test('failed content entry is displayed without retry loop', () async {
      final book = _book();
      final chapter = _chapter();
      final contentDao = _FakeContentDao();
      await contentDao.saveFailure(
        contentKey: ReaderChapterContentStore.contentKeyFor(
          book: book,
          chapter: chapter,
        ),
        origin: book.origin,
        bookUrl: book.bookUrl,
        chapterUrl: chapter.url,
        chapterIndex: chapter.index,
        message: '加載章節失敗: timeout',
        updatedAt: 1,
      );
      final service = _FakeBookSourceService(<Object>['remote body']);
      final repository = _repository(
        book: book,
        chapters: <BookChapter>[chapter],
        contentDao: contentDao,
        service: service,
      );

      final first = await repository.loadContent(0);
      final second = await repository.loadContent(0);

      expect(first.plainText, '加載章節失敗: timeout');
      expect(second.plainText, '加載章節失敗: timeout');
      expect(service.contentCalls, 0);
    });

    test(
      'clearContentCache prevents stale in-flight load from repopulating cache',
      () async {
        final book = _book();
        final chapter = _chapter();
        final firstEntry = Completer<ReaderChapterContentEntry?>();
        final secondEntry = Completer<ReaderChapterContentEntry?>();
        final contentDao = _QueuedContentDao(
          <Completer<ReaderChapterContentEntry?>>[firstEntry, secondEntry],
        );
        final repository = _repository(
          book: book,
          chapters: <BookChapter>[chapter],
          contentDao: contentDao,
          service: _FakeBookSourceService(<Object>['unused']),
        );

        final staleLoad = repository.loadContent(0);
        await Future<void>.delayed(Duration.zero);
        repository.clearContentCache();
        final freshLoad = repository.loadContent(0);
        await Future<void>.delayed(Duration.zero);

        secondEntry.complete(_storedEntry(book, chapter, 'fresh body'));
        final freshContent = await freshLoad;
        expect(freshContent.plainText, 'fresh body');
        expect(repository.cachedContent(0)?.plainText, 'fresh body');

        firstEntry.complete(_storedEntry(book, chapter, 'stale body'));
        final staleContent = await staleLoad;
        expect(staleContent.plainText, 'stale body');
        expect(repository.cachedContent(0)?.plainText, 'fresh body');
      },
    );

    test(
      'ensureChapters reports missing source instead of empty ready TOC',
      () {
        final book = _book();
        final repository = _repository(
          book: book,
          chapters: <BookChapter>[],
          contentDao: _FakeContentDao(),
          service: _FakeBookSourceService(<Object>['unused']),
          sourceMissing: true,
        );

        expect(
          repository.ensureChapters(),
          throwsA(
            isA<ChapterRepositoryException>().having(
              (error) => error.message,
              'message',
              '章節目錄載入失敗: 找不到書源',
            ),
          ),
        );
      },
    );
  });
}

ReaderChapterContentEntry _storedEntry(
  Book book,
  BookChapter chapter,
  String content,
) {
  return ReaderChapterContentEntry(
    contentKey: ReaderChapterContentStore.contentKeyFor(
      book: book,
      chapter: chapter,
    ),
    origin: book.origin,
    bookUrl: book.bookUrl,
    chapterUrl: chapter.url,
    chapterIndex: chapter.index,
    status: ReaderChapterContentStatus.ready,
    content: content,
    updatedAt: 1,
  );
}
