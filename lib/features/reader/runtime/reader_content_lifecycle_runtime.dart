import 'dart:async';

import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_content_manager.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_loader.dart';
import 'package:inkpage_reader/features/reader/engine/reader_perf_trace.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';

class ReaderContentLifecycleRuntime {
  static const int scrollPreloadRadius = 1;

  ChapterContentManager? _contentManager;
  StreamSubscription<int>? _chapterReadySub;
  Timer? _deferredWindowWarmupTimer;
  Timer? _extendedWindowWarmupTimer;
  Timer? _localAdjacentLoadTimer;
  ReaderChapterContentLoader? _chapterContentLoader;
  int _lastVisibleScrollChapter = -1;
  final Map<int, String> _chapterFailureMessages = <int, String>{};

  bool get hasContentManager => _contentManager != null;
  bool get isWholeBookPreloadEnabled =>
      hasContentManager && _contentManager!.wholeBookPreloadEnabled;

  bool isKnownEmptyChapter(int index) =>
      hasContentManager && _contentManager!.isKnownEmptyChapter(index);

  String? chapterFailureMessage(int chapterIndex) =>
      _chapterFailureMessages[chapterIndex];

  bool hasChapterFailure(int chapterIndex) =>
      _chapterFailureMessages.containsKey(chapterIndex);

  void clearChapterFailure(int chapterIndex) {
    _chapterFailureMessages.remove(chapterIndex);
  }

  bool hasCachedContent(int chapterIndex) {
    return _contentManager?.getCachedContent(chapterIndex) != null;
  }

  void updatePaginationConfig(PaginationConfig config) {
    _contentManager?.updateConfig(config);
  }

  Future<void> repaginateForDisplay({
    required int centerChapterIndex,
    required bool isScrollMode,
    required int scrollRadius,
  }) {
    if (!hasContentManager) return Future<void>.value();
    return _contentManager!.repaginateForDisplay(
      centerChapterIndex: centerChapterIndex,
      isScrollMode: isScrollMode,
      scrollRadius: scrollRadius,
    );
  }

  void syncPaginatedCacheTo(Map<int, List<TextPage>> chapterPagesCache) {
    if (!hasContentManager) return;
    chapterPagesCache
      ..clear()
      ..addAll(_contentManager!.paginatedCache);
  }

  void prioritizeChapter(int chapterIndex, {int preloadRadius = 1}) {
    if (!hasContentManager) return;
    _contentManager!.prioritizeChapter(
      chapterIndex,
      preloadRadius: preloadRadius,
    );
  }

  void putChapterContent({
    required int chapterIndex,
    required String content,
    Map<int, List<TextPage>>? chapterPagesCache,
    void Function(int chapterIndex)? refreshChapterRuntime,
  }) {
    if (!hasContentManager) return;
    _contentManager!.putContent(chapterIndex, content);
    chapterPagesCache?.remove(chapterIndex);
    refreshChapterRuntime?.call(chapterIndex);
  }

  void init({
    required Book book,
    required ChapterDao chapterDao,
    required ReplaceRuleDao replaceDao,
    required BookSourceDao sourceDao,
    required BookSourceService service,
    required int Function() currentChineseConvert,
    required BookSource? Function() getSource,
    required void Function(BookSource value) setSource,
    required String? Function(int currentIndex) resolveNextChapterUrl,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required void Function(List<TextPage> pages) setSlidePages,
    required void Function() resetPresentationState,
    required void Function(int chapterIndex) onChapterReady,
  }) {
    _chapterReadySub?.cancel();
    _deferredWindowWarmupTimer?.cancel();
    _extendedWindowWarmupTimer?.cancel();
    _localAdjacentLoadTimer?.cancel();
    _chapterContentLoader?.resetProcessingContext();
    _contentManager?.dispose();
    _chapterFailureMessages.clear();
    _lastVisibleScrollChapter = -1;
    chapterPagesCache.clear();
    setSlidePages(const <TextPage>[]);
    resetPresentationState();
    _chapterContentLoader = ReaderChapterContentLoader(
      book: book,
      chapterDao: chapterDao,
      replaceDao: replaceDao,
      sourceDao: sourceDao,
      service: service,
      currentChineseConvert: currentChineseConvert,
      getSource: getSource,
      setSource: setSource,
      resolveNextChapterUrl: resolveNextChapterUrl,
    );
    _contentManager = ChapterContentManager(
      fetchFn: (index) => _fetchChapterData(index, chapters: chapters),
      chapters: chapters,
    );
    _contentManager!.setProgressivePaginationEnabled(false);
    _chapterReadySub = _contentManager!.onChapterReady.listen(onChapterReady);
  }

