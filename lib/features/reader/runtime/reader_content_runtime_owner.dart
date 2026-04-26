import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_content_manager.dart'
    show PaginationConfig;
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/content_callbacks.dart';
import 'package:inkpage_reader/features/reader/provider/slide_window.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_content_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_content_lifecycle_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_content_pipeline.dart';

class ReaderContentRuntimeOwner {
  final ReaderContentLifecycleRuntime _lifecycle;
  final ReaderContentPipeline _pipeline;
  ContentCallbacks _callbacks = ContentCallbacks.empty;

  ReaderContentRuntimeOwner({
    ReaderContentLifecycleRuntime? lifecycle,
    ReaderContentPipeline? pipeline,
  }) : _lifecycle = lifecycle ?? ReaderContentLifecycleRuntime(),
       _pipeline = pipeline ?? ReaderContentPipeline();

  set callbacks(ContentCallbacks value) => _callbacks = value;

  SlideWindow get slideWindow => _pipeline.slideWindow;
  bool get hasPendingSlideRecenter => _pipeline.hasPendingSlideRecenter;
  bool get hasContentManager => _lifecycle.hasContentManager;
  bool get isWholeBookPreloadEnabled => _lifecycle.isWholeBookPreloadEnabled;
  bool get isScrollInteractionActive => _lifecycle.isUserInteractionActive;

  bool isKnownEmptyChapter(int index) => _lifecycle.isKnownEmptyChapter(index);

  String? chapterFailureMessage(int chapterIndex) =>
      _lifecycle.chapterFailureMessage(chapterIndex);

  bool hasChapterFailure(int chapterIndex) =>
      _lifecycle.hasChapterFailure(chapterIndex);

  void clearChapterFailure(int chapterIndex) {
    _lifecycle.clearChapterFailure(chapterIndex);
  }

  void clearChapterContentState(int chapterIndex) {
    _lifecycle.clearChapterContentState(chapterIndex);
    _callbacks.refreshChapterRuntime?.call(chapterIndex);
  }

  bool hasCachedChapterContent(int chapterIndex) {
    return _lifecycle.hasCachedContent(chapterIndex);
  }

  void prioritizeChapterContent(
    int chapterIndex, {
    int preloadRadius = 1,
    Set<int> retainedChapterIndexes = const <int>{},
  }) {
    _lifecycle.prioritizeChapter(
      chapterIndex,
      preloadRadius: preloadRadius,
      retainedChapterIndexes: retainedChapterIndexes,
    );
  }

  void putChapterContent({
    required int chapterIndex,
    required String content,
    Map<int, List<TextPage>>? chapterPagesCache,
  }) {
    _lifecycle.putChapterContent(
      chapterIndex: chapterIndex,
      content: content,
      chapterPagesCache: chapterPagesCache,
      refreshChapterRuntime: _callbacks.refreshChapterRuntime,
    );
  }

  void resetPresentationState() {
    _pipeline.reset();
  }

  void clearPendingSlideRecenter() {
    _pipeline.clearPendingSlideRecenter();
  }

  void pinSlideTarget({
    required int chapterIndex,
    required int charOffset,
    bool fromEnd = false,
  }) {
    _pipeline.pinSlideTarget(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
      fromEnd: fromEnd,
    );
  }

  ReaderSlideWindowUpdate? applyPendingSlideRecenter({
    required int currentPageIndex,
    required List<TextPage> currentSlidePages,
    required Map<int, List<TextPage>> chapterPagesCache,
    required int totalChapters,
  }) {
    return _pipeline.applyPendingSlideRecenter(
      currentPageIndex: currentPageIndex,
      currentSlidePages: currentSlidePages,
      chapterPagesCache: chapterPagesCache,
      totalChapters: totalChapters,
    );
  }

