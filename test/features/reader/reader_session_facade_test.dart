import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/engine/app_event_bus.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_host_base.dart'
    show ReaderCommandReason;
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_facade.dart';
import 'package:inkpage_reader/core/services/source_switch_service.dart';

class _FakeBookDao implements BookDao {
  final List<Book> upserts = <Book>[];
  final List<String> deletedUrls = <String>[];

  @override
  Future<void> upsert(Book book) async {
    upserts.add(book.copyWith());
  }

  @override
  Future<void> deleteByUrl(String url) async {
    deletedUrls.add(url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChapterDao implements ChapterDao {
  final List<List<BookChapter>> insertedBatches = <List<BookChapter>>[];
  final List<String> deletedBooks = <String>[];
  List<BookChapter> chapterResults = <BookChapter>[];

  @override
  Future<List<BookChapter>> getByBook(String bookUrl) async => chapterResults;

  @override
  Future<void> insertChapters(List<BookChapter> chapterList) async {
    insertedBatches.add(List<BookChapter>.from(chapterList));
  }

  @override
  Future<void> deleteByBook(String bookUrl) async {
    deletedBooks.add(bookUrl);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookSourceDao implements BookSourceDao {
  BookSource? source;

  @override
  Future<BookSource?> getByUrl(String url) async => source;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookmarkDao implements BookmarkDao {
  final List<Bookmark> upserts = <Bookmark>[];

  @override
  Future<void> upsert(Bookmark bookmark) async {
    upserts.add(bookmark);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book _makeBook() => Book(
  bookUrl: 'https://example.com/book',
  name: '測試書籍',
  author: 'Author',
  origin: 'https://example.com/source',
);

BookSource _makeSource({
  String url = 'https://example.com/source',
  String name = '來源 A',
}) => BookSource(bookSourceUrl: url, bookSourceName: name);

SearchBook _makeSearchBook({String origin = 'https://example.com/source-b'}) =>
    SearchBook(
      bookUrl: 'https://example.com/new-book',
      name: '測試書籍',
      author: 'Author',
      origin: origin,
      originName: '來源 B',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderSessionFacade', () {
    test('buildBookmark 會組合目前章節資訊', () {
      const facade = ReaderSessionFacade();

      final bookmark = facade.buildBookmark(
        book: _makeBook(),
        chapterIndex: 2,
        chapterTitle: '章節 3',
        chapterPos: 128,
        content: '片段內容',
      );

      expect(bookmark.bookName, '測試書籍');
      expect(bookmark.bookAuthor, 'Author');
      expect(bookmark.bookUrl, 'https://example.com/book');
      expect(bookmark.chapterIndex, 2);
      expect(bookmark.chapterName, '章節 3');
      expect(bookmark.chapterPos, 128);
      expect(bookmark.bookText, '片段內容');
      expect(bookmark.time, greaterThan(0));
    });

    test('addCurrentBookToBookshelf 會保存進度並發送書架事件', () async {
      const facade = ReaderSessionFacade();
      final progressStore = ReaderProgressStore();
      final bookDao = _FakeBookDao();
      final chapterDao = _FakeChapterDao();
      final book = _makeBook();
      final chapters = <BookChapter>[
        BookChapter(
          title: '章節 1',
          index: 0,
          bookUrl: 'https://example.com/book',
        ),
      ];
      AppEvent? receivedEvent;
      final subscription = AppEventBus().onName(AppEventBus.upBookshelf).listen(
        (event) {
          receivedEvent = event;
        },
      );
      var callbackCalled = false;

      await facade.addCurrentBookToBookshelf(
        book: book,
        chapters: chapters,
        location: const ReaderLocation(chapterIndex: 1, charOffset: 256),
        chapterTitle: '章節 2',
        progressStore: progressStore,
        bookDao: bookDao,
        chapterDao: chapterDao,
        onCompleted: () => callbackCalled = true,
      );
      await pumpEventQueue();

      expect(book.isInBookshelf, isTrue);
      expect(book.chapterIndex, 1);
      expect(book.charOffset, 256);
      expect(book.durChapterTitle, '章節 2');
      expect(book.durChapterTime, greaterThan(0));
      expect(bookDao.upserts, hasLength(1));
      expect(bookDao.upserts.single.isInBookshelf, isTrue);
      expect(chapterDao.insertedBatches, hasLength(1));
      expect(chapterDao.insertedBatches.single, hasLength(1));
      expect(receivedEvent?.data, 'https://example.com/book');
      expect(callbackCalled, isTrue);

      await subscription.cancel();
    });

    test('addCurrentBookToBookshelf 會清掉既有精準 anchor', () async {
      const facade = ReaderSessionFacade();
      final progressStore = ReaderProgressStore();
      final bookDao = _FakeBookDao();
      final chapterDao = _FakeChapterDao();
      final book =
          _makeBook()
            ..readerAnchorJson =
                '{"chapterIndex":1,"charOffset":256,"pageIndexSnapshot":4}';
      final chapters = <BookChapter>[
        BookChapter(
          title: '章節 1',
          index: 0,
          bookUrl: 'https://example.com/book',
        ),
      ];

      await facade.addCurrentBookToBookshelf(
        book: book,
        chapters: chapters,
        location: const ReaderLocation(chapterIndex: 1, charOffset: 256),
        chapterTitle: '章節 2',
        progressStore: progressStore,
        bookDao: bookDao,
        chapterDao: chapterDao,
      );

      expect(book.readerAnchorJson, isNull);
      expect(bookDao.upserts, hasLength(1));
      expect(bookDao.upserts.single.readerAnchorJson, isNull);
    });

    test('loadChapters 會優先沿用現有章節，否則回退 dao', () async {
      const facade = ReaderSessionFacade();
      final chapterDao = _FakeChapterDao();
      final existingChapters = <BookChapter>[
        BookChapter(
          title: '現有章節',
          index: 0,
          bookUrl: 'https://example.com/book',
        ),
      ];
      final daoChapters = <BookChapter>[
        BookChapter(
          title: 'DAO 章節',
          index: 1,
          bookUrl: 'https://example.com/book',
        ),
      ];
      chapterDao.chapterResults = daoChapters;

      final reused = await facade.loadChapters(
        book: _makeBook(),
        chapters: existingChapters,
        chapterDao: chapterDao,
      );
      final loaded = await facade.loadChapters(
        book: _makeBook(),
        chapters: const <BookChapter>[],
        chapterDao: chapterDao,
      );

      expect(reused, hasLength(1));
      expect(reused.single.title, '現有章節');
      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'DAO 章節');
    });

    test('loadSource 會透過 source dao 讀取目前來源', () async {
      const facade = ReaderSessionFacade();
      final sourceDao = _FakeBookSourceDao()..source = _makeSource();

      final source = await facade.loadSource(
        book: _makeBook(),
        sourceDao: sourceDao,
      );

      expect(source?.bookSourceName, '來源 A');
      expect(source?.bookSourceUrl, 'https://example.com/source');
    });

    test('saveBookmark 會寫入 bookmark dao 並執行回呼', () {
      const facade = ReaderSessionFacade();
      final bookmarkDao = _FakeBookmarkDao();
      final bookmark = facade.buildBookmark(
        book: _makeBook(),
        chapterIndex: 0,
        chapterTitle: '章節 1',
        chapterPos: 32,
      );
      var callbackCalled = false;

      facade.saveBookmark(
        bookmarkDao: bookmarkDao,
        bookmark: bookmark,
        onCompleted: () => callbackCalled = true,
      );

      expect(bookmarkDao.upserts, hasLength(1));
      expect(bookmarkDao.upserts.single.chapterPos, 32);
      expect(callbackCalled, isTrue);
    });

    test('applySourceSwitchResolution 會切到新書、保留舊書並 reload 目標章節', () async {
      const facade = ReaderSessionFacade();
      final bookDao = _FakeBookDao();
      final chapterDao = _FakeChapterDao();
      final migratedChapters = <BookChapter>[
        BookChapter(
          title: '新章節 1',
          index: 0,
          bookUrl: 'https://example.com/new-book',
        ),
        BookChapter(
          title: '新章節 2',
          index: 1,
          bookUrl: 'https://example.com/new-book',
        ),
      ];
      final book =
          _makeBook()
            ..isInBookshelf = true
            ..chapterIndex = 1
            ..charOffset = 96
            ..readerAnchorJson =
                '{"chapterIndex":1,"charOffset":96,"localOffsetSnapshot":288}'
            ..totalChapterNum = 2
            ..durChapterTitle = '舊章節';
      final source = _makeSource(
        url: 'https://example.com/source-b',
        name: '來源 B',
      );
      final migratedBook = book.migrateTo(
        _makeSearchBook(origin: source.bookSourceUrl).toBook()
          ..isInBookshelf = true,
        migratedChapters,
      );
      final resolution = SourceSwitchResolution(
        searchBook: _makeSearchBook(origin: source.bookSourceUrl),
        source: source,
        migratedBook: migratedBook,
        chapters: migratedChapters,
        targetChapterIndex: 1,
        validatedContent: 'validated content',
      );

      BookSource? assignedSource;
      List<BookChapter> assignedChapters = const <BookChapter>[];
      final clearedFailures = <int>[];
      final seededContent = <({int chapterIndex, String content})>[];
      final savedContent = <({BookChapter chapter, String content})>[];
      final updatedLocations = <ReaderLocation>[];
      final loadedChapters =
          <({int chapterIndex, ReaderCommandReason reason})>[];
      final jumpedTargets =
          <({int chapterIndex, int charOffset, ReaderCommandReason reason})>[];
      var refreshedTitles = false;
      var resetLifecycle = false;

      await facade.applySourceSwitchResolution(
        resolution: resolution,
        book: book,
        setSource: (value) => assignedSource = value,
        setChapters: (value) => assignedChapters = value,
        clearChapterFailure: clearedFailures.add,
        refreshChapterDisplayTitles: ({bool notify = true}) async {
          refreshedTitles = true;
        },
        resetContentLifecycle: ({bool refreshPaginationConfig = false}) {
          resetLifecycle = true;
        },
        putChapterContent: (chapterIndex, content) {
          seededContent.add((chapterIndex: chapterIndex, content: content));
        },
        bookDao: bookDao,
        chapterDao: chapterDao,
        saveChapterContent: (chapter, content) async {
          savedContent.add((chapter: chapter, content: content));
        },
        updateCommittedLocation: updatedLocations.add,
        loadChapter: (
          chapterIndex, {
          reason = ReaderCommandReason.system,
        }) async {
          loadedChapters.add((chapterIndex: chapterIndex, reason: reason));
        },
        jumpToChapterCharOffset: ({
          required chapterIndex,
          required charOffset,
          required reason,
        }) {
          jumpedTargets.add((
            chapterIndex: chapterIndex,
            charOffset: charOffset,
            reason: reason,
          ));
        },
      );

      expect(book.bookUrl, migratedBook.bookUrl);
      expect(book.origin, migratedBook.origin);
      expect(book.readerAnchorJson, isNull);
      expect(assignedSource?.bookSourceName, '來源 B');
      expect(assignedChapters, hasLength(2));
      expect(assignedChapters[1].content, isNull);
      expect(clearedFailures, <int>[1]);
      expect(refreshedTitles, isTrue);
      expect(resetLifecycle, isTrue);
      expect(savedContent.single.chapter.index, 1);
      expect(savedContent.single.content, 'validated content');
      expect(seededContent, hasLength(1));
      expect(seededContent.single.chapterIndex, 1);
      expect(updatedLocations, const <ReaderLocation>[
        ReaderLocation(chapterIndex: 1, charOffset: 96),
      ]);
      expect(loadedChapters, hasLength(1));
      expect(loadedChapters.single.chapterIndex, 1);
      expect(loadedChapters.single.reason, ReaderCommandReason.system);
      expect(jumpedTargets, hasLength(1));
      expect(jumpedTargets.single.chapterIndex, 1);
      expect(jumpedTargets.single.charOffset, 96);
      expect(bookDao.deletedUrls, isEmpty);
      expect(chapterDao.deletedBooks, <String>[migratedBook.bookUrl]);
      expect(bookDao.upserts, hasLength(1));
      expect(bookDao.upserts.single.readerAnchorJson, isNull);
      expect(chapterDao.insertedBatches, hasLength(1));
      expect(chapterDao.insertedBatches.single, hasLength(2));
    });
  });
}
