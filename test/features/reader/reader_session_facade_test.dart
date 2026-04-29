import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/engine/app_event_bus.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_facade.dart';

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

Book _makeBook() => Book(
  bookUrl: 'https://example.com/book',
  name: '測試書籍',
  author: 'Author',
  origin: 'https://example.com/source',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderSessionFacade', () {
    test('addCurrentBookToBookshelf 會保存進度並發送書架事件', () async {
      const facade = ReaderSessionFacade();
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
        location: const ReaderLocation(
          chapterIndex: 1,
          charOffset: 256,
          visualOffsetPx: 18,
        ),
        chapterTitle: '章節 2',
        bookDao: bookDao,
        chapterDao: chapterDao,
        onCompleted: () => callbackCalled = true,
      );
      await pumpEventQueue();

      expect(book.isInBookshelf, isTrue);
      expect(book.chapterIndex, 1);
      expect(book.charOffset, 256);
      expect(book.visualOffsetPx, 18);
      expect(book.durChapterTitle, '章節 2');
      expect(book.durChapterTime, greaterThan(0));
      expect(bookDao.upserts, hasLength(1));
      expect(bookDao.upserts.single.isInBookshelf, isTrue);
      expect(bookDao.upserts.single.visualOffsetPx, 18);
      expect(chapterDao.insertedBatches, hasLength(1));
      expect(chapterDao.insertedBatches.single, hasLength(1));
      expect(receivedEvent?.data, 'https://example.com/book');
      expect(callbackCalled, isTrue);

      await subscription.cancel();
    });

    test('addCurrentBookToBookshelf 會清掉既有精準 anchor', () async {
      const facade = ReaderSessionFacade();
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
        bookDao: bookDao,
        chapterDao: chapterDao,
      );

      expect(book.readerAnchorJson, isNull);
      expect(bookDao.upserts, hasLength(1));
      expect(bookDao.upserts.single.readerAnchorJson, isNull);
    });
  });
}