  ReaderSlideWindowUpdate rebuildSlidePages({
    required int currentChapterIndex,
    required int currentPageIndex,
    required List<TextPage> currentSlidePages,
    required List<TextPage>? runtimePages,
    required Map<int, List<TextPage>> chapterPagesCache,
    required int totalChapters,
    required ReaderPresentationAnchor durableAnchor,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    return _pipeline.rebuildSlidePages(
      currentChapterIndex: currentChapterIndex,
      currentPageIndex: currentPageIndex,
      currentSlidePages: currentSlidePages,
      runtimePages: runtimePages,
      chapterPagesCache: chapterPagesCache,
      totalChapters: totalChapters,
      durableLocation: durableAnchor.location,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
    );
  }

  ReaderSlidePageChange? handleSlidePageChanged({
    required int pageIndex,
    required List<TextPage> slidePages,
    required int currentChapterIndex,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
  }) {
    return _pipeline.handleSlidePageChanged(
      pageIndex: pageIndex,
      slidePages: slidePages,
      currentChapterIndex: currentChapterIndex,
      pagesForChapter: pagesForChapter,
      chapterAt: chapterAt,
    );
  }

  bool clearPinnedSlideTargetIfReached({
    required int currentPageIndex,
    required List<TextPage> slidePages,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    return _pipeline.clearPinnedSlideTargetIfReached(
      currentPageIndex: currentPageIndex,
      slidePages: slidePages,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
    );
  }

  ReaderContentPresentation resolvePresentation(
    ReaderPresentationRequest request,
  ) {
    return _pipeline.resolvePresentation(request);
  }

  void initLifecycle({
    required void Function(int chapterIndex) onChapterReady,
    required void Function() resetPresentationState,
    required void Function(List<TextPage> pages) setSlidePages,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Book book,
    required ChapterDao chapterDao,
    required ReaderChapterContentDao? chapterContentDao,
    required ReplaceRuleDao replaceDao,
    required BookSourceDao sourceDao,
    required BookSourceService service,
    required int Function() currentChineseConvert,
    required BookSource? Function() getSource,
    required void Function(BookSource value) setSource,
    required String? Function(int currentIndex) resolveNextChapterUrl,
    required List<BookChapter> chapters,
  }) {
    _lifecycle.init(
      book: book,
      chapterDao: chapterDao,
      chapterContentDao: chapterContentDao,
      replaceDao: replaceDao,
      sourceDao: sourceDao,
      service: service,
      currentChineseConvert: currentChineseConvert,
      getSource: getSource,
      setSource: setSource,
      resolveNextChapterUrl: resolveNextChapterUrl,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      setSlidePages: setSlidePages,
      resetPresentationState: resetPresentationState,
      onChapterReady: onChapterReady,
    );
  }

  void disposeLifecycle({
    required Map<int, List<TextPage>> chapterPagesCache,
    required void Function(List<TextPage> pages) setSlidePages,
    required void Function() resetPresentationState,
  }) {
    _lifecycle.dispose(
      chapterPagesCache: chapterPagesCache,
      setSlidePages: setSlidePages,
      resetPresentationState: resetPresentationState,
    );
  }

  void updatePaginationConfig(PaginationConfig config) {
    _lifecycle.updatePaginationConfig(config);
  }

  Future<void> repaginateForDisplay({
    required int centerChapterIndex,
    required bool isScrollMode,
    required int scrollRadius,
  }) {
    return _lifecycle.repaginateForDisplay(
      centerChapterIndex: centerChapterIndex,
      isScrollMode: isScrollMode,
      scrollRadius: scrollRadius,
    );
  }

  void syncPaginatedCacheTo(Map<int, List<TextPage>> chapterPagesCache) {
    _lifecycle.syncPaginatedCacheTo(chapterPagesCache);
  }

  Future<List<TextPage>> loadAndCacheChapter({
    required int index,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    bool silent = false,
  }) {
    return _lifecycle.loadAndCacheChapter(
      index: index,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: isDisposed,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: (chapterIndex) {
        _callbacks.refreshChapterRuntime?.call(chapterIndex);
      },
      silent: silent,
    );
  }

  Future<List<TextPage>> ensureChapterCached({
    required int index,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    Set<int> retainedChapterIndexes = const <int>{},
    bool silent = true,
    bool prioritize = false,
    int preloadRadius = 1,
  }) {
    return _lifecycle.ensureChapterCached(
      index: index,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: isDisposed,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: (chapterIndex) {
        _callbacks.refreshChapterRuntime?.call(chapterIndex);
      },
      isScrollMode: isScrollMode,
      isLocalScrollMode: isLocalScrollMode,
      retainedChapterIndexes: retainedChapterIndexes,
      silent: silent,
      prioritize: prioritize,
      preloadRadius: preloadRadius,
    );
  }

  void bootstrapChapterWindow({
    required int centerIndex,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    required Map<int, List<TextPage>> chapterPagesCache,
    Set<int> retainedChapterIndexes = const <int>{},
  }) {
    _lifecycle.bootstrapChapterWindow(
      centerIndex: centerIndex,
      isScrollMode: isScrollMode,
      isLocalScrollMode: isLocalScrollMode,
      chapterPagesCache: chapterPagesCache,
      retainedChapterIndexes: retainedChapterIndexes,
      refreshChapterRuntime: (chapterIndex) {
        _callbacks.refreshChapterRuntime?.call(chapterIndex);
      },
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
    Duration delay = const Duration(milliseconds: 1500),
  }) {
    _lifecycle.scheduleDeferredWindowWarmup(
      centerIndex: centerIndex,
      visibleChapterIndex: visibleChapterIndex,
      isScrollMode: isScrollMode,
      isLocalScrollMode: isLocalScrollMode,
      isDisposed: isDisposed,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: (chapterIndex) {
        _callbacks.refreshChapterRuntime?.call(chapterIndex);
      },
      delay: delay,
    );
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
  }) {
    _lifecycle.triggerSilentPreload(
      currentChapterIndex: currentChapterIndex,
      visibleChapterIndex: visibleChapterIndex,
      isScrollMode: isScrollMode,
      isLocalScrollMode: isLocalScrollMode,
      isDisposed: isDisposed,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: (chapterIndex) {
        _callbacks.refreshChapterRuntime?.call(chapterIndex);
      },
    );
  }

  void updateScrollPreloadForVisibleChapter({
    required int visibleChapter,
    required double? localOffset,
    required double Function(int chapterIndex) chapterHeightFor,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    Set<int> retainedChapterIndexes = const <int>{},
  }) {
    _lifecycle.updateScrollPreloadForVisibleChapter(
      visibleChapter: visibleChapter,
      localOffset: localOffset,
      chapterHeightFor: chapterHeightFor,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: isDisposed,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: (chapterIndex) {
        _callbacks.refreshChapterRuntime?.call(chapterIndex);
      },
      isScrollMode: isScrollMode,
      isLocalScrollMode: isLocalScrollMode,
      retainedChapterIndexes: retainedChapterIndexes,
    );
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
  }) {
    _lifecycle.setScrollInteractionActive(
      active: active,
      visibleChapterIndex: visibleChapterIndex,
      isScrollMode: isScrollMode,
      isLocalScrollMode: isLocalScrollMode,
      isDisposed: isDisposed,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: (chapterIndex) {
        _callbacks.refreshChapterRuntime?.call(chapterIndex);
      },
    );
  }

