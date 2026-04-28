import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_highlight.dart';
import 'package:inkpage_reader/features/reader/runtime/page_window.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/features/reader/runtime/tile_key.dart';

import 'reader_tile_layer.dart';
import 'tts_highlight_overlay_layer.dart';

class SlideReaderViewport extends StatefulWidget {
  const SlideReaderViewport({
    super.key,
    required this.runtime,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.onTapUp,
    this.ttsHighlight,
  });

  final ReaderRuntime runtime;
  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final GestureTapUpCallback? onTapUp;
  final ReaderTtsHighlight? ttsHighlight;

  @override
  State<SlideReaderViewport> createState() => _SlideReaderViewportState();
}

class _SlideReaderViewportState extends State<SlideReaderViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late int _lastLayoutGeneration;
  double _dragDx = 0;
  double _lastAnimationValue = 0;
  int _pendingDirection = 0;

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
  }

  @override
  void didUpdateWidget(covariant SlideReaderViewport oldWidget) {
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
    } else if (oldWidget.style.pageMode != widget.style.pageMode) {
      _resetViewport();
    }
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_onRuntimeChanged);
    widget.runtime.unregisterVisibleLocationCapture(this);
    widget.runtime.unregisterViewportRestore(this);
    _slideController.dispose();
    super.dispose();
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    final layoutChanged =
        _lastLayoutGeneration != widget.runtime.state.layoutGeneration;
    if (layoutChanged) {
      _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
      _resetViewport();
    }
    setState(() {});
  }

  void _onAnimationTick() {
    final current = _slideController.value;
    final delta = current - _lastAnimationValue;
    _lastAnimationValue = current;
    if (delta == 0) return;
    setState(() {
      _dragDx += delta;
    });
  }

  void _resetViewport() {
    _slideController.stop();
    _slideController.value = 0;
    _lastAnimationValue = 0;
    _pendingDirection = 0;
    _dragDx = 0;
  }

  bool _canMoveBackward(PageWindow window) {
    return window.prev != null;
  }

  bool _canMoveForward(PageWindow window) {
    return window.next != null;
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

  void _finalizeAnimation(double target) {
    final direction = _pendingDirection;
    final moved =
        direction == 0
            ? false
            : (direction > 0
                ? widget.runtime.moveToNextTile()
                : widget.runtime.moveToPrevTile());
    setState(() {
      _slideController.value = 0;
      _lastAnimationValue = 0;
      _dragDx = 0;
      _pendingDirection = 0;
    });
    if (target != 0 && moved) {
      widget.runtime.handleSlidePageSettled(
        widget.runtime.state.pageWindow!.current,
      );
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _slideController.stop();
    _slideController.value = 0;
    _lastAnimationValue = 0;
    _pendingDirection = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final window = widget.runtime.state.pageWindow;
    if (window == null) return;
    setState(() {
      _dragDx = _boundaryAdjustedDx(_dragDx + details.delta.dx, window);
    });
  }

  void _handleDragEnd(DragEndDetails details, double width) {
    if (width <= 0) {
      _resetViewport();
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final forward = _dragDx < 0;
    final distancePassed = _dragDx.abs() > width * 0.25;
    final velocityPassed = velocity.abs() > 700;
    final window = widget.runtime.state.pageWindow;
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
    final anchorY = _anchorOffsetInViewport();
    final contentY =
        (anchorY - widget.style.paddingTop)
            .clamp(0.0, page.contentHeight)
            .toDouble();
    final nearest = page.lineAtOrNearLocalY(page.localStartY + contentY);
    if (nearest == null) return null;
    return ReaderLocation(
      chapterIndex: page.chapterIndex,
      charOffset: nearest.startCharOffset,
      visualOffsetPx: contentY - nearest.top,
    );
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
                  child: SizedBox(width: width, height: height, child: current),
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
        );
      },
    );
  }
}
