import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/config/app_config.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/database/dao/read_record_dao.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/reader_perf_trace.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/reader_auto_page_mixin.dart';
import 'package:inkpage_reader/features/reader/provider/reader_auxiliary_flow_mixin.dart';
import 'package:inkpage_reader/features/reader/provider/reader_chapter_navigation_mixin.dart';
import 'package:inkpage_reader/features/reader/provider/content_callbacks.dart';
import 'package:inkpage_reader/features/reader/provider/reader_content_facade_mixin.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/provider/reader_settings_mixin.dart';
import 'package:inkpage_reader/features/reader/provider/reader_shell_interaction_mixin.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/read_aloud_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_chapter_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_chapter_fingerprint.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_bootstrap_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_navigation_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_factory.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_restore_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_layout.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_visibility_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_display_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_command.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_exit_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_facade.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine_factory.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_source.dart';
import 'package:inkpage_reader/features/reader/runtime/switchable_tts_engine.dart';
import 'package:inkpage_reader/features/reader/runtime/system_tts_engine.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_lifecycle_runtime.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';

import 'package:inkpage_reader/features/reader/provider/reader_tts_mixin.dart';

import 'package:inkpage_reader/features/reader/provider/reader_battery_mixin.dart';

class ReadBookController extends ReaderProviderBase
    with
        ReaderSettingsMixin,
        ReaderContentFacadeMixin,
        ReaderAuxiliaryFlowMixin,
        ReaderChapterNavigationMixin,
        ReaderAutoPageMixin,
        ReaderTtsMixin,
        ReaderBatteryMixin,
        ReaderShellInteractionMixin,
        WidgetsBindingObserver
    implements ReaderExitFlowDelegate {
  final Map<int, ReaderChapter> _chapterRuntimeCache = {};
  final Map<int, double> _chapterContentHeightCache = {};
  final Map<int, double> _chapterPlaceholderHeightCache = {};
  final ReaderChapterProvider _chapterProvider = const ReaderChapterProvider();
  final ReaderNavigationController _navigation = ReaderNavigationController();
  final ReaderRestoreCoordinator _restore = ReaderRestoreCoordinator();
  final ReaderProgressStore _progressStore = ReaderProgressStore();
  final ReaderScrollVisibilityCoordinator _scrollVisibility =
      ReaderScrollVisibilityCoordinator();
  final ReaderDisplayCoordinator _displayCoordinator =
      const ReaderDisplayCoordinator();
  late final SwitchableReaderTtsEngine _ttsEngineHost;
  late final ReaderTtsEngineFactory _ttsEngineFactory;
  late final ReaderProgressCoordinator _progressCoordinator;
  late final ReaderSessionState _sessionState;
  late final ReaderSessionCoordinator _sessionCoordinator;
  late final ReaderRuntimeController _runtimeController;
  final ReaderSessionFacade _sessionFacade = const ReaderSessionFacade();
  late final ReaderSessionRuntime _sessionRuntime;
  final ReaderViewportLifecycleRuntime _viewportLifecycle =
      ReaderViewportLifecycleRuntime();
  late final ReaderBootstrapRuntime _bootstrapRuntime;
  Future<void>? _activeFlushNow;
  int _lastReadRecordStamp = DateTime.now().millisecondsSinceEpoch;
  bool _lastVisibleScrollAnchorConfirmed = true;
  int? _pendingVisiblePlaceholderReanchorChapterIndex;
  late final ReaderAnchor _initialAnchor;

  /// 初始章節字元偏移（由呼叫方傳入，用於還原閱讀位置）
  int initialCharOffset = 0;

  ReadBookController({
    required Book book,
    ReaderLocation? initialLocation,
    ReaderAnchor? initialAnchor,
    List<BookChapter> initialChapters = const [],
  }) : super(book) {
    _initialAnchor =
        (initialAnchor ??
                ReaderAnchor.location(
                  initialLocation ??
                      ReaderLocation(
                        chapterIndex: book.durChapterIndex,
                        charOffset: book.durChapterPos,
                      ),
                ))
            .normalized();
    final initialReaderLocation =
        (initialLocation ?? _initialAnchor.location).normalized();
    currentChapterIndex = initialReaderLocation.chapterIndex;
    visibleChapterIndex = initialReaderLocation.chapterIndex;
    initialCharOffset = initialReaderLocation.charOffset;
    if (initialChapters.isNotEmpty) {
      chapters = List<BookChapter>.from(initialChapters);
    }
    _sessionState = ReaderSessionState(initialLocation: initialReaderLocation);
    _sessionCoordinator = ReaderSessionCoordinator(
      state: _sessionState,
      store: _progressStore,
      book: () => book,
      chapters: () => chapters,
      writeProgress:
          (chapterIndex, title, charOffset, readerAnchorJson) =>
              bookDao.updateProgress(
                book.bookUrl,
                chapterIndex,
                title,
                charOffset,
                readerAnchorJson: readerAnchorJson,
              ),
    );
    _runtimeController = ReaderRuntimeController(
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      slidePages: () => slidePages,
    );
    _ttsEngineHost = SwitchableReaderTtsEngine(
      delegate: SystemTtsEngine(tts: TTSService()),
    );
    _ttsEngineFactory = ReaderTtsEngineFactory(ttsService: TTSService());
    _sessionRuntime = ReaderSessionRuntime(
      runtimeController: _runtimeController,
      committedLocation: () => committedLocation,
      updateCommittedLocation: _sessionCoordinator.updateCommittedLocation,
      updateVisibleLocation: _sessionCoordinator.updateVisibleLocation,
      persistLocation: _persistSessionLocation,
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
      updateCommittedLocation: _updateCommittedLocation,
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

  double? cachedChapterContentHeight(int chapterIndex) {
    final height = _chapterContentHeightCache[chapterIndex];
    if (height == null || height <= 0) return null;
    return height;
  }

  double? _placeholderChapterContentHeight(int chapterIndex) {
    final height = _chapterPlaceholderHeightCache[chapterIndex];
    if (height == null || height <= 0) return null;
    return height;
  }

  void recordEstimatedPlaceholderChapterContentHeight(
    int chapterIndex, {
    required double contentHeight,
  }) {
    if (chapterIndex < 0 || chapterIndex >= chapters.length) return;
    if (contentHeight <= 0) return;
    final runtimeChapter = chapterAt(chapterIndex);
    if (runtimeChapter != null && runtimeChapter.chapterHeight > 0) return;
    final cachedPages = chapterPagesCache[chapterIndex];
    if (cachedPages != null && cachedPages.isNotEmpty) return;
    _chapterPlaceholderHeightCache[chapterIndex] = contentHeight;
  }

  @override
  double estimatedChapterContentHeight(
    int chapterIndex, {
    double fallback = 0.0,
  }) {
    final runtimeChapter = chapterAt(chapterIndex);
    if (runtimeChapter != null && runtimeChapter.chapterHeight > 0) {
      _chapterContentHeightCache[chapterIndex] = runtimeChapter.chapterHeight;
      return runtimeChapter.chapterHeight;
    }
    final pages = chapterPagesCache[chapterIndex];
    if (pages != null && pages.isNotEmpty) {
      final contentHeight = ChapterPositionResolver.chapterHeight(pages);
      if (contentHeight > 0) {
        _chapterContentHeightCache[chapterIndex] = contentHeight;
        return contentHeight;
      }
    }
    return cachedChapterContentHeight(chapterIndex) ??
        _placeholderChapterContentHeight(chapterIndex) ??
        fallback;
  }

  double estimatedChapterItemExtent(
    int chapterIndex, {
    double fallbackContent = 0.0,
  }) {
    final runtimeChapter = chapterAt(chapterIndex);
    if (runtimeChapter != null && runtimeChapter.metrics.itemExtent > 0) {
      return runtimeChapter.metrics.itemExtent;
    }
    return ReaderScrollLayout.chapterItemExtent(
      contentHeight: estimatedChapterContentHeight(
        chapterIndex,
        fallback: fallbackContent,
      ),
      hasSeparator: chapterIndex >= 0 && chapterIndex < chapters.length - 1,
      fontSize: fontSize,
      lineHeight: lineHeight,
    );
  }

  void clearChapterContentHeightCache([int? chapterIndex]) {
    if (chapterIndex == null) {
      _chapterContentHeightCache.clear();
      _chapterPlaceholderHeightCache.clear();
      return;
    }
    _chapterContentHeightCache.remove(chapterIndex);
    _chapterPlaceholderHeightCache.remove(chapterIndex);
  }

  ReaderPageFactory get pageFactory => ReaderPageFactory(
    prevChapter: prevChapterRuntime,
    currentChapter: curChapterRuntime,
    nextChapter: nextChapterRuntime,
    chapterCharOffset: committedLocation.charOffset,
  );

  ReaderCommandReason? get activeCommandReason =>
      _navigation.activeCommandReason;
  int? get activeNavigationToken => _navigation.activeNavigationToken;
  @override
  ReaderProgressStore get progressStore => _progressStore;
  ReaderLocation get committedLocation => _sessionCoordinator.committedLocation;
  ReaderLocation get visibleLocation => _sessionCoordinator.visibleLocation;
  ReaderLocation get durableLocation => _sessionCoordinator.durableLocation;
  bool get visibleConfirmed => _sessionCoordinator.visibleConfirmed;
  @override
  int get currentNavigationGeneration => _sessionCoordinator.generation;
  ReaderSessionPhase get sessionPhase => _sessionCoordinator.phase;
  bool get hasActiveNavigation => _navigation.hasActiveNavigation;
  bool get hasPendingVisiblePlaceholderReanchor =>
      _pendingVisiblePlaceholderReanchorChapterIndex != null;
  String? get currentChapterFailureMessage =>
      chapterFailureMessage(currentChapterIndex);

  @override
  Set<int> retainedChapterIndexes({int? focusChapterIndex}) {
    if (chapters.isEmpty) return const <int>{};
    final retained = <int>{};
    final shouldKeepNeighborhoodTargets = pageTurnMode == PageAnim.scroll;

    void keepNeighborhood(int chapterIndex) {
      if (chapterIndex < 0 || chapterIndex >= chapters.length) return;
      for (final candidate in <int>[
        chapterIndex - 1,
        chapterIndex,
        chapterIndex + 1,
      ]) {
        if (candidate >= 0 && candidate < chapters.length) {
          retained.add(candidate);
        }
      }
    }

    void keepChapter(int? chapterIndex) {
      if (chapterIndex == null ||
          chapterIndex < 0 ||
          chapterIndex >= chapters.length) {
        return;
      }
      retained.add(chapterIndex);
    }

    void keepTarget(int? chapterIndex) {
      if (chapterIndex == null ||
          chapterIndex < 0 ||
          chapterIndex >= chapters.length) {
        return;
      }
      if (shouldKeepNeighborhoodTargets) {
        keepNeighborhood(chapterIndex);
        return;
      }
      keepChapter(chapterIndex);
    }

    keepNeighborhood(currentChapterIndex);
    keepNeighborhood(visibleChapterIndex);
    keepTarget(focusChapterIndex);
    keepTarget(_navigation.activeNavigationTargetLocation?.chapterIndex);
    keepTarget(pendingScrollRestoreChapterIndex);
    for (final chapterIndex in readAloudController.retainedChapterIndexes) {
      keepChapter(chapterIndex);
    }
    return retained;
  }

  @override
  int resolveScrubChapterIndexForNavigation(dynamic value) {
    return _displayCoordinator.resolveScrubChapterIndex(
      value: value,
      totalChapters: chapters.length,
    );
  }

  @override
  Future<void> performChapterNavigation({
    required int targetIndex,
    required ReaderCommandReason reason,
    bool fromEnd = false,
  }) async {
    final transaction = _dispatchNavigationCommand(
      pageTurnMode == PageAnim.scroll
          ? ReaderNavigationCommand.chapter(
            reason: reason,
            targetLocation: ReaderLocation(
              chapterIndex: targetIndex,
              charOffset: 0,
            ),
            completionPolicy:
                ReaderNavigationCompletionPolicy.visibleLocationMatch,
          )
          : ReaderNavigationCommand.slide(
            reason: reason,
            targetLocation: ReaderLocation(
              chapterIndex: targetIndex,
              charOffset: 0,
            ),
          ),
      bumpGeneration: true,
      clearVisibleConfirmation: true,
    );
    if (transaction == null) return;
    await loadChapter(
      targetIndex,
      fromEnd: fromEnd,
      reason: reason,
      navigationToken: transaction.token,
    );
  }

  @override
  void guardTransientViewportChangesForShell() {
    _guardTransientViewportChanges();
  }

  @override
  void updateCurrentThemeBackgroundImage(String? path) {
    currentTheme.backgroundImage = path;
  }

  @override
  int get displayChapterIndexForAuxiliary => _displayPageChapterIndex;

  @override
  int resolveCurrentCharOffsetForAuxiliary() {
    return _resolveCurrentCharOffset();
  }

  @override
  void clearChapterRuntimeCacheEntry(int index) {
    _chapterRuntimeCache.remove(index);
    clearChapterContentHeightCache(index);
  }

  @override
  void updateCommittedLocationForAuxiliary(ReaderLocation location) {
    _updateCommittedLocation(location);
  }

  @override
  void onScrollChapterReadyApplied(int chapterIndex, {required bool hasPages}) {
    if (!hasPages || pageTurnMode != PageAnim.scroll) return;
    final targetLocation = _navigation.activeNavigationTargetLocation;
    final reason = activeCommandReason;
    if (targetLocation != null &&
        reason != null &&
        targetLocation.chapterIndex == chapterIndex) {
      final localOffset =
          reason == ReaderCommandReason.restore
              ? _resolveScrollRestoreLocalOffset(
                ReaderAnchor.location(targetLocation),
              )
              : _runtimeController.localOffsetForLocation(targetLocation);
      if (localOffset == null) return;
      if (reason == ReaderCommandReason.restore) {
        _navigation.retargetActiveNavigation(
          reason: reason,
          targetLocation: targetLocation,
          targetScrollLocalOffset: localOffset,
          completionPolicy:
              ReaderNavigationCompletionPolicy.visibleLocationMatch,
        );
      }
      requestJumpToChapter(
        chapterIndex: chapterIndex,
        alignment: 0.0,
        localOffset: localOffset,
        reason: reason,
      );
      if (!isDisposed) {
        notifyListeners();
      }
      return;
    }
    if (_navigation.hasActiveNavigation) return;
    if (_shouldQueueVisiblePlaceholderReanchor(chapterIndex)) {
      _pendingVisiblePlaceholderReanchorChapterIndex = chapterIndex;
      return;
    }
    _pendingVisiblePlaceholderReanchorChapterIndex = null;
    _applyVisiblePlaceholderReanchor(chapterIndex);
  }

  ReadAloudController _buildReadAloudController() {
    return ReadAloudController(
      ttsEngine: _ttsEngineHost,
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

  @override
  Future<void> loadTtsSettings() async {
    await super.loadTtsSettings();
    await _configureTtsEngine();
  }

  @override
  Future<void> reconfigureTtsEngine() => _configureTtsEngine();

  Future<void> _configureTtsEngine() async {
    final engine = await _ttsEngineFactory.create(
      overrideSourceKey: _resolveTtsSourceOverrideKey() ?? ttsSourceKey,
    );
    await _ttsEngineHost.setDelegate(engine);
  }

  String? _resolveTtsSourceOverrideKey() {
    final overrideKey = book.readConfig?.ttsEngine?.trim();
    if (overrideKey == null || overrideKey.isEmpty) return null;
    final normalized = ReaderTtsSourcePreference.normalize(overrideKey);
    return normalized == ReaderTtsSourcePreference.systemKey &&
            overrideKey != ReaderTtsSourcePreference.systemKey
        ? null
        : normalized;
  }

  void jumpToSlidePage(
    int pageIndex, {
    ReaderCommandReason reason = ReaderCommandReason.system,
    bool reuseActiveNavigation = false,
  }) {
    final shouldReuse =
        reuseActiveNavigation &&
        _navigation.hasActiveNavigation &&
        activeCommandReason == reason;
    if (!shouldReuse &&
        _dispatchNavigationCommand(
              ReaderNavigationCommand.slide(reason: reason),
            ) ==
            null) {
      return;
    }
    requestJumpToPage(pageIndex, reason: reason);
  }

  void jumpToChapterLocalOffset({
    required int chapterIndex,
    required double localOffset,
    double alignment = 0.0,
    ReaderCommandReason reason = ReaderCommandReason.system,
    bool reuseActiveNavigation = false,
  }) {
    final targetLocation = _runtimeController.resolveVisibleScrollLocation(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
    );
    final shouldReuse =
        reuseActiveNavigation &&
        _navigation.hasActiveNavigation &&
        activeCommandReason == reason;
    if (shouldReuse) {
      _navigation.retargetActiveNavigation(
        reason: reason,
        targetLocation: targetLocation,
        targetScrollLocalOffset: localOffset,
        completionPolicy: ReaderNavigationCompletionPolicy.visibleLocationMatch,
      );
      _sessionCoordinator.updateVisibleConfirmed(false);
    } else if (_dispatchNavigationCommand(
          ReaderNavigationCommand.chapter(
            reason: reason,
            targetLocation: targetLocation,
            targetScrollLocalOffset: localOffset,
            completionPolicy:
                ReaderNavigationCompletionPolicy.visibleLocationMatch,
          ),
          clearVisibleConfirmation: true,
        ) ==
        null) {
      return;
    }
    requestJumpToChapter(
      chapterIndex: chapterIndex,
      alignment: alignment,
      localOffset: localOffset,
      reason: reason,
    );
  }

  ReaderScrollViewportCommand buildScrollViewportCommand({
    required int chapterIndex,
    required double localOffset,
    double alignment = 0.0,
    ReaderCommandReason reason = ReaderCommandReason.system,
    ReaderAnchor? anchor,
  }) {
    final targetLocation = _runtimeController.resolveVisibleScrollLocation(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
    );
    final resolvedAnchor = (anchor ?? ReaderAnchor.location(targetLocation))
        .normalized()
        .copyWith(
          location: targetLocation,
          pageIndexSnapshot: _runtimeController.pageIndexForLocation(
            targetLocation,
          ),
          localOffsetSnapshot: localOffset,
        );
    return ReaderScrollViewportCommand(
      anchor: resolvedAnchor,
      reason: reason,
      target: ReaderScrollTarget(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        alignment: alignment,
      ),
    );
  }

  @override
  void jumpToChapterCharOffset({
    required int chapterIndex,
    required int charOffset,
    ReaderCommandReason reason = ReaderCommandReason.system,
    bool isRestoringJump = false,
    bool reuseActiveNavigation = false,
  }) {
    final targetLocation =
        ReaderLocation(
          chapterIndex: chapterIndex,
          charOffset: charOffset,
        ).normalized();
    final targetScrollLocalOffset =
        pageTurnMode == PageAnim.scroll
            ? (reason == ReaderCommandReason.restore
                ? _resolveScrollRestoreLocalOffset(
                  ReaderAnchor.location(targetLocation),
                )
                : _runtimeController.localOffsetForLocation(targetLocation))
            : null;
    final shouldReuse =
        reuseActiveNavigation &&
        _navigation.hasActiveNavigation &&
        activeCommandReason == reason;
    if (shouldReuse) {
      _navigation.retargetActiveNavigation(
        reason: reason,
        targetLocation: targetLocation,
        targetScrollLocalOffset: targetScrollLocalOffset,
        completionPolicy:
            pageTurnMode == PageAnim.scroll
                ? ReaderNavigationCompletionPolicy.visibleLocationMatch
                : ReaderNavigationCompletionPolicy.explicit,
      );
      if (pageTurnMode == PageAnim.scroll) {
        _sessionCoordinator.updateVisibleConfirmed(false);
      }
    } else if (_dispatchNavigationCommand(
          pageTurnMode == PageAnim.scroll
              ? ReaderNavigationCommand.chapter(
                reason: reason,
                targetLocation: targetLocation,
                targetScrollLocalOffset: targetScrollLocalOffset,
                completionPolicy:
                    ReaderNavigationCompletionPolicy.visibleLocationMatch,
              )
              : ReaderNavigationCommand.slide(
                reason: reason,
                targetLocation: targetLocation,
              ),
          clearVisibleConfirmation: pageTurnMode == PageAnim.scroll,
        ) ==
        null) {
      return;
    }
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
    bool isAnchorConfirmed = true,
    double anchorPadding = 0.0,
  }) {
    _lastVisibleScrollAnchorConfirmed = isAnchorConfirmed;
    _sessionCoordinator.updateVisibleConfirmed(isAnchorConfirmed);
    if (isAnchorConfirmed ||
        (_pendingVisiblePlaceholderReanchorChapterIndex != null &&
            _pendingVisiblePlaceholderReanchorChapterIndex != chapterIndex)) {
      _pendingVisiblePlaceholderReanchorChapterIndex = null;
    }
    final previousVisibleChapterIndex = visibleChapterIndex;
    final previousPageIndex = currentPageIndex;
    _progressCoordinator.updateVisibleChapterPosition(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      alignment: alignment,
      pageTurnMode: pageTurnMode,
      isLoading: isLoading,
      isAnchorConfirmed: isAnchorConfirmed,
      currentPageIndex: currentPageIndex,
      updateVisible: (ci, lo, al) {
        visibleChapterIndex = ci;
        visibleChapterLocalOffset = lo;
        visibleChapterAlignment = al;
      },
      updateCurrentChapterIndex: (ci) => currentChapterIndex = ci,
    );
    if (isAnchorConfirmed) {
      _progressCoordinator.updateScrollPageIndex(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        setCurrentPageIndex: (i) => currentPageIndex = i,
        setVisibleChapterIndex: (i) => visibleChapterIndex = i,
        setCurrentChapterIndex: (i) => currentChapterIndex = i,
      );
    }

    final update = _scrollVisibility.evaluate(
      visibleChapterIndexes: visibleChapterIndexes,
      focusChapterIndex: chapterIndex,
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

    final completedNavigation =
        isAnchorConfirmed
            ? _navigation.reconcileVisibleScrollTarget(
              chapterIndex: chapterIndex,
              localOffset: localOffset,
              anchorPadding: anchorPadding,
              chapterContentHeight: estimatedChapterContentHeight(chapterIndex),
              visibleLocation: visibleLocation,
            )
            : null;
    if (completedNavigation?.restoreToken case final restoreToken?) {
      _completeInitialScrollRestore(restoreToken);
    }

    if ((previousVisibleChapterIndex != visibleChapterIndex ||
            previousPageIndex != currentPageIndex ||
            completedNavigation != null) &&
        !isDisposed) {
      notifyListeners();
    }
  }

  @override
  void setScrollInteractionActive(bool active) {
    super.setScrollInteractionActive(active);
    if (active) return;
    final pendingChapterIndex = _pendingVisiblePlaceholderReanchorChapterIndex;
    if (pendingChapterIndex == null) return;
    _pendingVisiblePlaceholderReanchorChapterIndex = null;
    _applyVisiblePlaceholderReanchor(pendingChapterIndex);
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

  void completeNavigation(int token, ReaderCommandReason reason) {
    final completed = _navigation.completeNavigation(token, reason: reason);
    if (completed?.restoreToken case final restoreToken?) {
      _completeInitialScrollRestore(restoreToken);
    }
  }

  void abortNavigation(int token, ReaderCommandReason reason) {
    final aborted = _navigation.abortNavigation(token, reason: reason);
    if (aborted?.restoreToken case final restoreToken?) {
      _cancelInitialScrollRestore(restoreToken);
    }
  }

  bool shouldPersistForReason(ReaderCommandReason reason) {
    return _navigation.shouldPersistForReason(reason);
  }

  int registerPendingScrollRestore({
    int? chapterIndex,
    int charOffset = 0,
    double? localOffset,
    ReaderAnchor? anchor,
  }) {
    final resolvedAnchor = anchor?.normalized();
    final resolvedLocalOffset =
        localOffset ?? resolvedAnchor?.localOffsetSnapshot;
    return _restore.registerPendingScrollRestore(
      anchor: resolvedAnchor,
      chapterIndex: chapterIndex,
      charOffset: charOffset,
      localOffset: resolvedLocalOffset,
    );
  }

  int get pendingScrollRestoreToken => _restore.pendingScrollRestoreToken;
  ReaderAnchor? get pendingScrollRestoreAnchor =>
      _restore.pendingScrollRestoreAnchor;
  int? get pendingScrollRestoreChapterIndex =>
      _restore.pendingScrollRestoreChapterIndex;
  double? get pendingScrollRestoreLocalOffset =>
      _restore.pendingScrollRestoreLocalOffset;
  bool get hasPendingScrollRestore => _restore.hasPendingScrollRestore;
  bool get hasQueuedScrollRestore => _restore.hasQueuedScrollRestore;

  bool matchesPendingScrollRestore(int token) =>
      _restore.matchesPendingScrollRestore(token);

  ({int token, ReaderAnchor anchor, int chapterIndex, double localOffset})?
  dispatchPendingScrollRestore() {
    return _restore.dispatchPendingScrollRestore(
      resolveLocalOffset: _resolveScrollRestoreLocalOffset,
    );
  }

  void deferPendingScrollRestore(int token) {
    _restore.deferPendingScrollRestore(token);
  }

  void cancelPendingScrollRestoreFromUserScroll() {
    if (!hasPendingScrollRestore &&
        sessionPhase != ReaderSessionPhase.restoring &&
        activeCommandReason != ReaderCommandReason.restore) {
      return;
    }
    _navigation.clear(ReaderCommandReason.restore);
    _cancelInitialScrollRestore();
    if (!isDisposed) {
      notifyListeners();
    }
  }

  void markInitialRestoreCompleted() {
    if (sessionPhase != ReaderSessionPhase.restoring) return;
    _sessionCoordinator.updatePhase(ReaderSessionPhase.ready);
    notifyListeners();
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
    final chapterHeight = ChapterPositionResolver.chapterHeight(pages);
    if (chapterHeight > 0) {
      _chapterContentHeightCache[index] = chapterHeight;
    }
    _chapterRuntimeCache[index] = _chapterProvider.buildFromPages(
      chapter: chapters[index],
      chapterIndex: index,
      title: displayChapterTitleAt(index),
      pages: pages,
      separatorExtent:
          index < chapters.length - 1
              ? ReaderScrollLayout.chapterSeparatorExtent(
                fontSize: fontSize,
                lineHeight: lineHeight,
              )
              : 0.0,
    );
  }

  void refreshAllChapterRuntime() {
    _chapterRuntimeCache.clear();
    for (final entry in chapterPagesCache.entries) {
      refreshChapterRuntime(entry.key);
    }
  }

  @override
  void initContentManager() {
    clearChapterContentHeightCache();
    super.initContentManager();
  }

  @override
  void resetContentLifecycle({bool refreshPaginationConfig = false}) {
    clearChapterContentHeightCache();
    super.resetContentLifecycle(
      refreshPaginationConfig: refreshPaginationConfig,
    );
  }

  @override
  void disposeContentManager() {
    clearChapterContentHeightCache();
    super.disposeContentManager();
  }

  Future<void> _init() async {
    await _bootstrapRuntime.bootstrap(
      currentViewSize: viewSize,
      pageTurnMode: () => pageTurnMode,
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
        if (pageTurnMode == PageAnim.scroll) {
          _restoreInitialScrollLocation(
            chapterIndex: chapterIndex,
            charOffset: charOffset,
          );
          return true;
        }
        _restoreInitialSlideLocation(
          chapterIndex: chapterIndex,
          charOffset: charOffset,
        );
        return false;
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
          (pageIndex, {required reason, bool reuseActiveNavigation = false}) =>
              jumpToSlidePage(
                pageIndex,
                reason: reason as ReaderCommandReason,
                reuseActiveNavigation: reuseActiveNavigation,
              ),
      jumpToChapterLocalOffset:
          ({
            required chapterIndex,
            required localOffset,
            required alignment,
            required reason,
            bool reuseActiveNavigation = false,
          }) => jumpToChapterLocalOffset(
            chapterIndex: chapterIndex,
            localOffset: localOffset,
            alignment: alignment,
            reason: reason as ReaderCommandReason,
            reuseActiveNavigation: reuseActiveNavigation,
          ),
      jumpToChapterCharOffset:
          ({
            required chapterIndex,
            required charOffset,
            required reason,
            bool isRestoringJump = false,
            bool reuseActiveNavigation = false,
          }) => jumpToChapterCharOffset(
            chapterIndex: chapterIndex,
            charOffset: charOffset,
            reason: reason as ReaderCommandReason,
            isRestoringJump: isRestoringJump,
            reuseActiveNavigation: reuseActiveNavigation,
          ),
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      progressStore: _progressStore,
      shouldPersistVisiblePosition: shouldPersistVisiblePosition,
      currentCommittedLocation: () => committedLocation,
      updateCommittedLocation: _updateCommittedLocation,
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
      abortNavigation:
          ({required token, required reason}) =>
              abortNavigation(token, reason as ReaderCommandReason),
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
    unawaited(readerPrefsRepository.savePageTurnMode(v));
    _updateCommittedLocation(targetLocation);
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
    _sessionCoordinator.bumpGeneration();
    _sessionCoordinator.updateVisibleConfirmed(false);
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
  void nextPage({ReaderCommandReason reason = ReaderCommandReason.user}) {
    if (pageTurnMode != PageAnim.scroll) {
      super.nextPage(reason: reason);
      return;
    }
    unawaited(_stepScrollPage(forward: true, reason: reason));
  }

  @override
  void prevPage({ReaderCommandReason reason = ReaderCommandReason.user}) {
    if (pageTurnMode != PageAnim.scroll) {
      super.prevPage(reason: reason);
      return;
    }
    unawaited(_stepScrollPage(forward: false, reason: reason));
  }

  @override
  void dispose() {
    final pendingFlush = flushNow();
    WidgetsBinding.instance.removeObserver(this);
    _sessionCoordinator.updatePhase(ReaderSessionPhase.disposed);
    _progressCoordinator.dispose();
    stopBatteryHeartbeat();
    disposeAutoPageCoordinator();
    readAloudController.dispose();
    disposeContentManager();
    unawaited(pendingFlush);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (!isDisposed) {
        unawaited(flushNow());
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

  ReadingTheme get currentTheme {
    if (AppTheme.readingThemes.isEmpty) {
      return ReadingTheme(
        name: '預設',
        backgroundColor: const Color(0xFFFFFFFF),
        textColor: const Color(0xFF1A1A1A),
      );
    }
    return AppTheme.readingThemes[themeIndex.clamp(
      0,
      AppTheme.readingThemes.length - 1,
    )];
  }

  String get currentChapterTitle => displayChapterTitleAt(currentChapterIndex);
  String get currentChapterUrl =>
      chapters.isNotEmpty ? chapters[currentChapterIndex].url : '';

  @override
  ReaderLocation resolveExitLocation() {
    return _sessionRuntime.resolveExitLocation(_currentSessionContext());
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
          committedLocation.charOffset,
        ) ??
        ChapterPositionResolver.findPageIndexByCharOffset(
          pagesForChapter(chapterIndex),
          committedLocation.charOffset,
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

  BookChapter? get currentChapter =>
      chapters.isNotEmpty && currentChapterIndex < chapters.length
          ? chapters[currentChapterIndex]
          : null;
  bool get isBookmarked => false;
  double get rate => TTSService().rate;
  void jumpToPage(int index) {
    if (index >= 0 && index < slidePages.length) {
      onPageChanged(index);
    }
  }

  Future<void> refreshReplaceRules() async {
    if (!hasContentManager || isDisposed) return;
    _prepareSettingsRepaginateAnchor();
    await refreshChapterDisplayTitles(notify: false);
    resetContentLifecycle(refreshPaginationConfig: true);
    _sessionCoordinator.bumpGeneration();
    _sessionCoordinator.updateVisibleConfirmed(false);
    await loadChapter(
      currentChapterIndex,
      reason: ReaderCommandReason.settingsRepaginate,
    );
  }

  void setChineseConvert(int val) {
    _prepareSettingsRepaginateAnchor();
    chineseConvert = val;
    unawaited(readerPrefsRepository.saveChineseConvert(val));
    unawaited(refreshChapterDisplayTitles());
    resetContentLifecycle(refreshPaginationConfig: true);
    _sessionCoordinator.bumpGeneration();
    _sessionCoordinator.updateVisibleConfirmed(false);
    unawaited(
      loadChapter(
        currentChapterIndex,
        reason: ReaderCommandReason.settingsRepaginate,
      ),
    );
  }

  void setClickAction(int zone, int action) {
    clickActions[zone] = action;
    unawaited(readerPrefsRepository.saveClickActions(clickActions));
    notifyListeners();
  }

  List<TextPage> buildSlideRuntimePages() {
    return pageFactory.windowPages;
  }

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {
    clearChapterContentHeightCache();
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

  Future<void> flushNow() {
    final inFlight = _activeFlushNow;
    if (inFlight != null) return inFlight;
    late final Future<void> trackedFlush;
    trackedFlush = _flushNowInternal().whenComplete(() {
      if (identical(_activeFlushNow, trackedFlush)) {
        _activeFlushNow = null;
      }
    });
    _activeFlushNow = trackedFlush;
    return trackedFlush;
  }

  Future<void> _flushNowInternal() async {
    if (await _flushTtsProgress()) {
      await _flushReadRecord();
      return;
    }
    final flushedLocation = await _progressCoordinator.flushPendingProgress();
    if (flushedLocation == null) {
      final exitLocation = _sessionRuntime.resolveExitLocation(
        _currentSessionContext(),
      );
      if (exitLocation != durableLocation) {
        await _persistSessionLocation(exitLocation);
      }
    }
    await _flushReadRecord();
  }

  @override
  Future<void> persistExitProgress() async {
    await flushNow();
  }

  void _updateCommittedLocation(ReaderLocation location) {
    _sessionCoordinator.updateCommittedLocation(location);
  }

  Future<void> _persistSessionLocation(ReaderLocation location) {
    return _sessionCoordinator.persistAnchor(_buildPersistedAnchor(location));
  }

  ReaderAnchor _buildPersistedAnchor(
    ReaderLocation location, {
    ReaderAnchor? sourceAnchor,
    int? globalPageIndex,
  }) {
    final normalized = location.normalized();
    final baseAnchor = (sourceAnchor ?? ReaderAnchor.location(normalized))
        .normalized()
        .copyWith(
          location: normalized,
          contentHash: _contentHashForChapter(normalized.chapterIndex),
          layoutSignature: _currentLayoutSignature(),
        );
    final resolvedAnchor =
        _runtimeController
            .resolveViewportCommand(
              isScrollMode: pageTurnMode == PageAnim.scroll,
              anchor: baseAnchor.toPresentationAnchor(),
              sourceAnchor: baseAnchor,
              globalPageIndex: globalPageIndex,
            )
            .anchor;
    if (pageTurnMode == PageAnim.scroll) {
      return resolvedAnchor;
    }
    return resolvedAnchor.copyWith(
      localOffsetSnapshot: _runtimeController.localOffsetForLocation(
        normalized,
      ),
    );
  }

  String _currentLayoutSignature() {
    String fmt(double value) => value.toStringAsFixed(2);

    final size = viewSize;
    final width = size == null ? 'na' : size.width.toStringAsFixed(1);
    final height = size == null ? 'na' : size.height.toStringAsFixed(1);
    final mode = pageTurnMode == PageAnim.scroll ? 'scroll' : 'slide';
    return '$mode:$width:$height:${fmt(fontSize)}:${fmt(lineHeight)}:${fmt(paragraphSpacing)}:${fmt(letterSpacing)}:$textIndent:${textFullJustify ? 1 : 0}:${fmt(contentTopInset)}:${fmt(contentBottomInset)}';
  }

  String? _contentHashForChapter(int chapterIndex) {
    final runtimeChapter = chapterAt(chapterIndex);
    final pages = runtimeChapter?.pages ?? pagesForChapter(chapterIndex);
    return ReaderChapterFingerprint.structureDigest(
      chapterIndex: chapterIndex,
      pages: pages,
    );
  }

  bool _matchesPreciseRestoreAnchor(
    ReaderAnchor anchor,
    ReaderLocation location, {
    required bool requiresPageIndex,
    required bool requiresLocalOffset,
  }) {
    if (anchor.location.chapterIndex != location.chapterIndex) return false;
    if (requiresPageIndex && anchor.pageIndexSnapshot == null) return false;
    if (requiresLocalOffset && anchor.localOffsetSnapshot == null) return false;

    final layoutSignature = anchor.layoutSignature;
    if (layoutSignature == null ||
        layoutSignature != _currentLayoutSignature()) {
      return false;
    }

    final storedContentHash = anchor.contentHash;
    final currentContentHash = _contentHashForChapter(location.chapterIndex);
    if (storedContentHash == null || currentContentHash == null) return false;
    return storedContentHash == currentContentHash;
  }

  ReaderAnchor _buildInitialScrollRestoreAnchor(
    ReaderLocation location,
    ReaderAnchor baseAnchor,
  ) {
    final anchor =
        !_matchesPreciseRestoreAnchor(
              baseAnchor,
              location,
              requiresPageIndex: false,
              requiresLocalOffset: true,
            )
            ? _buildPersistedAnchor(location, sourceAnchor: baseAnchor)
            : baseAnchor.normalized().copyWith(
              location: location,
              contentHash: _contentHashForChapter(location.chapterIndex),
              layoutSignature: _currentLayoutSignature(),
              pageIndexSnapshot:
                  baseAnchor.pageIndexSnapshot ??
                  _runtimeController.pageIndexForLocation(location),
              localOffsetSnapshot: baseAnchor.localOffsetSnapshot,
            );
    return _dropUnresolvedZeroScrollSnapshot(anchor, location);
  }

  ReaderAnchor _dropUnresolvedZeroScrollSnapshot(
    ReaderAnchor anchor,
    ReaderLocation location,
  ) {
    if (location.charOffset <= 0) return anchor;
    if (_hasResolvedScrollLayoutForChapter(location.chapterIndex)) {
      return anchor;
    }
    final snapshot = anchor.localOffsetSnapshot;
    if (snapshot == null || snapshot > 0) return anchor;
    return anchor.withLocalOffsetSnapshot(null);
  }

  bool _hasResolvedScrollLayoutForChapter(int chapterIndex) {
    final runtimeChapter = chapterAt(chapterIndex);
    if (runtimeChapter != null && !runtimeChapter.isEmpty) return true;
    return pagesForChapter(chapterIndex).isNotEmpty;
  }

  double? _resolveScrollRestoreLocalOffset(ReaderAnchor anchor) {
    final location = anchor.location.normalized();
    final hasResolvedLayout = _hasResolvedScrollLayoutForChapter(
      location.chapterIndex,
    );
    final snapshot = anchor.localOffsetSnapshot;
    if (!hasResolvedLayout && location.charOffset > 0) {
      return snapshot != null && snapshot > 0 ? snapshot : null;
    }
    return _runtimeController.localOffsetForLocation(location);
  }

  ReaderAnchor _buildInitialSlideRestoreAnchor(
    ReaderLocation location,
    ReaderAnchor baseAnchor,
  ) {
    final globalPageIndex =
        _matchesPreciseRestoreAnchor(
              baseAnchor,
              location,
              requiresPageIndex: true,
              requiresLocalOffset: false,
            )
            ? _runtimeController.matchingSlidePageIndexSnapshot(
              location: location,
              pageIndexSnapshot: baseAnchor.pageIndexSnapshot,
            )
            : null;
    return _buildPersistedAnchor(
      location,
      sourceAnchor: baseAnchor,
      globalPageIndex: globalPageIndex,
    );
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

  Future<void> _stepScrollPage({
    required bool forward,
    required ReaderCommandReason reason,
  }) async {
    if (chapters.isEmpty) return;

    var target = _resolveScrollViewportStepTarget(forward: forward);
    if (target == null) {
      final neighborIndex =
          forward ? visibleChapterIndex + 1 : visibleChapterIndex - 1;
      if (neighborIndex >= 0 && neighborIndex < chapters.length) {
        await ensureChapterCached(
          neighborIndex,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        );
        if (isDisposed) return;
        target = _resolveScrollViewportStepTarget(forward: forward);
      }
    }

    if (target == null) {
      if (forward) {
        await nextChapter(reason: reason);
      } else {
        await prevChapter(fromEnd: false, reason: reason);
      }
      return;
    }

    final effectiveReason =
        reason == ReaderCommandReason.user
            ? ReaderCommandReason.userScroll
            : reason;
    jumpToChapterLocalOffset(
      chapterIndex: target.chapterIndex,
      localOffset: target.localOffset,
      alignment: 0.0,
      reason: effectiveReason,
    );
    notifyListeners();
  }

  ({int chapterIndex, double localOffset})? _resolveScrollViewportStepTarget({
    required bool forward,
  }) {
    final step = _scrollViewportStepSize();
    if (step <= 0 || chapters.isEmpty) return null;

    var targetChapterIndex = visibleChapterIndex.clamp(0, chapters.length - 1);
    var targetLocalOffset = visibleChapterLocalOffset;
    var remaining = step;

    while (remaining > 0.5) {
      final chapterHeight = _chapterHeightFor(targetChapterIndex);
      if (chapterHeight <= 0) return null;

      if (forward) {
        final available = (chapterHeight - targetLocalOffset).clamp(
          0.0,
          double.infinity,
        );
        if (remaining <= available ||
            targetChapterIndex >= chapters.length - 1) {
          return (
            chapterIndex: targetChapterIndex,
            localOffset: (targetLocalOffset + remaining).clamp(
              0.0,
              chapterHeight,
            ),
          );
        }
        remaining -= available;
        if (targetChapterIndex < chapters.length - 1) {
          remaining -= _chapterSeparatorExtent(targetChapterIndex);
          if (remaining <= 0.5) {
            return (chapterIndex: targetChapterIndex + 1, localOffset: 0.0);
          }
        }
        targetChapterIndex += 1;
        targetLocalOffset = 0.0;
        continue;
      }

      if (remaining <= targetLocalOffset || targetChapterIndex <= 0) {
        return (
          chapterIndex: targetChapterIndex,
          localOffset: (targetLocalOffset - remaining).clamp(
            0.0,
            chapterHeight,
          ),
        );
      }

      remaining -= targetLocalOffset;
      if (targetChapterIndex > 0) {
        remaining -= _chapterSeparatorExtent(targetChapterIndex - 1);
        if (remaining <= 0.5) {
          return (
            chapterIndex: targetChapterIndex - 1,
            localOffset: _chapterHeightFor(targetChapterIndex - 1),
          );
        }
      }
      targetChapterIndex -= 1;
      targetLocalOffset = _chapterHeightFor(targetChapterIndex);
      if (targetLocalOffset <= 0) return null;
    }

    return (chapterIndex: targetChapterIndex, localOffset: targetLocalOffset);
  }

  double _scrollViewportStepSize() {
    final size = viewSize;
    if (size == null) return 0.0;
    final viewportHeight =
        (size.height - scrollViewportTopInset - scrollViewportBottomInset)
            .clamp(1.0, double.infinity)
            .toDouble();
    return viewportHeight * 0.88;
  }

  double _chapterHeightFor(int chapterIndex) {
    final runtimeChapter = chapterAt(chapterIndex);
    if (runtimeChapter != null) {
      return runtimeChapter.metrics.contentHeight;
    }
    return estimatedChapterContentHeight(chapterIndex);
  }

  double _chapterSeparatorExtent(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= chapters.length - 1) return 0.0;
    final runtimeChapter = chapterAt(chapterIndex);
    if (runtimeChapter != null && runtimeChapter.metrics.separatorExtent > 0) {
      return runtimeChapter.metrics.separatorExtent;
    }
    return ReaderScrollLayout.chapterSeparatorExtent(
      fontSize: fontSize,
      lineHeight: lineHeight,
    );
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

  Future<bool> _flushTtsProgress() async {
    if (!isTtsActive) return false;
    ReaderLocation? savedLocation;
    await readAloudController.saveProgress(
      persist: (chapterIndex, charOffset) {
        savedLocation =
            ReaderLocation(
              chapterIndex: chapterIndex,
              charOffset: charOffset,
            ).normalized();
      },
    );
    final location = savedLocation;
    if (location == null) return false;
    await _persistSessionLocation(location);
    return true;
  }

  void _restoreInitialScrollLocation({
    required int chapterIndex,
    required int charOffset,
  }) {
    final location =
        ReaderLocation(
          chapterIndex: chapterIndex,
          charOffset: charOffset,
        ).normalized();
    final baseAnchor =
        _initialAnchor.location == location
            ? _initialAnchor
            : ReaderAnchor.location(location);
    final restoreAnchor = _buildInitialScrollRestoreAnchor(
      location,
      baseAnchor,
    );
    final localOffset = _resolveScrollRestoreLocalOffset(restoreAnchor);
    final transaction = _dispatchNavigationCommand(
      ReaderNavigationCommand.chapter(
        reason: ReaderCommandReason.restore,
        targetLocation: location,
        targetScrollLocalOffset: localOffset,
        completionPolicy: ReaderNavigationCompletionPolicy.visibleLocationMatch,
      ),
      clearVisibleConfirmation: true,
    );
    if (transaction == null) {
      return;
    }
    final restoreToken = registerPendingScrollRestore(anchor: restoreAnchor);
    _navigation.attachRestoreTokenToActiveNavigation(
      restoreToken,
      reason: ReaderCommandReason.restore,
    );
    currentChapterIndex = location.chapterIndex;
    visibleChapterIndex = location.chapterIndex;
    visibleChapterLocalOffset =
        localOffset ?? restoreAnchor.localOffsetSnapshot ?? 0.0;
    visibleChapterAlignment = 0.0;
    _sessionCoordinator.updateVisibleConfirmed(false);
    _updateCommittedLocation(location);
    _sessionCoordinator.updateVisibleLocation(location);
    notifyListeners();
  }

  void _restoreInitialSlideLocation({
    required int chapterIndex,
    required int charOffset,
  }) {
    final location =
        ReaderLocation(
          chapterIndex: chapterIndex,
          charOffset: charOffset,
        ).normalized();
    final baseAnchor =
        _initialAnchor.location == location
            ? _initialAnchor
            : ReaderAnchor.location(location);
    final restoreAnchor = _buildInitialSlideRestoreAnchor(location, baseAnchor);
    final targetPageIndex =
        restoreAnchor.pageIndexSnapshot?.clamp(
          0,
          slidePages.isEmpty ? 0 : slidePages.length - 1,
        ) ??
        0;

    currentChapterIndex = location.chapterIndex;
    visibleChapterIndex = location.chapterIndex;
    visibleChapterLocalOffset =
        restoreAnchor.localOffsetSnapshot ??
        _runtimeController.localOffsetForLocation(location);
    visibleChapterAlignment = 0.0;
    currentPageIndex = targetPageIndex;
    _updateCommittedLocation(location);
    _sessionCoordinator.updateVisibleLocation(location);
    requestControllerReset(targetPageIndex);
    notifyListeners();
  }

  void _completeInitialScrollRestore(int token) {
    if (!_restore.completePendingScrollRestore(token)) return;
    markInitialRestoreCompleted();
  }

  void _cancelInitialScrollRestore([int? token]) {
    if (token != null && !_restore.matchesPendingScrollRestore(token)) return;
    if (!hasPendingScrollRestore &&
        sessionPhase != ReaderSessionPhase.restoring) {
      return;
    }
    _restore.clear();
    if (sessionPhase == ReaderSessionPhase.restoring) {
      _sessionCoordinator.updatePhase(ReaderSessionPhase.ready);
      notifyListeners();
    }
  }

  bool _shouldQueueVisiblePlaceholderReanchor(int chapterIndex) {
    return isScrollInteractionActive &&
        !_lastVisibleScrollAnchorConfirmed &&
        visibleChapterIndex == chapterIndex &&
        _placeholderChapterContentHeight(chapterIndex) != null;
  }

  void _applyVisiblePlaceholderReanchor(int chapterIndex) {
    if (_navigation.hasActiveNavigation) return;
    if (_lastVisibleScrollAnchorConfirmed) return;
    if (pageTurnMode != PageAnim.scroll) return;
    if (visibleChapterIndex != chapterIndex) return;

    final estimatedContentHeight = _placeholderChapterContentHeight(
      chapterIndex,
    );
    final actualContentHeight = estimatedChapterContentHeight(chapterIndex);
    if (estimatedContentHeight == null ||
        estimatedContentHeight <= 0 ||
        actualContentHeight <= 0) {
      return;
    }

    final normalizedVisibleOffset =
        visibleChapterLocalOffset.clamp(0.0, estimatedContentHeight).toDouble();
    final progress =
        (normalizedVisibleOffset / estimatedContentHeight)
            .clamp(0.0, 1.0)
            .toDouble();
    final correctedLocalOffset =
        (actualContentHeight * progress)
            .clamp(0.0, actualContentHeight)
            .toDouble();
    if ((correctedLocalOffset - visibleChapterLocalOffset).abs() < 12.0) {
      return;
    }

    jumpToChapterLocalOffset(
      chapterIndex: chapterIndex,
      localOffset: correctedLocalOffset,
      alignment: 0.0,
      reason: ReaderCommandReason.system,
    );
    if (!isDisposed) {
      notifyListeners();
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

  ReaderNavigationTransaction? _dispatchNavigationCommand(
    ReaderNavigationCommand command, {
    bool bumpGeneration = false,
    bool clearVisibleConfirmation = false,
  }) {
    final transaction = _navigation.dispatch(command);
    if (transaction == null) return null;
    if (command.reason != ReaderCommandReason.restore &&
        sessionPhase == ReaderSessionPhase.restoring) {
      _cancelInitialScrollRestore();
    }
    if (bumpGeneration) {
      _sessionCoordinator.bumpGeneration();
    }
    if (clearVisibleConfirmation) {
      _sessionCoordinator.updateVisibleConfirmed(false);
    }
    return transaction;
  }
}
