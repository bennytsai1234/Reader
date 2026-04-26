import 'dart:async';
import 'package:flutter/material.dart';
import 'text_page.dart';
import 'chapter_provider.dart';
import 'reader_perf_trace.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';

/// 分頁設定值物件，傳遞給 ChapterProvider.paginate()
class PaginationConfig {
  final Size viewSize;
  final TextStyle titleStyle;
  final TextStyle contentStyle;
  final double paragraphSpacing;
  final int textIndent;
  final bool textFullJustify;
  final double padding;
  final double contentPaddingTop;
  final double contentPaddingBottom;

  const PaginationConfig({
    required this.viewSize,
    required this.titleStyle,
    required this.contentStyle,
    this.paragraphSpacing = 1.0,
    this.textIndent = 2,
    this.textFullJustify = true,
    this.padding = 16.0,
    this.contentPaddingTop = 0.0,
    this.contentPaddingBottom = 0.0,
  });

  @override
  bool operator ==(Object other) {
    return other is PaginationConfig &&
        other.viewSize == viewSize &&
        other.titleStyle == titleStyle &&
        other.contentStyle == contentStyle &&
        other.paragraphSpacing == paragraphSpacing &&
        other.textIndent == textIndent &&
        other.textFullJustify == textFullJustify &&
        other.padding == padding &&
        other.contentPaddingTop == contentPaddingTop &&
        other.contentPaddingBottom == contentPaddingBottom;
  }

  @override
  int get hashCode => Object.hash(
    viewSize,
    titleStyle,
    contentStyle,
    paragraphSpacing,
    textIndent,
    textFullJustify,
    padding,
    contentPaddingTop,
    contentPaddingBottom,
  );
}

/// 章節內容取得結果
class FetchResult {
  final String content;
  final String? displayTitle;
  final String? failureMessage;
  FetchResult({required this.content, this.displayTitle, this.failureMessage});
}

/// 章節內容取得函數的型別定義
typedef ChapterFetchFn = Future<FetchResult> Function(int chapterIndex);

/// ChapterContentManager — 章節內容管線
///
/// 獨立於 Provider 系統，負責：
/// - 章節內容取得（透過注入的 fetch 函數）
/// - 分頁計算與快取
/// - 預載佇列管理
/// - 視窗內容驅逐策略
///
/// 外部透過同步的 getCachedPages() 或 await getChapterPages() 取得結果，
/// 不再有「計算 shouldMerge → await → shouldMerge 過期」的問題。
class ChapterContentManager {
  /// 注入的章節內容取得函數
  final ChapterFetchFn _fetchFn;

  /// 章節列表（由外部提供）
  List<BookChapter> _chapters;

  /// 原始內容快取（限制大小防止 OOM）
  final Map<int, String> _contentCache = {};
  static const int _maxContentCacheSize = 30;

  /// 分頁結果快取
  final Map<int, List<TextPage>> _paginatedCache = {};
  final Map<int, List<TextPage>> _pendingDisplayRepaginatedPages = {};
  final Set<int> _pendingDisplayRepaginatedIndexes = <int>{};
  final Set<int> _pendingRawRepaginateIndexes = <int>{};
  final Map<int, String> _displayTitleCache = {};

  /// 目標預載視窗
  Set<int> _targetWindow = {};

  /// 預載佇列
  final List<int> _preloadQueue = [];
  bool _isPreloadingQueueActive = false;
  int _activeSilentPreloadCount = 0;
  int _maxConcurrentPreloads = 1;
  final Set<int> _priorityChapters = {};
  bool _userInteractionActive = false;

  /// 章節載入 Completer：協調主載入與靜默預載入，避免重複請求
  final Map<int, Completer<void>> _loadCompleters = {};

  /// 正在載入中的章節（靜默）
  final Set<int> _silentLoadingChapters = {};

  /// 已抓取但內容為空的章節集合（防止無限重試）
  final Set<int> _emptyContentChapters = {};

  /// 正在載入中的章節（主動，外部可查詢顯示 loading UI）
  final Set<int> _activeLoadingChapters = {};

  /// 預載完成通知
  final StreamController<int> _onChapterReadyController =
      StreamController<int>.broadcast();

  /// 當前分頁設定
  PaginationConfig? _config;

  /// 當前分頁設定版本，每次 updateConfig 遞增，用於丟棄過期的分頁結果
  int _configVersion = 0;

  /// 是否已 dispose
  bool _disposed = false;

  /// 是否啟用整本書背景預載模式
  bool _wholeBookPreloadEnabled = false;
  bool _progressivePaginationEnabled = false;

