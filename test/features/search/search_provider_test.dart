import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/search_keyword_dao.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_keyword.dart';
import 'package:legado_reader/features/search/search_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake DAOs
// ---------------------------------------------------------------------------

class _FakeSourceDao extends Fake implements BookSourceDao {
  List<BookSource> sources = [];

  @override
  Future<List<BookSource>> getAllPart() async => sources;

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((s) => s.enabled).toList();

  @override
  Future<List<BookSource>> getAll() async => sources;

  @override
  Future<BookSource?> getByUrl(String url) async =>
      sources.where((s) => s.bookSourceUrl == url).firstOrNull;
}

class _FakeKeywordDao extends Fake implements SearchKeywordDao {
  final List<SearchKeyword> _keywords = [];

  @override
  Future<List<SearchKeyword>> getByTime() async => _keywords;

  @override
  Future<List<SearchKeyword>> getAll() async => _keywords;

  @override
  Future<void> saveKeyword(String word) async {
    final idx = _keywords.indexWhere((k) => k.word == word);
    if (idx != -1) {
      _keywords[idx].usage += 1;
      _keywords[idx].lastUseTime = DateTime.now().millisecondsSinceEpoch;
    } else {
      _keywords.add(SearchKeyword(
        word: word,
        usage: 1,
        lastUseTime: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  @override
  Future<void> clearAll() async => _keywords.clear();

  @override
  Future<void> deleteByWord(String word) async =>
      _keywords.removeWhere((k) => k.word == word);

  @override
  Future<SearchKeyword?> getByWord(String word) async =>
      _keywords.where((k) => k.word == word).firstOrNull;
}

// ---------------------------------------------------------------------------
// 測試
// ---------------------------------------------------------------------------

void main() {
  late _FakeSourceDao fakeSourceDao;
  late _FakeKeywordDao fakeKeywordDao;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSourceDao = _FakeSourceDao();
    fakeKeywordDao = _FakeKeywordDao();

    final getIt = GetIt.instance;
    getIt.registerLazySingleton<BookSourceDao>(() => fakeSourceDao);
    getIt.registerLazySingleton<SearchKeywordDao>(() => fakeKeywordDao);
  });

  tearDown(() async => GetIt.instance.reset());

  Future<SearchProvider> makeProvider() async {
    final p = SearchProvider();
    await Future.delayed(Duration.zero); // 等 constructor async 完成
    return p;
  }

  group('SearchProvider - 書源群組', () {
    test('無書源時 sourceGroups 為空', () async {
      final p = await makeProvider();
      expect(p.sourceGroups, isEmpty);
    });

    test('有群組的書源會加入 sourceGroups', () async {
      fakeSourceDao.sources = [
        BookSource(bookSourceUrl: 'http://a.com', bookSourceName: 'A', bookSourceGroup: '玄幻'),
        BookSource(bookSourceUrl: 'http://b.com', bookSourceName: 'B', bookSourceGroup: '都市'),
      ];
      final p = await makeProvider();
      expect(p.sourceGroups, containsAll(['玄幻', '都市']));
    });

    test('searchScope 初始為全部', () async {
      final p = await makeProvider();
      expect(p.searchScope.isAll, isTrue);
    });
  });

  group('SearchProvider - 精準搜尋', () {
    test('初始 precisionSearch 為 false', () async {
      final p = await makeProvider();
      expect(p.precisionSearch, isFalse);
    });

    test('togglePrecisionSearch 切換狀態並寫入 prefs', () async {
      final p = await makeProvider();
      await p.togglePrecisionSearch();
      expect(p.precisionSearch, isTrue);
      await p.togglePrecisionSearch();
      expect(p.precisionSearch, isFalse);
    });
  });

  group('SearchProvider - 搜尋狀態', () {
    test('search 空字串不啟動搜尋', () async {
      final p = await makeProvider();
      await p.search('');
      expect(p.isSearching, isFalse);
      expect(p.lastSearchKey, isEmpty);
    });

    test('stopSearch 設定 isSearching = false', () async {
      final p = await makeProvider();
      // 直接呼叫 stopSearch，不實際觸發網路
      p.stopSearch();
      expect(p.isSearching, isFalse);
    });

    test('無啟用書源時 search 完成後 isSearching = false', () async {
      fakeSourceDao.sources = [];
      final p = await makeProvider();
      await p.search('測試');
      expect(p.isSearching, isFalse);
      expect(p.lastSearchKey, '測試');
    });
  });

  group('SearchProvider - 搜尋歷史', () {
    test('初始歷史為空', () async {
      final p = await makeProvider();
      expect(p.history, isEmpty);
    });

    test('搜尋後歷史更新', () async {
      fakeSourceDao.sources = [];
      final p = await makeProvider();
      await p.search('閱讀');
      expect(p.history, contains('閱讀'));
    });

    test('clearHistory 清空歷史', () async {
      fakeSourceDao.sources = [];
      final p = await makeProvider();
      await p.search('閱讀');
      await p.clearHistory();
      expect(p.history, isEmpty);
    });

    test('deleteHistoryKeyword 刪除單條記錄', () async {
      fakeSourceDao.sources = [];
      final p = await makeProvider();
      await p.search('閱讀');
      await p.search('搜尋');
      expect(p.history.length, 2);

      final keyword = p.historyKeywords.firstWhere((k) => k.word == '閱讀');
      await p.deleteHistoryKeyword(keyword);
      expect(p.history, isNot(contains('閱讀')));
      expect(p.history, contains('搜尋'));
    });
  });

  group('SearchProvider - progress', () {
    test('無書源時 progress 為 0', () async {
      final p = await makeProvider();
      expect(p.progress, 0.0);
    });

    test('totalSources 初始為 0', () async {
      final p = await makeProvider();
      expect(p.totalSources, 0);
    });
  });
}
