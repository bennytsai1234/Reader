import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/reader_chapter_content.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/download_service.dart';
import 'package:inkpage_reader/features/book_detail/book_detail_provider.dart';

// ---------------------------------------------------------------------------
// Fake DAOs
// ---------------------------------------------------------------------------

class _FakeBookDao extends Fake implements BookDao {
  final Map<String, Book> _store = {};

  @override
  Future<Book?> getByUrl(String url) async => _store[url];

  @override
  Future<void> upsert(Book book) async => _store[book.bookUrl] = book;

  @override
  Future<void> deleteByUrl(String url) async => _store.remove(url);
}

class _FakeChapterDao extends Fake implements ChapterDao {
  final Map<String, List<BookChapter>> _store = {};

  @override
  Future<List<BookChapter>> getChapters(String bookUrl) async =>
      _store[bookUrl] ?? [];

  @override
  Future<void> insertChapters(List<BookChapter> chapters) async {
    if (chapters.isEmpty) return;
    _store[chapters.first.bookUrl] = chapters;
  }
}

class _FakeChapterContentDao extends Fake implements ReaderChapterContentDao {
  _FakeChapterContentDao({Set<int> storedIndices = const <int>{}})
    : _storedIndices = Set<int>.from(storedIndices);

  final Set<int> _storedIndices;

  @override
  Future<String?> getContent({required String contentKey}) async {
    return null;
  }

  @override
  Future<ReaderChapterContentEntry?> getEntry({
    required String contentKey,
  }) async {
    return null;
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
    _storedIndices.add(chapterIndex);
  }

  @override
  Future<Set<int>> getStoredChapterIndices({
    required String origin,
    required String bookUrl,
  }) async {
    return Set<int>.from(_storedIndices);
  }

  @override
  Future<void> deleteContentByBook(String origin, String bookUrl) async {
    _storedIndices.clear();
  }
}

class _FakeSourceDao extends Fake implements BookSourceDao {
  _FakeSourceDao([this.source]);

  final BookSource? source;

  @override
  Future<BookSource?> getByUrl(String url) async => source;
}

class _FakeBookSourceService extends Fake implements BookSourceService {
  _FakeBookSourceService({this.chapterList = const <BookChapter>[]});

  final List<BookChapter> chapterList;

  @override
  Future<Book> getBookInfo(BookSource source, Book book) async => book;

  @override
  Future<List<BookChapter>> getChapterList(
    BookSource source,
    Book book, {
    int? chapterLimit,
    int? pageConcurrency,
  }) async {
    return chapterList;
  }
}

class _FakeDownloadService extends Fake implements DownloadService {
  Book? queuedBook;
  List<BookChapter> queuedChapters = <BookChapter>[];
  int addDownloadTaskCallCount = 0;

  @override
  Future<void> addDownloadTask(Book book, List<BookChapter> chapters) async {
    addDownloadTaskCallCount++;
    queuedBook = book;
    queuedChapters = List<BookChapter>.from(chapters);
  }
}

// ---------------------------------------------------------------------------
// 測試輔助
// ---------------------------------------------------------------------------

AggregatedSearchBook _makeSearchBook({
  String url = 'http://book.com',
  String origin = 'origin',
  String originName = '書源',
}) {
  final sb = SearchBook(
    bookUrl: url,
    name: '測試書',
    author: '作者',
    origin: origin,
    originName: originName,
  );
  return AggregatedSearchBook(book: sb, sources: ['書源']);
}

List<BookChapter> _makeChapters(int n) => List.generate(
  n,
  (i) => BookChapter(
    url: 'chapter_$i',
    title: '第 $i 章',
    bookUrl: 'http://book.com',
    index: i,
  ),
);

