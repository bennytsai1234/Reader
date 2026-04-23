import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<SearchBook> exploreResults = [];
  Book? hydratedBook;
  List<BookChapter> chapters = [];
  String content = '';
  Exception? contentError;
  Duration searchDelay = Duration.zero;

  Book? infoRequestBook;
  Book? chapterRequestBook;
  Book? contentRequestBook;
  BookChapter? contentRequestChapter;
  String? capturedNextChapterUrl;
  String? capturedExploreUrl;
  int? capturedChapterPageConcurrency;
  int? capturedContentPageConcurrency;

  @override
  Future<List<SearchBook>> searchBooks(
    BookSource source,
    String key, {
    int page = 1,
    bool Function(String name, String author)? filter,
    bool Function(int size)? shouldBreak,
    dynamic cancelToken,
  }) async {
    if (searchDelay > Duration.zero) {
      await Future<void>.delayed(searchDelay);
    }
    return searchResults;
  }

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
    int? pageConcurrency,
  }) async {
    chapterRequestBook = book;
    capturedChapterPageConcurrency = pageConcurrency;
    return chapters;
  }

  @override
  Future<String> getContent(
    BookSource source,
    Book book,
    BookChapter chapter, {
    String? nextChapterUrl,
    int? pageConcurrency,
  }) async {
    if (contentError != null) {
      throw contentError!;
    }
    contentRequestBook = book;
    contentRequestChapter = chapter;
    capturedNextChapterUrl = nextChapterUrl;
    capturedContentPageConcurrency = pageConcurrency;
    return content;
  }

  @override
  Future<List<SearchBook>> exploreBooks(
    BookSource source,
    String url, {
    int page = 1,
    dynamic cancelToken,
  }) async {
    capturedExploreUrl = url;
    return exploreResults;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'check hydrates book info before toc and passes next readable chapter',
    () async {
      final source = BookSource(
        bookSourceUrl: 'source://bb',
        bookSourceName: 'BB成人小说',
        searchUrl: '/search?key={{key}}',
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
      expect(fakeService.capturedChapterPageConcurrency, 1);
      expect(fakeService.capturedContentPageConcurrency, 1);

      final saved = fakeDao.store[source.bookSourceUrl]!;
      expect(saved.bookSourceGroup?.contains('搜尋失效') ?? false, isFalse);
      expect(saved.bookSourceGroup?.contains('目錄失效') ?? false, isFalse);
      expect(saved.bookSourceGroup?.contains('正文失效') ?? false, isFalse);
      expect(saved.bookSourceComment?.contains('// Error:') ?? false, isFalse);
      expect(saved.respondTime, greaterThanOrEqualTo(0));
      expect(service.progressOf(source.bookSourceUrl)?.message, '校驗成功');
      expect(service.progressOf(source.bookSourceUrl)?.isFinal, isTrue);
    },
  );

  test('check marks login-required sources as invalid', () async {
    final source = BookSource(
      bookSourceUrl: 'source://login',
      bookSourceName: '登入牆來源',
      searchUrl: '/search?key={{key}}',
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
    expect(service.progressOf(source.bookSourceUrl)?.message, contains('需要登入'));
    expect(service.progressOf(source.bookSourceUrl)?.hasIssue, isTrue);
  });

  test('loadConfig reads persisted validation preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'checkSourceKeyword': '測試詞',
      'checkSourceTimeout': 9,
      'checkSourceSearch': false,
      'checkSourceDiscovery': true,
      'checkSourceInfo': true,
      'checkSourceCategory': false,
      'checkSourceContent': false,
    });

    final service = CheckSourceService(
      service: _FakeBookSourceService(),
      sourceDao: _FakeBookSourceDao(),
      eventBus: AppEventBus(),
    );

    await service.loadConfig();

    expect(service.config.keyword, '測試詞');
    expect(service.config.timeoutSeconds, 9);
    expect(service.config.checkSearch, isFalse);
    expect(service.config.checkDiscovery, isTrue);
    expect(service.config.checkInfo, isTrue);
    expect(service.config.checkCategory, isFalse);
    expect(service.config.checkContent, isFalse);
  });

  test(
    'discovery-only check marks discovery failures without disabling search',
    () async {
      final source = BookSource(
        bookSourceUrl: 'source://discovery',
        bookSourceName: '發現源',
        exploreUrl: '玄幻::/explore',
      );

      final fakeDao =
          _FakeBookSourceDao()..store[source.bookSourceUrl] = source;
      final fakeService = _FakeBookSourceService()..exploreResults = [];
      final service = CheckSourceService(
        service: fakeService,
        sourceDao: fakeDao,
        eventBus: AppEventBus(),
      );

      await service.updateConfig(
        SourceCheckConfig.defaults.copyWith(
          checkSearch: false,
          checkDiscovery: true,
          checkInfo: false,
          checkCategory: false,
          checkContent: false,
        ),
      );
      await service.check([source.bookSourceUrl]);

      final saved = fakeDao.store[source.bookSourceUrl]!;
      expect(
        saved.bookSourceGroup?.contains(discoveryBrokenSourceGroupTag) ?? false,
        isTrue,
      );
      expect(saved.isSearchEnabledByRuntime, isTrue);
      expect(saved.isReadingEnabledByRuntime, isTrue);
      expect(fakeService.capturedExploreUrl, '/explore');
      expect(service.logs, isNotEmpty);
    },
  );

  test(
    'discovery toc failures use specific tag without disabling search',
    () async {
      final source = BookSource(
        bookSourceUrl: 'source://discovery-toc',
        bookSourceName: '發現目錄失效源',
        exploreUrl: '玄幻::/explore',
      );

      final fakeDao =
          _FakeBookSourceDao()..store[source.bookSourceUrl] = source;
      final fakeService =
          _FakeBookSourceService()
            ..exploreResults = [
              SearchBook(
                bookUrl: 'https://example.com/book/discovery-toc',
                name: '發現測試書',
                author: '作者甲',
                origin: source.bookSourceUrl,
                originName: source.bookSourceName,
              ),
            ]
            ..hydratedBook = Book(
              bookUrl: 'https://example.com/book/discovery-toc',
              tocUrl: 'https://example.com/book/discovery-toc/catalog',
              origin: source.bookSourceUrl,
              originName: source.bookSourceName,
              name: '發現測試書',
              author: '作者甲',
            )
            ..chapters = [];
      final service = CheckSourceService(
        service: fakeService,
        sourceDao: fakeDao,
        eventBus: AppEventBus(),
      );

      await service.updateConfig(
        SourceCheckConfig.defaults.copyWith(
          checkSearch: false,
          checkDiscovery: true,
          checkInfo: true,
          checkCategory: true,
          checkContent: true,
        ),
      );
      await service.check([source.bookSourceUrl]);

      final saved = fakeDao.store[source.bookSourceUrl]!;
      expect(
        saved.bookSourceGroup?.contains(discoveryTocBrokenSourceGroupTag) ??
            false,
        isTrue,
      );
      expect(
        saved.runtimeHealth.category,
        SourceHealthCategory.discoveryTocBroken,
      );
      expect(saved.isSearchEnabledByRuntime, isTrue);
      expect(saved.isReadingEnabledByRuntime, isTrue);
    },
  );

  test(
    'discovery detail failures use specific tag without disabling search',
    () async {
      final source = BookSource(
        bookSourceUrl: 'source://discovery-detail',
        bookSourceName: '發現詳情失效源',
        exploreUrl: '玄幻::/explore',
      );

      final fakeDao =
          _FakeBookSourceDao()..store[source.bookSourceUrl] = source;
      final fakeService =
          _FakeBookSourceService()
            ..exploreResults = [
              SearchBook(
                bookUrl: 'https://example.com/book/discovery-detail',
                name: '發現測試書',
                author: '作者甲',
                origin: source.bookSourceUrl,
                originName: source.bookSourceName,
              ),
            ]
            ..hydratedBook = Book(
              bookUrl: '',
              tocUrl: '',
              origin: source.bookSourceUrl,
              originName: source.bookSourceName,
              name: '',
              author: '作者甲',
            );
      final service = CheckSourceService(
        service: fakeService,
        sourceDao: fakeDao,
        eventBus: AppEventBus(),
      );

      await service.updateConfig(
        SourceCheckConfig.defaults.copyWith(
          checkSearch: false,
          checkDiscovery: true,
          checkInfo: true,
          checkCategory: true,
          checkContent: true,
        ),
      );
      await service.check([source.bookSourceUrl]);

      final saved = fakeDao.store[source.bookSourceUrl]!;
      expect(
        saved.bookSourceGroup?.contains(discoveryDetailBrokenSourceGroupTag) ??
            false,
        isTrue,
      );
      expect(
        saved.runtimeHealth.category,
        SourceHealthCategory.discoveryDetailBroken,
      );
      expect(saved.isSearchEnabledByRuntime, isTrue);
      expect(saved.isReadingEnabledByRuntime, isTrue);
    },
  );

  test(
    'discovery content failures use specific tag without disabling search',
    () async {
      final source = BookSource(
        bookSourceUrl: 'source://discovery-content',
        bookSourceName: '發現正文失效源',
        exploreUrl: '玄幻::/explore',
      );

      final fakeDao =
          _FakeBookSourceDao()..store[source.bookSourceUrl] = source;
      final fakeService =
          _FakeBookSourceService()
            ..exploreResults = [
              SearchBook(
                bookUrl: 'https://example.com/book/discovery-content',
                name: '發現測試書',
                author: '作者甲',
                origin: source.bookSourceUrl,
                originName: source.bookSourceName,
              ),
            ]
            ..hydratedBook = Book(
              bookUrl: 'https://example.com/book/discovery-content',
              tocUrl: 'https://example.com/book/discovery-content/catalog',
              origin: source.bookSourceUrl,
              originName: source.bookSourceName,
              name: '發現測試書',
              author: '作者甲',
            )
            ..chapters = [
              BookChapter(
                title: '第1章 開始',
                url: 'https://example.com/book/discovery-content/1.html',
                bookUrl: 'https://example.com/book/discovery-content',
              ),
            ]
            ..content = '太短';
      final service = CheckSourceService(
        service: fakeService,
        sourceDao: fakeDao,
        eventBus: AppEventBus(),
      );

      await service.updateConfig(
        SourceCheckConfig.defaults.copyWith(
          checkSearch: false,
          checkDiscovery: true,
          checkInfo: true,
          checkCategory: true,
          checkContent: true,
        ),
      );
      await service.check([source.bookSourceUrl]);

      final saved = fakeDao.store[source.bookSourceUrl]!;
      expect(
        saved.bookSourceGroup?.contains(discoveryContentBrokenSourceGroupTag) ??
            false,
        isTrue,
      );
      expect(
        saved.runtimeHealth.category,
        SourceHealthCategory.discoveryContentBroken,
      );
      expect(saved.isSearchEnabledByRuntime, isTrue);
      expect(saved.isReadingEnabledByRuntime, isTrue);
    },
  );

  test('dispose during in-flight check does not throw', () async {
    final source = BookSource(
      bookSourceUrl: 'source://dispose',
      bookSourceName: '延遲校驗源',
      searchUrl: '/search?key={{key}}',
    );

    final fakeDao = _FakeBookSourceDao()..store[source.bookSourceUrl] = source;
    final fakeService =
        _FakeBookSourceService()
          ..searchDelay = const Duration(milliseconds: 10)
          ..searchResults = <SearchBook>[];
    final service = CheckSourceService(
      service: fakeService,
      sourceDao: fakeDao,
      eventBus: AppEventBus(),
    );

    final future = service.check([source.bookSourceUrl]);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    service.dispose();

    await expectLater(future, completes);
  });
}
