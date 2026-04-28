import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/page_window.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/features/reader/runtime/tile_key.dart';

import 'reader_tile_layer.dart';

class SlideReaderViewport extends StatefulWidget {
  const SlideReaderViewport({
    super.key,
    required this.runtime,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.onTapUp,
  });

  final ReaderRuntime runtime;
  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final GestureTapUpCallback? onTapUp;

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
  }

  @override
  void didUpdateWidget(covariant SlideReaderViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) {
      oldWidget.runtime.removeListener(_onRuntimeChanged);
      widget.runtime.addListener(_onRuntimeChanged);
      _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
      _resetViewport();
    } else if (oldWidget.style.pageMode != widget.style.pageMode) {
      _resetViewport();
    }
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_onRuntimeChanged);
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

  double _boundaryAdjustedDx(double nextDx, PageWindow window) {
    if (nextDx > 0 && window.prev == null) {
      return nextDx * 0.35;
    }
    if (nextDx < 0 && window.next == null) {
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
    final shouldAdvance =
        (distancePassed || velocityPassed) &&
        ((forward && widget.runtime.state.pageWindow?.next != null) ||
            (!forward && widget.runtime.state.pageWindow?.prev != null));
    _pendingDirection = shouldAdvance ? (forward ? 1 : -1) : 0;
    final target = shouldAdvance ? (forward ? -width : width) : 0.0;
    _animateTo(target);
  }

  TileKey _tileKey(TextPage tile) {
    return TileKey(
      chapterIndex: tile.chapterIndex,
      tileIndex: tile.pageIndex,
      startOffset: tile.startCharOffset,
      endOffset: tile.endCharOffset,
      layoutRevision: widget.runtime.state.layoutGeneration,
    );
  }

  Widget _buildTile(TextPage tile) {
    return GestureDetector(
      key: ValueKey<TileKey>(_tileKey(tile)),
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      child: ReaderTileLayer(
        tile: tile,
        tileKey: _tileKey(tile),
        style: widget.style,
        backgroundColor: widget.backgroundColor,
        textColor: widget.textColor,
        expand: true,
      ),
    );
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
        final prev =
            window.prev == null
                ? _buildEdgePlaceholder(message: '已經是第一頁')
                : _buildTile(window.prev!);
        final current = _buildTile(window.current);
        final next =
            window.next == null
                ? _buildEdgePlaceholder(message: '已經是最後一頁')
                : _buildTile(window.next!);

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
                  offset: Offset(_dragDx - width, 0),
                  child: SizedBox(width: width, child: prev),
                ),
                Transform.translate(
                  offset: Offset(_dragDx, 0),
                  child: SizedBox(width: width, child: current),
                ),
                Transform.translate(
                  offset: Offset(_dragDx + width, 0),
                  child: SizedBox(width: width, child: next),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