  void handleChapterReady({
    required int chapterIndex,
    required int visibleChapterIndex,
    required int currentChapterIndex,
    required Map<int, List<TextPage>> chapterPagesCache,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
    required void Function() refreshSlidePages,
    Set<int> retainedChapterIndexes = const <int>{},
  }) {
    _lifecycle.handleChapterReady(
      chapterIndex: chapterIndex,
      visibleChapterIndex: visibleChapterIndex,
      currentChapterIndex: currentChapterIndex,
      chapterPagesCache: chapterPagesCache,
      isScrollMode: isScrollMode,
      isLocalScrollMode: isLocalScrollMode,
      hasPendingSlideRecenter: hasPendingSlideRecenter,
      isDisposed: isDisposed,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: (targetChapterIndex) {
        _callbacks.refreshChapterRuntime?.call(targetChapterIndex);
      },
      refreshSlidePages: refreshSlidePages,
      retainedChapterIndexes: retainedChapterIndexes,
    );
  }

  int effectivePreloadRadius({
    required int requestedRadius,
    required bool isScrollMode,
    required bool isLocalBook,
  }) {
    return _lifecycle.effectivePreloadRadius(
      requestedRadius: requestedRadius,
      isScrollMode: isScrollMode,
      isLocalBook: isLocalBook,
    );
  }

  void prepareChapterDisplayWindow({
    required int chapterIndex,
    required int preloadRadius,
    required bool isScrollMode,
    required bool isLocalScrollMode,
    required Map<int, List<TextPage>> chapterPagesCache,
    Set<int> retainedChapterIndexes = const <int>{},
  }) {
    _lifecycle.prepareChapterDisplayWindow(
      chapterIndex: chapterIndex,
      preloadRadius: preloadRadius,
      isScrollMode: isScrollMode,
      isLocalScrollMode: isLocalScrollMode,
      chapterPagesCache: chapterPagesCache,
      retainedChapterIndexes: retainedChapterIndexes,
      refreshChapterRuntime: (targetChapterIndex) {
        _callbacks.refreshChapterRuntime?.call(targetChapterIndex);
      },
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
  }) {
    _lifecycle.warmupAfterChapterLoad(
      chapterIndex: chapterIndex,
      preloadRadius: preloadRadius,
      visibleChapterIndex: visibleChapterIndex,
      isScrollMode: isScrollMode,
      isLocalBook: isLocalBook,
      isLocalScrollMode: isLocalScrollMode,
      isDisposed: isDisposed,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: (targetChapterIndex) {
        _callbacks.refreshChapterRuntime?.call(targetChapterIndex);
      },
    );
  }

  void preloadSlideNeighbors({
    required int chapterIndex,
    required int preloadRadius,
    required List<BookChapter> chapters,
    required Map<int, List<TextPage>> chapterPagesCache,
    required Set<int> loadingChapters,
    required bool Function() isDisposed,
    required void Function() notifyListeners,
  }) {
    _lifecycle.preloadSlideNeighbors(
      chapterIndex: chapterIndex,
      preloadRadius: preloadRadius,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: isDisposed,
      notifyListeners: notifyListeners,
      refreshChapterRuntime: (targetChapterIndex) {
        _callbacks.refreshChapterRuntime?.call(targetChapterIndex);
      },
    );
  }
}
