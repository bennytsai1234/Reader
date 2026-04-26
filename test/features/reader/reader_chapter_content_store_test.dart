import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/reader_chapter_content.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_store.dart';

class _FakeChapterDao implements ChapterDao {
  final List<List<BookChapter>> insertedBatches = <List<BookChapter>>[];

  @override
  Future<void> insertChapters(List<BookChapter> chapterList) async {
    insertedBatches.add(List<BookChapter>.from(chapterList));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChapterContentDao implements ReaderChapterContentDao {
  final Map<String, String> contentByKey = <String, String>{};
  final Map<String, int> indexByKey = <String, int>{};
  final Map<String, ReaderChapterContentStatus> statusByKey =
      <String, ReaderChapterContentStatus>{};

  @override
  Future<String?> getContent({required String contentKey}) async {
    return contentByKey[contentKey];
  }

  @override
  Future<ReaderChapterContentEntry?> getEntry({
    required String contentKey,
  }) async {
    final content = contentByKey[contentKey];
    final index = indexByKey[contentKey];
    if (content == null || index == null) return null;
    return ReaderChapterContentEntry(
      contentKey: contentKey,
      origin: 'https://source.example',
      bookUrl: 'https://example.com/book/1',
      chapterUrl: contentKey,
      chapterIndex: index,
      status: statusByKey[contentKey] ?? ReaderChapterContentStatus.ready,
      content: content,
      failureMessage:
          statusByKey[contentKey] == ReaderChapterContentStatus.failed
              ? content
              : null,
      updatedAt: 1,
    );
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
    contentByKey[contentKey] = content;
    indexByKey[contentKey] = chapterIndex;
    statusByKey[contentKey] = status;
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
  }) async {
    await saveContent(
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
  Future<Set<int>> getStoredChapterIndices({
    required String origin,
    required String bookUrl,
  }) async {
    return indexByKey.values.toSet();
  }

  @override
  Future<bool> hasReadyContent({required String contentKey}) async {
    return contentByKey[contentKey]?.isNotEmpty == true &&
        statusByKey[contentKey] != ReaderChapterContentStatus.failed;
  }

  @override
  Future<void> deleteContent({required String contentKey}) async {
    contentByKey.remove(contentKey);
    indexByKey.remove(contentKey);
    statusByKey.remove(contentKey);
  }

  @override
  Future<void> deleteByBook(String origin, String bookUrl) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book _book({bool bookshelf = false}) => Book(
  bookUrl: 'https://example.com/book/1',
  origin: 'https://source.example',
  name: 'Book',
  author: 'Author',
  isInBookshelf: bookshelf,
);

BookChapter _chapter(int index, String url) => BookChapter(
  title: 'c$index',
  index: index,
  url: url,
  bookUrl: 'https://example.com/book/1',
);

void main() {
  group('ReaderChapterContentStore', () {
    test('未加入書架的網路書也寫入同一套 storage', () async {
      final chapterDao = _FakeChapterDao();
      final contentDao = _FakeChapterContentDao();
      final store = ReaderChapterContentStore(
        chapterDao: chapterDao,
        contentDao: contentDao,
      );
      final book = _book();
      final chapter = _chapter(1, 'chapter-1');

      await store.saveRawContent(
        book: book,
        chapter: chapter,
        content: 'raw content',
      );

      expect(chapterDao.insertedBatches.single.single.url, 'chapter-1');
      expect(
        await store.getRawContent(book: book, chapter: chapter),
        'raw content',
      );
    });

    test('saveChapterMetadata=false 時只更新正文 storage', () async {
      final chapterDao = _FakeChapterDao();
      final contentDao = _FakeChapterContentDao();
      final store = ReaderChapterContentStore(
        chapterDao: chapterDao,
        contentDao: contentDao,
      );
      final book = _book(bookshelf: true);
      final chapter = _chapter(2, 'chapter-2');

      await store.saveRawContent(
        book: book,
        chapter: chapter,
        content: 'bookshelf raw',
        saveChapterMetadata: false,
      );

      expect(chapterDao.insertedBatches, isEmpty);
      expect(
        contentDao.contentByKey[ReaderChapterContentStore.contentKeyFor(
          book: book,
          chapter: chapter,
        )],
        'bookshelf raw',
      );
    });

    test('storedChapterIndices 直接來自 content storage', () async {
      final chapterDao = _FakeChapterDao();
      final contentDao = _FakeChapterContentDao();
      final store = ReaderChapterContentStore(
        chapterDao: chapterDao,
        contentDao: contentDao,
      );
      final book = _book();
      final chapters = [_chapter(0, 'chapter-0'), _chapter(1, 'chapter-1')];

      await store.saveRawContent(
        book: book,
        chapter: chapters[1],
        content: 'stored chapter',
      );

      expect(await store.storedChapterIndices(book: book), <int>{1});
    });

    test('不再讀取 chapter inline content，只讀 chapter content store', () async {
      final chapterDao = _FakeChapterDao();
      final contentDao = _FakeChapterContentDao();
      final store = ReaderChapterContentStore(
        chapterDao: chapterDao,
        contentDao: contentDao,
      );
      final book = _book(bookshelf: true);
      final chapter = _chapter(
        3,
        'chapter-3',
      ).copyWith(content: 'legacy inline');

      final content = await store.getRawContent(book: book, chapter: chapter);

      expect(content, isNull);
      expect(
        contentDao.contentByKey.containsKey(
          ReaderChapterContentStore.contentKeyFor(book: book, chapter: chapter),
        ),
        isFalse,
      );
    });

    test('failure 會保存內容與 failed 狀態，供畫面顯示與重試辨識', () async {
      final chapterDao = _FakeChapterDao();
      final contentDao = _FakeChapterContentDao();
      final store = ReaderChapterContentStore(
        chapterDao: chapterDao,
        contentDao: contentDao,
      );
      final book = _book();
      final chapter = _chapter(4, 'chapter-4');

      await store.saveFailure(
        book: book,
        chapter: chapter,
        message: '加載章節失敗: timeout',
      );

      final entry = await store.getContentEntry(book: book, chapter: chapter);
      expect(entry?.isFailed, isTrue);
      expect(entry?.content, '加載章節失敗: timeout');
      expect(
        await store.hasReadyContent(book: book, chapter: chapter),
        isFalse,
      );
    });
  });
}