  void dispose({
    required Map<int, List<TextPage>> chapterPagesCache,
    required void Function(List<TextPage> pages) setSlidePages,
    required void Function() resetPresentationState,
  }) {
    _chapterReadySub?.cancel();
    _deferredWindowWarmupTimer?.cancel();
    _extendedWindowWarmupTimer?.cancel();
    _localAdjacentLoadTimer?.cancel();
    _chapterContentLoader?.resetProcessingContext();
    chapterPagesCache.clear();
    setSlidePages(const <TextPage>[]);
    resetPresentationState();
    _contentManager?.dispose();
    _contentManager = null;
    _chapterContentLoader = null;
    _chapterFailureMessages.clear();
    _lastVisibleScrollChapter = -1;
  }

  Future<List<TextPage>> loadAndCacheChapter({
    required int index,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
    bool silent = false,
  }) async {
    if (index < 0 || index >= chapters.length || !hasContentManager) return [];
    final cached = chapterPagesCache[index];
    if (cached != null && cached.isNotEmpty) return cached;

    if (!silent) {
      loadingChapters.add(index);
      if (!isDisposed()) notifyListeners();
    }
    try {
      final pages = await _contentManager!.ensureChapterReady(index);
      if (pages.isNotEmpty) {
        chapterPagesCache[index] = pages;
        ReaderPerfTrace.mark(
          'reader cache chapter $index ready (pages: ${pages.length}, silent: $silent)',
        );
        refreshChapterRuntime(index);
        ReaderPerfTrace.mark('reader runtime chapter $index refreshed');
      }
      return pages;
    } finally {
      if (!silent) {
        loadingChapters.remove(index);
        if (!isDisposed()) notifyListeners();
      }
    }
  }

  Future<List<TextPage>> ensureChapterCached({
    required int index,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    bool silent = true,
    bool prioritize = false,
    int preloadRadius = 1,
  }) {
    if (hasContentManager && isScrollMode) {
      activateScrollWindow(
        centerIndex: index,
        preloadRadius: scrollPreloadRadius,
        preload: !isLocalScrollMode,
        chapterPagesCache: chapterPagesCache,
        refreshChapterRuntime: refreshChapterRuntime,
      );
      if (prioritize && !isLocalScrollMode) {
        _contentManager!.prioritize([index], centerIndex: index);
      }
    }
    return loadAndCacheChapter(
      index: index,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: isDisposed,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: refreshChapterRuntime,
      silent: silent,
    );
  }

  Future<List<TextPage>?> trySyncPaginate({
    required int chapterIndex,
    required Map<int, List<TextPage>> chapterPagesCache,
    required void Function(int chapterIndex) refreshChapterRuntime,
  }) async {
    if (!hasContentManager) return null;
    final pages = await _contentManager!.paginateIfCached(chapterIndex);
    if (pages.isEmpty) return null;
    chapterPagesCache[chapterIndex] = pages;
    refreshChapterRuntime(chapterIndex);
    return pages;
  }

  void bootstrapChapterWindow({
    required int centerIndex,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    required Map<int, List<TextPage>> chapterPagesCache,
    required void Function(int chapterIndex) refreshChapterRuntime,
  }) {
    if (!hasContentManager) return;
    prepareChapterDisplayWindow(
      chapterIndex: centerIndex,
      preloadRadius: isScrollMode ? scrollPreloadRadius : 1,
      isScrollMode: isScrollMode,
      isLocalScrollMode: isLocalScrollMode,
      chapterPagesCache: chapterPagesCache,
      refreshChapterRuntime: refreshChapterRuntime,
    );
  }

