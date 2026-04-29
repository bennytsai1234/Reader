import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader_v2/features/tts/reader_v2_tts_highlight.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_style.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_page_cache.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_tile_key.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_tile_layer.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_tts_highlight_overlay_layer.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_location.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_runtime.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_state.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_chapter_page_cache_manager.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_infinite_segment_strip.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_position_tracker.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_viewport_controller.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_visible_page_calculator.dart';

class ScrollReaderV2Viewport extends StatefulWidget {
  const ScrollReaderV2Viewport({
    super.key,
    required this.runtime,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.onTapUp,
    this.controller,
    this.ttsHighlight,
  });

  final ReaderV2Runtime runtime;
  final Color backgroundColor;
  final Color textColor;
  final ReaderV2Style style;
  final GestureTapUpCallback? onTapUp;
  final ReaderV2ViewportController? controller;
  final ReaderV2TtsHighlight? ttsHighlight;

  @override
  State<ScrollReaderV2Viewport> createState() => _ScrollReaderV2ViewportState();
}

class _ScrollReaderV2ViewportState extends State<ScrollReaderV2Viewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scrollAnimation;
  late ReaderV2ChapterPageCacheManager _cacheManager;
  late ReaderV2VisiblePageCalculator _visiblePages;
  final ReaderV2InfiniteSegmentStrip _strip = ReaderV2InfiniteSegmentStrip();
  final ReaderV2PositionTracker _positionTracker =
      const ReaderV2PositionTracker();

  ReaderV2Location? _lastReportedLocation;
  ReaderV2Location? _lastSyncedLocation;
  int? _currentChapterIndex;
  int _lastLayoutGeneration = 0;
  int _windowRequestId = 0;
  double _readingY = 0.0;
  double _lastAnimationValue = 0.0;
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);
  bool _initialJumpCompleted = false;
  bool _isDragging = false;
  bool _capturingVisibleLocation = false;
  bool _visibleLocationCaptureFramePending = false;
  bool _shiftWindowAgainRequested = false;
  Future<void>? _shiftWindowTask;
  Future<void> _viewportCommandTail = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _configureViewportModel();
    _scrollAnimation = AnimationController.unbounded(vsync: this)
      ..addListener(_handleScrollAnimationTick);
    _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
    _lastReportedLocation = widget.runtime.state.visibleLocation;
    widget.runtime.addListener(_onRuntimeChanged);
    widget.runtime.registerVisibleLocationCapture(
      this,
      _captureVisibleLocation,
    );
    widget.runtime.registerViewportRestore(this, _restoreToLocation);
    _attachController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_primeAndSyncToRuntimeLocation(force: true));
    });
  }

  void _configureViewportModel() {
    _cacheManager = ReaderV2ChapterPageCacheManager(
      runtime: widget.runtime,
      pageExtent: _scrollPageExtent,
    );
    _visiblePages = ReaderV2VisiblePageCalculator(
      cacheManager: _cacheManager,
      strip: _strip,
    );
  }

  @override
  void didUpdateWidget(covariant ScrollReaderV2Viewport oldWidget) {
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
      _configureViewportModel();
      _resetLoadedState();
      _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
      _lastReportedLocation = widget.runtime.state.visibleLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_primeAndSyncToRuntimeLocation(force: true));
      });
    } else if (oldWidget.style != widget.style) {
      _resetLoadedState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_primeAndSyncToRuntimeLocation(force: true));
      });
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
    _scrollAnimation
      ..removeListener(_handleScrollAnimationTick)
      ..dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _attachController() {
    widget.controller
      ?..scrollBy = _scrollBy
      ..animateBy = _animateBy
      ..moveToNextPage = null
      ..moveToPrevPage = null
      ..ensureCharRangeVisible = _ensureCharRangeVisible;
  }

  void _detachController(ReaderV2ViewportController? controller) {
    controller
      ?..scrollBy = null
      ..animateBy = null
      ..moveToNextPage = null
      ..moveToPrevPage = null
      ..ensureCharRangeVisible = null;
  }

  void _resetLoadedState() {
    _scrollAnimation.stop();
    _cacheManager.invalidateAll(reason: 'viewport reset');
    _strip.clear();
    _windowRequestId += 1;
    _lastSyncedLocation = null;
    _currentChapterIndex = null;
    _setReadingY(0.0);
    _lastAnimationValue = 0.0;
    _initialJumpCompleted = false;
  }

  void _onRuntimeChanged() {
    if (!mounted) return;
    final state = widget.runtime.state;
    final layoutChanged = _lastLayoutGeneration != state.layoutGeneration;
    if (layoutChanged) {
      _lastLayoutGeneration = state.layoutGeneration;
      _resetLoadedState();
    }

    if (state.phase == ReaderV2Phase.layingOut ||
        state.phase == ReaderV2Phase.switchingMode) {
      setState(() {});
      return;
    }

    if (_capturingVisibleLocation) {
      setState(() {});
      return;
    }

    final locationChanged = state.visibleLocation != _lastReportedLocation;
    if (layoutChanged || locationChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_primeAndSyncToRuntimeLocation(force: layoutChanged));
      });
    }
    setState(() {});
  }

  double _viewportHeight() {
    final height = widget.runtime.state.layoutSpec.viewportSize.height;
    return height.isFinite && height > 0 ? height : 1.0;
  }

  double _anchorOffsetInViewport() =>
      widget.runtime.state.layoutSpec.anchorOffsetInViewport;

  double _shiftThreshold() {
    return math.min(120.0, _viewportHeight() * 0.2);
  }

  double _fullPageHeight(ReaderV2PageCache page) {
    return page.height.isFinite && page.height > 0 ? page.height : 1.0;
  }

  double _scrollPageExtent(ReaderV2PageCache page) {
    final fullHeight = _fullPageHeight(page);
    if (page.lines.isEmpty) return fullHeight;

    final contentBottom = page.lines.fold<double>(
      0.0,
      (bottom, line) => math.max(bottom, line.bottom),
    );
    final visualHeight =
        widget.style.paddingTop + contentBottom + widget.style.paddingBottom;
    final minHeight = math.min(
      fullHeight,
      math.max(120.0, _viewportHeight() * 0.3),
    );
    return visualHeight.clamp(minHeight, fullHeight).toDouble();
  }

  double _forwardWindowExtent() =>
      _viewportHeight() * 1.5 + _anchorOffsetInViewport();

  double _backwardWindowExtent() => _viewportHeight() * 1.25;

  int _safeChapterIndex(int chapterIndex) {
    final chapterCount = widget.runtime.chapterCount;
    if (chapterCount <= 0) return 0;
    return chapterIndex.clamp(0, chapterCount - 1).toInt();
  }

  Future<bool> _tryEnsureChapterLoaded(
    int chapterIndex, {
    bool Function()? isCurrent,
  }) async {
    if (widget.runtime.chapterCount <= 0) return false;
    final safeChapterIndex = _safeChapterIndex(chapterIndex);
    return _cacheManager.ensureChapterLoaded(
      safeChapterIndex,
      isCurrent: () => mounted && (isCurrent?.call() ?? true),
    );
  }

  Future<void> _ensureWindowAround(
    int chapterIndex, {
    bool Function()? isCurrent,
  }) async {
    if (widget.runtime.chapterCount <= 0) return;
    final requestId = ++_windowRequestId;
    bool stillCurrent() {
      return mounted &&
          requestId == _windowRequestId &&
          (isCurrent?.call() ?? true);
    }

    final center = _safeChapterIndex(chapterIndex);
    final window = await _cacheManager.ensureWindowAround(
      centerChapterIndex: center,
      backwardExtent: _backwardWindowExtent(),
      forwardExtent: _forwardWindowExtent(),
      isCurrent: stillCurrent,
    );
    if (!stillCurrent() || window == null) return;

    _placeWindowInStrip(window);
    _currentChapterIndex = window.center.chapterIndex;
    setState(() {});
  }

  void _placeWindowInStrip(ReaderV2ChapterPageCacheWindow window) {
    final center = window.center;
    final centerTop = _strip.chapterTop(center.chapterIndex) ?? 0.0;
    _strip.placeChapter(
      chapterIndex: center.chapterIndex,
      startY: centerTop,
      height: center.extent,
    );

    var backwardTop = centerTop;
    for (final chapter in window.previous) {
      backwardTop -= chapter.extent;
      _strip.placeChapter(
        chapterIndex: chapter.chapterIndex,
        startY: backwardTop,
        height: chapter.extent,
      );
    }

    var forwardTop = centerTop + center.extent;
    for (final chapter in window.next) {
      _strip.placeChapter(
        chapterIndex: chapter.chapterIndex,
        startY: forwardTop,
        height: chapter.extent,
      );
      forwardTop += chapter.extent;
    }

    _strip.retain(window.retainedChapterIndexes);
  }

  Future<void> _primeAndSyncToRuntimeLocation({bool force = false}) async {
    final location = widget.runtime.state.visibleLocation.normalized(
      chapterCount: widget.runtime.chapterCount,
    );
    final layoutGeneration = widget.runtime.state.layoutGeneration;
    bool stillAtLocation() {
      if (!mounted) return false;
      final currentLocation = widget.runtime.state.visibleLocation.normalized(
        chapterCount: widget.runtime.chapterCount,
      );
      return widget.runtime.state.layoutGeneration == layoutGeneration &&
          currentLocation == location;
    }

    await _ensureWindowAround(
      location.chapterIndex,
      isCurrent: stillAtLocation,
    );
    if (!stillAtLocation()) return;
    if (!force && _initialJumpCompleted && _lastSyncedLocation == location) {
      return;
    }

    final target = _readingYForLocation(location);
    if (target != null) {
      _setReadingY(_clampReadingY(target));
    }
    _initialJumpCompleted = true;
    _lastSyncedLocation = location;
    final captured = widget.runtime.captureVisibleLocation();
    _lastReportedLocation = captured ?? location;
    if (mounted) setState(() {});
  }

  double? _readingYForLocation(ReaderV2Location location) {
    final chapterIndex = _safeChapterIndex(location.chapterIndex);
    return _positionTracker.readingYForLocation(
      location: location.copyWith(chapterIndex: chapterIndex),
      cacheManager: _cacheManager,
      strip: _strip,
      anchorOffset: _anchorOffsetInViewport(),
      style: widget.style,
    );
  }

  double _clampReadingY(double target) {
    final bounds = _strip.scrollBounds(
      viewportHeight: _viewportHeight(),
      anchorOffset: _anchorOffsetInViewport(),
    );
    if (bounds == null) return target;
    return target.clamp(bounds.min, bounds.max).toDouble();
  }

  ReaderV2Location? _captureVisibleLocation() {
    if (!_initialJumpCompleted || widget.runtime.chapterCount <= 0) {
      return null;
    }
    return _positionTracker.captureVisibleLocation(
      calculator: _visiblePages,
      cacheManager: _cacheManager,
      strip: _strip,
      readingY: _readingY,
      anchorOffset: _anchorOffsetInViewport(),
      style: widget.style,
    );
  }

  Future<bool> _restoreToLocation(ReaderV2Location location) async {
    if (!mounted || widget.runtime.chapterCount <= 0) return false;
    _scrollAnimation.stop();
    _isDragging = false;
    final layoutGeneration = widget.runtime.state.layoutGeneration;
    bool stillCurrent() {
      return mounted &&
          widget.runtime.state.layoutGeneration == layoutGeneration;
    }

    await _ensureWindowAround(location.chapterIndex, isCurrent: stillCurrent);
    if (!stillCurrent()) return false;
    final target = _readingYForLocation(location);
    if (target == null) return false;
    _setReadingY(_clampReadingY(target));
    _initialJumpCompleted = true;
    _lastSyncedLocation = location;
    _lastReportedLocation = location;
    if (mounted) setState(() {});
    await Future<void>.delayed(Duration.zero);
    return mounted && _captureVisibleLocation() != null;
  }

  void _captureAndReportVisibleLocation() {
    _capturingVisibleLocation = true;
    final ReaderV2Location? location;
    try {
      location = widget.runtime.captureVisibleLocation();
    } finally {
      _capturingVisibleLocation = false;
    }
    if (location != null) _lastReportedLocation = location;
  }

  bool _applyReadingDelta(double delta, {bool scheduleShift = true}) {
    if (delta == 0 || !_visiblePages.hasPages) return false;
    final nextReadingY = _clampReadingY(_readingY + delta);
    if ((nextReadingY - _readingY).abs() < 0.01) {
      if (scheduleShift) unawaited(_requestShiftWindowForAnchor());
      return false;
    }
    _setReadingY(nextReadingY);
    _scheduleVisibleLocationCapture();
    if (scheduleShift) unawaited(_requestShiftWindowForAnchor());
    return true;
  }

  void _setReadingY(double value) {
    _readingY = value;
    if (_scrollOffset.value != value) {
      _scrollOffset.value = value;
    }
  }

  void _scheduleVisibleLocationCapture() {
    if (_visibleLocationCaptureFramePending) return;
    _visibleLocationCaptureFramePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibleLocationCaptureFramePending = false;
      if (!mounted) return;
      _captureAndReportVisibleLocation();
    });
  }

  Future<void> _requestShiftWindowForAnchor() {
    final existing = _shiftWindowTask;
    if (existing != null) {
      _shiftWindowAgainRequested = true;
      return existing;
    }
    final task = _runCoalescedWindowShift();
    _shiftWindowTask = task;
    task.whenComplete(() {
      if (identical(_shiftWindowTask, task)) {
        _shiftWindowTask = null;
      }
    });
    return task;
  }

  Future<void> _runCoalescedWindowShift() async {
    do {
      _shiftWindowAgainRequested = false;
      await _shiftWindowForAnchor();
    } while (mounted && _shiftWindowAgainRequested);
  }

  Future<void> _shiftWindowForAnchor() async {
    final current = _currentChapterIndex;
    if (current == null) return;
    final anchorWorldY = _readingY + _anchorOffsetInViewport();
    final placement = _visiblePages.placementAtWorldY(anchorWorldY);
    if (placement == null) return;
    final targetChapter = placement.page.chapterIndex;
    if (targetChapter == current) return;
    if (!_shouldShiftWindow(current, targetChapter, anchorWorldY)) return;
    final layoutGeneration = widget.runtime.state.layoutGeneration;
    bool anchorStillTargetsShift() {
      if (!mounted ||
          widget.runtime.state.layoutGeneration != layoutGeneration) {
        return false;
      }
      final latestAnchorWorldY = _readingY + _anchorOffsetInViewport();
      final latestPlacement = _visiblePages.placementAtWorldY(
        latestAnchorWorldY,
      );
      return latestPlacement?.page.chapterIndex == targetChapter;
    }

    await _ensureWindowAround(
      targetChapter,
      isCurrent: anchorStillTargetsShift,
    );
  }

  bool _shouldShiftWindow(
    int currentChapter,
    int targetChapter,
    double anchorWorldY,
  ) {
    final targetTop = _strip.chapterTop(targetChapter);
    final currentTop = _strip.chapterTop(currentChapter);
    if (targetTop == null || currentTop == null) return false;
    final threshold = _shiftThreshold();
    if (targetChapter > currentChapter) {
      if (_isNearWindowEdge(forward: true, threshold: threshold)) return true;
      return anchorWorldY - targetTop >= threshold;
    }
    if (_isNearWindowEdge(forward: false, threshold: threshold)) return true;
    return currentTop - anchorWorldY >= threshold;
  }

  bool _isNearWindowEdge({required bool forward, required double threshold}) {
    return _strip.isNearEdge(
      forward: forward,
      readingY: _readingY,
      threshold: threshold,
      viewportHeight: _viewportHeight(),
      anchorOffset: _anchorOffsetInViewport(),
    );
  }

  void _handleScrollAnimationTick() {
    final current = _scrollAnimation.value;
    final delta = current - _lastAnimationValue;
    _lastAnimationValue = current;
    if (delta == 0) return;
    final moved = _applyReadingDelta(delta);
    if (!moved) {
      _scrollAnimation.stop();
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _isDragging = true;
    _scrollAnimation.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _applyReadingDelta(-details.delta.dy);
  }

  void _handleDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = -(details.primaryVelocity ?? 0.0);
    if (velocity.abs() < 50) {
      unawaited(_handleScrollSettled());
      return;
    }
    _startFling(velocity);
  }

  void _handleDragCancel() {
    _isDragging = false;
    unawaited(_handleScrollSettled());
  }

  void _startFling(double velocity) {
    _scrollAnimation.stop();
    _scrollAnimation.value = _readingY;
    _lastAnimationValue = _readingY;
    final simulation = ClampingScrollSimulation(
      position: _readingY,
      velocity: velocity,
    );
    unawaited(
      _scrollAnimation.animateWith(simulation).whenComplete(() {
        if (mounted) unawaited(_handleScrollSettled());
      }),
    );
  }

  Future<bool> _scrollBy(double delta) {
    return _enqueueViewportCommand(() => _scrollByNow(delta));
  }

  Future<bool> _scrollByNow(double delta) async {
    if (!mounted || delta == 0 || !_visiblePages.hasPages) return false;
    _scrollAnimation.stop();
    _isDragging = false;
    final moved = _applyReadingDelta(delta, scheduleShift: false);
    if (!moved) return false;
    await _requestShiftWindowForAnchor();
    await _handleScrollSettled();
    return mounted;
  }

  Future<bool> _animateBy(double delta) {
    return _enqueueViewportCommand(() => _animateByNow(delta));
  }

  Future<bool> _animateByNow(double delta) {
    if (delta == 0) return Future<bool>.value(false);
    return _animateToReadingY(_readingY + delta);
  }

  Future<bool> _enqueueViewportCommand(Future<bool> Function() command) {
    if (!mounted) return Future<bool>.value(false);
    final completer = Completer<bool>();
    _viewportCommandTail = _viewportCommandTail
        .catchError((_) {})
        .then((_) async {
          if (!mounted) return false;
          return command();
        })
        .then(
          completer.complete,
          onError: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted)
              completer.completeError(error, stackTrace);
          },
        );
    return completer.future;
  }

  Future<bool> _animateToReadingY(double target) async {
    if (!mounted || !_visiblePages.hasPages) return false;
    final start = _readingY;
    final clampedTarget = _clampReadingY(target);
    if ((clampedTarget - start).abs() < 0.01) return false;
    _scrollAnimation.stop();
    _isDragging = false;
    _scrollAnimation.value = _readingY;
    _lastAnimationValue = _readingY;
    try {
      await _scrollAnimation
          .animateTo(
            clampedTarget,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          )
          .orCancel;
    } on TickerCanceled {
      if (!mounted) return false;
    }
    if (!mounted) return false;
    final moved = (_readingY - start).abs() >= 0.01;
    if (!moved) return false;
    await _requestShiftWindowForAnchor();
    await _handleScrollSettled();
    return mounted;
  }

  Future<bool> _ensureCharRangeVisible({
    required int chapterIndex,
    required int startCharOffset,
    required int endCharOffset,
  }) {
    return _enqueueViewportCommand(
      () => _ensureCharRangeVisibleNow(
        chapterIndex: chapterIndex,
        startCharOffset: startCharOffset,
        endCharOffset: endCharOffset,
      ),
    );
  }

  Future<bool> _ensureCharRangeVisibleNow({
    required int chapterIndex,
    required int startCharOffset,
    required int endCharOffset,
  }) async {
    if (!mounted || widget.runtime.chapterCount <= 0) return false;
    final safeChapterIndex = _safeChapterIndex(chapterIndex);
    final layoutGeneration = widget.runtime.state.layoutGeneration;
    bool stillCurrent() {
      return mounted &&
          widget.runtime.state.layoutGeneration == layoutGeneration;
    }

    final ready = await _tryEnsureChapterLoaded(
      safeChapterIndex,
      isCurrent: stillCurrent,
    );
    if (!stillCurrent() || !ready) return false;
    await _ensureWindowAround(safeChapterIndex, isCurrent: stillCurrent);
    if (!stillCurrent()) return false;

    final chapter = _cacheManager.chapterAt(safeChapterIndex);
    final chapterTop = _strip.chapterTop(safeChapterIndex);
    if (chapter == null || chapterTop == null) return false;
    final rangeStart =
        startCharOffset <= endCharOffset ? startCharOffset : endCharOffset;
    final rangeEnd =
        startCharOffset <= endCharOffset ? endCharOffset : startCharOffset;
    final rangeLines = chapter.layout.linesForRange(rangeStart, rangeEnd);
    final fallback = chapter.layout.lineForCharOffset(rangeStart);
    final first = rangeLines.isEmpty ? fallback : rangeLines.first;
    final last = rangeLines.isEmpty ? fallback : rangeLines.last;
    if (first == null || last == null) return false;

    final firstTop = _positionTracker.lineWorldTop(
      chapter: chapter,
      chapterTop: chapterTop,
      line: first,
      style: widget.style,
    );
    final lastBottom = _positionTracker.lineWorldBottom(
      chapter: chapter,
      chapterTop: chapterTop,
      line: last,
      style: widget.style,
    );
    if (firstTop == null || lastBottom == null) return false;

    final viewportHeight = _viewportHeight();
    final topPadding = math.min(80.0, viewportHeight * 0.12);
    final bottomPadding = math.min(120.0, viewportHeight * 0.20);
    final visibleTop = _readingY + topPadding;
    final visibleBottom = _readingY + viewportHeight - bottomPadding;
    if (firstTop >= visibleTop && lastBottom <= visibleBottom) return true;

    final target =
        firstTop < visibleTop
            ? firstTop - topPadding
            : lastBottom - viewportHeight + bottomPadding;
    return _animateToReadingY(target);
  }

  Future<void> _handleScrollSettled() async {
    if (!mounted || _isDragging) return;
    _captureAndReportVisibleLocation();
    final saved = await widget.runtime.saveProgress();
    if (saved != null) _lastReportedLocation = saved;
  }

  ReaderV2TileKey _tileKey(ReaderV2PageCache tile) {
    return ReaderV2TileKey.fromPageCache(
      tile,
      layoutRevision: widget.runtime.state.layoutGeneration,
    );
  }

  Widget _buildLoadingState(ReaderV2State state) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: Center(
          child:
              state.phase == ReaderV2Phase.error
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

  Widget _buildCanvas() {
    final viewportHeight = _viewportHeight();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onVerticalDragCancel: _handleDragCancel,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: ClipRect(
          child: ValueListenableBuilder<double>(
            valueListenable: _scrollOffset,
            builder: (context, readingY, _) {
              return _buildVisiblePageStack(
                readingY: readingY,
                viewportHeight: viewportHeight,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVisiblePageStack({
    required double readingY,
    required double viewportHeight,
  }) {
    final children = <Widget>[];
    for (final placement in _visiblePages.visiblePages(
      readingY: readingY,
      viewportHeight: viewportHeight,
    )) {
      final screenY = placement.screenY(readingY);
      final pageHeight = placement.extent;
      children.add(
        Positioned(
          left: 0,
          right: 0,
          top: screenY,
          height: pageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ReaderV2TileLayer(
                tile: placement.page,
                tileKey: _tileKey(placement.page),
                style: widget.style,
                backgroundColor: widget.backgroundColor,
                textColor: widget.textColor,
                expand: true,
                paintBackground: false,
              ),
              ReaderV2TtsHighlightOverlayLayer(
                tile: placement.page,
                style: widget.style,
                textColor: widget.textColor,
                highlight: widget.ttsHighlight,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(fit: StackFit.expand, children: children);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.runtime.state;
    final currentChapter = _safeChapterIndex(
      _currentChapterIndex ?? state.visibleLocation.chapterIndex,
    );
    final currentLoaded = _cacheManager.containsChapter(currentChapter);
    if (state.phase != ReaderV2Phase.ready && !_initialJumpCompleted) {
      return _buildLoadingState(state);
    }
    if (!currentLoaded) {
      final layoutGeneration = state.layoutGeneration;
      unawaited(
        _ensureWindowAround(
          currentChapter,
          isCurrent:
              () =>
                  mounted &&
                  widget.runtime.state.layoutGeneration == layoutGeneration &&
                  _safeChapterIndex(
                        widget.runtime.state.visibleLocation.chapterIndex,
                      ) ==
                      currentChapter,
        ),
      );
      return _buildLoadingState(state);
    }
    return _buildCanvas();
  }
}