  ChapterContentManager({
    required ChapterFetchFn fetchFn,
    required List<BookChapter> chapters,
  }) : _fetchFn = fetchFn,
       _chapters = chapters;

  // --- 公開 API ---

  /// 預載完成通知 Stream
  Stream<int> get onChapterReady => _onChapterReadyController.stream;

  /// 是否有任何章節正在主動載入（用於顯示 loading UI）
  bool get isLoading => _activeLoadingChapters.isNotEmpty;

  /// 正在主動載入的章節集合
  Set<int> get activeLoadingChapters =>
      Set.unmodifiable(_activeLoadingChapters);

  /// 正在靜默預載的章節集合
  Set<int> get silentLoadingChapters =>
      Set.unmodifiable(_silentLoadingChapters);

  /// 已知為空內容的章節集合
  Set<int> get emptyContentChapters => Set.unmodifiable(_emptyContentChapters);

  bool isKnownEmptyChapter(int index) => _emptyContentChapters.contains(index);

  /// 是否啟用整本書預載
  bool get wholeBookPreloadEnabled => _wholeBookPreloadEnabled;

  /// 是否正在使用者互動中（例如 scroll drag）
  bool get userInteractionActive => _userInteractionActive;

  /// 取得分頁結果（快取優先，無快取時主動載入）
  /// 這是「顯性」載入路徑——會加入 _activeLoadingChapters
  Future<List<TextPage>> getChapterPages(int index) async {
    if (index < 0 || index >= _chapters.length) return [];
    if (_disposed) return [];

    // 已知空內容章節，直接回傳空列表，不重試
    if (_emptyContentChapters.contains(index)) return [];

    final cached = _paginatedCache[index];
    if (cached != null && cached.isNotEmpty) return cached;

    if (_contentCache.containsKey(index)) {
      final repaginated = await _cachedPagesOrRepaginate(index);
      if (repaginated.isNotEmpty) return repaginated;
    }

    // 任一載入流程已經保留了此章節：等待完成，避免主動/靜默雙重抓取
    final existingLoad = _loadCompleters[index];
    if (existingLoad != null) {
      _activeLoadingChapters.add(index);
      await existingLoad.future;
      _activeLoadingChapters.remove(index);
      if (_disposed) return [];
      return _cachedPagesOrRepaginate(index);
    }

    // 正在靜默預載中：等待其完成
    if (_silentLoadingChapters.contains(index)) {
      final completer = _loadCompleters[index];
      if (completer != null) {
        _activeLoadingChapters.add(index);
        await completer.future;
        _activeLoadingChapters.remove(index);
        if (_disposed) return [];
        final result = await _cachedPagesOrRepaginate(index);
        if (result.isNotEmpty) return result;
      }
    }

    // 已在主動載入中：避免重複
    if (_activeLoadingChapters.contains(index)) return [];

    // 新鮮載入
    _activeLoadingChapters.add(index);
    try {
      await _fetchAndPaginate(index);
      if (_disposed) return [];
      return _cachedPagesOrRepaginate(index);
    } catch (e) {
      AppLog.e('ChapterContentManager: Load chapter $index failed: $e');
      return [];
    } finally {
      _activeLoadingChapters.remove(index);
    }
  }

  /// 非阻塞快取查詢
  List<TextPage>? getCachedPages(int index) => _paginatedCache[index];

  /// 取得分頁結果快取（唯讀）
  Map<int, List<TextPage>> get paginatedCache =>
      Map.unmodifiable(_paginatedCache);

  bool get hasPendingDisplayRepagination =>
      _pendingDisplayRepaginatedIndexes.isNotEmpty;

  void seedPages(int index, List<TextPage> pages) {
    if (_disposed || index < 0 || index >= _chapters.length || pages.isEmpty) {
      return;
    }
    _paginatedCache[index] = pages;
  }

  /// 取得原始內容快取
  String? getCachedContent(int index) => _contentCache[index];

  /// Paginate a chapter whose content is already cached, skipping the fetch.
  /// Returns empty list if config is not set or content is not cached.
  /// Used as a fast path for local books to minimize placeholder display time.
  Future<List<TextPage>> paginateIfCached(int index) async {
    // Already paginated?
    final existing = _paginatedCache[index];
    if (existing != null && existing.isNotEmpty) return existing;

    final content = _contentCache[index];
    if (content == null) return [];

    return _paginateCachedContent(index);
  }

  /// 更新分頁設定；active paginated cache 會保留到 staged repaginate commit。
  void updateConfig(PaginationConfig config) {
    if (_config == config) return;
    _config = config;
    _configVersion++; // invalidate in-flight paginations
    _clearPendingDisplayRepagination();
  }

