import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/services/book_cover_storage_service.dart';
import 'package:inkpage_reader/core/services/download_service.dart';
import 'package:inkpage_reader/core/engine/app_event_bus.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_store.dart';

class StorageDownloadQueueResult {
  const StorageDownloadQueueResult._({
    required this.queuedChapterCount,
    required this.message,
  });

  final int queuedChapterCount;
  final String message;

  factory StorageDownloadQueueResult.queued(int count) {
    return StorageDownloadQueueResult._(
      queuedChapterCount: count,
      message: '已加入背景下載佇列，共 $count 章',
    );
  }

  factory StorageDownloadQueueResult.blocked(String message) {
    return StorageDownloadQueueResult._(
      queuedChapterCount: 0,
      message: message,
    );
  }
}

class BookDetailProvider extends ChangeNotifier {
  final BookDao _bookDao;
  final ChapterDao _chapterDao;
  final BookSourceDao _sourceDao;
  final ReaderChapterContentDao? _chapterContentDao;
  final BookSourceService _service;
  final BookCoverStorageService _coverStorage;
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
  bool get supportsBackgroundDownload => _book.origin != 'local';
  DownloadService get _resolvedDownloadService =>
      _downloadService ??= DownloadService();

  String _searchQuery = '';
  bool _isReversed = false;
  bool _disposed = false;
  bool get isReversed => _isReversed;

  Timer? _debounce;

