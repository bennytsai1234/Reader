import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/engine/web_book/web_book_service.dart';
import 'package:legado_reader/core/engine/explore_url_parser.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExploreProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = getIt<BookSourceDao>();
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  List<BookSource> _sources = [];
  BookSource? _selectedSource;

  List<ExploreKind> _allKinds = [];
  List<String> _groups = [];
  String? _selectedGroup;
  ExploreKind? _selectedKind;

  List<SearchBook> _books = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  List<BookSource> get sources => _sources;
  BookSource? get selectedSource => _selectedSource;
  List<String> get groups => _groups;
  String? get selectedGroup => _selectedGroup;
  List<ExploreKind> get filteredKinds => _selectedGroup == null
      ? _allKinds.where((k) => k.group == null).toList()
      : _allKinds.where((k) => k.group == _selectedGroup).toList();
  ExploreKind? get selectedKind => _selectedKind;
  List<SearchBook> get books => _books;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ExploreProvider() {
    _loadSources();
  }

  Future<void> _loadSources() async {
    final allEnabled = await _sourceDao.getEnabled();
    // 只顯示啟用了探索功能且有 exploreUrl 的書源
    _sources = allEnabled.where((s) => s.enabledExplore && s.hasExploreUrl).toList();
    if (_sources.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final lastSourceUrl = prefs.getString('explore_last_source');
      final restored = _sources.where((s) => s.bookSourceUrl == lastSourceUrl).firstOrNull;
      setSource(restored ?? _sources.first);
    }
    notifyListeners();
  }

  void setSource(BookSource? source) {
    _selectedSource = source;
    if (source == null) {
      _allKinds = [];
      _groups = [];
      _selectedGroup = null;
      _selectedKind = null;
      _books = [];
      notifyListeners();
      return;
    }
    _allKinds = ExploreUrlParser.parse(source.exploreUrl, source: source);

    // 提取所有唯一分組
    final groupSet = _allKinds.where((k) => k.group != null).map((k) => k.group!).toSet();
    _groups = groupSet.toList()..sort();

    // 嘗試恢復上次選擇的分類
    _restoreKindSelection();

    // 持久化選擇
    _saveSelection();

    // debounce 網路請求
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      refreshExplore();
    });
  }

  Future<void> _restoreKindSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGroup = prefs.getString('explore_last_group');
    final lastKindTitle = prefs.getString('explore_last_kind');

    if (lastGroup != null && _groups.contains(lastGroup)) {
      _selectedGroup = lastGroup;
    } else {
      _selectedGroup = _groups.isNotEmpty ? _groups.first : null;
    }

    final kinds = filteredKinds;
    final restoredKind = lastKindTitle != null
        ? kinds.where((k) => k.title == lastKindTitle).firstOrNull
        : null;
    _selectedKind = restoredKind ?? (kinds.isNotEmpty ? kinds.first : null);
    notifyListeners();
  }

  Future<void> _saveSelection() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedSource != null) {
      await prefs.setString('explore_last_source', _selectedSource!.bookSourceUrl);
    }
    if (_selectedGroup != null) {
      await prefs.setString('explore_last_group', _selectedGroup!);
    }
    if (_selectedKind != null) {
      await prefs.setString('explore_last_kind', _selectedKind!.title);
    }
  }

  void setGroup(String group) {
    _selectedGroup = group;
    final firstFiltered = filteredKinds;
    _selectedKind = firstFiltered.isNotEmpty ? firstFiltered.first : null;
    _saveSelection();
    refreshExplore();
  }

  void setKind(ExploreKind kind) {
    _selectedKind = kind;
    _saveSelection();
    refreshExplore();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cancelToken?.cancel('ExploreProvider disposed');
    super.dispose();
  }

  Future<void> refreshExplore() async {
    if (_selectedSource == null || _selectedKind == null) return;
    _cancelToken?.cancel('new explore request');
    _page = 1;
    _books = [];
    _hasMore = true;
    _loadData();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    _page++;
    _loadData();
  }

  bool get hasMore => _hasMore;

  Future<void> refresh() => refreshExplore();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _cancelToken = CancelToken();

    try {
      // TODO: pass _cancelToken to WebBook.exploreBookAwait once it supports cancelToken parameter
      final results = await WebBook.exploreBookAwait(
        _selectedSource!,
        _selectedKind!.url,
        page: _page,
      );
      if (_cancelToken?.isCancelled ?? false) return;
      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _books.addAll(results);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      AppLog.e('探索失敗', error: e);
      _errorMessage = '載入失敗：$e';
      if (_page > 1) _page--;
    } catch (e) {
      AppLog.e('探索失敗', error: e);
      _errorMessage = '載入失敗：$e';
      if (_page > 1) _page--;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
