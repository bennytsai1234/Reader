import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/engine/web_book/web_book_service.dart';
import 'package:legado_reader/core/engine/explore_url_parser.dart';

class ExploreProvider extends ChangeNotifier {
  final BookSourceDao _sourceDao = getIt<BookSourceDao>();

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

  ExploreProvider() {
    _loadSources();
  }

  Future<void> _loadSources() async {
    final allEnabled = await _sourceDao.getEnabled();
    // 只顯示啟用了探索功能且有 exploreUrl 的書源
    _sources = allEnabled.where((s) => s.enabledExplore && s.hasExploreUrl).toList();
    if (_sources.isNotEmpty) {
      setSource(_sources.first);
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
    
    // 初始化選中狀態
    _selectedGroup = _groups.isNotEmpty ? _groups.first : null;
    final firstFiltered = filteredKinds;
    _selectedKind = firstFiltered.isNotEmpty ? firstFiltered.first : null;
    
    refreshExplore();
  }

  void setGroup(String group) {
    _selectedGroup = group;
    final firstFiltered = filteredKinds;
    _selectedKind = firstFiltered.isNotEmpty ? firstFiltered.first : null;
    refreshExplore();
  }

  void setKind(ExploreKind kind) {
    _selectedKind = kind;
    refreshExplore();
  }

  Future<void> refreshExplore() async {
    if (_selectedSource == null || _selectedKind == null) return;
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

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await WebBook.exploreBookAwait(
        _selectedSource!, 
        _selectedKind!.url, 
        page: _page
      );
      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _books.addAll(results);
      }
    } catch (e) {
      debugPrint('探索失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