  /// 更新章節列表
  void updateChapters(List<BookChapter> chapters) {
    _chapters = chapters;
    _displayTitleCache.clear();
    _clearPendingDisplayRepagination();
  }

  void setUserInteractionActive(bool active) {
    _userInteractionActive = active;
    if (!active) {
      _processPreloadQueue();
    }
  }

  Future<List<TextPage>> ensureChapterReady(int index) {
    return getChapterPages(index);
  }

  void setProgressivePaginationEnabled(bool enabled) {
    _progressivePaginationEnabled = enabled;
  }

  void setPreloadConcurrency(int concurrency) {
    _maxConcurrentPreloads = concurrency.clamp(1, 4).toInt();
    _processPreloadQueue();
  }

  /// 啟用整本書背景預載
  ///
  /// 目前設計為：
  /// - display 仍然由外部決定如何組裝
  /// - preload 則直接以全書為範圍，不再依賴局部 window 遞進
  void enableWholeBookPreload({int? startIndex}) {
    if (_chapters.isEmpty) return;
    _wholeBookPreloadEnabled = true;
    _targetWindow = {for (int i = 0; i < _chapters.length; i++) i};
    final center = (startIndex ?? 0).clamp(0, _chapters.length - 1).toInt();
    AppLog.d(
      'ChapterContentManager: Whole-book preload enabled '
      '(start: $center, chapters: ${_chapters.length})',
    );
    _startPreloading(center, preloadRadius: _chapters.length);
  }

  /// 更新預載視窗中心，觸發背景預載
  void updateWindow(
    int centerChapterIndex, {
    int preloadRadius = 2,
    bool preload = true,
  }) {
    if (_chapters.isEmpty) return;
    if (_wholeBookPreloadEnabled) {
      if (_targetWindow.length != _chapters.length) {
        _targetWindow = {for (int i = 0; i < _chapters.length; i++) i};
      }
      if (preload) {
        _startPreloading(centerChapterIndex, preloadRadius: _chapters.length);
      }
      return;
    }
    final windowRadius = preloadRadius.clamp(0, _chapters.length).toInt();

    // 遲滯邏輯：只有當前中心仍落在窗口中間時才不更新。
    if (_targetWindow.isNotEmpty &&
        _targetWindow.contains(centerChapterIndex)) {
      final sorted = _targetWindow.toList()..sort();
      final currentLeft = sorted.first;
      final currentRight = sorted.last;
      if (windowRadius > 1 &&
          centerChapterIndex > currentLeft &&
          centerChapterIndex < currentRight) {
        return;
      }
    }

    final newIndices = _buildWindow(centerChapterIndex, radius: windowRadius);

    if (newIndices.length == _targetWindow.length &&
        newIndices.every((i) => _targetWindow.contains(i))) {
      return;
    }

    _targetWindow = newIndices;
    AppLog.d(
      'ChapterContentManager: Window updated to $_targetWindow (center: $centerChapterIndex)',
    );

    if (preload) {
      _startPreloading(centerChapterIndex, preloadRadius: preloadRadius);
    }
  }

  Set<int> activateWindow(
    int centerChapterIndex, {
    int preloadRadius = 2,
    bool preload = true,
    bool evictOutsideWindow = false,
    Set<int> retainedIndexes = const <int>{},
  }) {
    updateWindow(
      centerChapterIndex,
      preloadRadius: preloadRadius,
      preload: preload,
    );
    if (!evictOutsideWindow) return {};
    return evictOutsideActiveWindow(retainedIndexes: retainedIndexes);
  }

  void warmChaptersAround(int centerChapterIndex, {int radius = 2}) {
    warmupWindow(centerChapterIndex, preloadRadius: radius);
  }

  /// 檢查章節是否在目前目標視窗內
  bool isChapterInWindow(int index) => _targetWindow.contains(index);

  /// 對目前視窗做額外暖機預載，不改變視窗中心本身
  void warmupWindow(int centerChapterIndex, {int preloadRadius = 2}) {
    if (_targetWindow.isEmpty) return;
    if (_wholeBookPreloadEnabled) {
      _startPreloading(centerChapterIndex, preloadRadius: _chapters.length);
      return;
    }
    if (!_userInteractionActive) {
      _priorityChapters.clear();
    }
    _startPreloading(
      centerChapterIndex,
      preloadRadius: preloadRadius,
      scopeOverride: _buildWindow(centerChapterIndex, radius: preloadRadius),
    );
  }

