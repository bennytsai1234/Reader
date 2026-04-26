import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/reader_chapter_content.dart';
import 'package:inkpage_reader/core/services/chapter_content_preparation_pipeline.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_storage.dart';
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

Book _book() =>
    Book(bookUrl: 'book-1', origin: 'source-1', name: 'Book', author: 'Author');

BookChapter _chapter() => BookChapter(
  title: 'Chapter',
  index: 0,
  url: 'chapter-1',
  bookUrl: 'book-1',
);

void main() {
  group('ReaderChapterContentStorage', () {
    test('ready content 直接從 storage 回傳，不啟動 materialize', () async {
      final book = _book();
      final chapter = _chapter();
      final store = ReaderChapterContentStore(
        chapterDao: _FakeChapterDao(),
        contentDao: _FakeContentDao(),
      );
      await store.saveRawContent(
        book: book,
        chapter: chapter,
        content: 'stored raw',
      );
      var materializeCalls = 0;
      final storage = ReaderChapterContentStorage(
        book: book,
        contentStore: store,
        materialize: ({
          required chapterIndex,
          required chapter,
          sourceOverride,
          required forceRefresh,
          required saveChapterMetadata,
          required maxAttempts,
        }) async {
          materializeCalls++;
          return ChapterContentPreparationResult.ready('remote raw');
        },
      );

      final result = await storage.read(chapterIndex: 0, chapter: chapter);

      expect(result.isReady, isTrue);
      expect(result.content, 'stored raw');
      expect(materializeCalls, 0);
    });

    test('missing content 先 materialize，再從 storage 讀回', () async {
      final book = _book();
      final chapter = _chapter();
      final store = ReaderChapterContentStore(
        chapterDao: _FakeChapterDao(),
        contentDao: _FakeContentDao(),
      );
      var materializeCalls = 0;
      final storage = ReaderChapterContentStorage(
        book: book,
        contentStore: store,
        materialize: ({
          required chapterIndex,
          required chapter,
          sourceOverride,
          required forceRefresh,
          required saveChapterMetadata,
          required maxAttempts,
        }) async {
          materializeCalls++;
          await store.saveRawContent(
            book: book,
            chapter: chapter,
            content: 'stored after materialize',
          );
          return ChapterContentPreparationResult.ready('materialized raw');
        },
      );

      final result = await storage.read(chapterIndex: 0, chapter: chapter);

      expect(result.isReady, isTrue);
      expect(result.content, 'stored after materialize');
      expect(materializeCalls, 1);
    });

    test('same contentKey 的並行 request 只 materialize 一次', () async {
      final book = _book();
      final chapter = _chapter();
      final store = ReaderChapterContentStore(
        chapterDao: _FakeChapterDao(),
        contentDao: _FakeContentDao(),
      );
      final completer = Completer<ChapterContentPreparationResult>();
      var materializeCalls = 0;
      final storage = ReaderChapterContentStorage(
        book: book,
        contentStore: store,
        materialize: ({
          required chapterIndex,
          required chapter,
          sourceOverride,
          required forceRefresh,
          required saveChapterMetadata,
          required maxAttempts,
        }) {
          materializeCalls++;
          return completer.future;
        },
      );

      final first = storage.read(chapterIndex: 0, chapter: chapter);
      final second = storage.read(chapterIndex: 0, chapter: chapter);
      await Future<void>.delayed(Duration.zero);

      await store.saveRawContent(
        book: book,
        chapter: chapter,
        content: 'deduped raw',
      );
      completer.complete(ChapterContentPreparationResult.ready('ignored raw'));

      expect((await first).content, 'deduped raw');
      expect((await second).content, 'deduped raw');
      expect(materializeCalls, 1);
    });
  });
}
