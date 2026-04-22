import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'view/read_view_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_viewport_bridge.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_action_dispatcher.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_exit_coordinator.dart';
import 'package:inkpage_reader/features/reader/view/slide_page_controller.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_page_shell.dart';

class ReaderPage extends StatefulWidget {
  final Book book;
  const ReaderPage({super.key, required this.book});
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late PageController _pageCtrl;
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  late SlidePageController _slideCtrl;
  int _controllerGeneration = 0;
  final ReaderPageViewportBridge _viewportBridge = ReaderPageViewportBridge();
  final ReaderPageActionDispatcher _actionDispatcher =
      const ReaderPageActionDispatcher();
  final ReaderPageExitCoordinator _exitCoordinator =
      ReaderPageExitCoordinator();

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
          child: ReaderPageShell(
            provider: p,
            scaffoldKey: _key,
            content: _buildContent(context, p),
            onExitIntent:
                () => _exitCoordinator.handleExitIntent(
                  context: context,
                  provider: p,
                  isDrawerOpen: () => _key.currentState?.isDrawerOpen ?? false,
                  popNavigator: () => Navigator.of(context).pop(),
                ),
            onMore: () => _actionDispatcher.showMore(context),
            onOpenDrawer: () => _actionDispatcher.openDrawer(_key),
            onTts: () => _actionDispatcher.showTtsDialog(context),
            onInterface:
                () => _actionDispatcher.showInterfaceSettings(context, p),
            onSettings: () => _actionDispatcher.showMoreSettings(context, p),
            onAutoPage: () => _actionDispatcher.handleAutoPage(context, p),
            onToggleDayNight: p.toggleDayNightTheme,
            onSearch: () => _actionDispatcher.openSearch(context, p),
            onReplaceRule: () => _actionDispatcher.openReplaceRule(context, p),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ReaderProvider p) {
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

    return ReadViewRuntime(
      key: ValueKey(_controllerGeneration),
      provider: p,
      pageController: _pageCtrl,
      onContentTapUp:
          p.showControls
              ? null
              : (details) =>
                  _actionDispatcher.handleContentTapUp(context, p, details),
    );
  }
}