  void prioritizeChapter(
    int index, {
    int preloadRadius = 1,
    Set<int> retainedIndexes = const <int>{},
  }) {
    if (_disposed || index < 0 || index >= _chapters.length) return;
    if (!_wholeBookPreloadEnabled) {
      _targetWindow = _buildWindow(
        index,
        radius: preloadRadius.clamp(0, _chapters.length).toInt(),
      );
      evictOutsideWindow(retainedIndexes: retainedIndexes);
    }
    _priorityChapters
      ..clear()
      ..addAll(_buildWindow(index, radius: preloadRadius));

    if (!_isPreloadingQueueActive) {
      _preloadQueue.clear();
    } else if (_preloadQueue.length > 1) {
      _preloadQueue.removeRange(1, _preloadQueue.length);
    }

    final prioritized =
        _priorityChapters.toList()
          ..sort((a, b) => (a - index).abs().compareTo((b - index).abs()));
    for (final chapterIndex in prioritized.reversed) {
      _preloadQueue.remove(chapterIndex);
      _preloadQueue.insert(0, chapterIndex);
    }

    _startPreloading(index, preloadRadius: preloadRadius);
  }

  void prioritize(Iterable<int> chapterIndexes, {int centerIndex = 0}) {
    final ordered =
        chapterIndexes
            .where((idx) => idx >= 0 && idx < _chapters.length)
            .toList()
          ..sort(
            (a, b) =>
                (a - centerIndex).abs().compareTo((b - centerIndex).abs()),
          );
    if (ordered.isEmpty) return;
    _priorityChapters
      ..clear()
      ..addAll(ordered);
    for (final chapterIndex in ordered.reversed) {
      _preloadQueue.remove(chapterIndex);
      _preloadQueue.insert(0, chapterIndex);
    }
    _startPreloading(centerIndex, preloadRadius: ordered.length);
  }

  /// 驅逐視窗外的分頁快取，回傳被驅逐的章節索引
  Set<int> evictOutsideWindow({Set<int> retainedIndexes = const <int>{}}) {
    return evictOutside(_targetWindow, retainedIndexes: retainedIndexes);
  }

  Set<int> evictOutside(
    Set<int> indexesToKeep, {
    Set<int> retainedIndexes = const <int>{},
  }) {
    if (_wholeBookPreloadEnabled) return {};
    final effectiveKeep = <int>{...indexesToKeep, ...retainedIndexes};
    if (effectiveKeep.isEmpty) return {};
    final toEvict = <int>{};
    for (final idx in _paginatedCache.keys.toList()) {
      if (!effectiveKeep.contains(idx)) {
        toEvict.add(idx);
      }
    }
    for (final idx in toEvict) {
      _paginatedCache.remove(idx);
    }
    return toEvict;
  }

  /// 使用目前設定重新分頁指定章節（如果有內容快取）
  Future<List<TextPage>> repaginate(int index) async {
    _clearPendingDisplayRepagination();
    final content = _contentCache[index];
    if (content == null || _config == null || _disposed) return [];
    if (index < 0 || index >= _chapters.length) return [];

    final pages = await _doPaginate(index, content);
    if (_disposed) return [];
    _paginatedCache[index] = pages;
    return pages;
  }

  /// 重新分頁所有有內容快取的章節
  Future<void> repaginateAll() async {
    _clearPendingDisplayRepagination();
    if (_config == null || _disposed) return;

    final indices = _contentCache.keys.toList();
    for (final idx in indices) {
      if (_disposed) return;
      if (idx >= 0 && idx < _chapters.length) {
        final pages = await _doPaginate(idx, _contentCache[idx]!);
        if (_disposed) return;
        _paginatedCache[idx] = pages;
      }
    }
  }

  /// 外部手動注入內容快取（用於 replaceChapterSource 等場景）
  void putContent(int index, String content) {
    _saveContentCache(index, content);
    _paginatedCache.remove(index); // 內容變更，分頁作廢
    _pendingDisplayRepaginatedPages.remove(index);
    _pendingDisplayRepaginatedIndexes.remove(index);
  }

  void clearChapterContent(int index) {
    _contentCache.remove(index);
    _paginatedCache.remove(index);
    _pendingDisplayRepaginatedPages.remove(index);
    _pendingDisplayRepaginatedIndexes.remove(index);
    _pendingRawRepaginateIndexes.remove(index);
    _displayTitleCache.remove(index);
    _emptyContentChapters.remove(index);
    _preloadQueue.remove(index);
  }

  void dispose() {
    _disposed = true;
    _onChapterReadyController.close();
    _preloadQueue.clear();
    _loadCompleters.clear();
    _emptyContentChapters.clear();
    _pendingRawRepaginateIndexes.clear();
    _clearPendingDisplayRepagination();
  }

