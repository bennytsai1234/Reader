import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_layout.dart';
import 'package:inkpage_reader/features/reader/engine/line_layout.dart';
import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/features/reader/runtime/tile_key.dart';

import 'reader_tile_layer.dart';
import 'reader_viewport_controller.dart';

class ScrollReaderViewport extends StatefulWidget {
  const ScrollReaderViewport({
    super.key,
    required this.runtime,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.onTapUp,
    this.controller,
  });

  final ReaderRuntime runtime;
  final Color backgroundColor;
  final Color textColor;
  final ReadStyle style;
  final GestureTapUpCallback? onTapUp;
  final ReaderViewportController? controller;

  @override
  State<ScrollReaderViewport> createState() => _ScrollReaderViewportState();
}

class _LoadedChapter {
  _LoadedChapter({required this.layout, required List<PageCache> pages})
    : pages = List<PageCache>.unmodifiable(pages),
      extent = _visualExtent(pages);

  final ChapterLayout layout;
  final List<PageCache> pages;
  final double extent;

  PageCache? pageAt(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return null;
    return pages[pageIndex];
  }

  static double _visualExtent(List<PageCache> pages) {
    final extent = pages.fold<double>(
      0.0,
      (total, page) => total + _safePageHeight(page),
    );
    return extent <= 0 ? 1.0 : extent;
  }

  static double _safePageHeight(PageCache page) {
    return page.height.isFinite && page.height > 0 ? page.height : 1.0;
  }
}

class _CanvasPagePlacement {
  const _CanvasPagePlacement({
    required this.layout,
    required this.page,
    required this.virtualTop,
  });

  final ChapterLayout layout;
  final PageCache page;
  final double virtualTop;

  double get virtualBottom => virtualTop + _LoadedChapter._safePageHeight(page);
}

