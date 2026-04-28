import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/reader_chapter_content.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_content_preparation_pipeline.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_store.dart';

class _FakeChapterDao implements ChapterDao {
  @override
  Future<void> insertChapters(List<BookChapter> chapterList) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeContentDao implements ReaderChapterContentDao {
  final Map<String, ReaderChapterContentEntry> entries =
      <String, ReaderChapterContentEntry>{};

  @override
  Future<String?> getContent({required String contentKey}) async {
    return entries[contentKey]?.content;
  }

  @override
  Future<ReaderChapterContentEntry?> getEntry({
    required String contentKey,
  }) async {
    return entries[contentKey];
  }

  @override
  Future<bool> hasReadyContent({required String contentKey}) async {
    final entry = entries[contentKey];
    return entry != null && entry.isReady && entry.hasDisplayContent;
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
  Future<void> deleteContent({required String contentKey}) async {
    entries.remove(contentKey);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSourceDao implements BookSourceDao {
  _FakeSourceDao(this.source);

  final BookSource source;

  @override
  Future<BookSource?> getByUrl(String url) async => source;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
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
    int? pageConcurrency,
    String? nextChapterUrl,
  }) async {
    final response =
        responses[contentCalls.clamp(0, responses.length - 1).toInt()];
    contentCalls++;
    if (response is Exception) throw response;
    return response as String;
  }
}

Book _book() =>
    Book(bookUrl: 'book-1', origin: 'source-1', name: 'Book', author: 'Author');

BookChapter _chapter() => BookChapter(
  title: 'Chapter',
  index: 0,
  url: 'chapter-1',
  bookUrl: 'book-1',
);

void main() {
  group('ChapterContentPreparationPipeline', () {
    test('storage ready 時直接回傳，不打書源', () async {
      final book = _book();
      final chapter = _chapter();
      final contentDao = _FakeContentDao();
      final store = ReaderChapterContentStore(
        chapterDao: _FakeChapterDao(),
        contentDao: contentDao,
      );
      await store.saveRawContent(
        book: book,
        chapter: chapter,
        content: 'stored raw',
      );
      final service = _FakeBookSourceService(<Object>['remote raw']);
      final pipeline = ChapterContentPreparationPipeline(
        book: book,
        contentStore: store,
        sourceDao: _FakeSourceDao(BookSource(bookSourceUrl: 'source-1')),
        service: service,
      );

      final result = await pipeline.prepare(chapterIndex: 0, chapter: chapter);

      expect(result.isReady, isTrue);
      expect(result.content, 'stored raw');
      expect(service.contentCalls, 0);
    });

    test('抓取失敗會寫 failed 狀態，forceRefresh 可重新抓取', () async {
      final book = _book();
      final chapter = _chapter();
      final contentDao = _FakeContentDao();
      final store = ReaderChapterContentStore(
        chapterDao: _FakeChapterDao(),
        contentDao: contentDao,
      );
      final service = _FakeBookSourceService(<Object>[
        Exception('timeout'),
        'remote raw',
      ]);
      final pipeline = ChapterContentPreparationPipeline(
        book: book,
        contentStore: store,
        sourceDao: _FakeSourceDao(BookSource(bookSourceUrl: 'source-1')),
        service: service,
      );

      final failed = await pipeline.prepare(chapterIndex: 0, chapter: chapter);
      expect(failed.isFailed, isTrue);

      final failedEntry = await store.getContentEntry(
        book: book,
        chapter: chapter,
      );
      expect(failedEntry?.isFailed, isTrue);

      final retried = await pipeline.prepare(
        chapterIndex: 0,
        chapter: chapter,
        forceRefresh: true,
      );

      expect(retried.isReady, isTrue);
      expect(retried.content, 'remote raw');
      expect(service.contentCalls, 2);
    });

    test('本地書籍讀取錯誤會寫 failed 狀態', () async {
      final missingPath =
          '${Directory.systemTemp.path}/inkpage-reader-missing-${DateTime.now().microsecondsSinceEpoch}.txt';
      final book = Book(
        bookUrl: 'local://$missingPath',
        origin: 'local',
        name: 'Local Book',
        author: 'Author',
      );
      final chapter = BookChapter(
        title: 'Chapter',
        index: 0,
        url: 'local-chapter',
        bookUrl: book.bookUrl,
      );
      final contentDao = _FakeContentDao();
      final store = ReaderChapterContentStore(
        chapterDao: _FakeChapterDao(),
        contentDao: contentDao,
      );
      final pipeline = ChapterContentPreparationPipeline(
        book: book,
        contentStore: store,
        sourceDao: _FakeSourceDao(BookSource(bookSourceUrl: 'source-1')),
        service: _FakeBookSourceService(<Object>['unused']),
      );

      final result = await pipeline.prepare(chapterIndex: 0, chapter: chapter);
      final entry = await store.getContentEntry(book: book, chapter: chapter);

      expect(result.isFailed, isTrue);
      expect(result.content, startsWith('檔案不存在:'));
      expect(entry?.isFailed, isTrue);
      expect(entry?.content, startsWith('檔案不存在:'));
    });
  });
}
