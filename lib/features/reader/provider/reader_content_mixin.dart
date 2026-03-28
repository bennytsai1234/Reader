import 'dart:async';

import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/features/reader/engine/chapter_content_manager.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/reader_chapter_content_loader.dart';
import 'package:legado_reader/features/reader/engine/reader_perf_trace.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/provider/slide_window.dart';
import 'package:legado_reader/features/reader/provider/content_callbacks.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';

import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';

mixin ReaderContentMixin on ReaderProviderBase, ReaderSettingsMixin {
  static const int _scrollPreloadRadius = 1;
  ChapterContentManager? _contentManager;
  ChapterContentManager get contentManager => _contentManager!;
  bool get hasContentManager => _contentManager != null;
  bool get isWholeBookPreloadEnabled =>
      hasContentManager && contentManager.wholeBookPreloadEnabled;

  StreamSubscription<int>? _chapterReadySub;
  Timer? _deferredWindowWarmupTimer;
  Timer? _extendedWindowWarmupTimer;
  Timer? _localAdjacentLoadTimer;
  ReaderChapterContentLoader? _chapterContentLoader;
  bool _isPaginating = false;
  int _lastVisibleScrollChapter = -1;
  int? _pinnedSlideChapterIndex;
  int _pinnedSlideCharOffset = 0;
  bool _pinnedSlideFromEnd = false;

  SlideWindow _slideWindow = SlideWindow.empty;
  ContentCallbacks _contentCallbacks = ContentCallbacks.empty;

  /// Inject typed callbacks from ReadBookController.
  set contentCallbacks(ContentCallbacks callbacks) => _contentCallbacks = callbacks;

  /// The current slide window (for external access).
  SlideWindow get slideWindow => _slideWindow;

  List<TextPage> get currentChapterPages =>
      chapterPagesCache[currentChapterIndex] ?? const <TextPage>[];

  bool get _isLocalScrollMode =>
      pageTurnMode == PageAnim.scroll && book.origin == 'local';
  bool get _isLocalBook => book.origin == 'local';
  bool get _isScrollMode => pageTurnMode == PageAnim.scroll;
  int get _defaultSlideWarmupRadius => _isLocalBook ? 1 : 2;

  void initContentManager() {
    _chapterReadySub?.cancel();
    _deferredWindowWarmupTimer?.cancel();
    _extendedWindowWarmupTimer?.cancel();
    _localAdjacentLoadTimer?.cancel();
    _contentManager?.dispose();
    chapterPagesCache.clear();
    slidePages = [];
    _slideWindow = SlideWindow.empty;
    _chapterContentLoader = ReaderChapterContentLoader(
      book: book,
      chapterDao: chapterDao,
      replaceDao: replaceDao,
      sourceDao: sourceDao,
      service: service,
      currentChineseConvert: () => chineseConvert,
      getSource: () => source,
      setSource: (value) => source = value,
    );
    _contentManager = ChapterContentManager(
      fetchFn: _fetchChapterData,
      chapters: chapters,
    );
    _contentManager!.setProgressivePaginationEnabled(false);
    _chapterReadySub = contentManager.onChapterReady.listen(_handleChapterReady);
  }

  void updatePaginationConfig() {
    if (viewSize == null || !hasContentManager) return;
    final currentTheme = AppTheme.readingThemes[
        themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];
    final titleStyle = TextStyle(
      fontSize: fontSize + 4,
      fontWeight: FontWeight.bold,
      color: currentTheme.textColor,
      letterSpacing: letterSpacing,
    );
    final contentStyle = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      color: currentTheme.textColor,
      letterSpacing: letterSpacing,
    );
    contentManager.updateConfig(
      PaginationConfig(
        viewSize: viewSize!,
        titleStyle: titleStyle,
        contentStyle: contentStyle,
        paragraphSpacing: paragraphSpacing,
        textIndent: textIndent,
        textFullJustify: textFullJustify,
      ),
    );
  }

  Future<void> doPaginate({bool fromEnd = false}) async {
    if (_isPaginating || !hasContentManager || viewSize == null) return;
    final targetChapter = currentChapterIndex;
    _isPaginating = true;
    loadingChapters.add(targetChapter);
    notifyListeners();
    try {
      updatePaginationConfig();
      chapterPagesCache.clear();
      slidePages = [];
      final repaginateTargets = await contentManager.repaginateForDisplay(
        centerChapterIndex: targetChapter,
        isScrollMode: _isScrollMode,
        scrollRadius: _scrollPreloadRadius,
      );
      _syncRepaginatedTargets(repaginateTargets, ensureTargetChapter: targetChapter);
      _refreshSlidePages();
      _restoreDisplayPositionAfterRepaginate(
        targetChapter: targetChapter,
        fromEnd: fromEnd,
      );
    } finally {
      loadingChapters.remove(targetChapter);
      _isPaginating = false;
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> loadChapter(
    int index, {
    bool fromEnd = false,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    return loadChapterWithPreloadRadius(
      index,
      fromEnd: fromEnd,
      reason: reason,
    );
  }

  Future<void> loadChapterWithPreloadRadius(
    int index, {
    bool fromEnd = false,
    int preloadRadius = 2,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    if (index < 0 || index >= chapters.length || !hasContentManager) return;
    updatePaginationConfig();
    currentChapterIndex = index;
    visibleChapterIndex = index;
    final effectivePreloadRadius = _effectivePreloadRadius(preloadRadius);
    _prepareChapterDisplayWindow(
      index,
      preloadRadius: effectivePreloadRadius,
    );

    final pages = await _loadAndCacheChapter(index);
    if (pages.isEmpty || isDisposed) return;
    _warmupAfterChapterLoad(
      index,
      preloadRadius: effectivePreloadRadius,
    );
    _presentLoadedChapter(
      index,
      pages: pages,
      fromEnd: fromEnd,
      reason: reason,
    );
    if (!isDisposed) notifyListeners();
  }

  Future<List<TextPage>> _loadAndCacheChapter(
    int index, {
    bool silent = false,
  }) async {
    if (index < 0 || index >= chapters.length || !hasContentManager) return [];
    final cached = chapterPagesCache[index];
    if (cached != null && cached.isNotEmpty) return cached;

    if (!silent) {
      loadingChapters.add(index);
      if (!isDisposed) notifyListeners();
    }
    try {
      final pages = await contentManager.ensureChapterReady(index);
      if (pages.isNotEmpty) {
        chapterPagesCache[index] = pages;
        ReaderPerfTrace.mark(
          'reader cache chapter $index ready (pages: ${pages.length}, silent: $silent)',
        );
        _contentCallbacks.refreshChapterRuntime?.call(index);
        ReaderPerfTrace.mark('reader runtime chapter $index refreshed');
      }
      return pages;
    } finally {
      if (!silent) {
        loadingChapters.remove(index);
        if (!isDisposed) notifyListeners();
      }
    }
  }

  Future<List<TextPage>> ensureChapterCached(
    int index, {
    bool silent = true,
    bool prioritize = false,
    int preloadRadius = 1,
  }) {
    if (hasContentManager && _isScrollMode) {
      _activateScrollWindow(
        index,
        preloadRadius: _scrollPreloadRadius,
        preload: !_isLocalScrollMode,
      );
      if (prioritize && !_isLocalScrollMode) {
        contentManager.prioritize([index], centerIndex: index);
      }
    }
    return _loadAndCacheChapter(index, silent: silent);
  }

  void _refreshSlidePages() {
    final currentPage =
        currentPageIndex >= 0 && currentPageIndex < slidePages.length
            ? slidePages[currentPageIndex]
            : null;

    // Try runtime pages first (if ReadBookController provides them)
    final runtimePages = _contentCallbacks.buildSlideRuntimePages?.call();
    if (runtimePages is List<TextPage> && runtimePages.isNotEmpty) {
      _applySlidePages(runtimePages, previousPage: currentPage);
      return;
    }

    // Build window from cache
    final result = SlideWindow.build(
      centerChapterIndex: currentChapterIndex,
      currentPage: currentPage,
      cache: chapterPagesCache,
      totalChapters: chapters.length,
    );

    _slideWindow = result.window;
    slidePages = result.window.flatPages;

    if (slidePages.isEmpty) {
      currentPageIndex = 0;
      return;
    }

    final clampedIndex = result.mappedIndex.clamp(0, slidePages.length - 1);
    final indexChanged = clampedIndex != currentPageIndex;
    currentPageIndex = clampedIndex;
    if (indexChanged) {
      requestJumpToPage(currentPageIndex, reason: ReaderCommandReason.system);
    }
  }

  int _findSlidePageIndexByCharOffset({
    required int chapterIndex,
    required int charOffset,
    bool fromEnd = false,
  }) {
    if (slidePages.isEmpty) return 0;
    if (fromEnd) {
      for (var i = slidePages.length - 1; i >= 0; i--) {
        if (slidePages[i].chapterIndex == chapterIndex) return i;
      }
      return slidePages.length - 1;
    }
    final localPageIndex = ChapterPositionResolver.findPageIndexByCharOffset(
      chapterPagesCache[chapterIndex] ?? const <TextPage>[],
      charOffset,
    );
    final globalIndex = slidePages.indexWhere(
      (page) => page.chapterIndex == chapterIndex && page.index == localPageIndex,
    );
    return globalIndex >= 0 ? globalIndex : 0;
  }

  void _pinSlideTarget({
    required int chapterIndex,
    required int charOffset,
    bool fromEnd = false,
  }) {
    _pinnedSlideChapterIndex = chapterIndex;
    _pinnedSlideCharOffset = charOffset;
    _pinnedSlideFromEnd = fromEnd;
  }

  void _clearPinnedSlideTarget() {
    _pinnedSlideChapterIndex = null;
    _pinnedSlideCharOffset = 0;
    _pinnedSlideFromEnd = false;
  }

  bool _isPinnedSlideTargetReached() {
    final chapterIndex = _pinnedSlideChapterIndex;
    if (chapterIndex == null || slidePages.isEmpty) return true;
    final targetIndex = _findSlidePageIndexByCharOffset(
      chapterIndex: chapterIndex,
      charOffset: _pinnedSlideCharOffset,
      fromEnd: _pinnedSlideFromEnd,
    );
    return currentPageIndex == targetIndex;
  }

  void bootstrapChapterWindow(int centerIndex) {
    if (!hasContentManager) return;
    _prepareChapterDisplayWindow(
      centerIndex,
      preloadRadius: _isScrollMode ? _scrollPreloadRadius : 1,
    );
  }

  void scheduleDeferredWindowWarmup(
    int centerIndex, {
    Duration delay = const Duration(milliseconds: 1500),
  }) {
    if (_isLocalScrollMode) return;
    _deferredWindowWarmupTimer?.cancel();
    _extendedWindowWarmupTimer?.cancel();
    _deferredWindowWarmupTimer = Timer(delay, () {
      if (!isDisposed && hasContentManager) {
        if (_isScrollMode && contentManager.userInteractionActive) {
          scheduleDeferredWindowWarmup(
            visibleChapterIndex,
            delay: const Duration(milliseconds: 900),
          );
          return;
        }
        final warmupCenter = _isScrollMode ? visibleChapterIndex : centerIndex;
        if (_isScrollMode) {
          contentManager.warmupWindow(
            warmupCenter,
            preloadRadius: _scrollPreloadRadius,
          );
          if (_isLocalScrollMode) {
            unawaited(_loadAdjacentScrollChapters(warmupCenter));
          }
          return;
        }
        _warmSlideWindow(warmupCenter);
      }
    });
  }

  void triggerSilentPreload() {
    if (!hasContentManager) return;
    if (_isScrollMode) {
      if (_isLocalScrollMode) return;
      scheduleDeferredWindowWarmup(
        visibleChapterIndex,
        delay: const Duration(milliseconds: 900),
      );
      return;
    }
    _warmSlideWindow(currentChapterIndex);
  }

  void updateScrollPreloadForVisibleChapter(
    int visibleChapter, {
    double? localOffset,
  }) {
    if (!hasContentManager || !_isScrollMode) return;
    ReaderPerfTrace.mark(
      'scroll preload update center=$visibleChapter '
      '(cached: ${chapterPagesCache[visibleChapter]?.isNotEmpty == true}, '
      'loading: ${loadingChapters.contains(visibleChapter)})',
    );
    _activateScrollWindow(
      visibleChapter,
      preloadRadius: _scrollPreloadRadius,
      preload: !_isLocalScrollMode,
    );
    final visiblePages = chapterPagesCache[visibleChapter];
    if ((visiblePages == null || visiblePages.isEmpty) &&
        !loadingChapters.contains(visibleChapter)) {
      unawaited(
        ensureChapterCached(
          visibleChapter,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        ),
      );
    }
    if (_isLocalScrollMode) {
      _scheduleAdjacentScrollLoad(visibleChapter, immediate: true);
    }

    // ── Predictive preload based on scroll position ──
    if (localOffset != null && visiblePages != null && visiblePages.isNotEmpty) {
      final chapterHeight =
          ChapterPositionResolver.chapterHeight(visiblePages);
      if (chapterHeight > 0) {
        final progress = localOffset / chapterHeight;
        // Approaching end → preload next
        if (progress > 0.8) {
          final nextIdx = visibleChapter + 1;
          if (nextIdx < chapters.length &&
              !(chapterPagesCache[nextIdx]?.isNotEmpty ?? false) &&
              !loadingChapters.contains(nextIdx)) {
            unawaited(ensureChapterCached(nextIdx, silent: true, prioritize: true));
          }
        }
        // Approaching start → preload prev
        if (progress < 0.2) {
          final prevIdx = visibleChapter - 1;
          if (prevIdx >= 0 &&
              !(chapterPagesCache[prevIdx]?.isNotEmpty ?? false) &&
              !loadingChapters.contains(prevIdx)) {
            unawaited(ensureChapterCached(prevIdx, silent: true, prioritize: true));
          }
        }
      }
    }
  }

  /// Async fast path: if raw content is cached, paginate without fetch.
  /// Used by ScrollModeDelegate to reduce placeholder display time for local books.
  Future<List<TextPage>?> trySyncPaginate(int chapterIndex) async {
    if (!hasContentManager) return null;
    final pages = await contentManager.paginateIfCached(chapterIndex);
    if (pages.isEmpty) return null;
    chapterPagesCache[chapterIndex] = pages;
    _contentCallbacks.refreshChapterRuntime?.call(chapterIndex);
    return pages;
  }

  void setScrollInteractionActive(bool active) {
    if (!hasContentManager || !_isScrollMode) return;
    contentManager.setUserInteractionActive(active);
    if (_isLocalScrollMode) return;
    if (!active) {
      scheduleDeferredWindowWarmup(
        visibleChapterIndex,
        delay: const Duration(milliseconds: 700),
      );
    }
  }

  void onPageChanged(int i) {
    if (i < 0 || i >= slidePages.length) return;

    final page = slidePages[i];
    final newChapterIndex = page.chapterIndex;

    currentPageIndex = i;
    visibleChapterIndex = newChapterIndex;
    visibleChapterLocalOffset = ChapterPositionResolver.charOffsetToLocalOffset(
      chapterPagesCache[newChapterIndex] ?? const <TextPage>[],
      ChapterPositionResolver.getCharOffsetForPage(
        chapterPagesCache[newChapterIndex] ?? const <TextPage>[],
        page.index,
      ),
    );

    if (_isPinnedSlideTargetReached()) {
      _clearPinnedSlideTarget();
    }

    // Only recenter the window when the chapter actually changes
    final needsRecenter = newChapterIndex != currentChapterIndex;
    currentChapterIndex = newChapterIndex;

    if (needsRecenter) {
      // Atomic: build new window + remap index in one step
      final currentPage = slidePages[i];
      final result = SlideWindow.build(
        centerChapterIndex: newChapterIndex,
        currentPage: currentPage,
        cache: chapterPagesCache,
        totalChapters: chapters.length,
      );
      _slideWindow = result.window;
      slidePages = result.window.flatPages;
      currentPageIndex = result.mappedIndex.clamp(0, slidePages.length - 1);
      requestJumpToPage(currentPageIndex, reason: ReaderCommandReason.system);

      // Preload the new neighbor chapter
      _preloadSlideNeighbors(newChapterIndex, preloadRadius: _defaultSlideWarmupRadius);
    } else {
      // Same chapter, just refresh without recentering
      _refreshSlidePages();
    }

    notifyListeners();
    final title = chapters.isNotEmpty ? chapters[currentChapterIndex].title : '';
    unawaited(
      bookDao.updateProgress(
        book.bookUrl,
        page.chapterIndex,
        title,
        ChapterPositionResolver.getCharOffsetForPage(
          chapterPagesCache[page.chapterIndex] ?? const <TextPage>[],
          page.index,
        ),
      ),
    );
  }

  void nextPage({
    ReaderCommandReason reason = ReaderCommandReason.user,
  }) {
    if (pageTurnMode == PageAnim.scroll) {
      final target = (visibleChapterIndex + 1).clamp(0, chapters.length - 1);
      if (target != visibleChapterIndex) {
        unawaited(nextChapter(reason: reason));
      }
      return;
    }
    if (currentPageIndex < slidePages.length - 1) {
      currentPageIndex++;
      _contentCallbacks.jumpToSlidePage?.call(
        currentPageIndex,
        reason: reason,
      );
      notifyListeners();
    } else {
      unawaited(nextChapter(reason: reason));
    }
  }

  void prevPage({
    ReaderCommandReason reason = ReaderCommandReason.user,
  }) {
    if (pageTurnMode == PageAnim.scroll) {
      final target = (visibleChapterIndex - 1).clamp(0, chapters.length - 1);
      if (target != visibleChapterIndex) {
        unawaited(prevChapter(reason: reason));
      }
      return;
    }
    if (currentPageIndex > 0) {
      currentPageIndex--;
      _contentCallbacks.jumpToSlidePage?.call(
        currentPageIndex,
        reason: reason,
      );
      notifyListeners();
    } else {
      unawaited(prevChapter(reason: reason));
    }
  }

  Future<void> nextChapter({
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    final target = currentChapterIndex + 1;
    if (target < chapters.length) {
      book.durChapterPos = 0;
      await loadChapter(target, reason: reason);
    }
  }

  Future<void> prevChapter({
    bool fromEnd = true,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    final target = currentChapterIndex - 1;
    if (target >= 0) {
      if (!fromEnd) {
        book.durChapterPos = 0;
      }
      await loadChapter(target, fromEnd: fromEnd, reason: reason);
    }
  }

  Future<FetchResult> _fetchChapterData(int i) async {
    final chapter = chapters[i];
    debugPrint('Reader: Fetching content for chapter $i: ${chapter.title}');
    return _chapterContentLoader!.load(i, chapter);
  }

  void jumpToPosition({
    int? chapterIndex,
    int? charOffset,
    int? pageIndex,
    bool isRestoringJump = false,
  });

  void disposeContentManager() {
    _chapterReadySub?.cancel();
    _deferredWindowWarmupTimer?.cancel();
    _extendedWindowWarmupTimer?.cancel();
    _localAdjacentLoadTimer?.cancel();
    _chapterContentLoader?.resetProcessingContext();
    chapterPagesCache.clear();
    slidePages = [];
    _slideWindow = SlideWindow.empty;
    _contentManager?.dispose();
    _contentManager = null;
    _chapterContentLoader = null;
  }

  bool _shouldNotifyChapterReady(int chapterIndex) {
    if (loadingChapters.contains(chapterIndex)) return true;
    final center = visibleChapterIndex;
    return (chapterIndex - center).abs() <= _scrollPreloadRadius ||
        (chapterIndex - currentChapterIndex).abs() <= _scrollPreloadRadius;
  }

  void _scheduleAdjacentScrollLoad(
    int centerIndex, {
    bool immediate = false,
  }) {
    _localAdjacentLoadTimer?.cancel();
    final delay = immediate ? Duration.zero : const Duration(milliseconds: 280);
    _localAdjacentLoadTimer = Timer(delay, () {
      if (isDisposed || !_isLocalScrollMode) return;
      unawaited(_loadAdjacentScrollChapters(centerIndex));
    });
  }

  Future<void> _loadAdjacentScrollChapters(int centerIndex) async {
    final direction = _lastVisibleScrollChapter == -1
        ? 1
        : (centerIndex - _lastVisibleScrollChapter).sign;
    _lastVisibleScrollChapter = centerIndex;
    final neighbors = <int>[
      if (direction >= 0) centerIndex + 1,
      if (direction <= 0) centerIndex - 1,
      if (direction >= 0) centerIndex - 1,
      if (direction <= 0) centerIndex + 1,
    ];

    for (final neighbor in neighbors.toSet()) {
      if (neighbor < 0 || neighbor >= chapters.length) continue;
      if (chapterPagesCache[neighbor]?.isNotEmpty ?? false) continue;
      if (loadingChapters.contains(neighbor)) continue;
      await _loadAndCacheChapter(neighbor, silent: true);
      break;
    }
  }

  void _handleChapterReady(int chapterIndex) {
    if (isDisposed) return;
    final trace = Stopwatch()..start();
    final pages = contentManager.getCachedPages(chapterIndex);
    final shouldNotify = pages != null &&
        pages.isNotEmpty &&
        (!_isScrollMode || _shouldNotifyChapterReady(chapterIndex));
    if (pages != null && pages.isNotEmpty) {
      chapterPagesCache[chapterIndex] = pages;
      _contentCallbacks.refreshChapterRuntime?.call(chapterIndex);
      if (_isScrollMode) {
        _activateScrollWindow(
          visibleChapterIndex,
          preloadRadius: _scrollPreloadRadius,
          preload: !_isLocalScrollMode,
        );
      }
    }
    if (!_isScrollMode) {
      _refreshSlidePages();
    } else if (pages != null && pages.isNotEmpty) {
      notifyListeners();
    }
    trace.stop();
    ReaderPerfTrace.mark(
      'chapter ready applied $chapterIndex '
      '(pages: ${pages?.length ?? 0}, notify: $shouldNotify, '
      'scrollMode: $_isScrollMode, total: ${trace.elapsedMilliseconds}ms)',
    );
  }

  void _applySlidePages(
    List<TextPage> pages, {
    required TextPage? previousPage,
  }) {
    slidePages = pages;
    if (slidePages.isEmpty) {
      currentPageIndex = 0;
      return;
    }

    // Rebuild _slideWindow from flat pages (for runtime pages path)
    final segmentMap = <int, List<TextPage>>{};
    for (final page in pages) {
      segmentMap.putIfAbsent(page.chapterIndex, () => []).add(page);
    }
    _slideWindow = SlideWindow(
      segmentMap.entries
          .map((e) => SlideSegment(chapterIndex: e.key, pages: e.value))
          .toList(),
    );

    final targetIndex = _resolveSlideTargetIndex(previousPage);
    final clampedIndex = targetIndex.clamp(0, slidePages.length - 1);
    final indexChanged = clampedIndex != currentPageIndex;
    currentPageIndex = clampedIndex;
    if (indexChanged) {
      requestJumpToPage(
        currentPageIndex,
        reason: ReaderCommandReason.system,
      );
    }
  }

  int _resolveSlideTargetIndex(TextPage? previousPage) {
    final pinnedChapterIndex = _pinnedSlideChapterIndex;
    if (pinnedChapterIndex != null) {
      final pinnedIndex = _findSlidePageIndexByCharOffset(
        chapterIndex: pinnedChapterIndex,
        charOffset: _pinnedSlideCharOffset,
        fromEnd: _pinnedSlideFromEnd,
      );
      if (slidePages.isNotEmpty) {
        return pinnedIndex;
      }
    }
    if (previousPage != null) {
      final found = _slideWindow.findByPage(previousPage);
      if (found >= 0) return found;
    }
    return _findSlidePageIndexByCharOffset(
      chapterIndex: currentChapterIndex,
      charOffset: book.durChapterPos,
    );
  }

  int _effectivePreloadRadius(int requestedRadius) {
    if (_isLocalBook) return 1;
    if (_isScrollMode) {
      return requestedRadius.clamp(0, _scrollPreloadRadius).toInt();
    }
    return requestedRadius;
  }

  void _prepareChapterDisplayWindow(
    int chapterIndex, {
    required int preloadRadius,
  }) {
    if (_isScrollMode) {
      _activateScrollWindow(
        chapterIndex,
        preloadRadius: preloadRadius,
        preload: !_isLocalScrollMode,
      );
      return;
    }
    contentManager.updateWindow(
      chapterIndex,
      preloadRadius: preloadRadius,
      preload: !_isLocalScrollMode,
    );
  }

  void _warmupAfterChapterLoad(
    int chapterIndex, {
    required int preloadRadius,
  }) {
    if (preloadRadius <= 0) return;
    if (_isLocalScrollMode) {
      _scheduleAdjacentScrollLoad(chapterIndex, immediate: true);
      return;
    }
    if (_isScrollMode) {
      scheduleDeferredWindowWarmup(
        chapterIndex,
        delay: const Duration(milliseconds: 900),
      );
      return;
    }
    _preloadSlideNeighbors(chapterIndex, preloadRadius: preloadRadius);
    _warmSlideWindow(chapterIndex, radius: preloadRadius);
  }

  void _preloadSlideNeighbors(
    int chapterIndex, {
    required int preloadRadius,
  }) {
    for (final neighbor in [chapterIndex - 1, chapterIndex + 1]) {
      if (preloadRadius <= 0 ||
          neighbor < 0 ||
          neighbor >= chapters.length) {
        continue;
      }
      unawaited(_loadAndCacheChapter(neighbor, silent: true));
    }
  }

  void _presentLoadedChapter(
    int chapterIndex, {
    required List<TextPage> pages,
    required bool fromEnd,
    required ReaderCommandReason reason,
  }) {
    if (_isScrollMode) {
      final targetOffset = fromEnd && pages.isNotEmpty
          ? ChapterPositionResolver.charOffsetToLocalOffset(
              pages,
              ChapterPositionResolver.getCharOffsetForPage(
                pages,
                pages.length - 1,
              ),
            )
          : ChapterPositionResolver.charOffsetToLocalOffset(
              pages,
              book.durChapterPos,
            );
      _contentCallbacks.jumpToChapterLocalOffset?.call(
        chapterIndex: chapterIndex,
        localOffset: targetOffset,
        alignment: 0.0,
        reason: reason,
      );
      return;
    }
    final targetCharOffset = fromEnd && pages.isNotEmpty
        ? ChapterPositionResolver.getCharOffsetForPage(
            pages,
            pages.length - 1,
          )
        : book.durChapterPos;
    _pinSlideTarget(
      chapterIndex: chapterIndex,
      charOffset: targetCharOffset,
      fromEnd: fromEnd,
    );
    _refreshSlidePages();
    currentPageIndex = _findSlidePageIndexByCharOffset(
      chapterIndex: chapterIndex,
      charOffset: targetCharOffset,
      fromEnd: fromEnd,
    );
    (this as dynamic).jumpToSlidePage(
      currentPageIndex,
      reason: reason,
    );
  }

  void _syncRepaginatedTargets(
    Set<int> chapterIndexes, {
    required int ensureTargetChapter,
  }) {
    for (final entry in chapterIndexes) {
      final pages = contentManager.getCachedPages(entry);
      if (pages == null || pages.isEmpty) continue;
      chapterPagesCache[entry] = pages;
      _contentCallbacks.refreshChapterRuntime?.call(entry);
    }
    final targetPages = contentManager.getCachedPages(ensureTargetChapter);
    if (targetPages != null && targetPages.isNotEmpty) {
      chapterPagesCache[ensureTargetChapter] = targetPages;
      _contentCallbacks.refreshChapterRuntime?.call(ensureTargetChapter);
    }
  }

  void _restoreDisplayPositionAfterRepaginate({
    required int targetChapter,
    required bool fromEnd,
  }) {
    const reason = ReaderCommandReason.settingsRepaginate;
    if (_isScrollMode) {
      final pages = chapterPagesCache[targetChapter] ?? const <TextPage>[];
      final charOffset = fromEnd && pages.isNotEmpty
          ? ChapterPositionResolver.getCharOffsetForPage(
              pages,
              pages.length - 1,
            )
          : book.durChapterPos;
      _contentCallbacks.jumpToChapterCharOffset?.call(
        chapterIndex: targetChapter,
        charOffset: charOffset,
        reason: reason,
        isRestoringJump: false,
      );
      return;
    }
    _pinSlideTarget(
      chapterIndex: targetChapter,
      charOffset: book.durChapterPos,
      fromEnd: fromEnd,
    );
    currentPageIndex = _findSlidePageIndexByCharOffset(
      chapterIndex: targetChapter,
      charOffset: book.durChapterPos,
      fromEnd: fromEnd,
    );
    (this as dynamic).jumpToSlidePage(
      currentPageIndex,
      reason: reason,
    );
  }

  void _warmSlideWindow(int centerChapterIndex, {int? radius}) {
    final warmupRadius = radius ?? _defaultSlideWarmupRadius;
    contentManager.updateWindow(
      centerChapterIndex,
      preloadRadius: warmupRadius,
    );
    contentManager.warmChaptersAround(
      centerChapterIndex,
      radius: warmupRadius,
    );
  }

  void _activateScrollWindow(
    int centerIndex, {
    required int preloadRadius,
    bool preload = true,
  }) {
    if (!hasContentManager || !_isScrollMode) return;
    final evicted = contentManager.activateWindow(
      centerIndex,
      preloadRadius: preloadRadius,
      preload: preload,
      evictOutsideWindow: true,
    );
    for (final index in chapterPagesCache.keys.toList()) {
      if (evicted.contains(index)) {
        chapterPagesCache.remove(index);
      }
    }
    for (final index in evicted) {
      _contentCallbacks.refreshChapterRuntime?.call(index);
    }
  }

  void refreshSlidePagesForTesting({
    int? anchorChapterIndex,
    int charOffset = 0,
    bool fromEnd = false,
  }) {
    if (anchorChapterIndex != null) {
      _pinSlideTarget(
        chapterIndex: anchorChapterIndex,
        charOffset: charOffset,
        fromEnd: fromEnd,
      );
    }
    _refreshSlidePages();
  }
}