// ---------------------------------------------------------------------------
// 測試
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    GetIt.instance.registerLazySingleton<BookDao>(() => _FakeBookDao());
    GetIt.instance.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
    GetIt.instance.registerLazySingleton<BookSourceDao>(() => _FakeSourceDao());
  });

  tearDown(() async => GetIt.instance.reset());

  Future<BookDetailProvider> makeProvider({
    String url = 'http://book.com',
    String origin = 'origin',
    List<BookChapter> chapters = const [],
    BookSource? source,
    BookSourceService? service,
    DownloadService? downloadService,
    Set<int> storedIndices = const <int>{},
  }) async {
    final chapterDao = GetIt.instance<ChapterDao>() as _FakeChapterDao;
    if (chapters.isNotEmpty) {
      await chapterDao.insertChapters(chapters);
    }
    final p = BookDetailProvider(
      _makeSearchBook(url: url, origin: origin),
      sourceDao: _FakeSourceDao(source),
      chapterContentDao: _FakeChapterContentDao(storedIndices: storedIndices),
      service: service ?? _FakeBookSourceService(chapterList: chapters),
      downloadService: downloadService,
    );
    await Future.delayed(Duration.zero); // 等 _init() async 完成
    return p;
  }

  group('BookDetailProvider - 初始狀態', () {
    test('未在書架時 isInBookshelf 為 false', () async {
      final p = await makeProvider();
      expect(p.isInBookshelf, isFalse);
      expect(p.isLoading, isFalse);
    });

    test('DAO 中已有該書時 isInBookshelf 為 true', () async {
      final bookDao = GetIt.instance<BookDao>() as _FakeBookDao;
      final book = Book(
        bookUrl: 'http://book.com',
        name: '存在的書',
        author: '作者',
        origin: 'o',
        originName: 'on',
        isInBookshelf: true,
      );
      await bookDao.upsert(book);

      final p = await makeProvider();
      expect(p.isInBookshelf, isTrue);
    });
  });

  group('BookDetailProvider - 章節篩選', () {
    test('setSearchQuery 篩選章節', () async {
      final chapters = _makeChapters(5);
      chapters[2] = BookChapter(
        url: 'chapter_2',
        title: '特殊章節',
        bookUrl: 'http://book.com',
        index: 2,
      );
      final p = await makeProvider(chapters: chapters);

      p.setSearchQuery('特殊');
      await Future.delayed(const Duration(milliseconds: 350)); // debounce
      expect(p.filteredChapters, hasLength(1));
      expect(p.filteredChapters.first.title, '特殊章節');
    });

    test('清空 searchQuery 恢復全部章節', () async {
      final p = await makeProvider(chapters: _makeChapters(5));

      p.setSearchQuery('不存在');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(p.filteredChapters, isEmpty);

      p.setSearchQuery('');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(p.filteredChapters, hasLength(5));
    });

    test('toggleSort 反轉章節順序', () async {
      final p = await makeProvider(chapters: _makeChapters(3));
      expect(p.filteredChapters.first.index, 0);

      p.toggleSort();
      expect(p.isReversed, isTrue);
      expect(p.filteredChapters.first.index, 2);

      p.toggleSort();
      expect(p.filteredChapters.first.index, 0);
    });

    test('totalChapterCount 正確回傳數量', () async {
      final p = await makeProvider(chapters: _makeChapters(7));
      expect(p.totalChapterCount, 7);
    });
  });

  group('BookDetailProvider - 背景下載佇列', () {
    test('queueDownloadAll 會保留未入書架狀態並加入背景下載', () async {
      final downloadService = _FakeDownloadService();
      final chapters = _makeChapters(3);
      final provider = await makeProvider(
        chapters: chapters,
        source: BookSource(bookSourceUrl: 'origin', bookSourceName: '測試書源'),
        downloadService: downloadService,
      );

      final result = await provider.queueDownloadAll();

      expect(result.queuedChapterCount, 3);
      expect(result.message, '已加入背景下載佇列，共 3 章');
      expect(downloadService.addDownloadTaskCallCount, 1);
      expect(downloadService.queuedChapters, hasLength(3));
      expect(provider.isInBookshelf, isFalse);
      expect(
        await (GetIt.instance<BookDao>() as _FakeBookDao).getByUrl(
          'http://book.com',
        ),
        isNotNull,
      );
    });

    test('queueDownloadMissing 只會加入未下載章節', () async {
      final downloadService = _FakeDownloadService();
      final provider = await makeProvider(
        chapters: _makeChapters(5),
        storedIndices: <int>{1, 3},
        source: BookSource(bookSourceUrl: 'origin', bookSourceName: '測試書源'),
        downloadService: downloadService,
      );

      final result = await provider.queueDownloadMissing();

      expect(result.queuedChapterCount, 3);
      expect(
        downloadService.queuedChapters.map((chapter) => chapter.index).toList(),
        <int>[0, 2, 4],
      );
    });

    test('queueDownloadAll 會在缺少書源時阻擋背景下載', () async {
      final downloadService = _FakeDownloadService();
      final provider = await makeProvider(
        chapters: _makeChapters(2),
        downloadService: downloadService,
      );

      final result = await provider.queueDownloadAll();

      expect(result.queuedChapterCount, 0);
      expect(result.message, '目前找不到書源，請先換源後再試。');
      expect(downloadService.addDownloadTaskCallCount, 0);
      expect(provider.isInBookshelf, isFalse);
    });

    test('queueDownloadAll 會略過本地書籍的背景下載任務', () async {
      final downloadService = _FakeDownloadService();
      final provider = await makeProvider(
        origin: 'local',
        chapters: _makeChapters(2),
        downloadService: downloadService,
      );

      final result = await provider.queueDownloadAll();

      expect(result.queuedChapterCount, 0);
      expect(result.message, '這本書已經在裝置內，不需要背景下載。');
      expect(downloadService.addDownloadTaskCallCount, 0);
    });
  });
}
