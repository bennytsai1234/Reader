import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/search_book_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/source/change_source_provider.dart';

class _FakeBookSourceDao extends Fake implements BookSourceDao {
  List<BookSource> sources = <BookSource>[];

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((source) => source.enabled).toList();
}

class _FakeSearchBookDao extends Fake implements SearchBookDao {
  List<SearchBook> cachedResults = <SearchBook>[];

  @override
  Future<List<SearchBook>> getSearchBooks(String name, String author) async =>
      cachedResults;
}

typedef _PreciseSearchHandler =
    Future<List<SearchBook>> Function(String author);

class _FakeBookSourceService extends Fake implements BookSourceService {
  final Map<String, _PreciseSearchHandler> handlers =
      <String, _PreciseSearchHandler>{};
  final List<String> requestedSources = <String>[];
  final List<String> requestedAuthors = <String>[];

  @override
  Future<List<SearchBook>> preciseSearch(
    BookSource source,
    String name,
    String author,
  ) {
    requestedSources.add(source.bookSourceUrl);
    requestedAuthors.add(author);
    final handler = handlers[source.bookSourceUrl];
    if (handler == null) {
      return Future.value(const <SearchBook>[]);
    }
    return handler(author);
  }
}

Book _makeBook() {
  return Book(
    bookUrl: 'https://example.com/book/1',
    name: '測試書',
    author: '作者甲',
    origin: 'source://main',
    originName: '主書源',
  );
}

BookSource _makeSource({
  required String url,
  required String name,
  String? group,
}) {
  return BookSource(
    bookSourceUrl: url,
    bookSourceName: name,
    bookSourceGroup: group,
    enabled: true,
  );
}

SearchBook _makeSearchBook({
  required String origin,
  required String originName,
  String latestChapterTitle = '第 10 章',
}) {
  return SearchBook(
    bookUrl: 'https://example.com/book/1',
    name: '測試書',
    author: '作者甲',
    latestChapterTitle: latestChapterTitle,
    origin: origin,
    originName: originName,
  );
}

Future<void> _settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  group('ChangeSourceProvider', () {
    test('保留成功來源並忽略單一來源失敗', () async {
      final sourceDao =
          _FakeBookSourceDao()
            ..sources = <BookSource>[
              _makeSource(url: 'source://ok', name: '可用書源'),
              _makeSource(url: 'source://fail', name: '失敗書源'),
            ];
      final searchBookDao = _FakeSearchBookDao();
      final service = _FakeBookSourceService();
      service.handlers['source://ok'] =
          (_) async => <SearchBook>[
            _makeSearchBook(origin: 'source://ok', originName: '可用書源'),
          ];
      service.handlers['source://fail'] =
          (_) => Future<List<SearchBook>>.error(Exception('network error'));

      final provider = ChangeSourceProvider(
        _makeBook(),
        service: service,
        sourceDao: sourceDao,
        searchBookDao: searchBookDao,
        autoStart: false,
      );

      await provider.loadGroups();
      await provider.startSearch();

      expect(provider.isSearching, isFalse);
      expect(provider.filteredResults.length, 1);
      expect(provider.filteredResults.single.originName, '可用書源');
      expect(provider.status, '搜尋完成 (1 個書源失敗)');
    });

    test('後一次搜尋不會被較慢的舊結果覆蓋', () async {
      final firstSearch = Completer<List<SearchBook>>();
      final secondSearch = Completer<List<SearchBook>>();
      final sourceDao =
          _FakeBookSourceDao()
            ..sources = <BookSource>[
              _makeSource(url: 'source://main', name: '主書源'),
            ];
      final searchBookDao = _FakeSearchBookDao();
      final service = _FakeBookSourceService();
      service.handlers['source://main'] = (author) {
        return author.isEmpty ? secondSearch.future : firstSearch.future;
      };

      final provider = ChangeSourceProvider(
        _makeBook(),
        service: service,
        sourceDao: sourceDao,
        searchBookDao: searchBookDao,
        autoStart: false,
      );

      unawaited(provider.startSearch());
      await _settle();
      provider.toggleCheckAuthor();
      await _settle();

      secondSearch.complete(<SearchBook>[
        _makeSearchBook(origin: 'source://main', originName: '新結果'),
      ]);
      await _settle();

      firstSearch.complete(<SearchBook>[
        _makeSearchBook(origin: 'source://main', originName: '舊結果'),
      ]);
      await _settle();

      expect(provider.isSearching, isFalse);
      expect(provider.filteredResults.single.originName, '新結果');
    });

    test('重新搜尋後仍保留目前的篩選條件', () async {
      final sourceDao =
          _FakeBookSourceDao()
            ..sources = <BookSource>[
              _makeSource(url: 'source://fast', name: '快源'),
              _makeSource(url: 'source://slow', name: '慢源'),
            ];
      final searchBookDao = _FakeSearchBookDao();
      final service = _FakeBookSourceService();
      service.handlers['source://fast'] =
          (_) async => <SearchBook>[
            _makeSearchBook(origin: 'source://fast', originName: '快源'),
          ];
      service.handlers['source://slow'] =
          (_) async => <SearchBook>[
            _makeSearchBook(
              origin: 'source://slow',
              originName: '慢源',
              latestChapterTitle: '慢速更新',
            ),
          ];

      final provider = ChangeSourceProvider(
        _makeBook(),
        service: service,
        sourceDao: sourceDao,
        searchBookDao: searchBookDao,
        autoStart: false,
      );

      provider.applyFilter('慢');
      await provider.startSearch();

      expect(provider.filteredResults.length, 1);
      expect(provider.filteredResults.single.originName, '慢源');
    });

    test('已隔離或搜尋失效來源不會進入換源搜尋池', () async {
      final sourceDao =
          _FakeBookSourceDao()
            ..sources = <BookSource>[
              _makeSource(url: 'source://ok', name: '可用書源'),
              _makeSource(
                url: 'source://broken',
                name: '搜尋失效書源',
                group: searchBrokenSourceGroupTag,
              ),
              _makeSource(
                url: 'source://quarantine',
                name: '隔離書源',
                group: quarantineSourceGroupTag,
              ),
            ];
      final searchBookDao = _FakeSearchBookDao();
      final service = _FakeBookSourceService();
      service.handlers['source://ok'] =
          (_) async => <SearchBook>[
            _makeSearchBook(origin: 'source://ok', originName: '可用書源'),
          ];

      final provider = ChangeSourceProvider(
        _makeBook(),
        service: service,
        sourceDao: sourceDao,
        searchBookDao: searchBookDao,
        autoStart: false,
      );

      await provider.startSearch();

      expect(service.requestedSources, <String>['source://ok']);
      expect(provider.filteredResults.single.origin, 'source://ok');
    });
  });
}
