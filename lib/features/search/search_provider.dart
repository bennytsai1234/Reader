import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/search_keyword_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/models/search_keyword.dart';
import 'package:inkpage_reader/core/services/bookshelf_state_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/search_scope.dart';
import 'search_model.dart';

/// SearchProvider - 搜尋頁面狀態管理
/// (對標 Legado SearchViewModel.kt)
///
/// 職責：UI 狀態管理、搜尋歷史 CRUD、委派 [SearchModel] 執行搜尋。
/// 搜尋引擎邏輯已提取到 [SearchModel]。
class SearchProvider extends ChangeNotifier implements SearchModelCallback {
  final BookSourceDao _sourceDao = getIt<BookSourceDao>();
  final SearchKeywordDao _keywordDao = getIt<SearchKeywordDao>();
  final BookshelfStateTracker _bookshelfTracker;

  late final SearchModel _searchModel;
  late SearchScope _searchScope;
  bool _scopeLoaded = false;

  // --- UI State ---
  List<SearchKeyword> _history = [];
  List<SearchBook> _results = [];
  bool _isSearching = false;
  String _currentSource = '';
  String _lastSearchKey = '';
  int _failedSources = 0;
  int _totalSources = 0;
  int _completedSources = 0;

  // --- 搜尋設定 ---
  bool _precisionSearch = false;
  List<String> _sourceGroups = [];

  // --- Getters ---
  List<SearchKeyword> get historyKeywords => _history;
  List<String> get history => _history.map((e) => e.word).toList();
  List<SearchBook> get results => _results;
  bool get isSearching => _isSearching;
  String get currentSource => _currentSource;
  String get lastSearchKey => _lastSearchKey;
  double get progress =>
      _totalSources == 0
          ? 0
          : (_completedSources / _totalSources).clamp(0.0, 1.0);
  int get failedSources => _failedSources;
  int get totalSources => _totalSources;
  bool get precisionSearch => _precisionSearch;
  List<String> get sourceGroups => _sourceGroups;
  SearchScope get searchScope => _searchScope;
  bool get scopeLoaded => _scopeLoaded;

  SearchProvider({BookshelfStateTracker? bookshelfTracker})
    : _bookshelfTracker = bookshelfTracker ?? BookshelfStateTracker() {
    _searchModel = SearchModel(callback: this);
    _searchScope = SearchScope();
    _init();
  }

  Future<void> _init() async {
    _searchScope = await SearchScope.load();
    _scopeLoaded = true;
    await _bookshelfTracker.initialize(onChanged: notifyListeners);
    await _loadGroups();
    await _loadPrecisionPreference();
    await loadHistory();
  }

  bool isInBookshelf(SearchBook book) =>
      _bookshelfTracker.containsSearchBook(book);

  // ═══════════════════════════════════════════
  // 搜尋範圍管理
  // ═══════════════════════════════════════════

  Future<void> _loadGroups() async {
    final sources = await _sourceDao.getAllPart();
    final groups = <String>{};
    for (var s in sources) {
      if (s.bookSourceGroup != null && s.bookSourceGroup!.isNotEmpty) {
        groups.addAll(s.bookSourceGroup!.split(',').map((e) => e.trim()));
      }
    }
    _sourceGroups = groups.toList()..sort();
    notifyListeners();
  }

  void updateSearchScope(SearchScope scope) {
    _searchScope = scope;
    notifyListeners();
    // 若正在顯示搜尋結果，自動以新範圍重新搜尋
    if (_lastSearchKey.isNotEmpty && !_isSearching) {
      search(_lastSearchKey);
    }
  }

  // ═══════════════════════════════════════════
  // 精準搜尋
  // ═══════════════════════════════════════════

  Future<void> _loadPrecisionPreference() async {
    final p = await SharedPreferences.getInstance();
    _precisionSearch = p.getBool('precision_search') ?? false;
    notifyListeners();
  }

  Future<void> togglePrecisionSearch() async {
    _precisionSearch = !_precisionSearch;
    final p = await SharedPreferences.getInstance();
    await p.setBool('precision_search', _precisionSearch);
    notifyListeners();
    if (_lastSearchKey.isNotEmpty) {
      search(_lastSearchKey);
    }
  }

  // ═══════════════════════════════════════════
  // 搜尋操作
  // ═══════════════════════════════════════════

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) return;
    _lastSearchKey = keyword;
    _results = [];
    notifyListeners();

    // 儲存搜尋歷史
    await _keywordDao.saveKeyword(keyword);
    await loadHistory();

    // 委派搜尋引擎
    await _searchModel.search(
      key: keyword,
      scope: _searchScope,
      precisionSearch: _precisionSearch,
    );
  }

  /// 在指定書源內搜尋
  Future<void> searchInSource(BookSource source, String keyword) async {
    if (keyword.isEmpty) return;
    _lastSearchKey = keyword;
    _results = [];

    // 使用單一書源的 scope
    final singleScope = SearchScope.fromSource(source);
    notifyListeners();

    await _searchModel.search(
      key: keyword,
      scope: singleScope,
      precisionSearch: _precisionSearch,
    );
  }

  void stopSearch() {
    _searchModel.cancelSearch();
    _isSearching = false;
    _currentSource = '已停止';
    notifyListeners();
  }

  // ═══════════════════════════════════════════
  // 搜尋歷史管理
  // ═══════════════════════════════════════════

  Future<void> loadHistory() async {
    _history = await _keywordDao.getByTime();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _keywordDao.clearAll();
    _history = [];
    notifyListeners();
  }

  Future<void> deleteHistoryKeyword(SearchKeyword keyword) async {
    await _keywordDao.deleteByWord(keyword.word);
    _history.removeWhere((e) => e.word == keyword.word);
    notifyListeners();
  }

  // ═══════════════════════════════════════════
  // SearchModelCallback 實現
  // ═══════════════════════════════════════════

  @override
  void onSearchStart() {
    _isSearching = true;
    _failedSources = 0;
    _completedSources = 0;
    notifyListeners();
  }

  @override
  void onSearchSuccess(List<SearchBook> searchBooks) {
    _results = searchBooks;
    notifyListeners();
  }

  @override
  void onSearchFinish({required bool isEmpty}) {
    _isSearching = false;
    notifyListeners();
  }

  @override
  void onSearchProgress({
    required String currentSource,
    required int completed,
    required int total,
    required int failed,
  }) {
    _currentSource = currentSource;
    _completedSources = completed;
    _totalSources = total;
    _failedSources = failed;
    notifyListeners();
  }

  @override
  void dispose() {
    _bookshelfTracker.dispose();
    _searchModel.dispose();
    super.dispose();
  }
}