  void scheduleDeferredWindowWarmup({
    required int centerIndex,
    required int visibleChapterIndex,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    required bool Function() isDisposed,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
    Duration delay = const Duration(milliseconds: 1500),
  }) {
    if (isLocalScrollMode) return;
    _deferredWindowWarmupTimer?.cancel();
    _extendedWindowWarmupTimer?.cancel();
    final effectiveDelay =
        isScrollMode ? delay : const Duration(milliseconds: 150);
    _deferredWindowWarmupTimer = Timer(effectiveDelay, () {
      if (isDisposed() || !hasContentManager) return;
      if (isScrollMode && _contentManager!.userInteractionActive) {
        scheduleDeferredWindowWarmup(
          centerIndex: visibleChapterIndex,
          visibleChapterIndex: visibleChapterIndex,
          isScrollMode: isScrollMode,
          isLocalScrollMode: isLocalScrollMode,
          isDisposed: isDisposed,
          chapters: chapters,
          chapterPagesCache: chapterPagesCache,
          loadingChapters: loadingChapters,
          notifyListeners: notifyListeners,
          refreshChapterRuntime: refreshChapterRuntime,
          delay: const Duration(milliseconds: 900),
        );
        return;
      }
      final warmupCenter = isScrollMode ? visibleChapterIndex : centerIndex;
      if (isScrollMode) {
        _contentManager!.warmupWindow(
          warmupCenter,
          preloadRadius: scrollPreloadRadius,
        );
        if (isLocalScrollMode) {
          unawaited(
            _loadAdjacentScrollChapters(
              centerIndex: warmupCenter,
              chapters: chapters,
              chapterPagesCache: chapterPagesCache,
              loadingChapters: loadingChapters,
              isDisposed: isDisposed,
              notifyListeners: notifyListeners,
              refreshChapterRuntime: refreshChapterRuntime,
            ),
          );
        }
        return;
      }
      warmSlideWindow(centerChapterIndex: warmupCenter);
    });
  }

  void triggerSilentPreload({
    required int currentChapterIndex,
    required int visibleChapterIndex,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    required bool Function() isDisposed,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
  }) {
    if (!hasContentManager) return;
    if (isScrollMode) {
      if (isLocalScrollMode) return;
      scheduleDeferredWindowWarmup(
        centerIndex: visibleChapterIndex,
        visibleChapterIndex: visibleChapterIndex,
        isScrollMode: isScrollMode,
        isLocalScrollMode: isLocalScrollMode,
        isDisposed: isDisposed,
        chapters: chapters,
        chapterPagesCache: chapterPagesCache,
        loadingChapters: loadingChapters,
        notifyListeners: notifyListeners,
        refreshChapterRuntime: refreshChapterRuntime,
        delay: const Duration(milliseconds: 900),
      );
      return;
    }
    warmSlideWindow(centerChapterIndex: currentChapterIndex);
  }

