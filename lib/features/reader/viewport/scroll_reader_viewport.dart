import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';

import 'reader_painter.dart';

class ScrollReaderViewport extends StatefulWidget {
  const ScrollReaderViewport({
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
  State<ScrollReaderViewport> createState() => _ScrollReaderViewportState();
}

class _ScrollReaderViewportState extends State<ScrollReaderViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flingController;
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  double _pageOffset = 0;
  double _lastFlingPosition = 0;

  @override
  void initState() {
    super.initState();
    _flingController =
        AnimationController.unbounded(vsync: this)
          ..addListener(_onFlingTick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed ||
                status == AnimationStatus.dismissed) {
              _commitVisibleLocation();
            }
          });
    widget.runtime.addListener(_onRuntimeChanged);
  }

  @override
  void didUpdateWidget(covariant ScrollReaderViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) {
      oldWidget.runtime.removeListener(_onRuntimeChanged);
      widget.runtime.addListener(_onRuntimeChanged);
      _pageOffset = 0;
    }
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_onRuntimeChanged);
    _flingController.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    if (widget.runtime.state.phase == ReaderPhase.layingOut ||
        widget.runtime.state.phase == ReaderPhase.switchingMode) {
      _pageOffset = 0;
    }
    setState(() {});
    _markNeedsPaint();
  }

  void _onFlingTick() {
    final position = _flingController.value;
    final delta = position - _lastFlingPosition;
    _lastFlingPosition = position;
    _applyDelta(delta);
  }

  void _applyDelta(double delta) {
    final window = widget.runtime.state.pageWindow;
    if (window == null) return;
    _pageOffset += delta;
    _normalizePageWindow();
    _markNeedsPaint();
  }

  void _normalizePageWindow() {
    var window = widget.runtime.state.pageWindow;
    if (window == null) return;
    while (_pageOffset <= -window!.current.height) {
      final oldHeight = window.current.height;
      if (!widget.runtime.moveToNextPage()) {
        _pageOffset = _pageOffset.clamp(-oldHeight * 0.25, 0.0).toDouble();
        return;
      }
      _pageOffset += oldHeight;
      window = widget.runtime.state.pageWindow;
      if (window == null) return;
    }
    while (_pageOffset > 0) {
      if (!widget.runtime.moveToPrevPage()) {
        _pageOffset = 0;
        return;
      }
      window = widget.runtime.state.pageWindow;
      if (window == null) return;
      _pageOffset -= window.current.height;
    }
  }

  void _startFling(double velocity) {
    if (velocity.abs() < 80) {
      _commitVisibleLocation();
      return;
    }
    _lastFlingPosition = 0;
    _flingController.value = 0;
    unawaited(
      _flingController.animateWith(
        ClampingScrollSimulation(
          position: 0,
          velocity: velocity,
          friction: 0.018,
        ),
      ),
    );
  }

  void _commitVisibleLocation() {
    if (!mounted) return;
    final height = context.size?.height ?? 0;
    if (height <= 0) return;
    final location = widget.runtime.resolveVisibleLocation(
      pageOffset: _pageOffset,
      viewportHeight: height,
    );
    widget.runtime.updateVisibleLocation(location);
  }

  void _markNeedsPaint() {
    _repaint.value += 1;
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
            child:
                state.phase == ReaderPhase.error
                    ? Text(
                      state.errorMessage ?? 'Reader error',
                      style: TextStyle(color: widget.textColor),
                    )
                    : CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.textColor.withValues(alpha: 0.35),
                    ),
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      onVerticalDragStart: (_) {
        _flingController.stop();
      },
      onVerticalDragUpdate: (details) {
        _applyDelta(details.delta.dy);
      },
      onVerticalDragEnd: (details) {
        _startFling(details.primaryVelocity ?? 0);
      },
      onVerticalDragCancel: () {
        _commitVisibleLocation();
      },
      child: RepaintBoundary(
        child: CustomPaint(
          painter: ReaderPainter(
            backgroundColor: widget.backgroundColor,
            textColor: widget.textColor,
            style: widget.style,
            pageWindow: window,
            pageOffset: _pageOffset,
            repaint: _repaint,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
