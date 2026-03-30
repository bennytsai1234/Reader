import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/database/app_database.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/search_history_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:pool/pool.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = getIt<BookSourceDao>();
  final SearchHistoryDao _historyDao = getIt<SearchHistoryDao>();
  final BookSourceService _service = BookSourceService();

  List<SearchHistoryRow> _history = [];
  List<AggregatedSearchBook> _results = [];
  bool _isSearching = false;
  bool _isCancelled = false;
  int _searchCount = 0;
  int _totalSources = 0;
  String _currentSource = '';
  String _lastSearchKey = '';
  CancelToken? _cancelToken;
  int _failedSources = 0;

  // 搜尋範圍與精準搜尋
  List<String> _sourceGroups = ['全部'];
  String _selectedGroup = '全部';
  bool _precisionSearch = false;
  final List<String> _hotKeywords = ['劍來', '道詭異仙', '靈境行者', '深海餘燼', '赤心巡天', '大奉打更人'];

  List<String> get history => _history.map((e) => e.keyword).toList();
  List<AggregatedSearchBook> get results => _results;
  bool get isSearching => _isSearching;
  String get currentSource => _currentSource;
  String get lastSearchKey => _lastSearchKey;
  double get progress => _totalSources == 0 ? 0 : (_searchCount / _totalSources).clamp(0.0, 1.0);
  int get failedSources => _failedSources;
  int get totalSources => _totalSources;

  List<String> get sourceGroups => _sourceGroups;
  String get selectedGroup => _selectedGroup;
  bool get precisionSearch => _precisionSearch;
  List<String> get hotKeywords => _hotKeywords;

  SearchProvider() {
    loadHistory();
    _loadGroups();
    _loadPrecisionPreference();
  }

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

  void stopSearch() {
    _isCancelled = true;
    _cancelToken?.cancel('使用者取消搜尋');
    _cancelToken = null;
    _isSearching = false;
    _currentSource = '已停止';
    notifyListeners();
  }

  Future<void> _loadGroups() async {
    final sources = await _sourceDao.getAllPart();
    final groups = <String>{};
    for (var s in sources) {
      if (s.bookSourceGroup != null && s.bookSourceGroup!.isNotEmpty) {
        groups.addAll(s.bookSourceGroup!.split(',').map((e) => e.trim()));
      }
    }
    _sourceGroups = ['全部', ...groups.toList()..sort()];
    notifyListeners();
  }

  void setGroup(String group) {
    if (_selectedGroup != group) {
      _selectedGroup = group;
      notifyListeners();
      if (_lastSearchKey.isNotEmpty) {
        search(_lastSearchKey);
      }
    }
  }

  Future<void> loadHistory() async {
    _history = await _historyDao.getRecent();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _historyDao.clearAll();
    _history = [];
    notifyListeners();
  }

  Future<void> search(String keyword) async {
    if (keyword.isEmpty) return;
    _cancelToken?.cancel('新搜尋開始');
    _lastSearchKey = keyword;
    _isSearching = true;
    _isCancelled = false;
    _results = [];
    _searchCount = 0;
    _failedSources = 0;
    _cancelToken = CancelToken();
    notifyListeners();

    await _historyDao.add(keyword);
    await loadHistory();

    var enabledSources = await _sourceDao.getEnabled();
    if (_selectedGroup != '全部') {
      enabledSources = enabledSources.where((s) {
        final g = s.bookSourceGroup ?? '';
        return g.split(',').map((e) => e.trim()).contains(_selectedGroup);
      }).toList();
    }

    _totalSources = enabledSources.length;
    if (_totalSources == 0) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    final threadCount = await SharedPreferences.getInstance().then((p) => p.getInt('thread_count') ?? 8);
    final searchPool = Pool(threadCount);

    final tasks = <Future<void>>[];
    for (final source in enabledSources) {
      if (_isCancelled) break;
      tasks.add(searchPool.withResource(() async {
        if (_isCancelled) return;
        return _searchSingleSource(source, keyword);
      }));
    }

    await Future.wait(tasks);
    _isSearching = false;
    notifyListeners();
  }

  Future<void> searchInSource(BookSource source, String keyword) async {
    if (keyword.isEmpty) return;
    _cancelToken?.cancel('新搜尋開始');
    _lastSearchKey = keyword;
    _isSearching = true;
    _isCancelled = false;
    _results = [];
    _searchCount = 0;
    _failedSources = 0;
    _totalSources = 1;
    _cancelToken = CancelToken();
    notifyListeners();

    try {
      await _searchSingleSource(source, keyword);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> _searchSingleSource(BookSource source, String keyword) async {
    if (_isCancelled) return;
    _currentSource = source.bookSourceName;
    notifyListeners();
    try {
      if (_isCancelled) return;

      final books = await _service
          .searchBooks(source, keyword, cancelToken: _cancelToken)
          .timeout(const Duration(seconds: 30));
      if (_isCancelled) return;

      // 精準搜尋過濾
      final filteredBooks = _precisionSearch
          ? books.where((b) => b.name == keyword || b.author == keyword).toList()
          : books;

      _aggregateResults(filteredBooks);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      _failedSources++;
      AppLog.e('搜尋失敗 [${source.bookSourceName}]: $e', error: e);
    } catch (e) {
      _failedSources++;
      AppLog.e('搜尋失敗 [${source.bookSourceName}]: $e', error: e);
    } finally {
      _searchCount++;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Provider disposed');
    _cancelToken = null;
    super.dispose();
  }

  void _aggregateResults(List<SearchBook> newBooks) {
    for (final newBook in newBooks) {
      final normalizedAuthor = newBook.getRealAuthor();
      final index = _results.indexWhere(
        (r) => r.book.name == newBook.name && r.book.getRealAuthor() == normalizedAuthor,
      );

      if (index != -1) {
        if (!_results[index].sources.contains(newBook.originName)) {
          _results[index].sources.add(newBook.originName ?? '未知來源');
        }
      } else {
        _results.add(AggregatedSearchBook(book: newBook, sources: [newBook.originName ?? '未知來源']));
      }
    }
    _results.sort((a, b) => b.sources.length.compareTo(a.sources.length));
  }
}

