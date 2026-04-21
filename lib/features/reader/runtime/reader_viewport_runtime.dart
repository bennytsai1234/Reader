import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/read_view_runtime_coordinator.dart';

class ReaderViewportRuntimeUpdate {
  final bool didModeChange;
  final PendingScrollAction? pendingScrollAction;
  final bool shouldFollowTts;

  const ReaderViewportRuntimeUpdate({
    this.didModeChange = false,
    this.pendingScrollAction,
    this.shouldFollowTts = false,
  });
}

class ReaderViewportRuntime {
  final ReadViewRuntimeCoordinator _coordinator;
  int _lastPageTurnMode;
  int _lastTtsFollowOffset;
  bool _isUserScrolling = false;

  ReaderViewportRuntime({
    required int initialPageTurnMode,
    int initialTtsFollowOffset = -1,
    ReadViewRuntimeCoordinator coordinator = const ReadViewRuntimeCoordinator(),
  }) : _coordinator = coordinator,
       _lastPageTurnMode = initialPageTurnMode,
       _lastTtsFollowOffset = initialTtsFollowOffset;

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

    final pendingScrollAction = _coordinator.consumePendingScrollAction(
      provider,
    );
    final shouldFollowTts = _coordinator.shouldFollowTts(
      provider,
      lastTtsFollowOffset: _lastTtsFollowOffset,
      isUserScrolling: _isUserScrolling,
    );
    final followOffset = _currentTtsFollowOffset(provider);
    if (shouldFollowTts) {
      _lastTtsFollowOffset = followOffset;
    } else if (followOffset < 0) {
      _lastTtsFollowOffset = -1;
    }

    return ReaderViewportRuntimeUpdate(
      didModeChange: didModeChange,
      pendingScrollAction: pendingScrollAction,
      shouldFollowTts: shouldFollowTts,
    );
  }

  void beginUserScroll(ReaderProvider provider) {
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
    _lastTtsFollowOffset = -1;
    _lastPageTurnMode = provider.pageTurnMode;
    provider.setScrollInteractionActive(false);
  }

  int _currentTtsFollowOffset(ReaderProvider provider) {
    return provider.ttsWordStart >= 0
        ? provider.ttsWordStart
        : provider.ttsStart;
  }
}
