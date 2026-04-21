import 'package:flutter/material.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/settings/settings_page.dart';
import 'package:inkpage_reader/features/replace_rule/replace_rule_page.dart';
import 'package:inkpage_reader/features/search/search_page.dart';
import 'widgets/reader/reader_top_menu.dart';
import 'widgets/reader/reader_bottom_menu.dart';
import 'widgets/reader_chapters_drawer.dart';
import 'widgets/reader_settings_sheets.dart';
import 'view/read_view_runtime.dart';
import 'tts_dialog.dart';
import 'auto_read_dialog.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/reader_layout.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_viewport_bridge.dart';
import 'package:inkpage_reader/features/reader/view/slide_page_controller.dart';

class ReaderPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  final int chapterPos;
  const ReaderPage({
    super.key,
    required this.book,
    this.chapterIndex = 0,
    this.chapterPos = 0,
  });
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late PageController _pageCtrl;
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  late SlidePageController _slideCtrl;
  int _controllerGeneration = 0;
  final ReaderPageViewportBridge _viewportBridge = ReaderPageViewportBridge();
  bool _isHandlingExit = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 0);
    _slideCtrl = SlidePageController(_pageCtrl);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _slideCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  /// Recreate the PageController at [initialPage] so the new PageView
  /// starts at the correct position without a one-frame glitch.
  void _resetController(int initialPage) {
    _slideCtrl.dispose();
    _pageCtrl.dispose();
    _pageCtrl = PageController(initialPage: initialPage);
    _slideCtrl = SlidePageController(_pageCtrl);
    _controllerGeneration++;
  }

  /// Poll each frame until the page scroll animation has settled, then
  /// apply the deferred slide window recenter atomically.
  void _pollRecenter(ReaderProvider p) {
    final action = _viewportBridge.handleRecenterPoll(
      isMounted: mounted,
      hasPendingSlideRecenter: p.hasPendingSlideRecenter,
      isPageScrolling:
          _pageCtrl.hasClients && _pageCtrl.position.isScrollingNotifier.value,
    );
    if (action == ReaderPageRecenterAction.none) return;
    if (action == ReaderPageRecenterAction.reschedule) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pollRecenter(p));
      return;
    }
    // Scroll settled — rebuild window + reset controller atomically.
    // This triggers notifyListeners → Consumer rebuild → consumeControllerReset.
    p.applyPendingSlideRecenter();
  }

  void _handleTap(Offset pos, Size size, ReaderProvider p) {
    final x = pos.dx, y = pos.dy, w = size.width, h = size.height;
    int row = (y / (h / 3)).floor().clamp(0, 2);
    int col = (x / (w / 3)).floor().clamp(0, 2);
    _executeAction(p, p.clickActions[row * 3 + col]);
  }

  void _executeAction(ReaderProvider p, int action) {
    switch (action) {
      case 0:
        p.toggleControls();
        break;
      case 1:
        p.nextPage();
        break;
      case 2:
        p.prevPage();
        break;
      case 3:
        p.nextChapter();
        break;
      case 4:
        p.prevChapter(fromEnd: false);
        break;
      case 5:
        p.toggleTts();
        break;
      case 7:
        p.toggleBookmark();
        break;
      default:
        p.toggleControls();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, p, _) {
        final theme = p.currentTheme;
        final isDarkBackground = theme.backgroundColor.computeLuminance() < 0.5;
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
          child: PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) {
                return;
              }
              _handleExitIntent(context, p);
            },
            child: Scaffold(
              key: _key,
              body: _buildBody(context, p),
              drawer: ReaderChaptersDrawer(provider: p),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ReaderProvider p) {
    final shellUpdate = _viewportBridge.resolveBuildUpdate(
      controllerResetPage: p.consumeControllerReset(),
      hasPendingSlideRecenter: p.hasPendingSlideRecenter,
      pendingJumpPage: p.consumePendingJump(),
    );
    final resetTarget = shellUpdate.controllerResetPage;
    if (resetTarget != null) {
      _resetController(resetTarget);
    }
    if (shellUpdate.shouldScheduleRecenterPoll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pollRecenter(p));
    }
    final pendingJump = shellUpdate.pendingJumpPage;
    if (pendingJump != null) {
      _slideCtrl.jumpTo(
        pendingJump,
        onWillJump: p.consumePendingSlideJumpReason,
      );
    }

    return Container(
      color: p.currentTheme.backgroundColor,
      child: Stack(
        children: [
          ReadViewRuntime(
            key: ValueKey(_controllerGeneration),
            provider: p,
            pageController: _pageCtrl,
          ),

          if (((p.pageTurnMode == PageAnim.scroll &&
                      p.chapterPagesCache.isNotEmpty) ||
                  (p.pageTurnMode != PageAnim.scroll &&
                      p.slidePages.isNotEmpty)) &&
              !p.isLoading)
            _buildPermanentInfo(context, p),

          Positioned.fill(
            child: IgnorePointer(
              ignoring: p.showControls,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp:
                    (d) => _handleTap(
                      d.localPosition,
                      MediaQuery.sizeOf(context),
                      p,
                    ),
              ),
            ),
          ),

          if (p.showControls)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: p.toggleControls,
              ),
            ),

          ReaderTopMenu(
            provider: p,
            onBack: () => _handleExitIntent(context, p),
            onMore: () => _showMore(context),
          ),
          ReaderBottomMenu(
            provider: p,
            onOpenDrawer: () => _key.currentState?.openDrawer(),
            onTts: () => TtsDialog.show(context),
            onInterface:
                () => ReaderSettingsSheets.showInterfaceSettings(context, p),
            onSettings: () => ReaderSettingsSheets.showMoreSettings(context, p),
            onAutoPage: () async {
              if (!p.isAutoPaging) {
                p.toggleAutoPage();
                if (p.showControls) {
                  p.toggleControls();
                }
                return;
              }
              await AutoReadDialog.show(context);
            },
            onToggleDayNight: p.toggleDayNightTheme,
            onSearch: () {
              p.toggleControls();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchPage()),
              );
            },
            onReplaceRule: () {
              p.toggleControls();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReplaceRulePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleExitIntent(BuildContext context, ReaderProvider p) async {
    if (_isHandlingExit || !mounted) return;
    final navigator = Navigator.of(context);
    if (_key.currentState?.isDrawerOpen ?? false) {
      navigator.pop();
      return;
    }

    _isHandlingExit = true;
    try {
      final shouldPrompt = p.shouldPromptAddToBookshelfOnExit();
      await p.persistExitProgress();
      if (!shouldPrompt) {
        if (mounted) {
          navigator.pop();
        }
        return;
      }
      if (!context.mounted) return;
      final addToBookshelf = await _showAddToBookshelfDialog(context, p.book);
      if (!mounted) return;
      if (addToBookshelf == true) {
        await p.addCurrentBookToBookshelf();
      }
      if (mounted) {
        navigator.pop();
      }
    } finally {
      _isHandlingExit = false;
    }
  }

  Future<bool?> _showAddToBookshelfDialog(BuildContext context, Book book) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: const Text('加入書架？'),
            content: Text('《${book.name}》尚未加入書架，是否在退出前加入書架以保留目前閱讀進度？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('直接退出'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('加入書架'),
              ),
            ],
          ),
    );
  }

  Widget _buildPermanentInfo(BuildContext context, ReaderProvider p) =>
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                p.currentTheme.backgroundColor.withValues(alpha: 0.0),
                p.currentTheme.backgroundColor.withValues(alpha: 0.88),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              kReaderPermanentInfoTopPadding,
              16,
              MediaQuery.of(context).padding.bottom +
                  kReaderPermanentInfoBottomSpacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p.book.name,
                    style: TextStyle(
                      color: p.currentTheme.textColor.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  p.displayPageLabel,
                  style: TextStyle(
                    color: p.currentTheme.textColor.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    p.displayChapterPercentLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: p.currentTheme.textColor.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  void _showMore(BuildContext context) {
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReplaceRulePage()),
            );
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
}
