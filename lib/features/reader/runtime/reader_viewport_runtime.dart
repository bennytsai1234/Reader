import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_scroll_viewport_settle_state.dart';
import 'package:inkpage_reader/features/reader/runtime/read_view_runtime_coordinator.dart';

class ReaderViewportRuntimeUpdate {
  final bool didModeChange;
  final PendingScrollAction? pendingScrollAction;
  final bool shouldFollowTts;
  final bool shouldHoldScrollUntilRestore;
  final ReaderScrollViewportSettleState viewportSettleState;

  const ReaderViewportRuntimeUpdate({
    this.didModeChange = false,
    this.pendingScrollAction,
    this.shouldFollowTts = false,
    this.shouldHoldScrollUntilRestore = false,
    this.viewportSettleState = ReaderScrollViewportSettleState.settled,
  });
}

class ReaderViewportRuntime {
  final ReadViewRuntimeCoordinator _coordinator;
  int _lastPageTurnMode;
  int _lastTtsFollowKey;
  bool _isUserScrolling = false;

  ReaderViewportRuntime({
    required int initialPageTurnMode,
    int initialTtsFollowKey = -1,
    ReadViewRuntimeCoordinator coordinator = const ReadViewRuntimeCoordinator(),
  }) : _coordinator = coordinator,
       _lastPageTurnMode = initialPageTurnMode,
       _lastTtsFollowKey = initialTtsFollowKey;

  bool get isUserScrolling => _isUserScrolling;

  ReaderViewportRuntimeUpdate handleProviderStateChanged(
    ReaderProvider provider,
  ) {
    var didModeChange = false;
    if (_lastPageTurnMode != provider.pageTurnMode) {
      _lastPageTurnMode = provider.pageTurnMode;
      _isUserScrolling = false;
      provider.setScrollInteractionActive(false);
      didModeChange = true;
    }

    final hasVisibleData = _hasVisibleData(provider);
    final pendingScrollAction = _coordinator.consumePendingScrollAction(
      provider,
    );
    final viewportSettleState = _coordinator.resolveScrollViewportSettleState(
      provider,
      hasVisibleData: hasVisibleData,
    );
    final shouldFollowTts = _coordinator.shouldFollowTts(
      provider,
      lastTtsFollowKey: _lastTtsFollowKey,
      isUserScrolling: _isUserScrolling,
      hasVisibleData: hasVisibleData,
    );
    final followKey = _currentTtsFollowKey(provider);
    if (shouldFollowTts) {
      _lastTtsFollowKey = followKey;
    } else if (followKey < 0) {
      _lastTtsFollowKey = -1;
    } else if (viewportSettleState.shouldConsumeSuppressedTtsFollow) {
      _lastTtsFollowKey = followKey;
    }

    return ReaderViewportRuntimeUpdate(
      didModeChange: didModeChange,
      pendingScrollAction: pendingScrollAction,
      shouldFollowTts: shouldFollowTts,
      shouldHoldScrollUntilRestore: viewportSettleState.shouldHoldContent,
      viewportSettleState: viewportSettleState,
    );
  }

  void beginUserScroll(ReaderProvider provider) {
    provider.cancelPendingScrollRestoreFromUserScroll();
    _isUserScrolling = true;
    provider.autoPageProgressNotifier.value = 0.0;
    provider.pauseAutoPage();
    provider.setScrollInteractionActive(true);
  }

  void endUserScroll(ReaderProvider provider) {
    _isUserScrolling = false;
    provider.setScrollInteractionActive(false);
    if (!provider.showControls) {
      provider.resumeAutoPage();
    }
  }

  void reset(ReaderProvider provider) {
    _isUserScrolling = false;
    _lastTtsFollowKey = -1;
    _lastPageTurnMode = provider.pageTurnMode;
    provider.setScrollInteractionActive(false);
  }

  int _currentTtsFollowKey(ReaderProvider provider) {
    return provider.currentTtsPosition?.followKey ?? -1;
  }

  bool _hasVisibleData(ReaderProvider provider) {
    return provider.pageTurnMode == PageAnim.scroll
        ? provider.pageFactory.orderedChapters.isNotEmpty
        : provider.slidePages.isNotEmpty;
  }
}