class _ScrollReaderViewportState extends State<ScrollReaderViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scrollAnimation;
  final Map<int, _LoadedChapter> _loadedChapters = <int, _LoadedChapter>{};
  final Map<int, double> _chapterExtents = <int, double>{};
  final Map<int, double> _chapterVirtualTops = <int, double>{};
  final Map<int, Future<void>> _inFlightLoads = <int, Future<void>>{};

  ReaderLocation? _lastReportedLocation;
  ReaderLocation? _lastSyncedLocation;
  int? _currentChapterIndex;
  int _lastLayoutGeneration = 0;
  double _virtualScrollY = 0.0;
  double _lastAnimationValue = 0.0;
  bool _initialJumpCompleted = false;
  bool _isDragging = false;
  bool _capturingVisibleLocation = false;

  @override
  void initState() {
    super.initState();
    _scrollAnimation = AnimationController.unbounded(vsync: this)
      ..addListener(_handleScrollAnimationTick);
    _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
    _lastReportedLocation = widget.runtime.state.visibleLocation;
    widget.runtime.addListener(_onRuntimeChanged);
    widget.runtime.registerVisibleLocationCapture(
      this,
      _captureVisibleLocation,
    );
    _attachController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_primeAndSyncToRuntimeLocation(force: true));
    });
  }

  @override
  void didUpdateWidget(covariant ScrollReaderViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) {
      oldWidget.runtime.unregisterVisibleLocationCapture(this);
      oldWidget.runtime.removeListener(_onRuntimeChanged);
      widget.runtime.addListener(_onRuntimeChanged);
      widget.runtime.registerVisibleLocationCapture(
        this,
        _captureVisibleLocation,
      );
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
    _detachController(widget.controller);
    _scrollAnimation
      ..removeListener(_handleScrollAnimationTick)
      ..dispose();
    super.dispose();
  }

  void _attachController() {
    widget.controller?.scrollBy = _animateScrollBy;
  }

  void _detachController(ReaderViewportController? controller) {
    controller?.scrollBy = null;
  }

  void _resetLoadedState() {
    _scrollAnimation.stop();
    _loadedChapters.clear();
    _chapterExtents.clear();
    _chapterVirtualTops.clear();
    _inFlightLoads.clear();
    _lastSyncedLocation = null;
    _currentChapterIndex = null;
    _virtualScrollY = 0.0;
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

    if (state.phase == ReaderPhase.layingOut ||
        state.phase == ReaderPhase.switchingMode) {
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

  double _anchorOffsetInViewport() {
    final viewportHeight = _viewportHeight();
    return (viewportHeight * 0.2).clamp(24.0, 120.0).toDouble();
  }

  double _shiftThreshold() {
    return math.min(120.0, _viewportHeight() * 0.2);
  }

  int _safeChapterIndex(int chapterIndex) {
    final chapterCount = widget.runtime.chapterCount;
    if (chapterCount <= 0) return 0;
    return chapterIndex.clamp(0, chapterCount - 1).toInt();
  }

  List<int> _windowChapterIndexes() {
    final chapterCount = widget.runtime.chapterCount;
    if (chapterCount <= 0) return const <int>[];
    final center = _safeChapterIndex(
      _currentChapterIndex ?? widget.runtime.state.visibleLocation.chapterIndex,
    );
    return <int>[
      if (center > 0) center - 1,
      center,
      if (center + 1 < chapterCount) center + 1,
    ];
  }

  Future<void> _ensureChapterLoaded(int chapterIndex) {
    if (widget.runtime.chapterCount <= 0) return Future<void>.value();
    final safeChapterIndex = _safeChapterIndex(chapterIndex);
    if (_loadedChapters.containsKey(safeChapterIndex)) {
      return Future<void>.value();
    }
    final existing = _inFlightLoads[safeChapterIndex];
    if (existing != null) return existing;

    final task = () async {
      try {
        final layout = await widget.runtime.debugResolver.ensureLayout(
          safeChapterIndex,
        );
        if (!mounted) return;
        final pages = layout.pageCaches;
        final loaded = _LoadedChapter(layout: layout, pages: pages);
        _loadedChapters[safeChapterIndex] = loaded;
        _chapterExtents[safeChapterIndex] = loaded.extent;
      } finally {
        _inFlightLoads.remove(safeChapterIndex);
      }
    }();
    _inFlightLoads[safeChapterIndex] = task;
    return task;
  }

  Future<bool> _tryEnsureChapterLoaded(int chapterIndex) async {
    try {
      await _ensureChapterLoaded(chapterIndex);
      return _loadedChapters.containsKey(_safeChapterIndex(chapterIndex));
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureWindowAround(int chapterIndex) async {
    if (widget.runtime.chapterCount <= 0) return;
    final center = _safeChapterIndex(chapterIndex);
    final centerReady = await _tryEnsureChapterLoaded(center);
    if (!mounted) return;
    if (!centerReady) return;

    _currentChapterIndex = center;
    _chapterVirtualTops.putIfAbsent(center, () => 0.0);
    final centerTop = _chapterVirtualTops[center]!;
    final centerExtent =
        _chapterExtents[center] ?? _loadedChapters[center]?.extent ?? 1.0;

    final previous = center - 1;
    if (previous >= 0) {
      final previousReady = await _tryEnsureChapterLoaded(previous);
      if (!mounted) return;
      if (previousReady) {
        final previousExtent =
            _chapterExtents[previous] ??
            _loadedChapters[previous]?.extent ??
            1.0;
        _chapterVirtualTops.putIfAbsent(
          previous,
          () => centerTop - previousExtent,
        );
      }
    }

    final next = center + 1;
    if (next < widget.runtime.chapterCount) {
      final nextReady = await _tryEnsureChapterLoaded(next);
      if (!mounted) return;
      if (nextReady) {
        _chapterVirtualTops.putIfAbsent(next, () => centerTop + centerExtent);
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _primeAndSyncToRuntimeLocation({bool force = false}) async {
    final location = widget.runtime.state.visibleLocation.normalized(
      chapterCount: widget.runtime.chapterCount,
    );
    await _ensureWindowAround(location.chapterIndex);
    if (!mounted) return;
    if (!force && _initialJumpCompleted && _lastSyncedLocation == location) {
      return;
    }

    final target = _virtualScrollYForLocation(location);
    if (target != null) {
      _virtualScrollY = _clampVirtualScrollY(target);
    }
    _initialJumpCompleted = true;
    _lastSyncedLocation = location;
    final captured = widget.runtime.captureVisibleLocation();
    _lastReportedLocation = captured ?? location;
    if (mounted) setState(() {});
  }

  double? _virtualScrollYForLocation(ReaderLocation location) {
    final chapterIndex = _safeChapterIndex(location.chapterIndex);
    final loaded = _loadedChapters[chapterIndex];
    final chapterTop = _chapterVirtualTops[chapterIndex];
    if (loaded == null || chapterTop == null) return null;

    final layout = LineLayout.fromPages(
      loaded.layout.pages,
      chapterIndex: chapterIndex,
    );
    final item = layout.itemAtCharOffset(location.charOffset);
    if (item == null) return chapterTop - _anchorOffsetInViewport();
    final lineVirtualTop = _lineVirtualTop(
      loaded: loaded,
      chapterTop: chapterTop,
      item: item,
    );
    if (lineVirtualTop == null) return null;
    return lineVirtualTop + location.visualOffsetPx - _anchorOffsetInViewport();
  }

  double? _lineVirtualTop({
    required _LoadedChapter loaded,
    required double chapterTop,
    required LineItem item,
  }) {
    final page = loaded.pageAt(item.pageIndex);
    if (page == null) return null;
    final pageVirtualTop = _pageVirtualTop(
      chapterTop: chapterTop,
      pages: loaded.pages,
      pageIndex: item.pageIndex,
    );
    if (pageVirtualTop == null) return null;
    return pageVirtualTop +
        widget.style.paddingTop +
        item.localTop -
        page.localStartY;
  }

  double? _pageVirtualTop({
    required double chapterTop,
    required List<PageCache> pages,
    required int pageIndex,
  }) {
    if (pageIndex < 0 || pageIndex >= pages.length) return null;
    var top = chapterTop;
    for (var index = 0; index < pageIndex; index++) {
      top += _LoadedChapter._safePageHeight(pages[index]);
    }
    return top;
  }

  List<_CanvasPagePlacement> _pagePlacements() {
    final placements = <_CanvasPagePlacement>[];
    for (final chapterIndex in _windowChapterIndexes()) {
      final loaded = _loadedChapters[chapterIndex];
      final chapterTop = _chapterVirtualTops[chapterIndex];
      if (loaded == null || chapterTop == null) continue;
      var pageTop = chapterTop;
      for (final page in loaded.pages) {
        placements.add(
          _CanvasPagePlacement(
            layout: loaded.layout,
            page: page,
            virtualTop: pageTop,
          ),
        );
        pageTop += _LoadedChapter._safePageHeight(page);
      }
    }
    placements.sort((a, b) => a.virtualTop.compareTo(b.virtualTop));
    return placements;
  }

  double _clampVirtualScrollY(double target) {
    final placements = _pagePlacements();
    if (placements.isEmpty) return target;
    final minTop = placements
        .map((placement) => placement.virtualTop)
        .reduce(math.min);
    final maxBottom = placements
        .map((placement) => placement.virtualBottom)
        .reduce(math.max);
    final minScrollY = minTop;
    final maxScrollY = math.max(minScrollY, maxBottom - _viewportHeight());
    return target.clamp(minScrollY, maxScrollY).toDouble();
  }

  _CanvasPagePlacement? _placementAtVirtualY(double virtualY) {
    _CanvasPagePlacement? nearest;
    var nearestDistance = double.infinity;
    for (final placement in _pagePlacements()) {
      if (virtualY >= placement.virtualTop &&
          virtualY < placement.virtualBottom) {
        return placement;
      }
      final distance =
          virtualY < placement.virtualTop
              ? placement.virtualTop - virtualY
              : virtualY - placement.virtualBottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = placement;
      }
    }
    return nearest;
  }

  ReaderLocation? _captureVisibleLocation() {
    if (!_initialJumpCompleted || widget.runtime.chapterCount <= 0) {
      return null;
    }
    final anchorLineY = _anchorOffsetInViewport();
    final anchorVirtualY = _virtualScrollY + anchorLineY;
    final placement = _placementAtVirtualY(anchorVirtualY);
    if (placement == null) return null;

    final pageContentY =
        (anchorVirtualY - placement.virtualTop - widget.style.paddingTop)
            .clamp(0.0, placement.page.contentHeight)
            .toDouble();
    final chapterLocalY = placement.page.localStartY + pageContentY;
    final layout = LineLayout.fromPages(
      placement.layout.pages,
      chapterIndex: placement.page.chapterIndex,
    );
    final item = _lineItemAtOrNearLocalY(layout, chapterLocalY);
    if (item == null) return null;

    final loaded = _loadedChapters[item.chapterIndex];
    final chapterTop = _chapterVirtualTops[item.chapterIndex];
    if (loaded == null || chapterTop == null) return null;
    final lineVirtualTop = _lineVirtualTop(
      loaded: loaded,
      chapterTop: chapterTop,
      item: item,
    );
    if (lineVirtualTop == null) return null;
    final lineTopOnScreen = lineVirtualTop - _virtualScrollY;
    return ReaderLocation(
      chapterIndex: item.chapterIndex,
      charOffset: item.chapterPosition,
      visualOffsetPx: anchorLineY - lineTopOnScreen,
    );
  }

  LineItem? _lineItemAtOrNearLocalY(LineLayout layout, double localY) {
    LineItem? nearest;
    var nearestDistance = double.infinity;
    for (final item in layout.textItems) {
      if (localY >= item.localTop && localY <= item.localBottom) {
        nearest = item;
        break;
      }
      final distance =
          localY < item.localTop
              ? item.localTop - localY
              : localY - item.localBottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = item;
      }
    }
    return nearest;
  }

  void _captureAndReportVisibleLocation() {
    _capturingVisibleLocation = true;
    final ReaderLocation? location;
    try {
      location = widget.runtime.captureVisibleLocation();
    } finally {
      _capturingVisibleLocation = false;
    }
    if (location != null) _lastReportedLocation = location;
  }

  bool _applyVirtualScrollDelta(double delta) {
    if (delta == 0 || _pagePlacements().isEmpty) return false;
    final nextScrollY = _clampVirtualScrollY(_virtualScrollY + delta);
    if ((nextScrollY - _virtualScrollY).abs() < 0.01) return false;
    _virtualScrollY = nextScrollY;
    _captureAndReportVisibleLocation();
    unawaited(_shiftWindowForAnchor());
    if (mounted) setState(() {});
    return true;
  }

  Future<void> _shiftWindowForAnchor() async {
    final current = _currentChapterIndex;
    if (current == null) return;
    final anchorVirtualY = _virtualScrollY + _anchorOffsetInViewport();
    final placement = _placementAtVirtualY(anchorVirtualY);
    if (placement == null) return;
    final targetChapter = placement.page.chapterIndex;
    if (targetChapter == current) return;
    if (!_shouldShiftWindow(current, targetChapter, anchorVirtualY)) return;
    await _ensureWindowAround(targetChapter);
  }

  bool _shouldShiftWindow(
    int currentChapter,
    int targetChapter,
    double anchorVirtualY,
  ) {
    final targetTop = _chapterVirtualTops[targetChapter];
    final currentTop = _chapterVirtualTops[currentChapter];
    if (targetTop == null || currentTop == null) return false;
    final threshold = _shiftThreshold();
    if (targetChapter > currentChapter) {
      return anchorVirtualY - targetTop >= threshold;
    }
    return currentTop - anchorVirtualY >= threshold;
  }

  void _handleScrollAnimationTick() {
    final current = _scrollAnimation.value;
    final delta = current - _lastAnimationValue;
    _lastAnimationValue = current;
    if (delta == 0) return;
    final moved = _applyVirtualScrollDelta(delta);
    if (!moved) {
      _scrollAnimation.stop();
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _isDragging = true;
    _scrollAnimation.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _applyVirtualScrollDelta(-details.delta.dy);
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
    _scrollAnimation.value = _virtualScrollY;
    _lastAnimationValue = _virtualScrollY;
    final simulation = ClampingScrollSimulation(
      position: _virtualScrollY,
      velocity: velocity,
    );
    unawaited(
      _scrollAnimation.animateWith(simulation).whenComplete(() {
        if (mounted) unawaited(_handleScrollSettled());
      }),
    );
  }

  void _animateScrollBy(double delta) {
    if (delta == 0 || _pagePlacements().isEmpty) return;
    final target = _clampVirtualScrollY(_virtualScrollY + delta);
    if ((target - _virtualScrollY).abs() < 0.01) return;
    _scrollAnimation.stop();
    _scrollAnimation.value = _virtualScrollY;
    _lastAnimationValue = _virtualScrollY;
    unawaited(
      _scrollAnimation
          .animateTo(
            target,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() {
            if (mounted) unawaited(_handleScrollSettled());
          }),
    );
  }

  Future<void> _handleScrollSettled() async {
    if (!mounted || _isDragging) return;
    _captureAndReportVisibleLocation();
    final saved = await widget.runtime.saveProgress();
    if (saved != null) _lastReportedLocation = saved;
  }

  TileKey _tileKey(PageCache tile) {
    return TileKey.fromPageCache(
      tile,
      layoutRevision: widget.runtime.state.layoutGeneration,
    );
  }

  Widget _buildLoadingState(ReaderState state) {
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

  Widget _buildCanvas() {
    final viewportHeight = _viewportHeight();
    final children = <Widget>[];
    for (final placement in _pagePlacements()) {
      final screenY = placement.virtualTop - _virtualScrollY;
      final pageHeight = _LoadedChapter._safePageHeight(placement.page);
      if (screenY >= viewportHeight || screenY + pageHeight <= 0) continue;
      children.add(
        Positioned(
          left: 0,
          right: 0,
          top: screenY,
          height: pageHeight,
          child: ReaderTileLayer(
            tile: placement.page,
            tileKey: _tileKey(placement.page),
            style: widget.style,
            backgroundColor: widget.backgroundColor,
            textColor: widget.textColor,
            expand: true,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onVerticalDragCancel: _handleDragCancel,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: ClipRect(child: Stack(fit: StackFit.expand, children: children)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.runtime.state;
    final currentChapter = _safeChapterIndex(
      _currentChapterIndex ?? state.visibleLocation.chapterIndex,
    );
    final currentLoaded = _loadedChapters.containsKey(currentChapter);
    if (state.phase != ReaderPhase.ready && !_initialJumpCompleted) {
      return _buildLoadingState(state);
    }
    if (!currentLoaded) {
      unawaited(_ensureWindowAround(currentChapter));
      return _buildLoadingState(state);
    }
    return _buildCanvas();
  }
}
