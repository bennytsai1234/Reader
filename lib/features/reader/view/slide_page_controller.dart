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
  bool _scheduled = false;
  bool _disposed = false;
  int _clientAttachRetries = 0;

  SlidePageController(this.pageController);

  /// Schedule a jump to [pageIndex]. Multiple calls before the next frame
  /// coalesce — only the last target is used.
  void jumpTo(int pageIndex, {VoidCallback? onWillJump}) {
    _pendingJump = pageIndex;
    _pendingOnWillJump = onWillJump;
    if (_scheduled || _disposed) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final target = _pendingJump;
      final pendingOnWillJump = _pendingOnWillJump;
      if (_disposed || target == null) return;
      if (!pageController.hasClients) {
        if (_clientAttachRetries >= _maxClientAttachRetries) {
          _pendingJump = null;
          _pendingOnWillJump = null;
          return;
        }
        _clientAttachRetries += 1;
        jumpTo(target, onWillJump: pendingOnWillJump);
        return;
      }
      _clientAttachRetries = 0;
      _pendingJump = null;
      _pendingOnWillJump = null;
      if (pageController.position.isScrollingNotifier.value) {
        // User is actively scrolling — retry next frame
        jumpTo(target, onWillJump: pendingOnWillJump);
        return;
      }
      if (pageController.page?.round() != target) {
        pendingOnWillJump?.call();
        pageController.jumpToPage(target);
      }
    });
  }

  void dispose() {
    _disposed = true;
    _pendingJump = null;
    _pendingOnWillJump = null;
  }
}
