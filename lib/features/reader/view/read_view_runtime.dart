import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/read_view_runtime_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_state.dart';
import 'package:inkpage_reader/features/reader/view/delegate/scroll_mode_delegate.dart';
import 'package:inkpage_reader/features/reader/view/delegate/page_mode_delegate.dart';
import 'package:inkpage_reader/features/reader/view/scroll_execution_adapter.dart';
import 'package:inkpage_reader/features/reader/view/scroll_restore_runner.dart';
import 'package:inkpage_reader/features/reader/view/scroll_runtime_executor.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ReadViewRuntime extends StatefulWidget {
  final ReaderProvider provider;
  final PageController pageController;

  const ReadViewRuntime({
    super.key,
    required this.provider,
    required this.pageController,
  });

  @override
  State<ReadViewRuntime> createState() => _ReadViewRuntimeState();
}

class _ReadViewRuntimeState extends State<ReadViewRuntime>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnimation;
  bool _contentRevealed = false;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final Map<String, GlobalKey> _pageKeys = {};
  Timer? _userScrollResetTimer;
  bool _isUserScrolling = false;
  int _lastTtsScrolledStart = -1;
  late final ScrollExecutionAdapter _scrollExecution = ScrollExecutionAdapter(
    pageKeys: _pageKeys,
    onStateChanged: () {
      if (mounted) {
        setState(() {});
      }
    },
  );
  final ScrollRestoreRunner _scrollRestoreRunner = const ScrollRestoreRunner();
  final ReadViewRuntimeCoordinator _coordinator =
      const ReadViewRuntimeCoordinator();
  late final ScrollRuntimeExecutor _scrollRuntimeExecutor;

  @override
  void initState() {
    super.initState();
    _scrollRuntimeExecutor = ScrollRuntimeExecutor(
      provider: widget.provider,
      itemScrollController: _itemScrollController,
      pageKeys: _pageKeys,
      scrollExecution: _scrollExecution,
      scrollRestoreRunner: _scrollRestoreRunner,
      isMounted: () => mounted,
      onRestoreCompleted: () {
        if (mounted) {
          setState(() {});
        }
      },
      viewportHeight: () => context.size?.height ?? 0.0,
    );
    widget.provider.attachAutoPageTicker(createTicker);
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    // If the provider is already ready (e.g., ReadViewRuntime was recreated
    // due to a controller reset), skip the fade-in reveal to avoid a flash
    // on the next notifyListeners call.
    if (widget.provider.isReady) {
      _contentRevealed = true;
      _fadeCtrl.value = 1.0;
    }
    widget.provider.addListener(_onProviderStateChanged);
    _itemPositionsListener.itemPositions.addListener(
      _handleItemPositionsChanged,
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    widget.provider.removeListener(_onProviderStateChanged);
    _itemPositionsListener.itemPositions.removeListener(
      _handleItemPositionsChanged,
    );
    widget.provider.detachAutoPageTicker();
    _userScrollResetTimer?.cancel();
    widget.provider.setScrollInteractionActive(false);
    super.dispose();
  }

  void _onProviderStateChanged() {
    if (!mounted) return;

    // Reveal content with fade when ready
    if (!_contentRevealed && widget.provider.isReady) {
      _contentRevealed = true;
      _fadeCtrl.forward();
    }

    final p = widget.provider;
    p.reconcileVisibleScrollLoads();

    final pendingScrollAction = _coordinator.consumePendingScrollAction(p);
    if (pendingScrollAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pendingScrollAction.isRestore) {
          _scrollRuntimeExecutor.restoreScrollPosition(
            chapterIndex: pendingScrollAction.chapterIndex,
            localOffset: pendingScrollAction.localOffset,
            token: pendingScrollAction.token,
          );
          return;
        }
        _scrollRuntimeExecutor.jumpScrollPosition(
          chapterIndex: pendingScrollAction.chapterIndex,
          localOffset: pendingScrollAction.localOffset,
        );
      });
    }

    if (_coordinator.shouldFollowTts(
      p,
      lastTtsScrolledStart: _lastTtsScrolledStart,
      isUserScrolling: _isUserScrolling,
    )) {
      _lastTtsScrolledStart = p.ttsStart;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollRuntimeExecutor.scrollToTtsHighlight();
      });
    }

    setState(() {});
  }

  void _handleItemPositionsChanged() {
    final p = widget.provider;
    if (p.pageTurnMode != PageAnim.scroll) return;
    final positions =
        _itemPositionsListener.itemPositions.value.toList()
          ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    if (positions.isEmpty) return;
    final visible =
        positions
            .where(
              (item) => item.itemTrailingEdge > 0 && item.itemLeadingEdge < 1,
            )
            .toList();
    if (visible.isEmpty) return;
    final topItem = visible.first;
    final chapterIndex = topItem.index;
    final viewportHeight = context.size?.height ?? 1.0;
    final rawLocalOffset = (-topItem.itemLeadingEdge * viewportHeight).clamp(
      0.0,
      double.infinity,
    );
    final localOffset = (rawLocalOffset - p.contentTopInset).clamp(
      0.0,
      double.infinity,
    );
    p.handleVisibleScrollState(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      alignment: topItem.itemLeadingEdge.clamp(0.0, 1.0),
      visibleChapterIndexes: visible.map((item) => item.index).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final mediaPadding = MediaQuery.paddingOf(context);
        final insetsChanged = provider.updateContentInsets(
          top: mediaPadding.top + 8,
          bottom: mediaPadding.bottom + 28,
        );
        if (insetsChanged && provider.viewSize == size && provider.isReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              provider.doPaginate();
            }
          });
        }
        if (provider.viewSize != size) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => provider.setViewSize(size),
          );
        }

        // Show theme-colored placeholder during init
        if (provider.lifecycle == ReaderLifecycle.loading &&
            !_contentRevealed) {
          return Container(color: provider.currentTheme.backgroundColor);
        }

        final hasVisibleData =
            provider.pageTurnMode == PageAnim.scroll
                ? provider.pageFactory.orderedChapters.isNotEmpty
                : provider.slidePages.isNotEmpty;

        final waitingForFirstContent = _coordinator.shouldWaitForFirstContent(
          provider,
          hasVisibleData: hasVisibleData,
        );

        if (waitingForFirstContent) {
          return _buildViewportState(
            provider,
            _coordinator.resolveViewportState(
              provider,
              hasVisibleData: hasVisibleData,
            ),
          );
        }

        if (!hasVisibleData) {
          return _buildViewportState(
            provider,
            _coordinator.resolveViewportState(
              provider,
              hasVisibleData: hasVisibleData,
            ),
          );
        }

        final delegate =
            provider.pageTurnMode == PageAnim.scroll
                ? ScrollModeDelegate(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  pageKeys: _pageKeys,
                  isUserScrolling: () => _isUserScrolling,
                )
                : const PageModeDelegate();

        final content = NotificationListener<ScrollNotification>(
          onNotification:
              (notification) =>
                  _handleScrollNotification(notification, provider),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: delegate.build(
              context: context,
              provider: provider,
              pageController: widget.pageController,
            ),
          ),
        );

        return FadeTransition(
          opacity:
              _contentRevealed
                  ? _fadeAnimation
                  : const AlwaysStoppedAnimation(1.0),
          child: content,
        );
      },
    );
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    ReaderProvider provider,
  ) {
    if (provider.pageTurnMode != PageAnim.scroll) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _beginUserScroll(provider);
    } else if (notification is ScrollEndNotification) {
      _scheduleUserScrollReset(provider);
    }
    return false;
  }

  void _beginUserScroll(ReaderProvider provider) {
    _isUserScrolling = true;
    _userScrollResetTimer?.cancel();
    provider.pauseAutoPage();
    provider.setScrollInteractionActive(true);
  }

  void _scheduleUserScrollReset(ReaderProvider provider) {
    _userScrollResetTimer?.cancel();
    _userScrollResetTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _isUserScrolling = false;
      provider.setScrollInteractionActive(false);
      if (!provider.showControls) {
        provider.resumeAutoPage();
      }
    });
  }

  Widget _buildViewportState(
    ReaderProvider provider,
    ReaderViewportState state,
  ) {
    final textStyle = TextStyle(
      color: provider.currentTheme.textColor.withAlpha(160),
      fontSize: provider.fontSize,
    );
    return Container(
      color: provider.currentTheme.backgroundColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.showLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: provider.currentTheme.textColor.withValues(alpha: 0.35),
              ),
            ),
          if (state.message != null) Text(state.message!, style: textStyle),
        ],
      ),
    );
  }
}