  void commitPendingDisplayRepagination() {
    if (_pendingDisplayRepaginatedIndexes.isEmpty) return;
    for (final index in _pendingDisplayRepaginatedIndexes) {
      _paginatedCache.remove(index);
    }
    _paginatedCache.addAll(_pendingDisplayRepaginatedPages);
    _clearPendingDisplayRepagination();
  }

  // --- 內部邏輯 ---

  Future<void> _fetchAndPaginate(int index) async {
    final capturedConfigVersion = _configVersion;
    final completer = Completer<void>();
    _loadCompleters[index] = completer;
    final trace = Stopwatch()..start();
    ReaderPerfTrace.mark('chapter $index fetch/paginate start');

    try {
      final result = await _fetchFn(index);
      if (_disposed) return;

      // 空內容攔截：記錄並早期返回，避免無限重試
      if (result.content.trim().isEmpty) {
        AppLog.w(
          'ChapterContentManager: Chapter $index returned empty content, marking as empty',
        );
        _emptyContentChapters.add(index);
        return;
      }

      _saveContentCache(index, result.content);
      if (result.displayTitle != null && result.displayTitle!.isNotEmpty) {
        _displayTitleCache[index] = result.displayTitle!;
      }
      if (_progressivePaginationEnabled) {
        await _doPaginateProgressive(
          index,
          result.content,
          capturedConfigVersion,
        );
      } else {
        final pages = await _doPaginate(index, result.content);
        if (_disposed) return;

        // 版本驗證：若分頁設定在抓取期間被更新，丟棄此次結果
        if (_configVersion != capturedConfigVersion) {
          AppLog.d(
            'ChapterContentManager: Chapter $index pagination discarded (config changed)',
          );
          _pendingRawRepaginateIndexes.add(index);
          await _paginateCachedContent(index);
          return;
        }
        if (pages.isNotEmpty) {
          _paginatedCache[index] = pages;
        } else {
          _paginatedCache.remove(index);
        }
      }
    } finally {
      trace.stop();
      ReaderPerfTrace.mark(
        'chapter $index fetch/paginate done '
        '(pages: ${_paginatedCache[index]?.length ?? 0}, total: ${trace.elapsedMilliseconds}ms)',
      );
      _loadCompleters.remove(index);
      if (!completer.isCompleted) completer.complete();
    }
  }

  Future<List<TextPage>> _doPaginate(int index, String content) async {
    final config = _config;
    if (config == null ||
        config.viewSize.width <= 0 ||
        config.viewSize.height <= 0) {
      return [];
    }
    if (index < 0 || index >= _chapters.length) return [];

    final pages = await ReaderPerfTrace.measureAsync(
      'paginate chapter $index',
      () => ChapterProvider.paginate(
        content: content,
        chapter: _chapters[index],
        displayTitle: _chapterDisplayTitle(index),
        chapterIndex: index,
        chapterSize: _chapters.length,
        viewSize: config.viewSize,
        titleStyle: config.titleStyle,
        contentStyle: config.contentStyle,
        paragraphSpacing: config.paragraphSpacing,
        textIndent: config.textIndent,
        textFullJustify: config.textFullJustify,
        contentPaddingTop: config.contentPaddingTop,
        contentPaddingBottom: config.contentPaddingBottom,
      ),
    );

    return pages;
  }

  Future<void> repaginateWindow(Iterable<int> chapterIndexes) async {
    _clearPendingDisplayRepagination();
    if (_config == null || _disposed) return;

    final ordered =
        chapterIndexes
            .where((idx) => idx >= 0 && idx < _chapters.length)
            .toSet()
            .toList()
          ..sort();
    for (final idx in ordered) {
      if (_disposed) return;
      final content = _contentCache[idx];
      if (content == null) continue;
      final pages = await _doPaginate(idx, content);
      if (_disposed) return;
      if (pages.isNotEmpty) {
        _paginatedCache[idx] = pages;
        _onChapterReadyController.add(idx);
      } else {
        _paginatedCache.remove(idx);
      }
    }
  }

  Future<void> repaginateVisibleWindow(Iterable<int> chapterIndexes) {
    return repaginateWindow(chapterIndexes);
  }