  BookDetailProvider(
    AggregatedSearchBook searchBook, {
    BookDao? bookDao,
    ChapterDao? chapterDao,
    BookSourceDao? sourceDao,
    ReaderChapterContentDao? chapterContentDao,
    BookSourceService? service,
    BookCoverStorageService? coverStorage,
    DownloadService? downloadService,
  }) : _bookDao = bookDao ?? getIt<BookDao>(),
       _chapterDao = chapterDao ?? getIt<ChapterDao>(),
       _sourceDao = sourceDao ?? getIt<BookSourceDao>(),
       _chapterContentDao =
           chapterContentDao ??
           (getIt.isRegistered<ReaderChapterContentDao>()
               ? getIt<ReaderChapterContentDao>()
               : null),
       _service = service ?? BookSourceService(),
       _coverStorage = coverStorage ?? BookCoverStorageService(),
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
      _isInBookshelf = existing.isInBookshelf;
    } else {
      _book.isInBookshelf = false;
      await _bookDao.upsert(_book);
    }
    await _loadSource();
    await _loadBookInfo();
    await _loadChapters();
    unawaited(_storeDisplayCover());
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
      final wasInBookshelf = _book.isInBookshelf;
      final coverLocalPath = _book.coverLocalPath;
      final customCoverUrl = _book.customCoverUrl;
      final customCoverLocalPath = _book.customCoverLocalPath;
      final updatedBook = await _service.getBookInfo(_currentSource!, _book);
      updatedBook.isInBookshelf = wasInBookshelf;
      updatedBook.coverLocalPath = coverLocalPath;
      updatedBook.customCoverUrl = customCoverUrl;
      updatedBook.customCoverLocalPath = customCoverLocalPath;
      _book = updatedBook;
      await _bookDao.upsert(_book);
    } catch (e) {
      AppLog.e('加載書籍詳情失敗: $e', error: e);
      // 即使加載詳情失敗，仍嘗試用已有資訊載入目錄
      // 若 tocUrl 為空，以 bookUrl 作為備用
      if (_book.tocUrl.isEmpty) {
        _book.tocUrl = _book.bookUrl;
      }
      await _bookDao.upsert(_book);
    }
  }

  Future<void> _loadChapters() async {
    _allChapters = await _chapterDao.getByBook(_book.bookUrl);

    if (_allChapters.isEmpty && _currentSource != null) {
      if (!_currentSource!.isReadingEnabledByRuntime) {
        _applyFilter();
        return;
      }
      try {
        _allChapters = await _service.getChapterList(_currentSource!, _book);
        await _chapterDao.insertChapters(_allChapters);
      } catch (e) {
        _sourceIssueMessage = '目前來源目錄載入失敗，建議換源後再試';
        AppLog.e('加載目錄失敗: $e', error: e);
      }
    }
    _applyFilter();
  }

  Future<StorageDownloadQueueResult> queueDownloadAll() async {
    return _queueStorageDownload(
      resolveChapters: (_) => List<BookChapter>.from(_allChapters),
      emptyMessage: '目前沒有可下載的章節',
    );
  }

  Future<StorageDownloadQueueResult> queueDownloadFromCurrent() async {
    return _queueStorageDownload(
      resolveChapters: (_) {
        final startIndex = book.chapterIndex.clamp(0, _allChapters.length);
        return _allChapters
            .where((chapter) => chapter.index >= startIndex)
            .toList();
      },
      emptyMessage: '目前進度之後沒有可下載的章節',
    );
  }

  Future<StorageDownloadQueueResult> queueDownloadMissing() async {
    return _queueStorageDownload(
      resolveChapters:
          (storedIndices) =>
              _allChapters
                  .where((chapter) => !storedIndices.contains(chapter.index))
                  .toList(),
      emptyMessage: '目前沒有新的章節需要下載',
    );
  }

  Future<StorageDownloadQueueResult> _queueStorageDownload({
    required List<BookChapter> Function(Set<int> storedIndices) resolveChapters,
    required String emptyMessage,
  }) async {
    final blockedReason = await _prepareStorageDownloadQueue();
    if (blockedReason != null) {
      return StorageDownloadQueueResult.blocked(blockedReason);
    }

    final storedIndices = await _storedChapterIndices();
    final chapters = resolveChapters(storedIndices);
    if (chapters.isEmpty) {
      return StorageDownloadQueueResult.blocked(emptyMessage);
    }

    await _resolvedDownloadService.addDownloadTask(_book, chapters);
    return StorageDownloadQueueResult.queued(chapters.length);
  }

  Future<String?> _prepareStorageDownloadQueue() async {
    if (!supportsBackgroundDownload) {
      return '這本書已經在裝置內，不需要背景下載。';
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
      return _sourceIssueMessage ?? '目前沒有可下載的章節。';
    }

    await _bookDao.upsert(_book);
    await _saveChapterMetadataIfPossible();

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

  /// 執行換源：來源切換建立為另一本書，不覆蓋/刪除原書 storage。
  Future<void> changeSource(SearchBook newSource) async {
    _isLoading = true;
    notifyListeners();
    try {
      final oldBook = _book.copyWith();
      final candidate = newSource.toBook();
      final source = await _sourceDao.getByUrl(candidate.origin);
      if (source == null) {
        throw StateError('找不到對應書源');
      }
      _currentSource = source;
      final hydratedBook = await _service.getBookInfo(source, candidate);
      final nextBook = oldBook.migrateTo(
        hydratedBook.copyWith(isInBookshelf: oldBook.isInBookshelf),
        const <BookChapter>[],
      );
      _book = nextBook;
      await _loadSource();
      await _loadBookInfo();
      _allChapters = [];
      if (_currentSource != null) {
        _allChapters = await _service.getChapterList(_currentSource!, _book);
      }
      _book = oldBook.migrateTo(_book, _allChapters);
      _isInBookshelf = _book.isInBookshelf;
      await _chapterDao.deleteByBook(_book.bookUrl);
      await _bookDao.upsert(_book);
      await _chapterDao.insertChapters(_allChapters);
      unawaited(_storeDisplayCover());
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
      if (_book.syncTime == 0) {
        _book.syncTime = DateTime.now().millisecondsSinceEpoch;
      }
      _isLoading = true;
      notifyListeners();
      try {
        if (_allChapters.isEmpty) {
          await _loadChapters();
        }
        await _bookDao.upsert(_book);
        await _saveChapterMetadataIfPossible();
      } catch (e) {
        AppLog.e('加入書架失敗: $e', error: e);
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      await _bookDao.upsert(_book);
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
    _book.coverLocalPath = null;
    await _bookDao.upsert(_book);
    unawaited(_storeDisplayCover());
    notifyListeners();
  }

  Future<void> updateCover(String url) async {
    _book.customCoverUrl = url;
    _book.customCoverLocalPath = null;
    await _storeDisplayCover();
    await _bookDao.upsert(_book);
    notifyListeners();
  }

  void clearStoredContent() {
    unawaited(_clearStoredContent());
  }

  Future<void> _saveChapterMetadataIfPossible() {
    if (_allChapters.isEmpty) return Future<void>.value();
    final chapterContentDao = _chapterContentDao;
    if (chapterContentDao == null) {
      return _chapterDao.insertChapters(_allChapters);
    }
    return ReaderChapterContentStore(
      chapterDao: _chapterDao,
      contentDao: chapterContentDao,
    ).saveChapterMetadata(_allChapters);
  }

  Future<Set<int>> _storedChapterIndices() async {
    final chapterContentDao = _chapterContentDao;
    if (chapterContentDao == null) return <int>{};
    return ReaderChapterContentStore(
      chapterDao: _chapterDao,
      contentDao: chapterContentDao,
    ).storedChapterIndices(book: _book);
  }

  Future<void> _clearStoredContent() async {
    final chapterContentDao = _chapterContentDao;
    if (chapterContentDao == null) return;
    await ReaderChapterContentStore(
      chapterDao: _chapterDao,
      contentDao: chapterContentDao,
    ).deleteStoredContentForBook(book: _book);
  }

  Future<void> _storeDisplayCover() async {
    await _coverStorage.ensureDisplayCoverStored(_book);
    await _bookDao.upsert(_book);
    if (!_isLoading && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
