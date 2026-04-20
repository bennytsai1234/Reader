import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/exception/app_exception.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/check_source_service.dart';
import 'package:inkpage_reader/core/services/event_bus.dart';

class _FakeBookSourceDao extends Fake implements BookSourceDao {
  final Map<String, BookSource> store = {};

  @override
  Future<BookSource?> getByUrl(String url) async => store[url];

  @override
  Future<void> upsert(BookSource source) async {
    store[source.bookSourceUrl] = source;
  }
}

class _FakeBookSourceService extends Fake implements BookSourceService {
  List<SearchBook> searchResults = [];
  Book? hydratedBook;
  List<BookChapter> chapters = [];
  String content = '';
  Exception? contentError;

  Book? infoRequestBook;
  Book? chapterRequestBook;
  Book? contentRequestBook;
  BookChapter? contentRequestChapter;
  String? capturedNextChapterUrl;

  @override
  Future<List<SearchBook>> searchBooks(
    BookSource source,
    String key, {
    int page = 1,
    bool Function(String name, String author)? filter,
    bool Function(int size)? shouldBreak,
    dynamic cancelToken,
  }) async => searchResults;

  @override
  Future<Book> getBookInfo(BookSource source, Book book) async {
    infoRequestBook = book;
    return hydratedBook ?? book;
  }

  @override
  Future<List<BookChapter>> getChapterList(
    BookSource source,
    Book book, {
    int? chapterLimit,
  }) async {
    chapterRequestBook = book;
    return chapters;
  }

  @override
  Future<String> getContent(
    BookSource source,
    Book book,
    BookChapter chapter, {
    String? nextChapterUrl,
  }) async {
    if (contentError != null) {
      throw contentError!;
    }
    contentRequestBook = book;
    contentRequestChapter = chapter;
    capturedNextChapterUrl = nextChapterUrl;
    return content;
  }
}

void main() {
  test(
    'check hydrates book info before toc and passes next readable chapter',
    () async {
      final source = BookSource(
        bookSourceUrl: 'source://bb',
        bookSourceName: 'BB成人小说',
        bookSourceGroup: '搜尋失效',
        bookSourceComment: '// Error: 舊錯誤',
      );

      final fakeDao =
          _FakeBookSourceDao()..store[source.bookSourceUrl] = source;
      final fakeService =
          _FakeBookSourceService()
            ..searchResults = [
              SearchBook(
                bookUrl: 'https://example.com/book/1',
                name: '測試書',
                author: '作者甲',
                origin: source.bookSourceUrl,
                originName: source.bookSourceName,
              ),
            ]
            ..hydratedBook = Book(
              bookUrl: 'https://example.com/book/1',
              tocUrl: 'https://example.com/book/1/catalog',
              origin: source.bookSourceUrl,
              originName: source.bookSourceName,
              name: '測試書',
              author: '作者甲',
            )
            ..chapters = [
              BookChapter(
                title: '卷一',
                url: 'https://example.com/book/1/volume',
                bookUrl: 'https://example.com/book/1',
                isVolume: true,
              ),
              BookChapter(
                title: '第1章 開始',
                url: 'https://example.com/book/1/1.html',
                bookUrl: 'https://example.com/book/1',
              ),
              BookChapter(
                title: '第2章 延續',
                url: 'https://example.com/book/1/2.html',
                bookUrl: 'https://example.com/book/1',
              ),
            ]
            ..content = '這是一段足夠長的正文內容，肯定超過十個字。';

      final service = CheckSourceService(
        service: fakeService,
        sourceDao: fakeDao,
        eventBus: AppEventBus(),
      );

      await service.check([source.bookSourceUrl]);

      expect(
        fakeService.infoRequestBook?.bookUrl,
        'https://example.com/book/1',
      );
      expect(
        fakeService.chapterRequestBook?.tocUrl,
        'https://example.com/book/1/catalog',
      );
      expect(
        fakeService.contentRequestBook?.tocUrl,
        'https://example.com/book/1/catalog',
      );
      expect(fakeService.contentRequestChapter?.title, '第1章 開始');
      expect(
        fakeService.capturedNextChapterUrl,
        'https://example.com/book/1/2.html',
      );

      final saved = fakeDao.store[source.bookSourceUrl]!;
      expect(saved.bookSourceGroup?.contains('搜尋失效') ?? false, isFalse);
      expect(saved.bookSourceGroup?.contains('目錄失效') ?? false, isFalse);
      expect(saved.bookSourceGroup?.contains('正文失效') ?? false, isFalse);
      expect(saved.bookSourceComment?.contains('// Error:') ?? false, isFalse);
      expect(saved.respondTime, greaterThanOrEqualTo(0));
    },
  );

  test('check marks login-required sources as invalid', () async {
    final source = BookSource(
      bookSourceUrl: 'source://login',
      bookSourceName: '登入牆來源',
    );

    final fakeDao = _FakeBookSourceDao()..store[source.bookSourceUrl] = source;
    final fakeService =
        _FakeBookSourceService()
          ..searchResults = [
            SearchBook(
              bookUrl: 'https://example.com/book/login',
              name: '測試書',
              author: '作者甲',
              origin: source.bookSourceUrl,
              originName: source.bookSourceName,
            ),
          ]
          ..hydratedBook = Book(
            bookUrl: 'https://example.com/book/login',
            tocUrl: 'https://example.com/book/login/catalog',
            origin: source.bookSourceUrl,
            originName: source.bookSourceName,
            name: '測試書',
            author: '作者甲',
          )
          ..chapters = [
            BookChapter(
              title: '第1章 開始',
              url: 'https://example.com/book/login/1.html',
              bookUrl: 'https://example.com/book/login',
            ),
          ]
          ..contentError = LoginCheckException('正文需要登入後閱讀');

    final service = CheckSourceService(
      service: fakeService,
      sourceDao: fakeDao,
      eventBus: AppEventBus(),
    );

    await service.check([source.bookSourceUrl]);

    final saved = fakeDao.store[source.bookSourceUrl]!;
    expect(
      saved.bookSourceGroup?.contains(loginRequiredSourceGroupTag) ?? false,
      isTrue,
    );
    expect(saved.bookSourceComment, contains('正文需要登入後閱讀'));
  });
}