  Future<Set<int>> repaginateForDisplay({
    required int centerChapterIndex,
    required bool isScrollMode,
    int scrollRadius = 1,
  }) async {
    _clearPendingDisplayRepagination();
    final capturedConfigVersion = _configVersion;
    final scope =
        isScrollMode
            ? _buildWindow(centerChapterIndex, radius: scrollRadius)
            : Set<int>.from(
              _targetWindow.isNotEmpty ? _targetWindow : _paginatedCache.keys,
            );
    final repaginatedIndexes =
        isScrollMode ? scope : Set<int>.from(_contentCache.keys);
    final stagedPages = await _repaginateIntoMap(
      repaginatedIndexes,
      capturedConfigVersion: capturedConfigVersion,
    );
    if (_disposed || _configVersion != capturedConfigVersion) {
      _clearPendingDisplayRepagination();
      return scope;
    }
    _pendingDisplayRepaginatedIndexes
      ..clear()
      ..addAll(repaginatedIndexes);
    _pendingDisplayRepaginatedPages
      ..clear()
      ..addAll(stagedPages);
    return scope;
  }

  Set<int> evictOutsideActiveWindow({
    Set<int> retainedIndexes = const <int>{},
  }) {
    return evictOutside(_targetWindow, retainedIndexes: retainedIndexes);
  }

  void _saveContentCache(int index, String content) {
    _contentCache[index] = content;
    if (_wholeBookPreloadEnabled) {
      return;
    }
    if (_contentCache.length > _maxContentCacheSize) {
      // 找距離目標視窗中心最遠的章節驅逐（排除正在存入的）
      final center =
          _targetWindow.isEmpty
              ? index
              : (_targetWindow.reduce((a, b) => a + b) ~/ _targetWindow.length);
      final candidates = _contentCache.keys.where((k) => k != index);
      if (candidates.isNotEmpty) {
        final farthest = candidates.reduce(
          (a, b) => (a - center).abs() > (b - center).abs() ? a : b,
        );
        _contentCache.remove(farthest);
      }
    }
  }

  void _clearPendingDisplayRepagination() {
    _pendingDisplayRepaginatedPages.clear();
    _pendingDisplayRepaginatedIndexes.clear();
  }

  Future<List<TextPage>> _paginateCachedContent(
    int index, {
    bool notifyReady = false,
  }) async {
    final content = _contentCache[index];
    if (content == null || _config == null || _disposed) return [];
    if (index < 0 || index >= _chapters.length) return [];
    final capturedConfigVersion = _configVersion;
    final pages = await _doPaginate(index, content);
    if (_disposed || _configVersion != capturedConfigVersion) {
      _pendingRawRepaginateIndexes.add(index);
      return [];
    }
    if (pages.isNotEmpty) {
      _paginatedCache[index] = pages;
      _pendingRawRepaginateIndexes.remove(index);
      if (notifyReady && !_disposed) {
        _onChapterReadyController.add(index);
      }
      return pages;
    }
    _pendingRawRepaginateIndexes.add(index);
    _paginatedCache.remove(index);
    return [];
  }

  Future<List<TextPage>> _cachedPagesOrRepaginate(
    int index, {
    bool notifyReady = false,
  }) async {
    final cached = _paginatedCache[index];
    if (cached != null && cached.isNotEmpty) return cached;
    if (!_contentCache.containsKey(index)) return const <TextPage>[];

    // Viewport/inset changes can invalidate pagination exactly while network
    // content returns. Retry against the latest config before reporting "empty"
    // to the UI, otherwise the reader can sit on a blank placeholder until an
    // unrelated system redraw happens.
    for (var attempt = 0; attempt < 3 && !_disposed; attempt++) {
      final versionBefore = _configVersion;
      final pages = await _paginateCachedContent(
        index,
        notifyReady: notifyReady,
      );
      if (pages.isNotEmpty) return pages;
      if (_configVersion == versionBefore) break;
      await Future<void>.delayed(Duration.zero);
    }
    return _paginatedCache[index] ?? const <TextPage>[];
  }

  Future<Map<int, List<TextPage>>> _repaginateIntoMap(
    Iterable<int> chapterIndexes, {
    required int capturedConfigVersion,
  }) async {
    final stagedPages = <int, List<TextPage>>{};
    final ordered =
        chapterIndexes
            .where((idx) => idx >= 0 && idx < _chapters.length)
            .toSet()
            .toList()
          ..sort();
    for (final idx in ordered) {
      if (_disposed || _configVersion != capturedConfigVersion) break;
      final content = _contentCache[idx];
      if (content == null) continue;
      final pages = await _doPaginate(idx, content);
      if (_disposed || _configVersion != capturedConfigVersion) break;
      if (pages.isNotEmpty) {
        stagedPages[idx] = pages;
      }
    }
    return stagedPages;
  }

