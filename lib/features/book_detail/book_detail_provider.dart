import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:legado_reader/core/engine/app_event_bus.dart';
import 'package:legado_reader/core/di/injection.dart';

class BookDetailProvider extends ChangeNotifier {
  final BookDao _bookDao = getIt<BookDao>();
  final ChapterDao _chapterDao = getIt<ChapterDao>();
  final BookSourceDao _sourceDao = getIt<BookSourceDao>();
  final BookSourceService _service = BookSourceService();

  late Book _book;
  List<BookChapter> _allChapters = [];
  List<BookChapter> _displayChapters = [];
  bool _isLoading = true;
  bool _isInBookshelf = false;
  BookSource? _currentSource;
  BookSource? get currentSource => _currentSource;

  Book get book => _book;
  List<BookChapter> get filteredChapters => _displayChapters;
  int get totalChapterCount => _allChapters.length;
  bool get isLoading => _isLoading;
  bool get isInBookshelf => _isInBookshelf;

  String _searchQuery = '';
  bool _isReversed = false;
  bool get isReversed => _isReversed;
  
  Timer? _debounce;

  BookDetailProvider(AggregatedSearchBook searchBook) {
    _book = searchBook.book is Book ? searchBook.book as Book : Book(
      bookUrl: searchBook.book.bookUrl,
      name: searchBook.book.name,
      author: searchBook.book.author ?? '未知',
      coverUrl: searchBook.book.coverUrl,
      intro: searchBook.book.intro,
      origin: searchBook.book.origin,
      originName: searchBook.book.originName ?? '發現',
      type: searchBook.book.type,
    );
    _init();
  }

  Future<void> _init() async {
    final existing = await _bookDao.getByUrl(_book.bookUrl);
    if (existing != null) {
      _book = existing;
      _isInBookshelf = true;
    }
    await _loadSource();
    await _loadBookInfo();
    await _loadChapters();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSource() async {
    _currentSource = await _sourceDao.getByUrl(_book.origin);
  }

  /// 載入書籍詳情 (對標 Android BookInfoViewModel.loadBookInfo)
  /// 從書源獲取完整書籍資訊，包含 tocUrl、簡介、封面等
  Future<void> _loadBookInfo() async {
    if (_currentSource == null) return;
    try {
      final updatedBook = await _service.getBookInfo(_currentSource!, _book);
      _book = updatedBook;
      if (_isInBookshelf) {
        await _bookDao.upsert(_book);
      }
    } catch (e) {
      AppLog.e('加載書籍詳情失敗: $e', error: e);
      // 即使加載詳情失敗，仍嘗試用已有資訊載入目錄
      // 若 tocUrl 為空，以 bookUrl 作為備用
      if (_book.tocUrl.isEmpty) {
        _book.tocUrl = _book.bookUrl;
      }
    }
  }

  Future<void> _loadChapters() async {
    _allChapters = await _chapterDao.getChapters(_book.bookUrl);
    
    if (_allChapters.isEmpty && _currentSource != null) {
      try {
        _allChapters = await _service.getChapterList(_currentSource!, _book);
        if (_isInBookshelf) await _chapterDao.insertChapters(_allChapters);
      } catch (e) { AppLog.e('加載目錄失敗: $e', error: e); }
    }
    _applyFilter();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilter();
    });
  }

  void toggleSort() {
    _isReversed = !_isReversed;
    _applyFilter();
  }

  void _applyFilter() {
    var list = _allChapters;
    if (_searchQuery.isNotEmpty) {
      list = list.where((c) => c.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    _displayChapters = _isReversed ? list.reversed.toList() : List.from(list);
    notifyListeners();
  }

  /// 執行換源 (繼承舊版實作)
  Future<void> changeSource(SearchBook newSource) async {
    _isLoading = true;
    notifyListeners();
    try {
      final oldUrl = _book.bookUrl;
      _book.bookUrl = newSource.bookUrl;
      _book.origin = newSource.origin;
      _book.originName = newSource.originName ?? '未知';
      _book.tocUrl = newSource.tocUrl ?? '';
      await _loadSource();
      _allChapters = [];
      if (_currentSource != null) {
        _allChapters = await _service.getChapterList(_currentSource!, _book);
      }
      if (_isInBookshelf) {
        await _bookDao.deleteByUrl(oldUrl);
        await _bookDao.upsert(_book);
        await _chapterDao.insertChapters(_allChapters);
      }
      _applyFilter();
      AppEventBus().fire(AppEventBus.upBookshelf);
    } catch (e) { AppLog.e('換源失敗: $e', error: e); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> toggleInBookshelf() async {
    _isInBookshelf = !_isInBookshelf;
    _book.isInBookshelf = _isInBookshelf;
    
    if (_isInBookshelf) {
      _isLoading = true;
      notifyListeners();
      try {
        if (_allChapters.isEmpty) {
          await _loadChapters();
        }
        await _bookDao.upsert(_book);
        if (_allChapters.isNotEmpty) {
          await _chapterDao.insertChapters(_allChapters);
        }
      } catch (e) {
        AppLog.e('加入書架失敗: $e', error: e);
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      await _bookDao.upsert(_book);
      // 選用：移除書架時是否刪除章節？通常保留以利再次加入
    }
    
    AppEventBus().fire(AppEventBus.upBookshelf);
    notifyListeners();
  }

  Future<void> updateBookInfo(String name, String author, String intro, String coverUrl) async {
    _book.name = name; _book.author = author; _book.intro = intro; _book.coverUrl = coverUrl;
    if (_isInBookshelf) await _bookDao.upsert(_book);
    notifyListeners();
  }

  Future<void> updateCover(String url) async {
    _book.customCoverUrl = url;
    if (_isInBookshelf) await _bookDao.upsert(_book);
    notifyListeners();
  }

  void clearCache() {
    _chapterDao.deleteContentByBook(_book.bookUrl);
  }

  void preloadChapters(int start, int count) {
    // 預加載邏輯實作
    AppLog.d('Preloading $count chapters from $start');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
