import 'package:flutter/widgets.dart';

/// Encapsulates PageView jump logic with deduplication and debouncing.
///
/// Replaces the manual `_deferredPendingJump` + `_schedulePendingJump()`
/// pattern previously in [ReaderPage].
class SlidePageController {
  final PageController pageController;
  static const int _maxClientAttachRetries = 8;
  int? _pendingJump;
  VoidCallback? _pendingOnWillJump;
  VoidCallback? _pendingOnAlreadyAtTarget;
  bool _scheduled = false;
  bool _disposed = false;
  int _clientAttachRetries = 0;

  SlidePageController(this.pageController);

  /// Schedule a jump to [pageIndex]. Multiple calls before the next frame
  /// coalesce — only the last target is used.
  void jumpTo(
    int pageIndex, {
    VoidCallback? onWillJump,
    VoidCallback? onAlreadyAtTarget,
  }) {
    _pendingJump = pageIndex;
    _pendingOnWillJump = onWillJump;
    _pendingOnAlreadyAtTarget = onAlreadyAtTarget;
    if (_scheduled || _disposed) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final target = _pendingJump;
      final pendingOnWillJump = _pendingOnWillJump;
      final pendingOnAlreadyAtTarget = _pendingOnAlreadyAtTarget;
      if (_disposed || target == null) return;
      if (!pageController.hasClients) {
        if (_clientAttachRetries >= _maxClientAttachRetries) {
          _pendingJump = null;
          _pendingOnWillJump = null;
          _pendingOnAlreadyAtTarget = null;
          return;
        }
        _clientAttachRetries += 1;
        jumpTo(
          target,
          onWillJump: pendingOnWillJump,
          onAlreadyAtTarget: pendingOnAlreadyAtTarget,
        );
        return;
      }
      _clientAttachRetries = 0;
      _pendingJump = null;
      _pendingOnWillJump = null;
      _pendingOnAlreadyAtTarget = null;
      if (pageController.position.isScrollingNotifier.value) {
        // User is actively scrolling — retry next frame
        jumpTo(
          target,
          onWillJump: pendingOnWillJump,
          onAlreadyAtTarget: pendingOnAlreadyAtTarget,
        );
        return;
      }
      final currentPage = pageController.page?.round();
      if (currentPage == target) {
        pendingOnAlreadyAtTarget?.call();
        return;
      }
      pendingOnWillJump?.call();
      pageController.jumpToPage(target);
    });
  }

  void dispose() {
    _disposed = true;
    _pendingJump = null;
    _pendingOnWillJump = null;
    _pendingOnAlreadyAtTarget = null;
  }
}
