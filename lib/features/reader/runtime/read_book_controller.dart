import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/config/app_config.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/database/dao/read_record_dao.dart';
import 'package:inkpage_reader/core/services/source_switch_service.dart'
    show SourceSwitchResolution;
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/reader_perf_trace.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/reader_auto_page_mixin.dart';
import 'package:inkpage_reader/features/reader/provider/content_callbacks.dart';
import 'package:inkpage_reader/features/reader/provider/reader_content_facade_mixin.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/provider/reader_settings_mixin.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/read_aloud_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_chapter_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_bootstrap_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_navigation_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_factory.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_restore_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_visibility_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_display_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_command.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_facade.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_source_switch_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_lifecycle_runtime.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';

import 'package:inkpage_reader/features/reader/provider/reader_tts_mixin.dart';

import 'package:inkpage_reader/features/reader/provider/reader_battery_mixin.dart';

class ReadBookController extends ReaderProviderBase
    with
        ReaderSettingsMixin,
        ReaderContentFacadeMixin,
        ReaderAutoPageMixin,
        ReaderTtsMixin,
        ReaderBatteryMixin,
        WidgetsBindingObserver {
  final Map<int, ReaderChapter> _chapterRuntimeCache = {};
  final ReaderChapterProvider _chapterProvider = const ReaderChapterProvider();
  final ReaderNavigationController _navigation = ReaderNavigationController();
  final ReaderRestoreCoordinator _restore = ReaderRestoreCoordinator();
  final ReaderProgressStore _progressStore = ReaderProgressStore();
  final ReaderScrollVisibilityCoordinator _scrollVisibility =
      ReaderScrollVisibilityCoordinator();
  final ReaderDisplayCoordinator _displayCoordinator =
      const ReaderDisplayCoordinator();
  late final ReaderProgressCoordinator _progressCoordinator;
  late final ReaderSessionState _sessionState;
  late final ReaderSessionCoordinator _sessionCoordinator;
  late final ReaderRuntimeController _runtimeController;
  final ReaderSessionFacade _sessionFacade = const ReaderSessionFacade();
  final ReaderSourceSwitchRuntime _sourceSwitch = ReaderSourceSwitchRuntime();
  late final ReaderSessionRuntime _sessionRuntime;
  final ReaderViewportLifecycleRuntime _viewportLifecycle =
      ReaderViewportLifecycleRuntime();
  late final ReaderBootstrapRuntime _bootstrapRuntime;
  int _lastReadRecordStamp = DateTime.now().millisecondsSinceEpoch;

  /// 初始章節字元偏移（由呼叫方傳入，用於還原閱讀位置）
  int initialCharOffset = 0;

  ReadBookController({
    required Book book,
    int chapterIndex = 0,
    int chapterPos = 0,
    List<BookChapter> initialChapters = const [],
  }) : super(book) {
    currentChapterIndex = chapterIndex;
    visibleChapterIndex = chapterIndex;
    initialCharOffset = chapterPos;
    if (initialChapters.isNotEmpty) {
      chapters = List<BookChapter>.from(initialChapters);
    }
    _sessionState = ReaderSessionState(
      initialLocation: ReaderLocation(
        chapterIndex: chapterIndex,
        charOffset: chapterPos,
      ),
    );
    _sessionCoordinator = ReaderSessionCoordinator(
      state: _sessionState,
      store: _progressStore,
      book: () => book,
      chapters: () => chapters,
      writeProgress:
          (chapterIndex, title, charOffset) => bookDao.updateProgress(
            book.bookUrl,
            chapterIndex,
            title,
            charOffset,
          ),
    );
    _runtimeController = ReaderRuntimeController(
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      slidePages: () => slidePages,
    );
    _sessionRuntime = ReaderSessionRuntime(
      runtimeController: _runtimeController,
      sessionLocation: () => sessionLocation,
      updateSessionLocation: _sessionCoordinator.updateSessionLocation,
      updateVisibleLocation: _sessionCoordinator.updateVisibleLocation,
      persistLocation: _sessionCoordinator.persistLocation,
      dispatchViewportCommand: _dispatchViewportCommand,
    );
    _bootstrapRuntime = ReaderBootstrapRuntime(
      viewportLifecycle: _viewportLifecycle,
    );
    initTts(_buildReadAloudController());
    _progressCoordinator = ReaderProgressCoordinator(
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      store: _progressStore,
      durableLocation: () => durableLocation,
      shouldPersistVisiblePosition: shouldPersistVisiblePosition,
      updateVisibleLocation: _sessionCoordinator.updateVisibleLocation,
      updateSessionLocation: _updateSessionLocation,
      persistLocation: _persistSessionLocation,
    );
    _init();
  }

  ReaderChapter? chapterAt(int index) => _chapterRuntimeCache[index];
  ReaderChapter? get prevChapterRuntime => chapterAt(currentChapterIndex - 1);
  ReaderChapter? get curChapterRuntime => chapterAt(currentChapterIndex);
  ReaderChapter? get nextChapterRuntime => chapterAt(currentChapterIndex + 1);
  List<TextPage> pagesForChapter(int index) =>
      chapterAt(index)?.pages ?? chapterPagesCache[index] ?? const <TextPage>[];
  bool hasRuntimeChapter(int index) => chapterAt(index) != null;

  ReaderPageFactory get pageFactory => ReaderPageFactory(
    prevChapter: prevChapterRuntime,
    currentChapter: curChapterRuntime,
    nextChapter: nextChapterRuntime,
    chapterCharOffset: sessionLocation.charOffset,
  );

  ReaderCommandReason? get activeCommandReason =>
      _navigation.activeCommandReason;
  ReaderProgressStore get progressStore => _progressStore;
  ReaderLocation get sessionLocation => _sessionCoordinator.sessionLocation;
  ReaderLocation get visibleLocation => _sessionCoordinator.visibleLocation;
  ReaderLocation get durableLocation => _sessionCoordinator.durableLocation;
  ReaderSessionPhase get sessionPhase => _sessionCoordinator.phase;
  bool get isSwitchingSource => _sourceSwitch.isSwitching;
  String? get sourceSwitchMessage => _sourceSwitch.message;
  String? get currentChapterFailureMessage =>
      chapterFailureMessage(currentChapterIndex);

  ReadAloudController _buildReadAloudController() {
    return ReadAloudController(
      tts: TTSService(),
      nextChapter: () => nextChapter(reason: ReaderCommandReason.tts),
      prevChapter:
          ({bool fromEnd = true}) =>
              prevChapter(fromEnd: fromEnd, reason: ReaderCommandReason.tts),
      nextPage: handleTtsNextPage,
      prevPage: handleTtsPrevPage,
      canMoveToNextPage: _canMoveToNextSlidePage,
      canMoveToPrevPage: _canMoveToPrevSlidePage,
      requestJumpToPage: handleTtsPageJump,
      requestJumpToChapter: ({
        required int chapterIndex,
        required double alignment,
        required double localOffset,
      }) {
        handleTtsChapterJump(
          chapterIndex: chapterIndex,
          alignment: alignment,
          localOffset: localOffset,
        );
      },
      chapterOf: chapterAt,
      currentChapterIndex: () => currentChapterIndex,
      visibleChapterIndex: () => visibleChapterIndex,
      currentCharOffset: _resolveCurrentCharOffset,
      visibleCharOffset: _resolveVisibleCharOffset,
      isScrollMode: () => pageTurnMode == PageAnim.scroll,
      onStateChanged: notifyIfActive,
      updateMediaInfo: updateTtsMediaInfo,
    );
  }

  void jumpToSlidePage(
    int pageIndex, {
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    if (!_navigation.beginSlideJump(reason)) return;
    requestJumpToPage(pageIndex, reason: reason);
  }

  void jumpToChapterLocalOffset({
    required int chapterIndex,
    required double localOffset,
    double alignment = 0.0,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    if (!_navigation.beginChapterJump(reason)) return;
    requestJumpToChapter(
      chapterIndex: chapterIndex,
      alignment: alignment,
      localOffset: localOffset,
      reason: reason,
    );
  }

  void jumpToChapterCharOffset({
    required int chapterIndex,
    required int charOffset,
    ReaderCommandReason reason = ReaderCommandReason.system,
    bool isRestoringJump = false,
  }) {
    final canBegin =
        pageTurnMode == PageAnim.scroll
            ? _navigation.beginChapterJump(reason)
            : _navigation.beginSlideJump(reason);
    if (!canBegin) return;
    jumpToPosition(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
      reason: reason,
      isRestoringJump: isRestoringJump,
    );
    if (!isRestoringJump) {
      notifyListeners();
    }
  }

  void persistCurrentProgress({
    required int chapterIndex,
    int? pageIndex,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    if (!_navigation.canPersistProgress(reason)) return;
    saveProgress(chapterIndex, pageIndex ?? currentPageIndex, reason: reason);
  }

  void persistChapterCharOffsetProgress({
    required int chapterIndex,
    required int charOffset,
  }) {
    unawaited(
      _persistSessionLocation(
        ReaderLocation(chapterIndex: chapterIndex, charOffset: charOffset),
      ),
    );
  }

  bool shouldPersistVisiblePosition() {
    return _navigation.shouldPersistVisiblePosition();
  }

  void reconcileVisibleScrollLoads() {
    _scrollVisibility.reconcile(hasRuntimeChapter);
  }

  void handleVisibleScrollState({
    required int chapterIndex,
    required double localOffset,
    required double alignment,
    required List<int> visibleChapterIndexes,
  }) {
    final previousVisibleChapterIndex = visibleChapterIndex;
    final previousPageIndex = currentPageIndex;
    _progressCoordinator.updateVisibleChapterPosition(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      alignment: alignment,
      pageTurnMode: pageTurnMode,
      isLoading: isLoading,
      currentPageIndex: currentPageIndex,
      updateVisible: (ci, lo, al) {
        visibleChapterIndex = ci;
        visibleChapterLocalOffset = lo;
        visibleChapterAlignment = al;
      },
      updateCurrentChapterIndex: (ci) => currentChapterIndex = ci,
    );
    _progressCoordinator.updateScrollPageIndex(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      setCurrentPageIndex: (i) => currentPageIndex = i,
      setVisibleChapterIndex: (i) => visibleChapterIndex = i,
      setCurrentChapterIndex: (i) => currentChapterIndex = i,
    );

    final update = _scrollVisibility.evaluate(
      visibleChapterIndexes: visibleChapterIndexes,
      currentChapterIndex: currentChapterIndex,
      hasRuntimeChapter: hasRuntimeChapter,
      isLoadingChapter:
          (targetChapter) => loadingChapters.contains(targetChapter),
    );

    for (final visibleChapter in update.chaptersToEnsure) {
      ReaderPerfTrace.mark('visible chapter ensure requested $visibleChapter');
      unawaited(
        ensureChapterCached(
          visibleChapter,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        ),
      );
    }

    final preloadCenterChapter = update.preloadCenterChapter;
    if (preloadCenterChapter != null) {
      ReaderPerfTrace.mark(
        'visible chapter preload center $preloadCenterChapter',
      );
      updateScrollPreloadForVisibleChapter(
        preloadCenterChapter,
        localOffset: preloadCenterChapter == chapterIndex ? localOffset : null,
      );
    }

    if ((previousVisibleChapterIndex != visibleChapterIndex ||
            previousPageIndex != currentPageIndex) &&
        !isDisposed) {
      notifyListeners();
    }
  }

  ReaderCommandReason consumePendingSlideJumpReason() {
    return _navigation.consumePendingSlideJumpReason();
  }

  ReaderCommandReason consumePageChangeReason() {
    return _navigation.consumePageChangeReason();
  }

  void clearNavigationReason(ReaderCommandReason reason) {
    _navigation.clear(reason);
  }

  bool shouldPersistForReason(ReaderCommandReason reason) {
    return _navigation.shouldPersistForReason(reason);
  }

  int registerPendingScrollRestore({
    required int chapterIndex,
    required double localOffset,
  }) {
    return _restore.registerPendingScrollRestore(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
    );
  }

  int get pendingScrollRestoreToken => _restore.pendingScrollRestoreToken;
  int? get pendingScrollRestoreChapterIndex =>
      _restore.pendingScrollRestoreChapterIndex;
  double? get pendingScrollRestoreLocalOffset =>
      _restore.pendingScrollRestoreLocalOffset;

  bool matchesPendingScrollRestore(int token) =>
      _restore.matchesPendingScrollRestore(token);

  ({int chapterIndex, double localOffset})? consumePendingScrollRestore() {
    return _restore.consumePendingScrollRestore();
  }

  ({int chapterIndex, double localOffset})? nextAutoScrollTarget(
    double dtSeconds,
  ) {
    return _navigation.nextAutoScrollTarget(
      isAutoPaging: isAutoPaging,
      pageTurnMode: pageTurnMode,
      viewSize: viewSize,
      visibleChapterIndex: visibleChapterIndex,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
      scrollDeltaPerFrame: scrollDeltaPerFrame,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      dtSeconds: dtSeconds,
    );
  }

  ({int? chapterIndex, double? localOffset, bool advanceChapter})?
  evaluateScrollAutoPageStep(double dtSeconds) {
    return _navigation.evaluateScrollAutoPageStep(
      isAutoPaging: isAutoPaging,
      isAutoPagePaused: isAutoPagePaused,
      isLoading: isLoading,
      pageTurnMode: pageTurnMode,
      viewSize: viewSize,
      visibleChapterIndex: visibleChapterIndex,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
      scrollDeltaPerFrame: scrollDeltaPerFrame,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      dtSeconds: dtSeconds,
    );
  }

  void refreshChapterRuntime(int index) {
    final pages = chapterPagesCache[index];
    if (pages == null ||
        pages.isEmpty ||
        index < 0 ||
        index >= chapters.length) {
      _chapterRuntimeCache.remove(index);
      return;
    }
    _chapterRuntimeCache[index] = _chapterProvider.buildFromPages(
      chapter: chapters[index],
      chapterIndex: index,
      title: displayChapterTitleAt(index),
      pages: pages,
    );
  }

  void refreshAllChapterRuntime() {
    _chapterRuntimeCache.clear();
    for (final entry in chapterPagesCache.entries) {
      refreshChapterRuntime(entry.key);
    }
  }

  Future<void> _init() async {
    await _bootstrapRuntime.bootstrap(
      currentViewSize: viewSize,
      pageTurnMode: pageTurnMode,
      isLocalBook: book.origin == 'local',
      currentChapterIndex: currentChapterIndex,
      visibleChapterIndex: visibleChapterIndex,
      initialCharOffset: initialCharOffset,
      isDisposed: () => isDisposed,
      addObserver: () => WidgetsBinding.instance.addObserver(this),
      setLifecycle: (value) => lifecycle = value,
      updatePhase: _sessionCoordinator.updatePhase,
      wireCallbacks: _wireCallbacks,
      prepareTasks: <ReaderBootstrapPrepareTask>[
        loadSettings,
        loadAutoPageSettings,
        loadTtsSettings,
        _loadChapters,
        _loadSource,
      ],
      initContentManager: initContentManager,
      configureRepaginateHooks: () {
        onBeforeRepaginate = _prepareSettingsRepaginateAnchor;
        onSettingsChangedRepaginate = () {
          updatePaginationConfig();
          doPaginate();
        };
      },
      batchUpdate: batchUpdate,
      applyViewSize: (size) {
        viewSize = size;
        updatePaginationConfig();
      },
      loadChapterWithPreloadRadius: (chapterIndex, preloadRadius) {
        return loadChapterWithPreloadRadius(
          chapterIndex,
          preloadRadius: preloadRadius,
        );
      },
      bootstrapChapterWindow: bootstrapChapterWindow,
      restoreInitialCharOffset: (chapterIndex, charOffset) {
        jumpToChapterCharOffset(
          chapterIndex: chapterIndex,
          charOffset: charOffset,
          reason: ReaderCommandReason.restore,
          isRestoringJump: false,
        );
      },
      clearInitialCharOffset: () => initialCharOffset = 0,
      startBatteryHeartbeat: startBatteryHeartbeat,
      attachReadAloud: readAloudController.attach,
      scheduleDeferredWindowWarmup: scheduleDeferredWindowWarmup,
      updateScrollPreloadForVisibleChapter:
          updateScrollPreloadForVisibleChapter,
      triggerSilentPreload: triggerSilentPreload,
    );
  }

  void _wireCallbacks() {
    contentCallbacks = ContentCallbacks(
      refreshChapterRuntime: refreshChapterRuntime,
      refreshAllChapterRuntime: refreshAllChapterRuntime,
      buildSlideRuntimePages: buildSlideRuntimePages,
      jumpToSlidePage:
          (pageIndex, {required reason}) =>
              jumpToSlidePage(pageIndex, reason: reason as ReaderCommandReason),
      jumpToChapterLocalOffset:
          ({
            required chapterIndex,
            required localOffset,
            required alignment,
            required reason,
          }) => jumpToChapterLocalOffset(
            chapterIndex: chapterIndex,
            localOffset: localOffset,
            alignment: alignment,
            reason: reason as ReaderCommandReason,
          ),
      jumpToChapterCharOffset:
          ({
            required chapterIndex,
            required charOffset,
            required reason,
            bool isRestoringJump = false,
          }) => jumpToChapterCharOffset(
            chapterIndex: chapterIndex,
            charOffset: charOffset,
            reason: reason as ReaderCommandReason,
            isRestoringJump: isRestoringJump,
          ),
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      progressStore: _progressStore,
      shouldPersistVisiblePosition: shouldPersistVisiblePosition,
      currentSessionLocation: () => sessionLocation,
      updateSessionLocation: _updateSessionLocation,
      persistCurrentProgress:
          ({required chapterIndex, int? pageIndex, required reason}) =>
              persistCurrentProgress(
                chapterIndex: chapterIndex,
                pageIndex: pageIndex,
                reason: reason as ReaderCommandReason,
              ),
      evaluateScrollAutoPageStep: evaluateScrollAutoPageStep,
      clearNavigationReason:
          (reason) => _navigation.clear(reason as ReaderCommandReason),
      canMoveToNextSlidePage: _canMoveToNextSlidePage,
      canMoveToPrevSlidePage: _canMoveToPrevSlidePage,
      globalPageIndexFor:
          ({required chapterIndex, required localPageIndex}) =>
              pageFactory.globalPageIndexFor(
                chapterIndex: chapterIndex,
                localPageIndex: localPageIndex,
              ),
    );
    contentCallbacksRef.debugAssertComplete();
  }

  Future<void> _loadChapters() async {
    chapters = await _sessionFacade.loadChapters(
      book: book,
      chapters: chapters,
      chapterDao: chapterDao,
    );
    if (isDisposed) return;
    await refreshChapterDisplayTitles(notify: false);
    if (!isDisposed) notifyListeners();
  }

  Future<void> _loadSource() async {
    source = await _sessionFacade.loadSource(book: book, sourceDao: sourceDao);
  }

  double textPadding = 16.0;
  double get autoPageProgress => autoPageProgressNotifier.value;

  void setViewSize(Size size) {
    final update = _viewportLifecycle.handleViewSizeChange(
      size: size,
      currentViewSize: viewSize,
      hasContentManager: hasContentManager,
      hasCachedCurrentChapterContent: hasCachedChapterContent(
        currentChapterIndex,
      ),
      hasCurrentChapterPages:
          chapterPagesCache[currentChapterIndex]?.isNotEmpty ?? false,
      isPaginatingContent: isPaginatingContent,
    );
    if (update.completedBootstrapSize) {
      return;
    }
    if (!update.shouldApplySize) return;

    viewSize = size;
    if (update.shouldRefreshPaginationConfig) {
      updatePaginationConfig();
    }
    if (update.shouldRepaginate) {
      unawaited(doPaginate());
    }
  }

  @override
  void setPageTurnMode(int v) {
    if (pageTurnMode == v) return;

    final targetLocation = _resolveModeSwitchLocation();
    pageTurnMode = v;
    AppConfig.readerPageAnim = v;
    saveSetting('page_turn_mode', v);
    _updateSessionLocation(targetLocation);
    _sessionCoordinator.updateVisibleLocation(targetLocation);
    currentChapterIndex = targetLocation.chapterIndex;
    visibleChapterIndex = targetLocation.chapterIndex;

    if (hasRuntimeChapter(targetLocation.chapterIndex) ||
        pagesForChapter(targetLocation.chapterIndex).isNotEmpty) {
      _applyModeSwitchWithCachedContent(targetLocation);
      if (isAutoPaging) {
        restartAutoPageCycle();
      }
      return;
    }

    notifyListeners();
    if (isAutoPaging) {
      restartAutoPageCycle();
    }
    unawaited(
      loadChapter(
        targetLocation.chapterIndex,
        reason: ReaderCommandReason.settingsRepaginate,
      ),
    );
  }

  @override
  void onPageChanged(int i) {
    if (pageTurnMode == PageAnim.scroll) return;
    if (i < 0 || i >= slidePages.length) return;

    super.onPageChanged(i);
    final reason = consumePageChangeReason();
    if (shouldPersistForReason(reason)) {
      persistCurrentProgress(
        chapterIndex: currentChapterIndex,
        pageIndex: i,
        reason: reason,
      );
    }
    if (i >= slidePages.length - 2 && !isLoading) {
      triggerSilentPreload();
    }

    // 提前偵測章節邊界，在接近章節末/首頁時就 prioritize 相鄰章節預載，
    // 避免使用者翻到最後一頁後才開始 fetch 下一章節而需要等待。
    _prefetchSlideNeighborIfNearBoundary(i);
  }

  /// 當目前頁接近所在章節的末尾或開頭時，提前觸發相鄰章節的優先預載。
  /// [lookAheadPages]：距邊界幾頁內開始預載（預設 3 頁）。
  void _prefetchSlideNeighborIfNearBoundary(
    int globalPageIndex, {
    int lookAheadPages = 3,
  }) {
    if (!hasContentManager || slidePages.isEmpty) return;
    if (globalPageIndex < 0 || globalPageIndex >= slidePages.length) return;

    final page = slidePages[globalPageIndex];
    final chapterIndex = page.chapterIndex;
    final chapterPages = pagesForChapter(chapterIndex);
    if (chapterPages.isEmpty) return;

    final localIndex = page.index; // 此頁在本章節中的頁碼（0-based）
    final chapterPageCount = chapterPages.length;

    // 接近章節末尾 → 預載下一章節
    if (localIndex >= chapterPageCount - 1 - lookAheadPages) {
      final next = chapterIndex + 1;
      if (next < chapters.length &&
          !(chapterPagesCache[next]?.isNotEmpty ?? false) &&
          !loadingChapters.contains(next)) {
        prioritizeChapterContent(next, preloadRadius: 1);
      }
    }

    // 接近章節開頭 → 預載上一章節
    if (localIndex <= lookAheadPages) {
      final prev = chapterIndex - 1;
      if (prev >= 0 &&
          !(chapterPagesCache[prev]?.isNotEmpty ?? false) &&
          !loadingChapters.contains(prev)) {
        prioritizeChapterContent(prev, preloadRadius: 1);
      }
    }
  }

  void handleSlidePageChanged(int index) {
    if (slidePages.isEmpty) return;
    onPageChanged(index);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistSessionProgress();
    _sessionCoordinator.updatePhase(ReaderSessionPhase.disposed);
    _progressCoordinator.dispose();
    stopBatteryHeartbeat();
    disposeAutoPageCoordinator();
    readAloudController.dispose();
    disposeContentManager();
    super.dispose();
  }

  void toggleControls() {
    _guardTransientViewportChanges();
    showControls = !showControls;
    if (showControls) {
      pauseAutoPage();
    } else {
      resumeAutoPage();
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (!isDisposed) {
        _persistSessionProgress();
        unawaited(_flushReadRecord());
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _lastReadRecordStamp = DateTime.now().millisecondsSinceEpoch;
    }
  }

  TextPage? get nextPageForAutoPage {
    if (!isAutoPaging || pageTurnMode == PageAnim.scroll) return null;
    final nextIdx = currentPageIndex + 1;
    if (nextIdx < slidePages.length) return slidePages[nextIdx];
    return null;
  }

  ReadingTheme get currentTheme =>
      AppTheme.readingThemes[themeIndex.clamp(
        0,
        AppTheme.readingThemes.length - 1,
      )];

  String get currentChapterTitle => displayChapterTitleAt(currentChapterIndex);
  String get currentChapterUrl =>
      chapters.isNotEmpty ? chapters[currentChapterIndex].url : '';

  ReaderLocation resolveExitLocation() {
    return _sessionRuntime.resolveExitLocation(_currentSessionContext());
  }

  bool shouldPromptAddToBookshelfOnExit() {
    return !book.isInBookshelf && showAddToShelfAlert;
  }

  Future<void> addCurrentBookToBookshelf() async {
    final location = resolveExitLocation();
    final title =
        location.chapterIndex >= 0 && location.chapterIndex < chapters.length
            ? chapters[location.chapterIndex].title
            : (book.durChapterTitle ?? '');
    await _sessionFacade.addCurrentBookToBookshelf(
      book: book,
      chapters: chapters,
      location: location,
      chapterTitle: title,
      progressStore: _progressStore,
      bookDao: bookDao,
      chapterDao: chapterDao,
      onCompleted: notifyListeners,
    );
  }

  String get displayChapterPercentLabel {
    return _displayCoordinator.formatReadProgress(
      chapterIndex: _displayPageChapterIndex,
      totalChapters: chapters.length,
      pageIndex: displayPageIndex,
      totalPages: displayPageCount,
    );
  }

  int get displayPageCount {
    final chapterIndex = _displayPageChapterIndex;
    if (chapterIndex < 0) return 0;
    final runtimeChapter = chapterAt(chapterIndex);
    if (runtimeChapter != null) return runtimeChapter.pageCount;
    return pagesForChapter(chapterIndex).length;
  }

  int get displayPageIndex {
    final chapterIndex = _displayPageChapterIndex;
    if (chapterIndex < 0) return 0;
    if (pageTurnMode == PageAnim.scroll) {
      final runtimeChapter = chapterAt(chapterIndex);
      final localPageIndex =
          runtimeChapter != null
              ? runtimeChapter.getPageIndexByCharIndex(
                visibleLocation.charOffset,
              )
              : ChapterPositionResolver.findPageIndexByCharOffset(
                pagesForChapter(chapterIndex),
                visibleLocation.charOffset,
              );
      return localPageIndex < 0 ? 0 : localPageIndex;
    }

    if (currentPageIndex >= 0 && currentPageIndex < slidePages.length) {
      return slidePages[currentPageIndex].index;
    }

    final runtimeChapter = chapterAt(chapterIndex);
    return runtimeChapter?.getPageIndexByCharIndex(
          sessionLocation.charOffset,
        ) ??
        ChapterPositionResolver.findPageIndexByCharOffset(
          pagesForChapter(chapterIndex),
          sessionLocation.charOffset,
        );
  }

  String get displayPageLabel {
    return _displayCoordinator.formatPageLabel(
      displayPageIndex,
      displayPageCount,
    );
  }

  int get _displayPageChapterIndex {
    if (pageTurnMode == PageAnim.scroll) {
      return visibleChapterIndex;
    }
    if (currentPageIndex >= 0 && currentPageIndex < slidePages.length) {
      return slidePages[currentPageIndex].chapterIndex;
    }
    return currentChapterIndex;
  }

  @override
  TTSService get tts => TTSService();

  double backgroundBlur = 0.0;
  void setBackgroundBlur(double v) {
    backgroundBlur = v;
    notifyListeners();
  }

  void setBackgroundImage(String? path) {
    currentTheme.backgroundImage = path;
    notifyListeners();
  }

  BookChapter? get currentChapter =>
      chapters.isNotEmpty && currentChapterIndex < chapters.length
          ? chapters[currentChapterIndex]
          : null;
  bool get isBookmarked => false;
  double get rate => TTSService().rate;
  bool isScrubbing = false;
  int scrubIndex = 0;

  void onScrubStart() {
    isScrubbing = true;
    scrubIndex = currentChapterIndex;
    notifyListeners();
  }

  void onScrubbing(dynamic value) {
    final targetIndex = _displayCoordinator.resolveScrubChapterIndex(
      value: value,
      totalChapters: chapters.length,
    );
    if (scrubIndex != targetIndex) {
      scrubIndex = targetIndex;
      notifyListeners();
    }
  }

  void onScrubEnd(dynamic value) {
    isScrubbing = false;
    final targetIndex = _displayCoordinator.resolveScrubChapterIndex(
      value: value,
      totalChapters: chapters.length,
    );
    unawaited(jumpToChapter(targetIndex));
    notifyListeners();
  }

  void jumpToPage(int index) {
    if (index >= 0 && index < slidePages.length) {
      onPageChanged(index);
    }
  }

  Future<void> toggleBookmark() async {
    addBookmark();
  }

  void addBookmark({String? content}) {
    final chapterIndex = _displayPageChapterIndex;
    final bookmark = _sessionFacade.buildBookmark(
      book: book,
      chapterIndex: chapterIndex,
      chapterTitle: displayChapterTitleAt(chapterIndex),
      chapterPos: _resolveCurrentCharOffset(),
      content: content,
    );
    _sessionFacade.saveBookmark(
      bookmarkDao: bookmarkDao,
      bookmark: bookmark,
      onCompleted: notifyListeners,
    );
  }

  void replaceChapterSource(int index, BookSource source, String content) {
    if (index >= 0 && index < chapters.length) {
      chapters[index].content = content;
      putChapterContent(index, content);
      clearChapterFailure(index);
      _chapterRuntimeCache.remove(index);
      if (index == currentChapterIndex) {
        unawaited(loadChapter(index, reason: ReaderCommandReason.system));
      }
      notifyListeners();
    }
  }

  Future<bool> autoChangeSourceForCurrentChapter() async {
    final result = await _sourceSwitch.autoChangeSourceForCurrentChapter(
      book: book,
      targetChapterIndex: currentChapterIndex,
      targetChapterTitle: currentChapterTitle,
      applyResolution: _applySourceSwitchResolution,
      notifyListeners: notifyListeners,
    );
    return result?.changed ?? false;
  }

  Future<void> changeBookSourceTo(SearchBook searchBook) async {
    final result = await _sourceSwitch.changeBookSource(
      book: book,
      searchBook: searchBook,
      targetChapterIndex: currentChapterIndex,
      targetChapterTitle: currentChapterTitle,
      applyResolution: _applySourceSwitchResolution,
      notifyListeners: notifyListeners,
    );
    if (result?.error != null) {
      Error.throwWithStackTrace(
        result!.error!,
        result.stackTrace ?? StackTrace.current,
      );
    }
  }

  Future<void> _applySourceSwitchResolution(
    SourceSwitchResolution resolution,
  ) async {
    await _sessionFacade.applySourceSwitchResolution(
      resolution: resolution,
      book: book,
      setSource: (value) => source = value,
      setChapters: (value) => chapters = value,
      clearChapterFailure: clearChapterFailure,
      refreshChapterDisplayTitles: refreshChapterDisplayTitles,
      resetContentLifecycle: resetContentLifecycle,
      putChapterContent: putChapterContent,
      bookDao: bookDao,
      chapterDao: chapterDao,
      updateSessionLocation: _updateSessionLocation,
      loadChapter: loadChapter,
      jumpToChapterCharOffset:
          ({
            required chapterIndex,
            required charOffset,
            required ReaderCommandReason reason,
          }) => jumpToChapterCharOffset(
            chapterIndex: chapterIndex,
            charOffset: charOffset,
            reason: reason,
          ),
      reason: ReaderCommandReason.system,
    );
  }

  Future<void> jumpToChapter(int index) async {
    if (index >= 0 && index < chapters.length) {
      _updateSessionLocation(
        ReaderLocation(chapterIndex: index, charOffset: 0),
      );
      await loadChapter(index, reason: ReaderCommandReason.user);
    }
  }

  Future<void> refreshReplaceRules() async {
    if (!hasContentManager || isDisposed) return;
    _prepareSettingsRepaginateAnchor();
    await refreshChapterDisplayTitles(notify: false);
    resetContentLifecycle(refreshPaginationConfig: true);
    await loadChapter(
      currentChapterIndex,
      reason: ReaderCommandReason.settingsRepaginate,
    );
  }

  void setChineseConvert(int val) {
    _prepareSettingsRepaginateAnchor();
    chineseConvert = val;
    _persistSetting('chinese_convert_v2', val);
    unawaited(refreshChapterDisplayTitles());
    resetContentLifecycle(refreshPaginationConfig: true);
    unawaited(
      loadChapter(
        currentChapterIndex,
        reason: ReaderCommandReason.settingsRepaginate,
      ),
    );
  }

  void setClickAction(int zone, int action) {
    clickActions[zone] = action;
    _updateSettingAndNotify('click_actions', clickActions.join(','));
  }

  List<TextPage> buildSlideRuntimePages() {
    return pageFactory.windowPages;
  }

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {
    var shouldRepaginate = true;
    var nextFromEnd = fromEnd;
    while (shouldRepaginate && !isDisposed) {
      _viewportLifecycle.beginRepaginateIteration();
      _sessionCoordinator.updatePhase(ReaderSessionPhase.repaginating);
      await super.doPaginate(fromEnd: nextFromEnd);
      refreshAllChapterRuntime();
      if (isDisposed) return;
      _sessionCoordinator.updatePhase(ReaderSessionPhase.ready);
      shouldRepaginate =
          _viewportLifecycle.hasPendingRepaginateForLatestViewport;
      nextFromEnd = false;
    }
  }

  void _guardTransientViewportChanges() {
    _viewportLifecycle.guardTransientViewportChanges();
  }

  int _resolveCurrentCharOffset() {
    return _sessionRuntime.resolveCurrentCharOffset(_currentSessionContext());
  }

  int _resolveVisibleCharOffset() {
    return _sessionRuntime.resolveVisibleCharOffset(
      visibleChapterIndex: visibleChapterIndex,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
    );
  }

  void _persistSetting(String key, dynamic value) {
    saveSetting(key, value);
  }

  void _updateSettingAndNotify(String key, dynamic value) {
    _persistSetting(key, value);
    notifyListeners();
  }

  /// 根據 charOffset / pageIndex 解析目標位置並觸發跳轉。
  bool _canMoveToNextSlidePage() {
    return currentPageIndex >= 0 && currentPageIndex < slidePages.length - 1;
  }

  bool _canMoveToPrevSlidePage() {
    return currentPageIndex > 0;
  }

  /// 此方法取代原本 [ReaderProgressMixin.jumpToPosition]。
  void jumpToPosition({
    int? chapterIndex,
    int? charOffset,
    int? pageIndex,
    ReaderCommandReason reason = ReaderCommandReason.system,
    bool isRestoringJump = false,
  }) {
    _sessionRuntime.jumpToPosition(
      isScrollMode: pageTurnMode == PageAnim.scroll,
      currentChapterIndex: currentChapterIndex,
      chapterIndex: chapterIndex,
      charOffset: charOffset,
      pageIndex: pageIndex,
      reason: reason,
    );
    notifyListeners();
  }

  /// 計算並持久化進度（slide 或 scroll mode）。
  /// 此方法取代原本 [ReaderProgressMixin.saveProgress]。
  void saveProgress(
    int chapterIndex,
    int pageIndex, {
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    _progressCoordinator.saveProgress(
      chapterIndex: chapterIndex,
      pageIndex: pageIndex,
      pageTurnMode: pageTurnMode,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
      slidePages: slidePages,
    );
  }

  void _persistSessionProgress() {
    if (isTtsActive) {
      saveTtsProgress();
      return;
    }
    if (pageTurnMode == PageAnim.scroll) {
      persistChapterCharOffsetProgress(
        chapterIndex: visibleChapterIndex,
        charOffset: _resolveVisibleCharOffset(),
      );
      return;
    }
    persistCurrentProgress(
      chapterIndex: currentChapterIndex,
      pageIndex: currentPageIndex,
    );
  }

  Future<void> persistExitProgress() async {
    await _sessionRuntime.persistExitProgress(_currentSessionContext());
    await _flushReadRecord();
  }

  void _updateSessionLocation(ReaderLocation location) {
    _sessionCoordinator.updateSessionLocation(location);
  }

  Future<void> _persistSessionLocation(ReaderLocation location) {
    return _sessionCoordinator.persistLocation(location);
  }

  void _prepareSettingsRepaginateAnchor() {
    final anchor = _sessionRuntime.prepareSettingsRepaginateAnchor(
      _currentSessionContext(),
    );
    currentChapterIndex = anchor.location.chapterIndex;
    visibleChapterIndex = anchor.location.chapterIndex;
    visibleChapterLocalOffset = anchor.localOffset;
  }

  ReaderLocation _resolveModeSwitchLocation() {
    return _sessionRuntime.resolveModeSwitchLocation(_currentSessionContext());
  }

  void _dispatchViewportCommand(ReaderViewportCommand command) {
    if (command is ReaderScrollViewportCommand) {
      requestJumpToChapter(
        chapterIndex: command.target.chapterIndex,
        localOffset: command.target.localOffset,
        alignment: command.target.alignment,
        reason: command.reason,
      );
      return;
    }
    if (command is ReaderSlideViewportCommand) {
      currentPageIndex = command.target.globalPageIndex;
      requestJumpToPage(command.target.globalPageIndex, reason: command.reason);
    }
  }

  ReaderSessionRuntimeContext _currentSessionContext() {
    return ReaderSessionRuntimeContext(
      isScrollMode: pageTurnMode == PageAnim.scroll,
      currentChapterIndex: currentChapterIndex,
      visibleChapterIndex: visibleChapterIndex,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
      currentPageIndex: currentPageIndex,
    );
  }

  Future<void> _flushReadRecord() async {
    if (!getIt.isRegistered<ReadRecordDao>()) return;
    final readRecordDao = getIt<ReadRecordDao>();
    final now = DateTime.now().millisecondsSinceEpoch;
    final seconds = ((now - _lastReadRecordStamp) / 1000).floor();
    _lastReadRecordStamp = now;
    if (seconds <= 0) return;
    try {
      await readRecordDao.incrementReadTime(
        bookName: book.name,
        seconds: seconds,
        lastRead: now,
      );
    } catch (error, stack) {
      AppLog.e('閱讀記錄寫入失敗: ${book.name}', error: error, stackTrace: stack);
    }
  }

  void _applyModeSwitchWithCachedContent(ReaderLocation targetLocation) {
    if (pageTurnMode == PageAnim.slide) {
      refreshSlidePagesForTesting(
        anchorChapterIndex: targetLocation.chapterIndex,
        charOffset: targetLocation.charOffset,
      );
    } else {
      bootstrapChapterWindow(targetLocation.chapterIndex);
    }
    jumpToChapterCharOffset(
      chapterIndex: targetLocation.chapterIndex,
      charOffset: targetLocation.charOffset,
      reason: ReaderCommandReason.settingsRepaginate,
    );
  }
}