  void updateScrollPreloadForVisibleChapter({
    required int visibleChapter,
    required double? localOffset,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
    required bool isScrollMode,
    required bool isLocalScrollMode,
  }) {
    if (!hasContentManager || !isScrollMode) return;
    ReaderPerfTrace.mark(
      'scroll preload update center=$visibleChapter '
      '(cached: ${chapterPagesCache[visibleChapter]?.isNotEmpty == true}, '
      'loading: ${loadingChapters.contains(visibleChapter)})',
    );
    activateScrollWindow(
      centerIndex: visibleChapter,
      preloadRadius: scrollPreloadRadius,
      preload: !isLocalScrollMode,
      chapterPagesCache: chapterPagesCache,
      refreshChapterRuntime: refreshChapterRuntime,
    );
    final visiblePages = chapterPagesCache[visibleChapter];
    if ((visiblePages == null || visiblePages.isEmpty) &&
        !loadingChapters.contains(visibleChapter)) {
      unawaited(
        ensureChapterCached(
          index: visibleChapter,
          chapters: chapters,
          chapterPagesCache: chapterPagesCache,
          loadingChapters: loadingChapters,
          isDisposed: isDisposed,
          notifyListeners: notifyListeners,
          refreshChapterRuntime: refreshChapterRuntime,
          isScrollMode: isScrollMode,
          isLocalScrollMode: isLocalScrollMode,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        ),
      );
    }
    if (isLocalScrollMode) {
      _scheduleAdjacentScrollLoad(
        centerIndex: visibleChapter,
        chapters: chapters,
        chapterPagesCache: chapterPagesCache,
        loadingChapters: loadingChapters,
        isDisposed: isDisposed,
        notifyListeners: notifyListeners,
        refreshChapterRuntime: refreshChapterRuntime,
        immediate: true,
      );
    }

    if (localOffset != null &&
        visiblePages != null &&
        visiblePages.isNotEmpty) {
      final chapterHeight = ChapterPositionResolver.chapterHeight(visiblePages);
      if (chapterHeight > 0) {
        final progress = localOffset / chapterHeight;
        if (progress > 0.8) {
          final nextIdx = visibleChapter + 1;
          if (nextIdx < chapters.length &&
              !(chapterPagesCache[nextIdx]?.isNotEmpty ?? false) &&
              !loadingChapters.contains(nextIdx)) {
            unawaited(
              ensureChapterCached(
                index: nextIdx,
                chapters: chapters,
                chapterPagesCache: chapterPagesCache,
                loadingChapters: loadingChapters,
                isDisposed: isDisposed,
                notifyListeners: notifyListeners,
                refreshChapterRuntime: refreshChapterRuntime,
                isScrollMode: isScrollMode,
                isLocalScrollMode: isLocalScrollMode,
                prioritize: true,
              ),
            );
          }
        }
        if (progress < 0.2) {
          final prevIdx = visibleChapter - 1;
          if (prevIdx >= 0 &&
              !(chapterPagesCache[prevIdx]?.isNotEmpty ?? false) &&
              !loadingChapters.contains(prevIdx)) {
            unawaited(
              ensureChapterCached(
                index: prevIdx,
                chapters: chapters,
                chapterPagesCache: chapterPagesCache,
                loadingChapters: loadingChapters,
                isDisposed: isDisposed,
                notifyListeners: notifyListeners,
                refreshChapterRuntime: refreshChapterRuntime,
                isScrollMode: isScrollMode,
                isLocalScrollMode: isLocalScrollMode,
                prioritize: true,
              ),
            );
          }
        }
      }
    }
  }

  void setScrollInteractionActive({
    required bool active,
    required int visibleChapterIndex,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    required bool Function() isDisposed,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
  }) {
    if (!hasContentManager) return;
    if (!isScrollMode) {
      if (!active) {
        _contentManager!.setUserInteractionActive(false);
      }
      return;
    }
    _contentManager!.setUserInteractionActive(active);
    if (isLocalScrollMode) return;
    if (!active) {
      scheduleDeferredWindowWarmup(
        centerIndex: visibleChapterIndex,
        visibleChapterIndex: visibleChapterIndex,
        isScrollMode: isScrollMode,
        isLocalScrollMode: isLocalScrollMode,
        isDisposed: isDisposed,
        chapters: chapters,
        chapterPagesCache: chapterPagesCache,
        loadingChapters: loadingChapters,
        notifyListeners: notifyListeners,
        refreshChapterRuntime: refreshChapterRuntime,
        delay: const Duration(milliseconds: 700),
      );
    }
  }

