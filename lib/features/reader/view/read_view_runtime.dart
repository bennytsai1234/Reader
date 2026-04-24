import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/reader_layout.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/read_view_runtime_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_layout.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_execution_bridge.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_runtime.dart';
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
  final GestureTapUpCallback? onContentTapUp;

  const ReadViewRuntime({
    super.key,
    required this.provider,
    required this.pageController,
    this.onContentTapUp,
  });

  @override
  State<ReadViewRuntime> createState() => _ReadViewRuntimeState();
}

class _ReadViewRuntimeState extends State<ReadViewRuntime>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnimation;
  bool _contentRevealed = false;
  bool _holdContentUntilScrollRestore = false;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final Map<String, GlobalKey> _pageKeys = {};
  Timer? _userScrollResetTimer;
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
  final ReaderViewportExecutionBridge _executionBridge =
      const ReaderViewportExecutionBridge();
  late final ScrollRuntimeExecutor _scrollRuntimeExecutor;
  late final ReaderViewportRuntime _viewportRuntime;

  @override
  void initState() {
    super.initState();
    _viewportRuntime = ReaderViewportRuntime(
      initialPageTurnMode: widget.provider.pageTurnMode,
    );
    _scrollRuntimeExecutor = ScrollRuntimeExecutor(
      provider: widget.provider,
      itemScrollController: _itemScrollController,
      pageKeys: _pageKeys,
      scrollExecution: _scrollExecution,
      scrollRestoreRunner: _scrollRestoreRunner,
      isMounted: () => mounted,
      viewportHeight: () => context.size?.height ?? 0.0,
    );
    widget.provider.attachAutoPageTicker(createTicker);
    widget.provider.attachScrollAutoPageDriver((deltaPixels) {
      return _scrollExecution.scrollByDelta(
        provider: widget.provider,
        deltaPixels: deltaPixels,
      );
    });
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    // If the provider is already ready (e.g., ReadViewRuntime was recreated
    // due to a controller reset), skip the fade-in reveal to avoid a flash
    // on the next notifyListeners call.
    final initialViewportSettleState = _coordinator
        .resolveScrollViewportSettleState(
          widget.provider,
          hasVisibleData: _hasVisibleData(widget.provider),
        );
    if (widget.provider.isReady &&
        !initialViewportSettleState.shouldHoldContent) {
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
    widget.provider.detachScrollAutoPageDriver();
    _userScrollResetTimer?.cancel();
    _viewportRuntime.reset(widget.provider);
    super.dispose();
  }

  void _onProviderStateChanged() {
    if (!mounted) return;

    final p = widget.provider;
    final runtimeUpdate = _viewportRuntime.handleProviderStateChanged(p);
    _holdContentUntilScrollRestore =
        runtimeUpdate.viewportSettleState.shouldHoldContent;
    if (!_holdContentUntilScrollRestore && !_contentRevealed && p.isReady) {
      _contentRevealed = true;
      _fadeCtrl.forward();
    }
    if (runtimeUpdate.didModeChange) {
      _pageKeys.clear();
      _userScrollResetTimer?.cancel();
    }
    p.reconcileVisibleScrollLoads();

    final pendingScrollAction = runtimeUpdate.pendingScrollAction;
    if (pendingScrollAction != null) {
      final command = pendingScrollAction.command;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pendingScrollAction.isRestore) {
          _scrollRuntimeExecutor.restoreScrollPosition(
            chapterIndex: command.target.chapterIndex,
            localOffset: command.target.localOffset,
            token: pendingScrollAction.restoreToken,
            navigationToken: pendingScrollAction.navigationToken,
          );
          return;
        }
        _scrollRuntimeExecutor.jumpScrollPosition(
          chapterIndex: command.target.chapterIndex,
          localOffset: command.target.localOffset,
          onCompleted:
              () => widget.provider.completeNavigation(
                pendingScrollAction.navigationToken,
                command.reason,
              ),
        );
      });
    }

    if (runtimeUpdate.shouldFollowTts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollRuntimeExecutor.scrollToTtsHighlight();
      });
    }

    setState(() {});
  }

  void _handleItemPositionsChanged() {
    final p = widget.provider;
    if (p.pageTurnMode != PageAnim.scroll) return;
    final viewportHeight = context.size?.height ?? 1.0;
    final update = _executionBridge.resolveVisibleScrollUpdate(
      positions: _itemPositionsListener.itemPositions.value,
      viewportHeight: viewportHeight,
      chapterHeightFor: p.estimatedChapterContentHeight,
      chapterItemExtentFor: p.estimatedChapterItemExtent,
    );
    if (update == null) return;
    final pageAnchor = _scrollExecution.resolveAnchorLocation(provider: p);
    p.handleVisibleScrollState(
      chapterIndex: pageAnchor?.chapterIndex ?? update.chapterIndex,
      localOffset: pageAnchor?.localOffset ?? update.localOffset,
      alignment: update.alignment,
      visibleChapterIndexes: update.visibleChapterIndexes,
      isAnchorConfirmed: pageAnchor != null,
      anchorPadding: ReaderScrollLayout.anchorPadding(
        viewportHeight: viewportHeight,
        topInset: p.scrollViewportTopInset,
      ),
    );
  }

  bool _hasVisibleData(ReaderProvider provider) {
    return provider.pageTurnMode == PageAnim.scroll
        ? provider.pageFactory.orderedChapters.isNotEmpty
        : provider.slidePages.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final mediaPadding = MediaQuery.paddingOf(context);
        final contentTopInset = mediaPadding.top + kReaderContentTopSpacing;
        final contentBottomInset =
            mediaPadding.bottom + kReaderPermanentInfoReservedHeight;
        final contentInsetsChanged = provider.updateContentInsets(
          top: contentTopInset,
          bottom: contentBottomInset,
        );
        final scrollInsetsChanged = provider.updateScrollViewportInsets(
          top: contentTopInset,
          bottom: contentBottomInset,
        );
        final layoutUpdate = _executionBridge.resolveLayoutUpdate(
          size: size,
          contentInsetsChanged: contentInsetsChanged,
          scrollInsetsChanged: scrollInsetsChanged,
          currentViewSize: provider.viewSize,
          isReady: provider.isReady,
        );
        if (layoutUpdate.shouldRepaginate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              provider.doPaginate();
            }
          });
        }
        final nextViewSize = layoutUpdate.nextViewSize;
        if (nextViewSize != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => provider.setViewSize(nextViewSize),
          );
        }

        final hasVisibleData = _hasVisibleData(provider);
        final settleState = _coordinator.resolveScrollViewportSettleState(
          provider,
          hasVisibleData: hasVisibleData,
        );

        // Keep the viewport quiet while restoring the initial scroll anchor.
        if (!_contentRevealed &&
            (settleState.shouldHoldContent ||
                (!hasVisibleData &&
                    (provider.lifecycle == ReaderLifecycle.loading ||
                        provider.sessionPhase == ReaderSessionPhase.restoring ||
                        _holdContentUntilScrollRestore)))) {
          return Container(color: provider.currentTheme.backgroundColor);
        }

        final blockingViewportState = _coordinator.resolveBlockingViewportState(
          provider,
        );
        if (blockingViewportState != null) {
          return _buildViewportState(provider, blockingViewportState);
        }

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
                  isUserScrolling: () => _viewportRuntime.isUserScrolling,
                )
                : const PageModeDelegate();

        final content = NotificationListener<ScrollNotification>(
          onNotification:
              (notification) =>
                  _handleScrollNotification(notification, provider),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              key: ValueKey<int>(provider.pageTurnMode),
              child: delegate.build(
                context: context,
                provider: provider,
                pageController: widget.pageController,
                onContentTapUp: widget.onContentTapUp,
              ),
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
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _viewportRuntime.beginUserScroll(provider);
    } else if (notification is ScrollEndNotification) {
      _scheduleUserScrollReset(provider);
    }
    return false;
  }

  void _scheduleUserScrollReset(ReaderProvider provider) {
    _userScrollResetTimer?.cancel();
    _userScrollResetTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _viewportRuntime.endUserScroll(provider);
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
