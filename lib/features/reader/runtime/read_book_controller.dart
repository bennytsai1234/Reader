import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/reader_perf_trace.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/provider/reader_auto_page_mixin.dart';
import 'package:legado_reader/features/reader/provider/content_callbacks.dart';
import 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_progress_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:legado_reader/features/reader/runtime/read_aloud_controller.dart';
import 'package:legado_reader/features/reader/runtime/reader_chapter_provider.dart';
import 'package:legado_reader/features/reader/runtime/reader_navigation_controller.dart';
import 'package:legado_reader/features/reader/runtime/reader_page_factory.dart';
import 'package:legado_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:legado_reader/features/reader/runtime/reader_restore_coordinator.dart';
import 'package:legado_reader/features/reader/runtime/reader_scroll_visibility_coordinator.dart';
import 'package:legado_reader/features/reader/runtime/reader_tts_follow_coordinator.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadBookController extends ReaderProviderBase
    with
        ReaderSettingsMixin,
        ReaderContentMixin,
        ReaderProgressMixin,
        ReaderAutoPageMixin,
        WidgetsBindingObserver {
  List<String> _chapterDisplayTitles = const [];
  final Map<int, ReaderChapter> _chapterRuntimeCache = {};
  final ReaderChapterProvider _chapterProvider = const ReaderChapterProvider();
  final ReaderNavigationController _navigation = ReaderNavigationController();
  final ReaderRestoreCoordinator _restore = ReaderRestoreCoordinator();
  final ReaderProgressStore _progressStore = ReaderProgressStore();
  final ReaderScrollVisibilityCoordinator _scrollVisibility =
      ReaderScrollVisibilityCoordinator();
  final ReaderTtsFollowCoordinator _ttsFollow =
      const ReaderTtsFollowCoordinator();
  late final ReadAloudController _readAloudController;
  final Completer<Size> _viewSizeCompleter = Completer<Size>();
  int _ttsMode = 0;
  bool _initialSessionPrimed = false;
  DateTime? _ignoreViewportChangesUntil;

  ReadBookController({
    required Book book,
    int chapterIndex = 0,
    int chapterPos = 0,
  }) : super(book) {
    currentChapterIndex = chapterIndex;
    visibleChapterIndex = chapterIndex;
    initialCharOffset = chapterPos;
    _readAloudController = _buildReadAloudController();
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
    chapterCharOffset: book.durChapterPos,
  );

  int get ttsStart => _readAloudController.ttsStart;
  int get ttsEnd => _readAloudController.ttsEnd;
  int get ttsChapterIndex => _readAloudController.ttsChapterIndex;
  bool get isTtsActive => _readAloudController.isActive;
  bool get stopAfterChapter => _readAloudController.stopAfterChapter;
  ReaderCommandReason? get activeCommandReason =>
      _navigation.activeCommandReason;
  ReaderProgressStore get progressStore => _progressStore;

  ReadAloudController _buildReadAloudController() {
    return ReadAloudController(
      tts: TTSService(),
      nextChapter: () => nextChapter(reason: ReaderCommandReason.tts),
      prevChapter:
          ({bool fromEnd = true}) =>
              prevChapter(fromEnd: fromEnd, reason: ReaderCommandReason.tts),
      nextPage: _handleTtsNextPage,
      prevPage: _handleTtsPrevPage,
      canMoveToNextPage: _canMoveToNextSlidePage,
      canMoveToPrevPage: _canMoveToPrevSlidePage,
      requestJumpToPage: _handleTtsPageJump,
      requestJumpToChapter: ({
        required int chapterIndex,
        required double alignment,
        required double localOffset,
      }) {
        _handleTtsChapterJump(
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
      onStateChanged: _notifyIfActive,
      updateMediaInfo: _updateTtsMediaInfo,
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
    if (!_navigation.beginCharJump(reason)) return;
    jumpToPosition(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
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
      _progressStore.persistCharOffset(
        write:
            (chapterIndex, title, charOffset) => bookDao.updateProgress(
              book.bookUrl,
              chapterIndex,
              title,
              charOffset,
            ),
        book: book,
        chapters: chapters,
        chapterIndex: chapterIndex,
        charOffset: charOffset,
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
    updateVisibleChapterPosition(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      alignment: alignment,
    );
    updateScrollPageIndex(chapterIndex, localOffset);

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
      updateScrollPreloadForVisibleChapter(preloadCenterChapter);
    }
  }

  ReaderTtsFollowTarget? evaluateTtsFollowTarget({
    required double viewportHeight,
  }) {
    final chapterIndex =
        ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex;
    final runtimeChapter = chapterAt(chapterIndex);
    final pages = pagesForChapter(chapterIndex);
    if (((runtimeChapter == null && pages.isEmpty) ||
            (runtimeChapter != null && runtimeChapter.isEmpty)) ||
        ttsStart < 0) {
      return null;
    }
    final targetLocalOffset =
        runtimeChapter != null
            ? runtimeChapter.resolveScrollAnchor(ttsStart).localOffset
            : ChapterPositionResolver.charOffsetToLocalOffset(pages, ttsStart);
    return _ttsFollow.evaluate(
      chapterIndex: chapterIndex,
      visibleChapterIndex: visibleChapterIndex,
      targetLocalOffset: targetLocalOffset,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
      viewportHeight: viewportHeight,
    );
  }

  ReaderCommandReason consumePendingSlideJumpReason() {
    return _navigation.consumePendingSlideJumpReason();
  }

  ReaderCommandReason consumePageChangeReason() {
    return _navigation.consumePageChangeReason();
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
    WidgetsBinding.instance.addObserver(this);
    lifecycle = ReaderLifecycle.loading;

    // Wire typed callbacks (replaces `this as dynamic` casts)
    contentCallbacks = ContentCallbacks(
      refreshChapterRuntime: refreshChapterRuntime,
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
      // Progress-related callbacks (used by ReaderProgressMixin)
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      progressStore: _progressStore,
      shouldPersistVisiblePosition: shouldPersistVisiblePosition,
      persistCurrentProgress:
          ({required chapterIndex, int? pageIndex, required reason}) =>
              persistCurrentProgress(
                chapterIndex: chapterIndex,
                pageIndex: pageIndex,
                reason: reason as ReaderCommandReason,
              ),
    );

    // ── Phase 1: PREPARE (parallel data loading, no UI updates) ──
    await Future.wait([
      loadSettings(),
      _loadReadAloudPreferences(),
      _loadChapters(),
      _loadSource(),
    ]);
    if (isDisposed) return;

    initContentManager();
    onSettingsChangedRepaginate = () {
      updatePaginationConfig();
      doPaginate();
    };

    // ── Phase 2: RENDER (wait for viewSize, single UI update) ──
    final size = viewSize ?? await _viewSizeCompleter.future;
    if (isDisposed) return;

    batchUpdate(() {
      viewSize = size;
      updatePaginationConfig();
    });

    // Load initial chapter content
    if (!_initialSessionPrimed) {
      _initialSessionPrimed = true;
      final initialPreloadRadius =
          pageTurnMode == PageAnim.scroll && book.origin == 'local' ? 1 : 0;
      await loadChapterWithPreloadRadius(
        currentChapterIndex,
        preloadRadius:
            pageTurnMode == PageAnim.scroll ? initialPreloadRadius : 1,
      );
      if (isDisposed) return;
    }

    // Apply restore position + transition to ready in ONE update
    batchUpdate(() {
      bootstrapChapterWindow(currentChapterIndex);
      if (initialCharOffset > 0) {
        jumpToChapterCharOffset(
          chapterIndex: currentChapterIndex,
          charOffset: initialCharOffset,
          reason: ReaderCommandReason.restore,
          isRestoringJump: false,
        );
      }
      lifecycle = ReaderLifecycle.ready;
    });

    // ── Phase 3: WARMUP (background, non-blocking) ──
    _startHeartbeat();
    _readAloudController.attach();
    scheduleDeferredWindowWarmup(currentChapterIndex);
    if (pageTurnMode == PageAnim.scroll) {
      updateScrollPreloadForVisibleChapter(visibleChapterIndex);
      triggerSilentPreload();
    }
  }

  Timer? _heartbeatTimer;
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      batteryLevelNotifier.value = (batteryLevelNotifier.value - 1).clamp(
        0,
        100,
      );
    });
  }

  Future<void> _loadChapters() async {
    chapters = await chapterDao.getChapters(book.bookUrl);
    if (isDisposed) return;
    await _refreshChapterDisplayTitles(notify: false);
    if (!isDisposed) notifyListeners();
  }

  Future<void> _loadSource() async {
    source = await sourceDao.getByUrl(book.origin);
  }

  Future<void> _loadReadAloudPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _ttsMode = prefs.getInt('reader_tts_mode') ?? 0;
  }

  double textPadding = 16.0;
  int get batteryLevel => batteryLevelNotifier.value;
  double get autoPageProgress => autoPageProgressNotifier.value;

  void setViewSize(Size size) {
    // During init: just complete the completer, don't paginate
    if (!_viewSizeCompleter.isCompleted) {
      _viewSizeCompleter.complete(size);
      return;
    }

    // Post-init: handle viewport changes (orientation, keyboard, etc.)
    if (viewSize == null) {
      viewSize = size;
      if (!hasContentManager) return;
      updatePaginationConfig();
      if (contentManager.getCachedContent(currentChapterIndex) != null &&
          (chapterPagesCache[currentChapterIndex]?.isEmpty ?? true)) {
        unawaited(doPaginate());
      }
      return;
    }

    if (_shouldIgnoreViewSizeChange(size)) return;

    viewSize = size;
    if (hasContentManager &&
        contentManager.getCachedContent(currentChapterIndex) != null) {
      unawaited(doPaginate());
    }
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
  }

  void handleSlidePageChanged(int index) {
    if (slidePages.isEmpty) return;
    onPageChanged(index);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistSessionProgress();
    scrollSaveTimer?.cancel();
    _heartbeatTimer?.cancel();
    disposeAutoPageCoordinator();
    _readAloudController.dispose();
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
      }
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
  String get displayChapterPercentLabel {
    if (chapters.isEmpty) return '0.0%';
    final chapterIndex = _displayPageChapterIndex.clamp(0, chapters.length - 1);
    return '${(chapterIndex / chapters.length * 100).toStringAsFixed(1)}%';
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
              ? runtimeChapter.pageIndexAtLocalOffset(visibleChapterLocalOffset)
              : ChapterPositionResolver.pageIndexAtLocalOffset(
                pagesForChapter(chapterIndex),
                visibleChapterLocalOffset,
              );
      return localPageIndex < 0 ? 0 : localPageIndex;
    }

    if (currentPageIndex >= 0 && currentPageIndex < slidePages.length) {
      return slidePages[currentPageIndex].index;
    }

    final runtimeChapter = chapterAt(chapterIndex);
    return runtimeChapter?.getPageIndexByCharIndex(book.durChapterPos) ??
        ChapterPositionResolver.findPageIndexByCharOffset(
          pagesForChapter(chapterIndex),
          book.durChapterPos,
        );
  }

  String get displayPageLabel {
    final count = displayPageCount;
    if (count <= 0) return '0/0';
    final page = (displayPageIndex + 1).clamp(1, count);
    return '$page/$count';
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

  String displayChapterTitleAt(int index) {
    if (index < 0 || index >= chapters.length) return '';
    if (index < _chapterDisplayTitles.length &&
        _chapterDisplayTitles[index].isNotEmpty) {
      return _chapterDisplayTitles[index];
    }
    return chapters[index].title;
  }

  Future<void> _refreshChapterDisplayTitles({bool notify = true}) async {
    if (chapters.isEmpty) {
      _chapterDisplayTitles = const [];
      if (notify && !isDisposed) {
        refreshAllChapterRuntime();
        notifyListeners();
      }
      return;
    }

    final titleRules =
        (await replaceDao.getEnabled())
            .where((rule) => rule.isEnabled && rule.scopeTitle)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final titles = <String>[];
    for (final chapter in chapters) {
      titles.add(
        await chapter.getDisplayTitle(
          replaceRules: titleRules,
          chineseConvertType: chineseConvert,
        ),
      );
    }
    if (isDisposed) return;
    _chapterDisplayTitles = titles;
    refreshAllChapterRuntime();
    if (notify && !isDisposed) {
      notifyListeners();
    }
  }

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
  int get ttsMode => _ttsMode;
  double get rate => TTSService().rate;
  bool isScrubbing = false;
  int scrubIndex = 0;

  void onScrubStart() {
    isScrubbing = true;
    scrubIndex = currentChapterIndex;
    notifyListeners();
  }

  void onScrubbing(dynamic value) {
    final targetIndex = _resolveScrubChapterIndex(value);
    if (scrubIndex != targetIndex) {
      scrubIndex = targetIndex;
      notifyListeners();
    }
  }

  void onScrubEnd(dynamic value) {
    isScrubbing = false;
    final targetIndex = _resolveScrubChapterIndex(value);
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
    final bookmark = _buildBookmark(content: content);
    bookmarkDao.upsert(bookmark);
    notifyListeners();
  }

  void replaceChapterSource(int index, BookSource source, String content) {
    if (index >= 0 && index < chapters.length) {
      chapters[index].content = content;
      contentManager.putContent(index, content);
      chapterPagesCache.remove(index);
      _chapterRuntimeCache.remove(index);
      if (index == currentChapterIndex) {
        unawaited(loadChapter(index, reason: ReaderCommandReason.system));
      }
      notifyListeners();
    }
  }

  Future<void> jumpToChapter(int index) async {
    if (index >= 0 && index < chapters.length) {
      book.durChapterPos = 0;
      await loadChapter(index, reason: ReaderCommandReason.user);
    }
  }

  void setChineseConvert(int val) {
    chineseConvert = val;
    _persistSetting('chinese_convert_v2', val);
    unawaited(_refreshChapterDisplayTitles());
    disposeContentManager();
    initContentManager();
    updatePaginationConfig();
    unawaited(
      loadChapter(
        currentChapterIndex,
        reason: ReaderCommandReason.settingsRepaginate,
      ),
    );
  }

  void setTtsMode(int val) {
    _ttsMode = val;
    _updateSettingAndNotify('tts_mode', val);
  }

  void setStopAfterChapter(bool val) {
    _readAloudController.setStopAfterChapter(val);
  }

  void setTtsRate(double val) {
    _updateTtsPreference(
      key: 'tts_rate',
      value: val,
      apply: () => TTSService().setRate(val),
    );
  }

  void setTtsPitch(double val) {
    _updateTtsPreference(
      key: 'tts_pitch',
      value: val,
      apply: () => TTSService().setPitch(val),
    );
  }

  void setTtsLanguage(String lang) {
    _updateTtsPreference(
      key: 'tts_language',
      value: lang,
      apply: () => TTSService().setLanguage(lang),
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
    await super.doPaginate(fromEnd: fromEnd);
    refreshAllChapterRuntime();
  }

  bool _shouldIgnoreViewSizeChange(Size size) {
    final currentSize = viewSize;
    if (currentSize == null) return false;
    final dw = (currentSize.width - size.width).abs();
    final dh = (currentSize.height - size.height).abs();
    if (dw < 12 && dh < 24) return true;
    if (dw < 1 && dh < 96) return true;
    final guardUntil = _ignoreViewportChangesUntil;
    if (guardUntil != null && DateTime.now().isBefore(guardUntil)) {
      return dw < 64 && dh < 180;
    }
    return false;
  }

  void _guardTransientViewportChanges() {
    _ignoreViewportChangesUntil = DateTime.now().add(
      const Duration(milliseconds: 500),
    );
  }

  void toggleTts() {
    _runWithAutoPageStopped(_readAloudController.toggle);
  }

  void startTtsFromLine(int lineIndex) {
    _runWithAutoPageStopped(() {
      _readAloudController.startFromLine(lineIndex);
    });
  }

  void stopTts() {
    _readAloudController.stop();
    _navigation.clear(ReaderCommandReason.tts);
  }

  Future<void> nextPageOrChapter() {
    return _readAloudController.nextPageOrChapter();
  }

  Future<void> prevPageOrChapter() {
    return _readAloudController.prevPageOrChapter();
  }

  void saveTtsProgress() {
    unawaited(
      _readAloudController.saveProgress(
        persist: (chapterIndex, charOffset) {
          persistChapterCharOffsetProgress(
            chapterIndex: chapterIndex,
            charOffset: charOffset,
          );
        },
      ),
    );
  }

  Future<void> _handleTtsNextPage() async {
    if (_canMoveToNextSlidePage()) {
      nextPage(reason: ReaderCommandReason.tts);
    }
  }

  Future<void> _handleTtsPrevPage() async {
    if (_canMoveToPrevSlidePage()) {
      prevPage(reason: ReaderCommandReason.tts);
    }
  }

  bool _canMoveToNextSlidePage() {
    return currentPageIndex >= 0 && currentPageIndex < slidePages.length - 1;
  }

  bool _canMoveToPrevSlidePage() {
    return currentPageIndex > 0;
  }

  void _handleTtsPageJump(int pageIndex) {
    final chapterIndex =
        ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex;
    final globalIndex = pageFactory.globalPageIndexFor(
      chapterIndex: chapterIndex,
      localPageIndex: pageIndex,
    );
    if (globalIndex != null && globalIndex >= 0) {
      jumpToSlidePage(globalIndex, reason: ReaderCommandReason.tts);
    }
  }

  void _handleTtsChapterJump({
    required int chapterIndex,
    required double alignment,
    required double localOffset,
  }) {
    jumpToChapterLocalOffset(
      chapterIndex: chapterIndex,
      alignment: alignment,
      localOffset: localOffset,
      reason: ReaderCommandReason.tts,
    );
  }

  int _resolveCurrentCharOffset() {
    if (pageTurnMode == PageAnim.scroll) {
      return _resolveVisibleCharOffset();
    }
    if (currentPageIndex >= 0 && currentPageIndex < slidePages.length) {
      final page = slidePages[currentPageIndex];
      final chapter = chapterAt(page.chapterIndex);
      if (chapter != null) {
        return chapter.charOffsetForPageIndex(page.index);
      }
      final chapterPages = pagesForChapter(page.chapterIndex);
      return ChapterPositionResolver.getCharOffsetForPage(
        chapterPages,
        page.index,
      );
    }
    return book.durChapterPos;
  }

  int _resolveVisibleCharOffset() {
    final chapter = chapterAt(visibleChapterIndex);
    if (chapter != null) {
      return chapter.charOffsetFromLocalOffset(visibleChapterLocalOffset);
    }
    final pages = pagesForChapter(visibleChapterIndex);
    return ChapterPositionResolver.localOffsetToCharOffset(
      pages,
      visibleChapterLocalOffset,
    );
  }

  void _notifyIfActive() {
    if (!isDisposed) notifyListeners();
  }

  void _updateTtsMediaInfo(String title, String author) {
    TTSService().updateMediaInfo(
      title: title.isEmpty ? book.name : title,
      author: author.isEmpty ? book.author : author,
    );
  }

  int _resolveScrubChapterIndex(dynamic value) {
    final rawIndex =
        value is double
            ? (value * (chapters.length - 1)).round()
            : value as int;
    if (chapters.isEmpty) return 0;
    return rawIndex.clamp(0, chapters.length - 1);
  }

  Bookmark _buildBookmark({String? content}) {
    final chapterIndex = _displayPageChapterIndex;
    return Bookmark(
      time: DateTime.now().millisecondsSinceEpoch,
      bookName: book.name,
      bookAuthor: book.author,
      bookUrl: book.bookUrl,
      chapterIndex: chapterIndex,
      chapterName: displayChapterTitleAt(chapterIndex),
      chapterPos: _resolveCurrentCharOffset(),
      bookText: content ?? '',
    );
  }

  void _runWithAutoPageStopped(VoidCallback action) {
    if (isAutoPaging) stopAutoPage();
    action();
  }

  void _persistSetting(String key, dynamic value) {
    saveSetting(key, value);
  }

  void _updateSettingAndNotify(String key, dynamic value) {
    _persistSetting(key, value);
    notifyListeners();
  }

  void _updateTtsPreference({
    required String key,
    required dynamic value,
    required VoidCallback apply,
  }) {
    apply();
    _updateSettingAndNotify(key, value);
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
}