  void handleChapterReady({
    required int chapterIndex,
    required int visibleChapterIndex,
    required int currentChapterIndex,
    required Map<int, List<TextPage>> chapterPagesCache,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    required bool hasPendingSlideRecenter,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
    required void Function() refreshSlidePages,
  }) {
    if (isDisposed()) return;
    final trace = Stopwatch()..start();
    final pages = _contentManager?.getCachedPages(chapterIndex);
    final shouldNotify =
        pages != null &&
        pages.isNotEmpty &&
        (!isScrollMode ||
            _shouldNotifyChapterReady(
              chapterIndex: chapterIndex,
              visibleChapterIndex: visibleChapterIndex,
              currentChapterIndex: currentChapterIndex,
            ));
    if (pages != null && pages.isNotEmpty) {
      chapterPagesCache[chapterIndex] = pages;
      refreshChapterRuntime(chapterIndex);
      if (isScrollMode) {
        activateScrollWindow(
          centerIndex: visibleChapterIndex,
          preloadRadius: scrollPreloadRadius,
          preload: !isLocalScrollMode,
          chapterPagesCache: chapterPagesCache,
          refreshChapterRuntime: refreshChapterRuntime,
        );
      }
    }
    if (!isScrollMode) {
      if (!hasPendingSlideRecenter) {
        refreshSlidePages();
      }
      if (!isDisposed()) notifyListeners();
    } else if (pages != null && pages.isNotEmpty) {
      if (!isDisposed()) notifyListeners();
    }
    trace.stop();
    ReaderPerfTrace.mark(
      'chapter ready applied $chapterIndex '
      '(pages: ${pages?.length ?? 0}, notify: $shouldNotify, '
      'scrollMode: $isScrollMode, total: ${trace.elapsedMilliseconds}ms)',
    );
  }

  int effectivePreloadRadius({
    required int requestedRadius,
    required bool isScrollMode,
    required bool isLocalBook,
  }) {
    if (isLocalBook && isScrollMode) return 1;
    if (isScrollMode) {
      return requestedRadius.clamp(0, scrollPreloadRadius).toInt();
    }
    return requestedRadius;
  }

  void prepareChapterDisplayWindow({
    required int chapterIndex,
    required int preloadRadius,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    required Map<int, List<TextPage>> chapterPagesCache,
    required void Function(int chapterIndex) refreshChapterRuntime,
  }) {
    if (!hasContentManager) return;
    if (isScrollMode) {
      activateScrollWindow(
        centerIndex: chapterIndex,
        preloadRadius: preloadRadius,
        preload: !isLocalScrollMode,
        chapterPagesCache: chapterPagesCache,
        refreshChapterRuntime: refreshChapterRuntime,
      );
      return;
    }
    _contentManager!.updateWindow(
      chapterIndex,
      preloadRadius: preloadRadius,
      preload: !isLocalScrollMode,
    );
  }

  void warmupAfterChapterLoad({
    required int chapterIndex,
    required int preloadRadius,
    required int visibleChapterIndex,
    required bool isScrollMode,
    required bool isLocalBook,
    required bool isLocalScrollMode,
    required bool Function() isDisposed,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
  }) {
    if (preloadRadius <= 0) return;
    if (isLocalScrollMode) {
      _scheduleAdjacentScrollLoad(
        centerIndex: chapterIndex,
        chapters: chapters,
        chapterPagesCache: chapterPagesCache,
        loadingChapters: loadingChapters,
        isDisposed: isDisposed,
        notifyListeners: notifyListeners,
        refreshChapterRuntime: refreshChapterRuntime,
        immediate: true,
      );
      return;
    }
    if (isScrollMode) {
      scheduleDeferredWindowWarmup(
        centerIndex: chapterIndex,
        visibleChapterIndex: visibleChapterIndex,
        isScrollMode: isScrollMode,
        isLocalScrollMode: isLocalScrollMode,
        isDisposed: isDisposed,
        chapters: chapters,
        chapterPagesCache: chapterPagesCache,
        loadingChapters: loadingChapters,
        notifyListeners: notifyListeners,
        refreshChapterRuntime: refreshChapterRuntime,
        delay: const Duration(milliseconds: 900),
      );
      return;
    }
    preloadSlideNeighbors(
      chapterIndex: chapterIndex,
      preloadRadius: preloadRadius,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: isDisposed,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: refreshChapterRuntime,
    );
    warmSlideWindow(centerChapterIndex: chapterIndex, radius: preloadRadius);
  }

