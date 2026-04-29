import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_highlight.dart';
import 'package:inkpage_reader/features/reader/runtime/tile_key.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_tile_layer.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_viewport_controller.dart';
import 'package:inkpage_reader/features/reader/viewport/tts_highlight_overlay_layer.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_location.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_page_window.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_runtime.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_state.dart';

typedef ReaderLocation = ReaderV2Location;
typedef PageWindow = ReaderV2PageWindow;
typedef ReaderRuntime = ReaderV2Runtime;
typedef ReaderMode = ReaderV2Mode;
typedef ReaderPhase = ReaderV2Phase;

class SlideReaderV2Viewport extends StatefulWidget {
  const SlideReaderV2Viewport({
    super.key,
    required this.runtime,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.onTapUp,
    this.controller,
    this.ttsHighlight,
  });

  final ReaderRuntime runtime;
  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final GestureTapUpCallback? onTapUp;
  final ReaderViewportController? controller;
  final ReaderTtsHighlight? ttsHighlight;

  @override
  State<SlideReaderV2Viewport> createState() => _SlideReaderV2ViewportState();
}

class _SlideReaderV2ViewportState extends State<SlideReaderV2Viewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late int _lastLayoutGeneration;
  double _dragDx = 0;
  double _rawDragDx = 0;
  double _lastAnimationValue = 0;
  int _pendingDirection = 0;
  bool _postFrameCapturePending = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController.unbounded(vsync: this)
      ..addListener(_onAnimationTick);
    _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
    widget.runtime.addListener(_onRuntimeChanged);
    widget.runtime.registerVisibleLocationCapture(
      this,
      _captureVisibleLocation,
    );
    widget.runtime.registerViewportRestore(this, _restoreToLocation);
    _attachController();
    _schedulePostFrameVisibleLocationCapture();
  }

  @override
  void didUpdateWidget(covariant SlideReaderV2Viewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) {
      oldWidget.runtime.unregisterVisibleLocationCapture(this);
      oldWidget.runtime.unregisterViewportRestore(this);
      oldWidget.runtime.removeListener(_onRuntimeChanged);
      widget.runtime.addListener(_onRuntimeChanged);
      widget.runtime.registerVisibleLocationCapture(
        this,
        _captureVisibleLocation,
      );
      widget.runtime.registerViewportRestore(this, _restoreToLocation);
      _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
      _resetViewport();
      _schedulePostFrameVisibleLocationCapture();
    } else if (oldWidget.style.pageMode != widget.style.pageMode) {
      _resetViewport();
    }
    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _attachController();
    }
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_onRuntimeChanged);
    widget.runtime.unregisterVisibleLocationCapture(this);
    widget.runtime.unregisterViewportRestore(this);
    _detachController(widget.controller);
    _slideController.dispose();
    super.dispose();
  }

  void _attachController() {
    widget.controller
      ?..moveToNextPage = _moveToNextPage
      ..moveToPrevPage = _moveToPrevPage
      ..ensureCharRangeVisible = _ensureCharRangeVisible;
  }

  void _detachController(ReaderViewportController? controller) {
    controller
      ?..moveToNextPage = null
      ..moveToPrevPage = null
      ..ensureCharRangeVisible = null;
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    final layoutChanged =
        _lastLayoutGeneration != widget.runtime.state.layoutGeneration;
    if (layoutChanged) {
      _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
      _resetViewport();
    }
    if (widget.runtime.state.phase == ReaderPhase.ready) {
      _schedulePostFrameVisibleLocationCapture();
    }
    setState(() {});
  }

  void _schedulePostFrameVisibleLocationCapture() {
    if (_postFrameCapturePending) return;
    _postFrameCapturePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameCapturePending = false;
      if (!mounted) return;
      widget.runtime.captureVisibleLocation();
    });
  }

  void _onAnimationTick() {
    final current = _slideController.value;
    final delta = current - _lastAnimationValue;
    _lastAnimationValue = current;
    if (delta == 0) return;
    setState(() {
      _dragDx += delta;
      _rawDragDx = _dragDx;
    });
  }

  void _resetViewport() {
    _slideController.stop();
    _slideController.value = 0;
    _lastAnimationValue = 0;
    _pendingDirection = 0;
    _dragDx = 0;
    _rawDragDx = 0;
  }

  bool _canMoveBackward(PageWindow window) {
    return window.prev != null && !window.prev!.isPlaceholder;
  }

  bool _canMoveForward(PageWindow window) {
    return window.next != null && !window.next!.isPlaceholder;
  }

  double _boundaryAdjustedDx(double nextDx, PageWindow window) {
    if (nextDx > 0 && !_canMoveBackward(window)) {
      return nextDx * 0.35;
    }
    if (nextDx < 0 && !_canMoveForward(window)) {
      return nextDx * 0.35;
    }
    return nextDx;
  }

  Future<void> _animateTo(
    double target, {
    Curve curve = Curves.easeOutCubic,
  }) async {
    _slideController.stop();
    _lastAnimationValue = 0;
    _slideController.value = 0;
    await _slideController.animateTo(
      target - _dragDx,
      duration: const Duration(milliseconds: 220),
      curve: curve,
    );
    _finalizeAnimation(target);
  }

  Future<bool> _moveToNextPage() {
    return _animateToAdjacentPage(forward: true);
  }

  Future<bool> _moveToPrevPage() {
    return _animateToAdjacentPage(forward: false);
  }

  Future<bool> _animateToAdjacentPage({required bool forward}) async {
    if (!mounted) return false;
    final width = context.size?.width ?? 0.0;
    if (!width.isFinite || width <= 0) {
      return widget.runtime.moveSlidePageAndSettle(forward: forward);
    }
    final window = widget.runtime.state.pageWindow;
    final neighbor = window == null ? null : (forward ? window.next : window.prev);
    if (neighbor == null) return false;
    if (neighbor.isPlaceholder) {
      return widget.runtime.moveSlidePageAndSettle(forward: forward);
    }
    _pendingDirection = forward ? 1 : -1;
    await _animateTo(forward ? -width : width);
    return mounted;
  }

  void _finalizeAnimation(double target) {
    final direction = _pendingDirection;
    final moved =
        direction == 0
            ? false
            : widget.runtime.moveSlidePageAndSettle(forward: direction > 0);
    setState(() {
      _slideController.value = 0;
      _lastAnimationValue = 0;
      _dragDx = 0;
      _rawDragDx = 0;
      _pendingDirection = 0;
    });
    if (target != 0 && moved) return;
  }

  void _handleDragStart(DragStartDetails details) {
    _slideController.stop();
    _slideController.value = 0;
    _lastAnimationValue = 0;
    _pendingDirection = 0;
    _rawDragDx = _dragDx;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final window = widget.runtime.state.pageWindow;
    if (window == null) return;
    setState(() {
      _rawDragDx += details.delta.dx;
      _dragDx = _boundaryAdjustedDx(_rawDragDx, window);
    });
  }

  void _handleDragEnd(DragEndDetails details, double width) {
    if (width <= 0) {
      _resetViewport();
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final forward = _rawDragDx < 0;
    final distancePassed = _rawDragDx.abs() > width * 0.25;
    final velocityPassed = velocity.abs() > 700;
    final window = widget.runtime.state.pageWindow;
    final neighbor =
        window == null ? null : (forward ? window.next : window.prev);
    if ((distancePassed || velocityPassed) &&
        window != null &&
        neighbor != null &&
        neighbor.isPlaceholder) {
      _pendingDirection = 0;
      if (forward) {
        widget.runtime.moveToNextTile();
      } else {
        widget.runtime.moveToPrevTile();
      }
      _animateTo(0.0);
      return;
    }
    final shouldAdvance =
        (distancePassed || velocityPassed) &&
        window != null &&
        (forward ? _canMoveForward(window) : _canMoveBackward(window));
    _pendingDirection = shouldAdvance ? (forward ? 1 : -1) : 0;
    final target = shouldAdvance ? (forward ? -width : width) : 0.0;
    _animateTo(target);
  }

  TileKey _tileKey(PageCache tile) {
    return TileKey.fromPageCache(
      tile,
      layoutRevision: widget.runtime.state.layoutGeneration,
    );
  }

  SlidePagePlacement _placementForPage({
    required TextPage page,
    required int pageSlot,
    required double width,
  }) {
    return SlidePagePlacement(
      page: widget.runtime.pageCacheFor(page),
      virtualLeft: width * pageSlot,
      pageSlot: pageSlot,
    );
  }

  Widget _buildTile(SlidePagePlacement placement) {
    final pageCache = placement.page;
    return GestureDetector(
      key: ValueKey<TileKey>(_tileKey(pageCache)),
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ReaderTileLayer(
            tile: pageCache,
            tileKey: _tileKey(pageCache),
            style: widget.style,
            backgroundColor: widget.backgroundColor,
            textColor: widget.textColor,
            expand: true,
            paintBackground: false,
          ),
          TtsHighlightOverlayLayer(
            tile: pageCache,
            style: widget.style,
            textColor: widget.textColor,
            highlight: widget.ttsHighlight,
          ),
        ],
      ),
    );
  }

  ReaderLocation? _captureVisibleLocation() {
    if (_dragDx.abs() > 0.5 ||
        _slideController.isAnimating ||
        widget.runtime.state.phase != ReaderPhase.ready) {
      return null;
    }
    final current = widget.runtime.state.pageWindow?.current;
    if (current == null || current.isPlaceholder) return null;
    final page = widget.runtime.pageCacheFor(current);
    if (page.lines.isEmpty) return null;
    final anchorLineY = _anchorOffsetInViewport();
    final anchorContentY = anchorLineY - widget.style.paddingTop;
    final contentY = anchorContentY.clamp(0.0, page.contentHeight).toDouble();
    final nearest = page.lineAtOrNearLocalY(page.localStartY + contentY);
    if (nearest == null) return null;
    return ReaderLocation(
      chapterIndex: page.chapterIndex,
      charOffset: nearest.startCharOffset,
      visualOffsetPx: anchorContentY - nearest.top,
    );
  }

  Future<bool> _ensureCharRangeVisible({
    required int chapterIndex,
    required int startCharOffset,
    required int endCharOffset,
  }) async {
    if (!mounted || widget.runtime.chapterCount <= 0) return false;
    final safeChapterIndex =
        chapterIndex.clamp(0, widget.runtime.chapterCount - 1).toInt();
    final targetOffset =
        (startCharOffset <= endCharOffset ? startCharOffset : endCharOffset);
    final safeTargetOffset = targetOffset < 0 ? 0 : targetOffset;
    final state = widget.runtime.state;
    if (state.phase != ReaderPhase.ready) return false;
    final window = state.pageWindow;
    if (window == null) return false;
    if (_pageContainsChar(
      window.current,
      chapterIndex: safeChapterIndex,
      charOffset: safeTargetOffset,
    )) {
      return true;
    }
    if (_pageContainsChar(
      window.next,
      chapterIndex: safeChapterIndex,
      charOffset: safeTargetOffset,
    )) {
      return _moveToAdjacentTtsPage(
        forward: true,
        chapterIndex: safeChapterIndex,
        charOffset: safeTargetOffset,
      );
    }
    if (_pageContainsChar(
      window.prev,
      chapterIndex: safeChapterIndex,
      charOffset: safeTargetOffset,
    )) {
      return _moveToAdjacentTtsPage(
        forward: false,
        chapterIndex: safeChapterIndex,
        charOffset: safeTargetOffset,
      );
    }
    return _jumpToTtsPage(
      chapterIndex: safeChapterIndex,
      charOffset: safeTargetOffset,
    );
  }

  bool _pageContainsChar(
    TextPage? page, {
    required int chapterIndex,
    required int charOffset,
  }) {
    if (page == null || page.isPlaceholder) return false;
    return page.chapterIndex == chapterIndex &&
        page.containsCharOffset(charOffset);
  }

  Future<bool> _moveToAdjacentTtsPage({
    required bool forward,
    required int chapterIndex,
    required int charOffset,
  }) async {
    _resetViewport();
    final moved = widget.runtime.moveSlidePageAndSettle(
      forward: forward,
      settledLocation: ReaderLocation(
        chapterIndex: chapterIndex,
        charOffset: charOffset,
      ),
    );
    if (!moved || !mounted) return false;
    final current = widget.runtime.state.pageWindow?.current;
    return _pageContainsChar(
      current,
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    );
  }

  Future<bool> _jumpToTtsPage({
    required int chapterIndex,
    required int charOffset,
  }) async {
    final layoutGeneration = widget.runtime.state.layoutGeneration;
    _resetViewport();
    await widget.runtime.jumpToLocation(
      ReaderLocation(chapterIndex: chapterIndex, charOffset: charOffset),
      immediateSave: false,
    );
    if (!mounted ||
        widget.runtime.state.layoutGeneration != layoutGeneration ||
        widget.runtime.state.phase != ReaderPhase.ready) {
      return false;
    }
    final current = widget.runtime.state.pageWindow?.current;
    if (!_pageContainsChar(
      current,
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    )) {
      return false;
    }
    widget.runtime.settleCurrentSlidePage(
      settledLocation: ReaderLocation(
        chapterIndex: chapterIndex,
        charOffset: charOffset,
      ),
    );
    return true;
  }

  Future<bool> _restoreToLocation(ReaderLocation location) async {
    if (!mounted || widget.runtime.state.phase != ReaderPhase.ready) {
      return false;
    }
    _resetViewport();
    await Future<void>.delayed(Duration.zero);
    return mounted && _captureVisibleLocation() != null;
  }

  double _screenXFor({
    required int pageSlot,
    required double width,
    SlidePagePlacement? placement,
  }) {
    final pageOffsetX = -_dragDx;
    return placement?.screenX(pageOffsetX) ?? width * pageSlot - pageOffsetX;
  }

  double _anchorOffsetInViewport() {
    final viewportHeight = widget.runtime.state.layoutSpec.viewportSize.height;
    return (viewportHeight * 0.2).clamp(24.0, 120.0).toDouble();
  }

  Widget _buildEdgePlaceholder({required String message}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: widget.textColor.withValues(alpha: 0.7),
              fontSize: widget.style.fontSize,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.runtime.state;
    final window = state.pageWindow;
    if (state.phase != ReaderPhase.ready || window == null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onTapUp,
        child: ColoredBox(
          color: widget.backgroundColor,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.textColor.withValues(alpha: 0.35),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : widget.runtime.state.layoutSpec.viewportSize.height;
        final prevPlacement =
            window.prev == null
                ? null
                : _placementForPage(
                  page: window.prev!,
                  pageSlot: -1,
                  width: width,
                );
        final currentPlacement = _placementForPage(
          page: window.current,
          pageSlot: 0,
          width: width,
        );
        final nextPlacement =
            window.next == null
                ? null
                : _placementForPage(
                  page: window.next!,
                  pageSlot: 1,
                  width: width,
                );
        final prev =
            window.prev == null
                ? _buildEdgePlaceholder(message: '已經是第一頁')
                : _buildTile(prevPlacement!);
        final current = _buildTile(currentPlacement);
        final next =
            window.next == null
                ? _buildEdgePlaceholder(message: '已經是最後一頁')
                : _buildTile(nextPlacement!);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: widget.onTapUp,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: (details) => _handleDragEnd(details, width),
          onHorizontalDragCancel: _resetViewport,
          child: ColoredBox(
            color: widget.backgroundColor,
            child: ClipRect(
              child: Stack(
                children: [
                  Transform.translate(
                    offset: Offset(
                      _screenXFor(
                        pageSlot: -1,
                        width: width,
                        placement: prevPlacement,
                      ),
                      0,
                    ),
                    child: SizedBox(width: width, height: height, child: prev),
                  ),
                  Transform.translate(
                    offset: Offset(
                      _screenXFor(
                        pageSlot: 0,
                        width: width,
                        placement: currentPlacement,
                      ),
                      0,
                    ),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: current,
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(
                      _screenXFor(
                        pageSlot: 1,
                        width: width,
                        placement: nextPlacement,
                      ),
                      0,
                    ),
                    child: SizedBox(width: width, height: height, child: next),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
