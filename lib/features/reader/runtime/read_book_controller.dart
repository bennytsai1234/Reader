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
  final ReaderTtsFollowCoordinator _ttsFollow = const ReaderTtsFollowCoordinator();
  late final ReadAloudController _readAloudController;
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
    _readAloudController = ReadAloudController(
      tts: TTSService(),
      nextChapter: () => nextChapter(reason: ReaderCommandReason.tts),
      prevChapter: ({
        bool fromEnd = true,
      }) => prevChapter(
        fromEnd: fromEnd,
        reason: ReaderCommandReason.tts,
      ),
      nextPage: () async {
        if (currentPageIndex < slidePages.length - 1) {
          nextPage(reason: ReaderCommandReason.tts);
        }
      },
      prevPage: () async {
        if (currentPageIndex > 0) {
          prevPage(reason: ReaderCommandReason.tts);
        }
      },
      canMoveToNextPage: () => currentPageIndex >= 0 && currentPageIndex < slidePages.length - 1,
      canMoveToPrevPage: () => currentPageIndex > 0,
      requestJumpToPage: (pageIndex) {
        final chapterIndex =
            ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex;
        final globalIndex = pageFactory.globalPageIndexFor(
          chapterIndex: chapterIndex,
          localPageIndex: pageIndex,
        );
        if (globalIndex != null && globalIndex >= 0) {
          jumpToSlidePage(globalIndex, reason: ReaderCommandReason.tts);
        }
      },
      requestJumpToChapter: ({
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
      },
      chapterOf: chapterAt,
      currentChapterIndex: () => currentChapterIndex,
      visibleChapterIndex: () => visibleChapterIndex,
      currentCharOffset: () {
        if (pageTurnMode == PageAnim.scroll) {
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
      },
      visibleCharOffset: () {
        final chapter = chapterAt(visibleChapterIndex);
        if (chapter != null) {
          return chapter.charOffsetFromLocalOffset(visibleChapterLocalOffset);
        }
        final pages = pagesForChapter(visibleChapterIndex);
        return ChapterPositionResolver.localOffsetToCharOffset(
          pages,
          visibleChapterLocalOffset,
        );
      },
      isScrollMode: () => pageTurnMode == PageAnim.scroll,
      onStateChanged: () {
        if (!isDisposed) notifyListeners();
      },
      updateMediaInfo: (title, author) {
        TTSService().updateMediaInfo(
          title: title.isEmpty ? book.name : title,
          author: author.isEmpty ? book.author : author,
        );
      },
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
        chapterCharOffset: book.durChapterPos,
      );

  int get ttsStart => _readAloudController.ttsStart;
  int get ttsEnd => _readAloudController.ttsEnd;
  int get ttsChapterIndex => _readAloudController.ttsChapterIndex;
  bool get isTtsActive => _readAloudController.isActive;
  bool get stopAfterChapter => _readAloudController.stopAfterChapter;
  ReaderCommandReason? get activeCommandReason => _navigation.activeCommandReason;
  ReaderProgressStore get progressStore => _progressStore;

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
        write: (chapterIndex, title, charOffset) => bookDao.updateProgress(
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
      isLoadingChapter: (targetChapter) => loadingChapters.contains(targetChapter),
    );

    for (final visibleChapter in update.chaptersToEnsure) {
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
    final targetLocalOffset = runtimeChapter != null
        ? runtimeChapter.resolveScrollAnchor(ttsStart).localOffset
        : ChapterPositionResolver.charOffsetToLocalOffset(
            pages,
            ttsStart,
          );
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

  void completeRestoreTransition() {
    if (!isDisposed && lifecycle == ReaderLifecycle.restoring) {
      ReaderPerfTrace.mark(
        'restore ready chapter=$visibleChapterIndex offset=${visibleChapterLocalOffset.toStringAsFixed(1)}',
      );
      _restore.clear();
      _navigation.clear(ReaderCommandReason.restore);
      lifecycle = ReaderLifecycle.ready;
      notifyListeners();
    }
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

  ({
    int? chapterIndex,
    double? localOffset,
    bool advanceChapter,
  })? evaluateScrollAutoPageStep(double dtSeconds) {
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
    if (pages == null || pages.isEmpty || index < 0 || index >= chapters.length) {
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

    lifecycle = ReaderLifecycle.restoring;
    pendingRestorePos = initialCharOffset;
    if (viewSize != null) {
      await _primeInitialWindow();
    }
    _startHeartbeat();
    _readAloudController.attach();
  }

  Timer? _heartbeatTimer;
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      batteryLevelNotifier.value =
          (batteryLevelNotifier.value - 1).clamp(0, 100);
    });
  }

  Future<void> _loadChapters() async {
    chapters = await chapterDao.getChapters(book.bookUrl);
    if (isDisposed) return;
    _chapterDisplayTitles = chapters.map((chapter) => chapter.title).toList();
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
    if (viewSize == null) {
      viewSize = size;
      if (!hasContentManager) return;
      updatePaginationConfig();
      if (!_initialSessionPrimed) {
        unawaited(_primeInitialWindow());
        return;
      }
      if (contentManager.getCachedContent(currentChapterIndex) != null &&
          (chapterPagesCache[currentChapterIndex]?.isEmpty ?? true)) {
        unawaited(doPaginate().then((_) => applyPendingRestore()));
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
    if (!isRestoring && shouldPersistForReason(reason)) {
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
    if (isRestoring) {
      completeRestoreTransition();
      return;
    }
    onPageChanged(index);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (isTtsActive) {
      saveTtsProgress();
    } else {
      persistCurrentProgress(
        chapterIndex: currentChapterIndex,
        pageIndex: currentPageIndex,
      );
    }
    scrollSaveTimer?.cancel();
    _heartbeatTimer?.cancel();
    disposeAutoPageCoordinator();
    _readAloudController.detach();
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
        if (isTtsActive) {
          saveTtsProgress();
        } else {
          persistCurrentProgress(
            chapterIndex: currentChapterIndex,
            pageIndex: currentPageIndex,
          );
        }
      }
    }
  }

  TextPage? get nextPageForAutoPage {
    if (!isAutoPaging || pageTurnMode == PageAnim.scroll) return null;
    final nextIdx = currentPageIndex + 1;
    if (nextIdx < slidePages.length) return slidePages[nextIdx];
    return null;
  }

  ReadingTheme get currentTheme => AppTheme.readingThemes[
      themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];

  String get currentChapterTitle => displayChapterTitleAt(currentChapterIndex);
  String get currentChapterUrl =>
      chapters.isNotEmpty ? chapters[currentChapterIndex].url : '';

  String displayChapterTitleAt(int index) {
    if (index < 0 || index >= chapters.length) return '';
    if (index < _chapterDisplayTitles.length &&
        _chapterDisplayTitles[index].isNotEmpty) {
      return _chapterDisplayTitles[index];
    }
    return chapters[index].title;
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
    final targetIndex = value is double
        ? (value * (chapters.length - 1)).round()
        : value as int;
    if (scrubIndex != targetIndex) {
      scrubIndex = targetIndex;
      notifyListeners();
    }
  }

  void onScrubEnd(dynamic value) {
    isScrubbing = false;
    final targetIndex = value is double
        ? (value * (chapters.length - 1)).round()
        : value as int;
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
    final bookmark = Bookmark(
      time: DateTime.now().millisecondsSinceEpoch,
      bookName: book.name,
      bookAuthor: book.author,
      bookUrl: book.bookUrl,
      chapterIndex: currentChapterIndex,
      chapterName: chapters[currentChapterIndex].title,
      chapterPos: currentPageIndex,
      bookText: content ?? '',
    );
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
    saveSetting('chinese_convert_v2', val);
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
    saveSetting('tts_mode', val);
    notifyListeners();
  }

  void setStopAfterChapter(bool val) {
    _readAloudController.setStopAfterChapter(val);
  }

  void setTtsRate(double val) {
    TTSService().setRate(val);
    saveSetting('tts_rate', val);
    notifyListeners();
  }

  void setTtsPitch(double val) {
    TTSService().setPitch(val);
    saveSetting('tts_pitch', val);
    notifyListeners();
  }

  void setTtsLanguage(String lang) {
    TTSService().setLanguage(lang);
    saveSetting('tts_language', lang);
    notifyListeners();
  }

  void setClickAction(int zone, int action) {
    clickActions[zone] = action;
    saveSetting('click_actions', clickActions.join(','));
    notifyListeners();
  }

  List<TextPage> buildSlideRuntimePages() {
    return pageFactory.windowPages;
  }

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {
    await super.doPaginate(fromEnd: fromEnd);
    refreshAllChapterRuntime();
  }

  Future<void> _primeInitialWindow() async {
    if (_initialSessionPrimed || isDisposed || !hasContentManager || viewSize == null) {
      return;
    }
    _initialSessionPrimed = true;
    final initialPreloadRadius =
        pageTurnMode == PageAnim.scroll && book.origin == 'local' ? 1 : 0;
    await ReaderPerfTrace.measureAsync(
      'prime initial window chapter $currentChapterIndex',
      () => loadChapterWithPreloadRadius(
        currentChapterIndex,
        preloadRadius: pageTurnMode == PageAnim.scroll ? initialPreloadRadius : 1,
      ),
    );
    if (isDisposed) return;
    bootstrapChapterWindow(currentChapterIndex);
    applyPendingRestore();
    scheduleDeferredWindowWarmup(currentChapterIndex);
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
    if (isAutoPaging) stopAutoPage();
    _readAloudController.toggle();
  }

  void startTtsFromLine(int lineIndex) {
    if (isAutoPaging) stopAutoPage();
    _readAloudController.startFromLine(lineIndex);
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
    unawaited(_readAloudController.saveProgress(
      persist: (chapterIndex, charOffset) {
        persistChapterCharOffsetProgress(
          chapterIndex: chapterIndex,
          charOffset: charOffset,
        );
      },
    ));
  }
}