  void _startPreloading(
    int centerChapterIndex, {
    int preloadRadius = 2,
    Iterable<int>? scopeOverride,
  }) {
    // 一般模式保留目前執行中的第一項，替換 pending 部分；
    // 整本書模式則保留整條 queue，直到全書吃完。
    if (!_isPreloadingQueueActive) {
      _preloadQueue.clear();
    } else if (!_wholeBookPreloadEnabled && _preloadQueue.length > 1) {
      _preloadQueue.removeRange(1, _preloadQueue.length);
    }

    final List<int> candidates = [];
    final Iterable<int> preloadScope =
        scopeOverride ??
        (_wholeBookPreloadEnabled
            ? Iterable<int>.generate(_chapters.length)
            : _targetWindow);
    for (final idx in preloadScope) {
      if (!_paginatedCache.containsKey(idx) &&
          !_activeLoadingChapters.contains(idx) &&
          !_silentLoadingChapters.contains(idx) &&
          !_emptyContentChapters.contains(idx)) {
        candidates.add(idx);
      }
    }

    // 依距離中心從近到遠排序
    candidates.sort(
      (a, b) => (a - centerChapterIndex).abs().compareTo(
        (b - centerChapterIndex).abs(),
      ),
    );

    for (final c in candidates) {
      if ((_wholeBookPreloadEnabled ||
              (c - centerChapterIndex).abs() <= preloadRadius) &&
          !_preloadQueue.contains(c)) {
        _preloadQueue.add(c);
      }
    }

    if (_priorityChapters.isNotEmpty) {
      final prioritized =
          _priorityChapters.toList()..sort(
            (a, b) => (a - centerChapterIndex).abs().compareTo(
              (b - centerChapterIndex).abs(),
            ),
          );
      for (final chapterIndex in prioritized.reversed) {
        final existingIndex = _preloadQueue.indexOf(chapterIndex);
        if (existingIndex > 0) {
          _preloadQueue.removeAt(existingIndex);
          _preloadQueue.insert(0, chapterIndex);
        }
      }
    }

    _processPreloadQueue();
  }

  void _processPreloadQueue() {
    if (_isPreloadingQueueActive || _preloadQueue.isEmpty) return;
    _isPreloadingQueueActive = true;

    while (_preloadQueue.isNotEmpty &&
        _activeSilentPreloadCount < _maxConcurrentPreloads) {
      if (_disposed) break;
      if (_userInteractionActive &&
          _priorityChapters.isNotEmpty &&
          !_priorityChapters.contains(_preloadQueue.first)) {
        break;
      }
      final target = _preloadQueue.removeAt(0);

      if (_paginatedCache.containsKey(target) ||
          _activeLoadingChapters.contains(target)) {
        continue;
      }

      if (_silentLoadingChapters.contains(target) ||
          _loadCompleters.containsKey(target)) {
        continue;
      }

      _silentLoadingChapters.add(target);
      final completer = Completer<void>();
      _loadCompleters[target] = completer;
      _activeSilentPreloadCount++;
      unawaited(
        _preloadChapterSilently(target, completer).whenComplete(() {
          _activeSilentPreloadCount =
              (_activeSilentPreloadCount - 1)
                  .clamp(0, _maxConcurrentPreloads)
                  .toInt();
          if (!_disposed &&
              !_userInteractionActive &&
              _preloadQueue.isNotEmpty) {
            _processPreloadQueue();
          }
        }),
      );
    }

    _isPreloadingQueueActive = false;
    if (!_disposed &&
        !_userInteractionActive &&
        _preloadQueue.isNotEmpty &&
        _activeSilentPreloadCount < _maxConcurrentPreloads) {
      _processPreloadQueue();
    }
  }

