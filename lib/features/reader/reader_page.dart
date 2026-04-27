import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/book_storage_service.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_auto_page_controller.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_bookmark_controller.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_dependencies.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_menu_controller.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_settings_controller.dart';
import 'package:inkpage_reader/features/reader/controllers/reader_tts_controller.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';
import 'package:inkpage_reader/features/reader/engine/layout_engine.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/models/reader_tap_action.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_open_target.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_exit_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_facade.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_screen.dart';
import 'package:inkpage_reader/features/reader/widgets/reader/reader_bottom_menu.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_chapters_drawer.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_controller_sheets.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_page_shell.dart';
import 'package:inkpage_reader/features/search/search_page.dart';
import 'package:inkpage_reader/features/settings/settings_page.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.book,
    this.openTarget,
    this.initialChapters = const <BookChapter>[],
  });

  final Book book;
  final ReaderOpenTarget? openTarget;
  final List<BookChapter> initialChapters;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage>
    implements ReaderExitFlowDelegate {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ReaderPageExitCoordinator _exitCoordinator =
      ReaderPageExitCoordinator();
  final ReaderSessionFacade _sessionFacade = const ReaderSessionFacade();
  late final ReaderSettingsController _settings;
  late final ReaderMenuController _menu;
  late final ReaderDependencies _dependencies;
  late final ChapterRepository _repository;
  late final BookStorageService _bookStorageService;

  ReaderRuntime? _runtime;
  ReaderTtsController? _tts;
  ReaderAutoPageController? _autoPage;
  ReaderBookmarkController? _bookmark;
  Size? _lastViewportSize;
  String? _lastLayoutSignature;
  int _lastContentSettingsGeneration = 0;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _settings =
        ReaderSettingsController()..addListener(_handleControllerChanged);
    _menu = ReaderMenuController()..addListener(_handleControllerChanged);
    _dependencies = ReaderDependencies(
      book: widget.book,
      initialChapters: widget.initialChapters,
      currentChineseConvert: () => _settings.chineseConvert,
    );
    _bookStorageService = BookStorageService(
      bookDao: _dependencies.bookDao,
      chapterDao: _dependencies.chapterDao,
      contentDao: _dependencies.readerChapterContentDao,
      bookmarkDao: _dependencies.bookmarkDao,
    );
    _repository = _dependencies.createChapterRepository();
    _lastContentSettingsGeneration = _settings.contentSettingsGeneration;
    unawaited(_settings.loadSettings());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _settings.removeListener(_handleControllerChanged);
    _menu.removeListener(_handleControllerChanged);
    _autoPage?.removeListener(_handleControllerChanged);
    _tts?.removeListener(_handleControllerChanged);
    unawaited(_runtime?.flushProgress());
    _autoPage?.dispose();
    _tts?.dispose();
    _runtime?.dispose();
    _menu.dispose();
    _settings.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  ReaderRuntime _ensureRuntime(Size size, ReadStyle style) {
    final existing = _runtime;
    if (existing != null) return existing;

    final spec = LayoutSpec.fromViewport(viewportSize: size, style: style);
    final progressController = ReaderProgressController(
      book: widget.book,
      repository: _repository,
      bookDao: _dependencies.bookDao,
    );
    final initialLocation =
        widget.openTarget?.location ??
        ReaderLocation(
          chapterIndex: widget.book.chapterIndex,
          charOffset: widget.book.charOffset,
        );
    final runtime = ReaderRuntime(
      book: widget.book,
      repository: _repository,
      layoutEngine: LayoutEngine(),
      progressController: progressController,
      initialLayoutSpec: spec,
      initialMode: _modeFor(_settings.pageTurnMode),
      initialLocation: initialLocation,
    )..addListener(_handleControllerChanged);

    final tts = ReaderTtsController(runtime: runtime)
      ..addListener(_handleControllerChanged);
    final autoPage = ReaderAutoPageController(runtime: runtime)
      ..addListener(_handleControllerChanged);
    final bookmarkDao = _dependencies.bookmarkDao;
    _runtime = runtime;
    _tts = tts;
    _autoPage = autoPage;
    if (bookmarkDao != null) {
      _bookmark = ReaderBookmarkController(
        book: widget.book,
        runtime: runtime,
        bookmarkDao: bookmarkDao,
      );
    }
    _lastLayoutSignature = spec.layoutSignature;
    unawaited(tts.loadSettings());

    if (!_opening) {
      _opening = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(runtime.openBook().whenComplete(() => _opening = false));
      });
    }
    return runtime;
  }

  ReaderMode _modeFor(int pageTurnMode) {
    return pageTurnMode == PageAnim.scroll
        ? ReaderMode.scroll
        : ReaderMode.slide;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _settings.currentTheme;
    final isDarkBackground = theme.backgroundColor.computeLuminance() < 0.5;
    final runtime = _runtime;
    final page = _currentPage(runtime);
    final chapterIndex = _currentChapterIndex(runtime);
    final navigation = ReaderChapterNavigationState(
      chapterCount: runtime?.chapterCount ?? widget.initialChapters.length,
      currentIndex: chapterIndex,
      isScrubbing: _menu.isScrubbing,
      scrubIndex: _menu.scrubIndex,
      pendingIndex: _menu.pendingChapterNavigationIndex,
      titleFor: _chapterTitleAt,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkBackground ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isDarkBackground ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkBackground ? Brightness.light : Brightness.dark,
      ),
      child: ReaderPageShell(
        book: widget.book,
        scaffoldKey: _scaffoldKey,
        content: _buildContent(context),
        drawer: ReaderChaptersDrawer(
          chapters: runtime?.chapters ?? widget.initialChapters,
          currentChapterIndex: chapterIndex,
          titleFor: _chapterTitleAt,
          listenable: runtime,
          onChapterTap: _jumpToChapter,
        ),
        backgroundColor: theme.backgroundColor,
        textColor: theme.textColor,
        controlsVisible: _menu.controlsVisible,
        readBarStyleFollowPage: _settings.readBarStyleFollowPage,
        showReadTitleAddition: _settings.showReadTitleAddition,
        hasVisibleContent: page != null,
        isLoading: runtime == null || runtime.state.phase != ReaderPhase.ready,
        chapterTitle: _chapterTitleAt(chapterIndex),
        chapterUrl: _chapterUrlAt(chapterIndex),
        originName: widget.book.originName,
        displayPageLabel: _displayPageLabel(page),
        displayChapterPercentLabel: _displayChapterPercentLabel(page),
        navigation: navigation,
        isAutoPaging: _autoPage?.isRunning ?? false,
        dayNightIcon: _settings.dayNightToggleIcon,
        dayNightTooltip: _settings.dayNightToggleTooltip,
        onExitIntent: _handleExitIntent,
        onMore: _showMore,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onTts: _showTts,
        onInterface:
            () => ReaderControllerSheets.showInterfaceSettings(
              context,
              _settings,
            ),
        onSettings:
            () =>
                ReaderControllerSheets.showAdvancedSettings(context, _settings),
        onAutoPage: _toggleAutoPage,
        onToggleDayNight: _settings.toggleDayNightTheme,
        onSearch: _openSearch,
        onReplaceRule: _openReplaceRule,
        onToggleControls: _menu.toggleControls,
        onPrevChapter: () => unawaited(_jumpRelativeChapter(-1)),
        onNextChapter: () => unawaited(_jumpRelativeChapter(1)),
        onScrubStart: () => _menu.onScrubStart(chapterIndex),
        onScrubbing: _menu.onScrubbing,
        onScrubEnd: (index) {
          _menu.onScrubEnd(index);
          unawaited(_jumpToChapter(index));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final mediaPadding = MediaQuery.paddingOf(context);
        _lastViewportSize = size;

        final style = _settings.readStyleFor(mediaPadding);
        final runtime = _ensureRuntime(size, style);
        _syncRuntimeConfiguration(runtime, size, style);

        final theme = _settings.currentTheme;
        return EngineReaderScreen(
          runtime: runtime,
          backgroundColor: theme.backgroundColor,
          textColor: theme.textColor,
          style: style,
          onContentTapUp:
              _menu.controlsVisible ? null : (details) => _handleTap(details),
        );
      },
    );
  }

  void _syncRuntimeConfiguration(
    ReaderRuntime runtime,
    Size size,
    ReadStyle style,
  ) {
    final spec = LayoutSpec.fromViewport(viewportSize: size, style: style);
    if (_lastLayoutSignature != spec.layoutSignature) {
      _lastLayoutSignature = spec.layoutSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(runtime.updateLayoutSpec(spec));
      });
    }
    final targetMode = _modeFor(_settings.pageTurnMode);
    if (runtime.state.mode != targetMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(runtime.switchMode(targetMode));
      });
    }
    if (_lastContentSettingsGeneration != _settings.contentSettingsGeneration) {
      _lastContentSettingsGeneration = _settings.contentSettingsGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(runtime.reloadContentPreservingLocation());
      });
    }
  }

  void _handleTap(TapUpDetails details) {
    final size = _lastViewportSize;
    final runtime = _runtime;
    if (size == null || runtime == null) return;
    final row = (details.localPosition.dy / (size.height / 3)).floor().clamp(
      0,
      2,
    );
    final col = (details.localPosition.dx / (size.width / 3)).floor().clamp(
      0,
      2,
    );
    final action = ReaderTapAction.fromCode(
      _settings.clickActions[row * 3 + col],
    );
    switch (action) {
      case ReaderTapAction.menu:
        _menu.toggleControls();
        return;
      case ReaderTapAction.nextPage:
        runtime.moveToNextPage();
        return;
      case ReaderTapAction.prevPage:
        runtime.moveToPrevPage();
        return;
      case ReaderTapAction.nextChapter:
        unawaited(_jumpRelativeChapter(1));
        return;
      case ReaderTapAction.prevChapter:
        unawaited(_jumpRelativeChapter(-1));
        return;
      case ReaderTapAction.toggleTts:
        unawaited(_tts?.toggle());
        return;
      case ReaderTapAction.bookmark:
        unawaited(_toggleBookmark());
        return;
    }
  }

  Future<void> _jumpRelativeChapter(int delta) async {
    final runtime = _runtime;
    if (runtime == null) return;
    final target =
        (runtime.state.visibleLocation.chapterIndex + delta)
            .clamp(0, (runtime.chapterCount - 1).clamp(0, 1 << 20))
            .toInt();
    await _jumpToChapter(target);
  }

  Future<void> _jumpToChapter(int index) async {
    final runtime = _runtime;
    if (runtime == null) return;
    final safeIndex =
        index.clamp(0, (runtime.chapterCount - 1).clamp(0, 1 << 20)).toInt();
    await runtime.jumpToChapter(safeIndex);
    _menu.completeChapterNavigation();
  }

  void _toggleAutoPage() {
    final autoPage = _autoPage;
    if (autoPage == null) return;
    if (!autoPage.isRunning) _menu.hideControlsForAutoPage();
    autoPage.toggle();
  }

  void _showTts() {
    final tts = _tts;
    if (tts == null) return;
    ReaderControllerSheets.showTts(context, tts: tts, settings: _settings);
  }

  void _handleExitIntent() {
    unawaited(
      _exitCoordinator.handleExitIntent(
        context: context,
        provider: this,
        isDrawerOpen: () => _scaffoldKey.currentState?.isDrawerOpen ?? false,
        popNavigator: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showMore() {
    AppBottomSheet.show(
      context: context,
      title: '更多操作',
      icon: Icons.more_horiz_rounded,
      children: [
        ListTile(
          leading: const Icon(Icons.rule_rounded),
          title: const Text('內容替換規則'),
          subtitle: const Text('自定義字詞替換與屏蔽'),
          onTap: () {
            Navigator.pop(context);
            _openReplaceRule();
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings_suggest_rounded),
          title: const Text('全域系統設定'),
          subtitle: const Text('備份、還原與解析引擎配置'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
      ],
    );
  }

  void _openSearch() {
    _menu.dismissControls();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  void _openReplaceRule() {
    _menu.dismissControls();
    final replaceDao = _dependencies.replaceDao;
    if (replaceDao == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('替換規則資料庫不可用')));
      return;
    }
    AppBottomSheet.show(
      context: context,
      title: '替換規則',
      icon: Icons.rule_rounded,
      children: [
        FutureBuilder<int>(
          future: replaceDao.getEnabled().then((rules) => rules.length),
          builder: (context, snapshot) {
            final countText =
                snapshot.hasData ? '目前啟用 ${snapshot.data} 條規則' : '正在讀取啟用規則';
            return ListTile(
              leading: const Icon(Icons.fact_check_rounded),
              title: const Text('規則狀態'),
              subtitle: Text(countText),
            );
          },
        ),
        StatefulBuilder(
          builder: (context, setSheetState) {
            return SwitchListTile(
              secondary: const Icon(Icons.auto_fix_high_rounded),
              title: const Text('本書套用替換規則'),
              subtitle: const Text('切換後會重新載入目前章節'),
              value: widget.book.getUseReplaceRule(),
              onChanged: (value) {
                setSheetState(() {
                  (widget.book.readConfig ??= ReadConfig()).useReplaceRule =
                      value;
                });
                unawaited(_dependencies.bookDao.upsert(widget.book));
                unawaited(_runtime?.reloadContentPreservingLocation());
              },
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.refresh_rounded),
          title: const Text('重新套用並刷新目前章節'),
          onTap: () {
            Navigator.pop(context);
            unawaited(_runtime?.reloadContentPreservingLocation());
          },
        ),
      ],
    );
  }

  Future<void> _toggleBookmark() async {
    await _bookmark?.addVisibleLocationBookmark();
  }

  @override
  Book get book => widget.book;

  @override
  bool shouldPromptAddToBookshelfOnExit() {
    return !widget.book.isInBookshelf && _settings.showAddToShelfAlert;
  }

  @override
  Future<void> persistExitProgress() async {
    await _runtime?.flushProgress();
  }

  @override
  Future<void> addCurrentBookToBookshelf() async {
    final runtime = _runtime;
    final location =
        runtime?.state.visibleLocation ??
        ReaderLocation(
          chapterIndex: widget.book.chapterIndex,
          charOffset: widget.book.charOffset,
        );
    final chapters = runtime?.chapters ?? widget.initialChapters;
    await _sessionFacade.addCurrentBookToBookshelf(
      book: widget.book,
      chapters: chapters,
      location: location,
      chapterTitle: _chapterTitleAt(location.chapterIndex),
      progressStore: ReaderProgressStore(),
      bookDao: _dependencies.bookDao,
      chapterDao: _dependencies.chapterDao,
    );
    if (mounted) setState(() {});
  }

  @override
  Future<void> discardUnkeptBookStorage() {
    return _bookStorageService.discardBook(widget.book);
  }

  int _currentChapterIndex(ReaderRuntime? runtime) {
    final count = runtime?.chapterCount ?? widget.initialChapters.length;
    if (runtime == null || count <= 0) return 0;
    return runtime.state.visibleLocation.chapterIndex
        .clamp(0, count - 1)
        .toInt();
  }

  TextPage? _currentPage(ReaderRuntime? runtime) {
    if (runtime == null) return null;
    return runtime.state.pageWindow?.current ?? runtime.state.currentSlidePage;
  }

  String _chapterTitleAt(int index) {
    final runtime = _runtime;
    if (runtime != null) return runtime.titleFor(index);
    if (index < 0 || index >= widget.initialChapters.length) return '';
    return widget.initialChapters[index].title;
  }

  String _chapterUrlAt(int index) {
    final runtime = _runtime;
    if (runtime != null) return runtime.chapterUrlAt(index);
    if (index < 0 || index >= widget.initialChapters.length) return '';
    return widget.initialChapters[index].url;
  }

  String _displayPageLabel(TextPage? page) {
    if (page == null || page.pageSize <= 0) return '0/0';
    return '${page.pageIndex + 1}/${page.pageSize}';
  }

  String _displayChapterPercentLabel(TextPage? page) {
    if (page == null) return '0.0%';
    return page.readProgress;
  }
}
