import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/download_service.dart';
import 'package:inkpage_reader/core/engine/app_event_bus.dart';
import 'package:inkpage_reader/core/di/injection.dart';

class OfflineCacheQueueResult {
  const OfflineCacheQueueResult._({
    required this.queuedChapterCount,
    required this.message,
  });

  final int queuedChapterCount;
  final String message;

  factory OfflineCacheQueueResult.queued(int count) {
    return OfflineCacheQueueResult._(
      queuedChapterCount: count,
      message: '已加入離線快取佇列，共 $count 章',
    );
  }

  factory OfflineCacheQueueResult.blocked(String message) {
    return OfflineCacheQueueResult._(queuedChapterCount: 0, message: message);
  }
}

class BookDetailProvider extends ChangeNotifier {
  final BookDao _bookDao;
  final ChapterDao _chapterDao;
  final BookSourceDao _sourceDao;
  final BookSourceService _service;
  DownloadService? _downloadService;

  late Book _book;
  List<BookChapter> _allChapters = [];
  List<BookChapter> _displayChapters = [];
  bool _isLoading = true;
  bool _isInBookshelf = false;
  BookSource? _currentSource;
  BookSource? get currentSource => _currentSource;
  String? _sourceIssueMessage;
  String? get sourceIssueMessage => _sourceIssueMessage;

  Book get book => _book;
  List<BookChapter> get filteredChapters => _displayChapters;
  List<BookChapter> get allChapters => List.unmodifiable(_allChapters);
  int get totalChapterCount => _allChapters.length;
  bool get isLoading => _isLoading;
  bool get isInBookshelf => _isInBookshelf;
  bool get supportsOfflineCache => _book.origin != 'local';
  DownloadService get _resolvedDownloadService =>
      _downloadService ??= DownloadService();

  String _searchQuery = '';
  bool _isReversed = false;
  bool get isReversed => _isReversed;

  Timer? _debounce;

  BookDetailProvider(
    AggregatedSearchBook searchBook, {
    BookDao? bookDao,
    ChapterDao? chapterDao,
    BookSourceDao? sourceDao,
    BookSourceService? service,
    DownloadService? downloadService,
  }) : _bookDao = bookDao ?? getIt<BookDao>(),
       _chapterDao = chapterDao ?? getIt<ChapterDao>(),
       _sourceDao = sourceDao ?? getIt<BookSourceDao>(),
       _service = service ?? BookSourceService(),
       _downloadService = downloadService {
    _book =
        searchBook.book is Book
            ? searchBook.book as Book
            : Book(
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
    final health = _currentSource?.runtimeHealth;
    if (health != null &&
        health.category != SourceHealthCategory.healthy &&
        !health.allowsReading) {
      _sourceIssueMessage = health.description;
    } else {
      _sourceIssueMessage = null;
    }
  }

  /// 載入書籍詳情 (對標 Android BookInfoViewModel.loadBookInfo)
  /// 從書源獲取完整書籍資訊，包含 tocUrl、簡介、封面等
  Future<void> _loadBookInfo() async {
    if (_currentSource == null) return;
    if (!_currentSource!.isReadingEnabledByRuntime) {
      return;
    }
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
      if (!_currentSource!.isReadingEnabledByRuntime) {
        _applyFilter();
        return;
      }
      try {
        _allChapters = await _service.getChapterList(_currentSource!, _book);
        if (_isInBookshelf) await _chapterDao.insertChapters(_allChapters);
      } catch (e) {
        _sourceIssueMessage = '目前來源目錄載入失敗，建議換源後再試';
        AppLog.e('加載目錄失敗: $e', error: e);
      }
    }
    _applyFilter();
  }

  Future<OfflineCacheQueueResult> queueDownloadAll() async {
    return _queueOfflineCache(
      resolveChapters: (_) => List<BookChapter>.from(_allChapters),
      emptyMessage: '目前沒有可離線快取的章節',
    );
  }

  Future<OfflineCacheQueueResult> queueDownloadFromCurrent() async {
    return _queueOfflineCache(
      resolveChapters: (_) {
        final startIndex = book.durChapterIndex.clamp(0, _allChapters.length);
        return _allChapters
            .where((chapter) => chapter.index >= startIndex)
            .toList();
      },
      emptyMessage: '目前進度之後沒有可離線快取的章節',
    );
  }

  Future<OfflineCacheQueueResult> queueDownloadUncached() async {
    return _queueOfflineCache(
      resolveChapters:
          (cachedIndices) =>
              _allChapters
                  .where((chapter) => !cachedIndices.contains(chapter.index))
                  .toList(),
      emptyMessage: '目前沒有新的章節需要離線快取',
    );
  }

  Future<OfflineCacheQueueResult> _queueOfflineCache({
    required List<BookChapter> Function(Set<int> cachedIndices) resolveChapters,
    required String emptyMessage,
  }) async {
    final blockedReason = await _prepareOfflineCacheQueue();
    if (blockedReason != null) {
      return OfflineCacheQueueResult.blocked(blockedReason);
    }

    final cachedIndices = await _chapterDao.getCachedChapterIndices(
      _book.bookUrl,
    );
    final chapters = resolveChapters(cachedIndices);
    if (chapters.isEmpty) {
      return OfflineCacheQueueResult.blocked(emptyMessage);
    }

    await _resolvedDownloadService.addDownloadTask(_book, chapters);
    return OfflineCacheQueueResult.queued(chapters.length);
  }

  Future<String?> _prepareOfflineCacheQueue() async {
    if (!supportsOfflineCache) {
      return '這本書已經在裝置內，不需要再加入離線快取。';
    }

    if (_currentSource == null) {
      await _loadSource();
    }
    final source = _currentSource;
    if (source == null) {
      return '目前找不到書源，請先換源後再試。';
    }
    if (!source.isReadingEnabledByRuntime) {
      return _sourceIssueMessage ?? '目前來源無法提供正文，請先換源後再試。';
    }

    if (_allChapters.isEmpty) {
      await _loadChapters();
    }
    if (_allChapters.isEmpty) {
      return _sourceIssueMessage ?? '目前沒有可離線快取的章節。';
    }

    var bookshelfChanged = false;
    if (!_isInBookshelf) {
      _isInBookshelf = true;
      _book.isInBookshelf = true;
      bookshelfChanged = true;
    }

    await _bookDao.upsert(_book);
    await _chapterDao.insertChapters(_allChapters);

    if (bookshelfChanged) {
      AppEventBus().fire(AppEventBus.upBookshelf);
      notifyListeners();
    }

    return null;
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
      list =
          list
              .where(
                (c) =>
                    c.title.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
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
      await _loadBookInfo();
      _allChapters = [];
      if (_currentSource != null) {
        _allChapters = await _service.getChapterList(_currentSource!, _book);
      }
      if (_isInBookshelf) {
        await _bookDao.deleteByUrl(oldUrl);
        await _chapterDao.deleteByBook(oldUrl);
        await _chapterDao.deleteByBook(_book.bookUrl);
        await _bookDao.upsert(_book);
        await _chapterDao.insertChapters(_allChapters);
      }
      _applyFilter();
      AppEventBus().fire(AppEventBus.upBookshelf);
    } catch (e) {
      AppLog.e('換源失敗: $e', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<void> updateBookInfo(
    String name,
    String author,
    String intro,
    String coverUrl,
  ) async {
    _book.name = name;
    _book.author = author;
    _book.intro = intro;
    _book.coverUrl = coverUrl;
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