  Future<void> _preloadChapterSilently(
    int index,
    Completer<void> completer,
  ) async {
    if (index < 0 || index >= _chapters.length) return;
    if (_activeLoadingChapters.contains(index) ||
        _paginatedCache.containsKey(index)) {
      return;
    }
    final capturedConfigVersion = _configVersion;
    final trace = Stopwatch()..start();
    ReaderPerfTrace.mark('chapter $index silent preload start');

    try {
      final result = await _fetchFn(index);
      if (_disposed) return;

      // 空內容攔截
      if (result.content.trim().isEmpty) {
        AppLog.w(
          'ChapterContentManager: Silent preload chapter $index empty content',
        );
        _emptyContentChapters.add(index);
        return;
      }

      _saveContentCache(index, result.content);
      if (result.displayTitle != null && result.displayTitle!.isNotEmpty) {
        _displayTitleCache[index] = result.displayTitle!;
      }
      if (_progressivePaginationEnabled) {
        await _doPaginateProgressive(
          index,
          result.content,
          capturedConfigVersion,
        );
      } else {
        final pages = await _doPaginate(index, result.content);
        if (_disposed) return;

        if (_configVersion != capturedConfigVersion) {
          AppLog.d(
            'ChapterContentManager: Chapter $index silent preload discarded (config changed)',
          );
          _pendingRawRepaginateIndexes.add(index);
          await _cachedPagesOrRepaginate(index, notifyReady: true);
          return;
        }

        if (pages.isNotEmpty) {
          _paginatedCache[index] = pages;
        } else {
          _paginatedCache.remove(index);
        }

        // 通知外部：新章節已就緒
        if (!_disposed && pages.isNotEmpty) {
          _onChapterReadyController.add(index);
        }
      }
    } catch (e) {
      AppLog.e('ChapterContentManager: Preload chapter $index failed: $e');
    } finally {
      trace.stop();
      ReaderPerfTrace.mark(
        'chapter $index silent preload done '
        '(pages: ${_paginatedCache[index]?.length ?? 0}, total: ${trace.elapsedMilliseconds}ms)',
      );
      _silentLoadingChapters.remove(index);
      _loadCompleters.remove(index);
      if (!completer.isCompleted) completer.complete();
    }
  }

  Future<void> _doPaginateProgressive(
    int index,
    String content, [
    int? capturedVersion,
  ]) async {
    final config = _config;
    if (config == null ||
        config.viewSize.width <= 0 ||
        config.viewSize.height <= 0) {
      return;
    }
    if (index < 0 || index >= _chapters.length) return;

    final chapter = _chapters[index];
    List<TextPage> latestPages = const <TextPage>[];
    final progressiveTrace = Stopwatch()..start();
    await for (final pages in ChapterProvider.paginateProgressive(
      content: content,
      chapter: chapter,
      displayTitle: _chapterDisplayTitle(index),
      chapterIndex: index,
      chapterSize: _chapters.length,
      viewSize: config.viewSize,
      titleStyle: config.titleStyle,
      contentStyle: config.contentStyle,
      paragraphSpacing: config.paragraphSpacing,
      textIndent: config.textIndent,
      textFullJustify: config.textFullJustify,
      contentPaddingTop: config.contentPaddingTop,
      contentPaddingBottom: config.contentPaddingBottom,
    )) {
      if (_disposed) return;
      if (capturedVersion != null && _configVersion != capturedVersion) {
        AppLog.d(
          'ChapterContentManager: Chapter $index progressive pagination aborted mid-stream (config changed)',
        );
        _paginatedCache.remove(index);
        return;
      }
      latestPages = pages;
      if (pages.isNotEmpty) {
        _paginatedCache[index] = pages;
        _onChapterReadyController.add(index);
        ReaderPerfTrace.mark(
          'paginate chapter $index progressive chunk '
          '(pages: ${pages.length}, elapsed: ${progressiveTrace.elapsedMilliseconds}ms)',
        );
      }
      await Future.delayed(Duration.zero);
    }
    progressiveTrace.stop();
    ReaderPerfTrace.mark(
      'paginate chapter $index progressive done '
      '(pages: ${latestPages.length}, total: ${progressiveTrace.elapsedMilliseconds}ms)',
    );

    if (capturedVersion != null && _configVersion != capturedVersion) {
      AppLog.d(
        'ChapterContentManager: Chapter $index progressive pagination discarded (config changed)',
      );
      _paginatedCache.remove(index);
      return;
    }

    if (latestPages.isEmpty) {
      _paginatedCache.remove(index);
      return;
    }
  }

  Set<int> _buildWindow(int centerChapterIndex, {int radius = 2}) {
    if (_chapters.isEmpty) return {};
    final safeCenter =
        centerChapterIndex.clamp(0, _chapters.length - 1).toInt();
    final desiredSize = (radius * 2) + 1;
    var start = safeCenter - radius;
    var end = safeCenter + radius;

    if (start < 0) {
      end += -start;
      start = 0;
    }
    if (end >= _chapters.length) {
      start -= end - (_chapters.length - 1);
      end = _chapters.length - 1;
    }

    start = start.clamp(0, _chapters.length - 1).toInt();
    end = end.clamp(0, _chapters.length - 1).toInt();

    final currentSize = end - start + 1;
    if (currentSize < desiredSize && currentSize < _chapters.length) {
      final missing = desiredSize - currentSize;
      start = (start - missing).clamp(0, _chapters.length - 1).toInt();
    }

    return {for (int i = start; i <= end; i++) i};
  }

  String _chapterDisplayTitle(int index) {
    return _displayTitleCache[index] ?? _chapters[index].title;
  }
}