  void preloadSlideNeighbors({
    required int chapterIndex,
    required int preloadRadius,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
  }) {
    if (preloadRadius <= 0) return;
    for (int delta = 1; delta <= preloadRadius; delta++) {
      for (final neighbor in [chapterIndex + delta, chapterIndex - delta]) {
        if (neighbor < 0 || neighbor >= chapters.length) continue;
        if (chapterPagesCache[neighbor]?.isNotEmpty ?? false) continue;
        unawaited(
          loadAndCacheChapter(
            index: neighbor,
            chapters: chapters,
            chapterPagesCache: chapterPagesCache,
            loadingChapters: loadingChapters,
            isDisposed: isDisposed,
            notifyListeners: notifyListeners,
            refreshChapterRuntime: refreshChapterRuntime,
            silent: true,
          ),
        );
      }
    }
  }

  void warmSlideWindow({required int centerChapterIndex, int? radius}) {
    if (!hasContentManager) return;
    final warmupRadius = radius ?? 2;
    _contentManager!.updateWindow(
      centerChapterIndex,
      preloadRadius: warmupRadius,
    );
    _contentManager!.warmChaptersAround(
      centerChapterIndex,
      radius: warmupRadius,
    );
  }

  void activateScrollWindow({
    required int centerIndex,
    required int preloadRadius,
    required bool preload,
    required Map<int, List<TextPage>> chapterPagesCache,
    required void Function(int chapterIndex) refreshChapterRuntime,
  }) {
    if (!hasContentManager) return;
    final evicted = _contentManager!.activateWindow(
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
      refreshChapterRuntime(index);
    }
  }

  Future<FetchResult> _fetchChapterData(
    int index, {
    required List<BookChapter> chapters,
  }) async {
    final chapter = chapters[index];
    AppLog.d('Reader: Fetching content for chapter $index: ${chapter.title}');
    final result = await _chapterContentLoader!.load(index, chapter);
    if (result.failureMessage == null ||
        result.failureMessage!.trim().isEmpty) {
      _chapterFailureMessages.remove(index);
    } else {
      _chapterFailureMessages[index] = result.failureMessage!;
    }
    return result;
  }

  bool _shouldNotifyChapterReady({
    required int chapterIndex,
    required int visibleChapterIndex,
    required int currentChapterIndex,
  }) {
    if (_contentManager == null) return false;
    if (_contentManager!.activeLoadingChapters.contains(chapterIndex)) {
      return true;
    }
    return (chapterIndex - visibleChapterIndex).abs() <= scrollPreloadRadius ||
        (chapterIndex - currentChapterIndex).abs() <= scrollPreloadRadius;
  }

  void _scheduleAdjacentScrollLoad({
    required int centerIndex,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
    bool immediate = false,
  }) {
    _localAdjacentLoadTimer?.cancel();
    final delay = immediate ? Duration.zero : const Duration(milliseconds: 280);
    _localAdjacentLoadTimer = Timer(delay, () {
      if (isDisposed()) return;
      unawaited(
        _loadAdjacentScrollChapters(
          centerIndex: centerIndex,
          chapters: chapters,
          chapterPagesCache: chapterPagesCache,
          loadingChapters: loadingChapters,
          isDisposed: isDisposed,
          notifyListeners: notifyListeners,
          refreshChapterRuntime: refreshChapterRuntime,
        ),
      );
    });
  }

  Future<void> _loadAdjacentScrollChapters({
    required int centerIndex,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required void Function(int chapterIndex) refreshChapterRuntime,
  }) async {
    final direction =
        _lastVisibleScrollChapter == -1
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
      await loadAndCacheChapter(
        index: neighbor,
        chapters: chapters,
        chapterPagesCache: chapterPagesCache,
        loadingChapters: loadingChapters,
        isDisposed: isDisposed,
        notifyListeners: notifyListeners,
        refreshChapterRuntime: refreshChapterRuntime,
        silent: true,
      );
      break;
    }
  }
}
