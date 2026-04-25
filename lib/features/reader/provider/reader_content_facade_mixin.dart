import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_content_manager.dart'
    show PaginationConfig;
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/content_callbacks.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_state.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_content_lifecycle_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_content_runtime_owner.dart';
import 'package:inkpage_reader/features/reader/provider/slide_window.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';
import 'package:inkpage_reader/core/models/book/book_extensions.dart';

import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';

mixin ReaderContentFacadeMixin on ReaderProviderBase, ReaderSettingsMixin {
  final ReaderContentRuntimeOwner _contentOwner = ReaderContentRuntimeOwner();
  int get currentNavigationGeneration => 0;
  double estimatedChapterContentHeight(
    int chapterIndex, {
    double fallback = 0.0,
  });
  bool get hasContentManager => _contentOwner.hasContentManager;
  bool get isWholeBookPreloadEnabled => _contentOwner.isWholeBookPreloadEnabled;
  bool get isScrollInteractionActive => _contentOwner.isScrollInteractionActive;
  bool isKnownEmptyChapter(int index) =>
      _contentOwner.isKnownEmptyChapter(index);
  @protected
  Set<int> retainedChapterIndexes({int? focusChapterIndex}) => const <int>{};

  void onScrollChapterReadyApplied(
    int chapterIndex, {
    required bool hasPages,
  }) {}

  bool _isPaginating = false;
  ContentCallbacks _contentCallbacks = ContentCallbacks.empty;
  ReaderViewportState? _transientViewportState;
  int? _transientViewportChapterIndex;

  List<String> _chapterDisplayTitles = const [];

  String? chapterFailureMessage(int chapterIndex) =>
      _contentOwner.chapterFailureMessage(chapterIndex);

  bool hasChapterFailure(int chapterIndex) =>
      _contentOwner.hasChapterFailure(chapterIndex);

  ReaderViewportState? get transientViewportState => _transientViewportState;
  int? get transientViewportChapterIndex => _transientViewportChapterIndex;

  void clearChapterFailure(int chapterIndex) {
    _contentOwner.clearChapterFailure(chapterIndex);
  }

  ReaderViewportState? chapterViewportStateFor(int chapterIndex) {
    final failureMessage = chapterFailureMessage(chapterIndex);
    if (failureMessage != null && failureMessage.trim().isNotEmpty) {
      return ReaderViewportState.message(failureMessage);
    }
    if (isKnownEmptyChapter(chapterIndex)) {
      return const ReaderViewportState.message('本章暫無內容');
    }
    return null;
  }

  void showTransientViewportStateForChapter(
    int chapterIndex,
    ReaderViewportState state, {
    bool notify = true,
  }) {
    final didChange =
        _transientViewportChapterIndex != chapterIndex ||
        _transientViewportState?.showLoading != state.showLoading ||
        _transientViewportState?.message != state.message;
    _transientViewportChapterIndex = chapterIndex;
    _transientViewportState = state;
    if (didChange && notify && !isDisposed) {
      notifyListeners();
    }
  }

  void clearTransientViewportState({bool notify = true}) {
    if (_transientViewportState == null &&
        _transientViewportChapterIndex == null) {
      return;
    }
    _transientViewportState = null;
    _transientViewportChapterIndex = null;
    if (notify && !isDisposed) {
      notifyListeners();
    }
  }

  /// Inject typed callbacks from ReadBookController.
  set contentCallbacks(ContentCallbacks callbacks) {
    _contentCallbacks = callbacks;
    _contentOwner.callbacks = callbacks;
  }

  /// Access typed callbacks (for mixins that depend on ReaderContentFacadeMixin).
  ContentCallbacks get contentCallbacksRef => _contentCallbacks;

  /// The current slide window (for external access).
  SlideWindow get slideWindow => _contentOwner.slideWindow;

  List<TextPage> get currentChapterPages =>
      chapterPagesCache[currentChapterIndex] ?? const <TextPage>[];

  String displayChapterTitleAt(int index) {
    if (index < 0 || index >= chapters.length) return '';
    if (index < _chapterDisplayTitles.length &&
        _chapterDisplayTitles[index].isNotEmpty) {
      return _chapterDisplayTitles[index];
    }
    return chapters[index].title;
  }

  Future<void> refreshChapterDisplayTitles({bool notify = true}) async {
    if (chapters.isEmpty) {
      _chapterDisplayTitles = const [];
      if (notify && !isDisposed) {
        _contentCallbacks.refreshAllChapterRuntime?.call();
        notifyListeners();
      }
      return;
    }

    final titleRules =
        (await replaceDao.getEnabled())
            .where((rule) => rule.isEnabled && rule.scopeTitle)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final titles =
        chapters
            .map(
              (chapter) => chapter.getDisplayTitle(
                replaceRules: titleRules,
                useReplace: book.getUseReplaceRule(),
                chineseConvertType: chineseConvert,
              ),
            )
            .toList();
    if (isDisposed) return;
    _chapterDisplayTitles = titles;
    _contentCallbacks.refreshAllChapterRuntime?.call();
    if (notify && !isDisposed) {
      notifyListeners();
    }
  }

  bool get _isLocalScrollMode =>
      pageTurnMode == PageAnim.scroll && book.origin == 'local';
  bool get _isLocalBook => book.origin == 'local';
  bool get _isScrollMode => pageTurnMode == PageAnim.scroll;
  int get _effectiveScrollPreloadRadius =>
      !_isLocalBook && book.isInBookshelf
          ? ReaderContentLifecycleRuntime.bookshelfNetworkScrollPreloadRadius
          : ReaderContentLifecycleRuntime.scrollPreloadRadius;
  // 本地書 slide 模式的 warmup 半徑與網路書相同（disk I/O 無額外成本）。
  // 僅 scroll 模式維持 1 避免過多章節同時持在記憶體中。
  int get _defaultSlideWarmupRadius => 2;
  bool get isPaginatingContent => _isPaginating;

  bool get hasPendingSlideRecenter => _contentOwner.hasPendingSlideRecenter;

  bool hasCachedChapterContent(int chapterIndex) {
    return _contentOwner.hasCachedChapterContent(chapterIndex);
  }

  void prioritizeChapterContent(int chapterIndex, {int preloadRadius = 1}) {
    _contentOwner.prioritizeChapterContent(
      chapterIndex,
      preloadRadius: preloadRadius,
      retainedChapterIndexes: retainedChapterIndexes(
        focusChapterIndex: chapterIndex,
      ),
    );
  }

  void putChapterContent(int chapterIndex, String content) {
    _contentOwner.putChapterContent(
      chapterIndex: chapterIndex,
      content: content,
      chapterPagesCache: chapterPagesCache,
    );
  }

  /// Rebuild the slide window centered on the deferred chapter and reset
  /// the page controller. Called from [reader_page.dart] after the page
  /// scroll animation has fully settled.
  void applyPendingSlideRecenter() {
    final update = _contentOwner.applyPendingSlideRecenter(
      currentPageIndex: currentPageIndex,
      currentSlidePages: slidePages,
      chapterPagesCache: chapterPagesCache,
      totalChapters: chapters.length,
    );
    if (update == null) return;
    slidePages = update.slidePages;
    currentPageIndex = update.currentPageIndex;
    requestControllerReset(currentPageIndex);
    notifyListeners();
  }

  void initContentManager() {
    _contentOwner.initLifecycle(
      onChapterReady: handleChapterReadyEvent,
      resetPresentationState: _contentOwner.resetPresentationState,
      setSlidePages: (pages) => slidePages = pages,
      chapterPagesCache: chapterPagesCache,
      book: book,
      chapterDao: chapterDao,
      tempChapterCacheDao: readerTempChapterCacheDao,
      replaceDao: replaceDao,
      sourceDao: sourceDao,
      service: service,
      currentChineseConvert: () => chineseConvert,
      getSource: () => source,
      setSource: (value) => source = value,
      resolveNextChapterUrl: _nextReadableChapterUrl,
      chapters: chapters,
    );
  }

  void resetContentLifecycle({bool refreshPaginationConfig = false}) {
    disposeContentManager();
    initContentManager();
    if (refreshPaginationConfig) {
      updatePaginationConfig();
    }
  }

  void updatePaginationConfig() {
    if (viewSize == null || !hasContentManager) return;
    final currentTheme =
        AppTheme.readingThemes[themeIndex.clamp(
          0,
          AppTheme.readingThemes.length - 1,
        )];
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
    _contentOwner.updatePaginationConfig(
      PaginationConfig(
        viewSize: viewSize!,
        titleStyle: titleStyle,
        contentStyle: contentStyle,
        paragraphSpacing: paragraphSpacing,
        textIndent: textIndent,
        textFullJustify: textFullJustify,
        contentPaddingTop: contentTopInset,
        contentPaddingBottom: contentBottomInset,
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
      await _contentOwner.repaginateForDisplay(
        centerChapterIndex: targetChapter,
        isScrollMode: _isScrollMode,
        scrollRadius: _effectiveScrollPreloadRadius,
      );
      _syncChapterPagesCacheFromContentManager();
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
    int? navigationToken,
  }) async {
    return loadChapterWithPreloadRadius(
      index,
      fromEnd: fromEnd,
      reason: reason,
      navigationToken: navigationToken,
    );
  }

  Future<void> loadChapterWithPreloadRadius(
    int index, {
    bool fromEnd = false,
    int preloadRadius = 2,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
    int? navigationToken,
  }) async {
    if (index < 0 || index >= chapters.length || !hasContentManager) return;
    final navigationGeneration = currentNavigationGeneration;
    // An explicit chapter navigation supersedes any pending recenter.
    _contentOwner.clearPendingSlideRecenter();
    updatePaginationConfig();
    final effectivePreloadRadius = _effectivePreloadRadius(preloadRadius);
    _prepareChapterDisplayWindow(index, preloadRadius: effectivePreloadRadius);

    final pages = await _loadAndCacheChapter(index);
    if (isDisposed || navigationGeneration != currentNavigationGeneration) {
      if (navigationToken != null) {
        _contentCallbacks.abortNavigation?.call(
          token: navigationToken,
          reason: reason,
        );
      }
      return;
    }
    final chapterViewportState =
        chapterViewportStateFor(index) ??
        (pages.isEmpty ? const ReaderViewportState.message('本章暫無內容') : null);
    if (chapterViewportState != null) {
      if (navigationToken != null) {
        _contentCallbacks.abortNavigation?.call(
          token: navigationToken,
          reason: reason,
        );
      }
      showTransientViewportStateForChapter(index, chapterViewportState);
      return;
    }
    clearTransientViewportState(notify: false);
    currentChapterIndex = index;
    visibleChapterIndex = index;
    _warmupAfterChapterLoad(index, preloadRadius: effectivePreloadRadius);
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
    return _contentOwner.loadAndCacheChapter(
      index: index,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: () => isDisposed,
      notifyListeners: notifyListeners,
      silent: silent,
    );
  }

  Future<List<TextPage>> ensureChapterCached(
    int index, {
    bool silent = true,
    bool prioritize = false,
    int preloadRadius = 1,
  }) {
    return _contentOwner.ensureChapterCached(
      index: index,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: () => isDisposed,
      notifyListeners: notifyListeners,
      isScrollMode: _isScrollMode,
      isLocalScrollMode: _isLocalScrollMode,
      retainedChapterIndexes: retainedChapterIndexes(focusChapterIndex: index),
      silent: silent,
      prioritize: prioritize,
      preloadRadius: preloadRadius,
    );
  }

  void _refreshSlidePages({
    ReaderCommandReason reason = ReaderCommandReason.system,
    bool requestJump = true,
  }) {
    final runtimePages = _contentCallbacks.buildSlideRuntimePages?.call();
    final update = _contentOwner.rebuildSlidePages(
      currentChapterIndex: currentChapterIndex,
      currentPageIndex: currentPageIndex,
      currentSlidePages: slidePages,
      runtimePages:
          runtimePages is List<TextPage> && runtimePages.isNotEmpty
              ? runtimePages
              : null,
      chapterPagesCache: chapterPagesCache,
      totalChapters: chapters.length,
      durableAnchor: ReaderPresentationAnchor(
        location:
            _contentCallbacks.currentCommittedLocation?.call() ??
            ReaderLocation(chapterIndex: currentChapterIndex, charOffset: 0),
      ),
      chapterAt:
          (chapterIndex) => _contentCallbacks.chapterAt?.call(chapterIndex),
      pagesForChapter:
          (chapterIndex) =>
              (_contentCallbacks.pagesForChapter?.call(chapterIndex)
                  as List<TextPage>?) ??
              chapterPagesCache[chapterIndex] ??
              const <TextPage>[],
    );
    slidePages = update.slidePages;
    currentPageIndex = update.currentPageIndex;
    if (requestJump && update.shouldRequestJump) {
      requestJumpToPage(currentPageIndex, reason: reason);
    }
  }

  void bootstrapChapterWindow(int centerIndex) {
    _contentOwner.bootstrapChapterWindow(
      centerIndex: centerIndex,
      isScrollMode: _isScrollMode,
      isLocalScrollMode: _isLocalScrollMode,
      chapterPagesCache: chapterPagesCache,
      retainedChapterIndexes: retainedChapterIndexes(
        focusChapterIndex: centerIndex,
      ),
    );
  }

  void scheduleDeferredWindowWarmup(
    int centerIndex, {
    Duration delay = const Duration(milliseconds: 1500),
  }) {
    _contentOwner.scheduleDeferredWindowWarmup(
      centerIndex: centerIndex,
      visibleChapterIndex: visibleChapterIndex,
      isScrollMode: _isScrollMode,
      isLocalScrollMode: _isLocalScrollMode,
      isDisposed: () => isDisposed,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      notifyListeners: notifyListeners,
      delay: delay,
    );
  }

  void triggerSilentPreload() {
    _contentOwner.triggerSilentPreload(
      currentChapterIndex: currentChapterIndex,
      visibleChapterIndex: visibleChapterIndex,
      isScrollMode: _isScrollMode,
      isLocalScrollMode: _isLocalScrollMode,
      isDisposed: () => isDisposed,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      notifyListeners: notifyListeners,
    );
  }

  void updateScrollPreloadForVisibleChapter(
    int visibleChapter, {
    double? localOffset,
  }) {
    _contentOwner.updateScrollPreloadForVisibleChapter(
      visibleChapter: visibleChapter,
      localOffset: localOffset,
      chapterHeightFor: estimatedChapterContentHeight,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: () => isDisposed,
      notifyListeners: notifyListeners,
      isScrollMode: _isScrollMode,
      isLocalScrollMode: _isLocalScrollMode,
      retainedChapterIndexes: retainedChapterIndexes(
        focusChapterIndex: visibleChapter,
      ),
    );
  }

  void setScrollInteractionActive(bool active) {
    _contentOwner.setScrollInteractionActive(
      active: active,
      visibleChapterIndex: visibleChapterIndex,
      isScrollMode: _isScrollMode,
      isLocalScrollMode: _isLocalScrollMode,
      isDisposed: () => isDisposed,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      notifyListeners: notifyListeners,
    );
  }

  void onPageChanged(int i) {
    final change = _contentOwner.handleSlidePageChanged(
      pageIndex: i,
      slidePages: slidePages,
      currentChapterIndex: currentChapterIndex,
      pagesForChapter: (chapterIndex) {
        return chapterPagesCache[chapterIndex] ?? const <TextPage>[];
      },
      chapterAt:
          (chapterIndex) => _contentCallbacks.chapterAt?.call(chapterIndex),
    );
    if (change == null) return;

    currentPageIndex = i;
    visibleChapterIndex = change.chapterIndex;
    visibleChapterLocalOffset = change.localOffset;

    // Only recenter the window when the chapter actually changes
    currentChapterIndex = change.chapterIndex;

    if (change.needsRecenter) {
      // Do NOT rebuild slidePages or reset the controller here. Flutter's
      // PageView fires onPageChanged at the scroll midpoint (50%), while the
      // animation is still playing. Rebuilding the window now would swap out
      // the page list mid-animation, causing wrong content to show for the
      // remaining 50% of the slide. Instead, store the target and let
      // reader_page.dart call applyPendingSlideRecenter() once the scroll
      // has fully settled — at which point the reset is visually invisible.
      // Begin preloading the new neighbor chapter in the background.
      _preloadSlideNeighbors(
        change.chapterIndex,
        preloadRadius: _defaultSlideWarmupRadius,
      );
    } else {
      // Same chapter, just refresh without recentering
      _refreshSlidePages();
    }

    notifyListeners();
  }

  void nextPage({ReaderCommandReason reason = ReaderCommandReason.user}) {
    if (pageTurnMode == PageAnim.scroll) {
      final target = (visibleChapterIndex + 1).clamp(0, chapters.length - 1);
      if (target != visibleChapterIndex) {
        unawaited(nextChapter(reason: reason));
      }
      return;
    }
    if (currentPageIndex < slidePages.length - 1) {
      currentPageIndex++;
      _contentCallbacks.jumpToSlidePage?.call(currentPageIndex, reason: reason);
      notifyListeners();
    } else {
      unawaited(nextChapter(reason: reason));
    }
  }

  void prevPage({ReaderCommandReason reason = ReaderCommandReason.user}) {
    if (pageTurnMode == PageAnim.scroll) {
      final target = (visibleChapterIndex - 1).clamp(0, chapters.length - 1);
      if (target != visibleChapterIndex) {
        unawaited(prevChapter(reason: reason));
      }
      return;
    }
    if (currentPageIndex > 0) {
      currentPageIndex--;
      _contentCallbacks.jumpToSlidePage?.call(currentPageIndex, reason: reason);
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
      _contentCallbacks.updateCommittedLocation?.call(
        ReaderLocation(chapterIndex: target, charOffset: 0),
      );
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
        _contentCallbacks.updateCommittedLocation?.call(
          ReaderLocation(chapterIndex: target, charOffset: 0),
        );
      }
      await loadChapter(target, fromEnd: fromEnd, reason: reason);
    }
  }

  String? _nextReadableChapterUrl(int currentIndex) {
    for (var i = currentIndex + 1; i < chapters.length; i++) {
      final chapter = chapters[i];
      if (!chapter.isVolume && chapter.url.isNotEmpty) {
        return chapter.url;
      }
    }
    return null;
  }

  void disposeContentManager() {
    _contentOwner.disposeLifecycle(
      chapterPagesCache: chapterPagesCache,
      setSlidePages: (pages) => slidePages = pages,
      resetPresentationState: _contentOwner.resetPresentationState,
    );
  }

  void handleChapterReadyEvent(int chapterIndex) {
    _contentOwner.handleChapterReady(
      chapterIndex: chapterIndex,
      visibleChapterIndex: visibleChapterIndex,
      currentChapterIndex: currentChapterIndex,
      chapterPagesCache: chapterPagesCache,
      isScrollMode: _isScrollMode,
      isLocalScrollMode: _isLocalScrollMode,
      isDisposed: () => isDisposed,
      notifyListeners: notifyListeners,
      refreshSlidePages: () => _refreshSlidePages(),
      retainedChapterIndexes: retainedChapterIndexes(
        focusChapterIndex: chapterIndex,
      ),
    );
    if (_isScrollMode) {
      onScrollChapterReadyApplied(
        chapterIndex,
        hasPages: chapterPagesCache[chapterIndex]?.isNotEmpty ?? false,
      );
    }
  }

  int _effectivePreloadRadius(int requestedRadius) {
    return _contentOwner.effectivePreloadRadius(
      requestedRadius: requestedRadius,
      isScrollMode: _isScrollMode,
      isLocalBook: _isLocalBook,
    );
  }

  void _prepareChapterDisplayWindow(
    int chapterIndex, {
    required int preloadRadius,
  }) {
    _contentOwner.prepareChapterDisplayWindow(
      chapterIndex: chapterIndex,
      preloadRadius: preloadRadius,
      isScrollMode: _isScrollMode,
      isLocalScrollMode: _isLocalScrollMode,
      chapterPagesCache: chapterPagesCache,
      retainedChapterIndexes: retainedChapterIndexes(
        focusChapterIndex: chapterIndex,
      ),
    );
  }

  void _warmupAfterChapterLoad(int chapterIndex, {required int preloadRadius}) {
    _contentOwner.warmupAfterChapterLoad(
      chapterIndex: chapterIndex,
      preloadRadius: preloadRadius,
      visibleChapterIndex: visibleChapterIndex,
      isScrollMode: _isScrollMode,
      isLocalBook: _isLocalBook,
      isLocalScrollMode: _isLocalScrollMode,
      isDisposed: () => isDisposed,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      notifyListeners: notifyListeners,
    );
  }

  void _preloadSlideNeighbors(int chapterIndex, {required int preloadRadius}) {
    _contentOwner.preloadSlideNeighbors(
      chapterIndex: chapterIndex,
      preloadRadius: preloadRadius,
      chapters: chapters,
      chapterPagesCache: chapterPagesCache,
      loadingChapters: loadingChapters,
      isDisposed: () => isDisposed,
      notifyListeners: notifyListeners,
    );
  }

  ReaderPresentationAnchor _presentationAnchorForChapter(
    int chapterIndex, {
    required bool fromEnd,
  }) {
    final committedLocation =
        _contentCallbacks.currentCommittedLocation?.call();
    final anchorLocation =
        committedLocation != null &&
                committedLocation.chapterIndex == chapterIndex
            ? committedLocation
            : ReaderLocation(chapterIndex: chapterIndex, charOffset: 0);
    return ReaderPresentationAnchor(location: anchorLocation, fromEnd: fromEnd);
  }

  void _presentLoadedChapter(
    int chapterIndex, {
    required List<TextPage> pages,
    required bool fromEnd,
    required ReaderCommandReason reason,
  }) {
    if (pages.isNotEmpty) {
      _contentCallbacks.refreshChapterRuntime?.call(chapterIndex);
    }
    clearTransientViewportState(notify: false);
    final presentation = _contentOwner.resolvePresentation(
      ReaderPresentationRequest(
        anchor: _presentationAnchorForChapter(chapterIndex, fromEnd: fromEnd),
        isScrollMode: _isScrollMode,
        chapterPages: pages,
        slidePages: slidePages,
        runtimeChapter: _contentCallbacks.chapterAt?.call(chapterIndex),
      ),
    );
    _contentCallbacks.updateCommittedLocation?.call(presentation.location);
    if (_isScrollMode) {
      final target = presentation.scrollTarget!;
      _contentCallbacks.jumpToChapterLocalOffset?.call(
        chapterIndex: target.chapterIndex,
        localOffset: target.localOffset,
        alignment: target.alignment,
        reason: reason,
        reuseActiveNavigation: true,
      );
      return;
    }
    _contentOwner.pinSlideTarget(
      chapterIndex: chapterIndex,
      charOffset: presentation.location.charOffset,
      fromEnd: fromEnd,
    );
    _refreshSlidePages();
    currentPageIndex = presentation.slidePageIndex ?? 0;
    _contentCallbacks.jumpToSlidePage?.call(
      currentPageIndex,
      reason: reason,
      reuseActiveNavigation: true,
    );
  }

  void _restoreDisplayPositionAfterRepaginate({
    required int targetChapter,
    required bool fromEnd,
  }) {
    const reason = ReaderCommandReason.settingsRepaginate;
    final pages = chapterPagesCache[targetChapter] ?? const <TextPage>[];
    final presentation = _contentOwner.resolvePresentation(
      ReaderPresentationRequest(
        anchor: _presentationAnchorForChapter(targetChapter, fromEnd: fromEnd),
        isScrollMode: _isScrollMode,
        chapterPages: pages,
        slidePages: slidePages,
        runtimeChapter: _contentCallbacks.chapterAt?.call(targetChapter),
      ),
    );
    _contentCallbacks.updateCommittedLocation?.call(presentation.location);
    if (_isScrollMode) {
      _contentCallbacks.jumpToChapterCharOffset?.call(
        chapterIndex: targetChapter,
        charOffset: presentation.location.charOffset,
        reason: reason,
        isRestoringJump: false,
      );
      return;
    }
    _contentOwner.pinSlideTarget(
      chapterIndex: targetChapter,
      charOffset: presentation.location.charOffset,
      fromEnd: fromEnd,
    );
    currentPageIndex = presentation.slidePageIndex ?? 0;
    _contentCallbacks.jumpToSlidePage?.call(currentPageIndex, reason: reason);
  }

  void _syncChapterPagesCacheFromContentManager() {
    if (!hasContentManager) return;
    _contentOwner.syncPaginatedCacheTo(chapterPagesCache);
    _contentCallbacks.refreshAllChapterRuntime?.call();
  }

  void refreshSlidePagesForTesting({
    int? anchorChapterIndex,
    int charOffset = 0,
    bool fromEnd = false,
  }) {
    refreshSlidePagesForAnchor(
      anchorChapterIndex: anchorChapterIndex,
      charOffset: charOffset,
      fromEnd: fromEnd,
    );
  }

  void refreshSlidePagesForAnchor({
    int? anchorChapterIndex,
    int charOffset = 0,
    bool fromEnd = false,
    ReaderCommandReason reason = ReaderCommandReason.system,
    bool requestJump = true,
  }) {
    if (anchorChapterIndex != null) {
      _contentOwner.pinSlideTarget(
        chapterIndex: anchorChapterIndex,
        charOffset: charOffset,
        fromEnd: fromEnd,
      );
    }
    _refreshSlidePages(reason: reason, requestJump: requestJump);
  }

  bool clearPinnedSlideTargetIfReached(int currentPageIndex) {
    return _contentOwner.clearPinnedSlideTargetIfReached(
      currentPageIndex: currentPageIndex,
      slidePages: slidePages,
      chapterAt:
          (chapterIndex) => _contentCallbacks.chapterAt?.call(chapterIndex),
      pagesForChapter:
          (chapterIndex) =>
              (_contentCallbacks.pagesForChapter?.call(chapterIndex)
                  as List<TextPage>?) ??
              chapterPagesCache[chapterIndex] ??
              const <TextPage>[],
    );
  }
}
