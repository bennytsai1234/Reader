import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_layout.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
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
  const _LoadedChapter({
    required this.layout,
    required this.tile,
    required this.extent,
  });

  final ChapterLayout layout;
  final TextPage tile;
  final double extent;
}

class _ScrollReaderViewportState extends State<ScrollReaderViewport> {
  late final ScrollController _controller;
  final Map<int, _LoadedChapter> _loadedChapters = <int, _LoadedChapter>{};
  final Map<int, double> _chapterExtents = <int, double>{};
  final Map<int, Future<void>> _inFlightLoads = <int, Future<void>>{};
  ReaderLocation? _lastReportedLocation;
  ReaderLocation? _lastSyncedLocation;
  int _lastLayoutGeneration = 0;
  bool _applyingProgrammaticScroll = false;
  bool _initialJumpCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_handleScroll);
    _lastLayoutGeneration = widget.runtime.state.layoutGeneration;
    _lastReportedLocation = widget.runtime.state.visibleLocation;
    widget.runtime.addListener(_onRuntimeChanged);
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
      oldWidget.runtime.removeListener(_onRuntimeChanged);
      widget.runtime.addListener(_onRuntimeChanged);
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
    _detachController(widget.controller);
    _controller
      ..removeListener(_handleScroll)
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
    _loadedChapters.clear();
    _chapterExtents.clear();
    _inFlightLoads.clear();
    _lastSyncedLocation = null;
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
    final locationChanged = state.visibleLocation != _lastReportedLocation;
    if ((layoutChanged || locationChanged) && !_applyingProgrammaticScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_primeAndSyncToRuntimeLocation(force: layoutChanged));
      });
    }
    setState(() {});
  }

  double _estimatedChapterExtent() {
    final viewportHeight = widget.runtime.state.layoutSpec.viewportSize.height;
    return viewportHeight <= 0 ? 1.0 : viewportHeight;
  }

  double _chapterExtent(int chapterIndex) {
    return _loadedChapters[chapterIndex]?.extent ??
        _chapterExtents[chapterIndex] ??
        _estimatedChapterExtent();
  }

  double _chapterBaseOffset(int chapterIndex) {
    var offset = 0.0;
    for (var i = 0; i < chapterIndex; i++) {
      offset += _chapterExtent(i);
    }
    return offset;
  }

  double _localOffsetForLine(TextLine line) {
    return line.top.clamp(0.0, double.infinity).toDouble();
  }

  double _localOffsetForLocationInLayout(
    ChapterLayout layout,
    ReaderLocation location,
  ) {
    if (layout.lines.isEmpty) return 0.0;
    for (final line in layout.lines) {
      if (location.charOffset <= line.startCharOffset) {
        return _localOffsetForLine(line);
      }
      if (location.charOffset >= line.startCharOffset &&
          location.charOffset < line.endCharOffset) {
        return _localOffsetForLine(line);
      }
    }
    return _localOffsetForLine(layout.lines.last);
  }

  ReaderLocation _locationForChapterLocalOffset(
    int chapterIndex,
    double localOffset,
  ) {
    final loaded = _loadedChapters[chapterIndex];
    if (loaded == null || loaded.layout.lines.isEmpty) {
      return ReaderLocation(chapterIndex: chapterIndex, charOffset: 0);
    }
    final safeOffset = localOffset.clamp(0.0, loaded.extent).toDouble();
    TextLine nearest = loaded.layout.lines.first;
    var nearestDistance = double.infinity;
    for (final line in loaded.layout.lines) {
      if (safeOffset >= line.top && safeOffset <= line.bottom) {
        return ReaderLocation(
          chapterIndex: chapterIndex,
          charOffset: line.startCharOffset,
        );
      }
      final distance =
          safeOffset < line.top
              ? line.top - safeOffset
              : safeOffset - line.bottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = line;
      }
    }
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: nearest.startCharOffset,
    );
  }

  double _globalOffsetForLocation(ReaderLocation location) {
    final baseOffset = _chapterBaseOffset(location.chapterIndex);
    final loaded = _loadedChapters[location.chapterIndex];
    if (loaded == null) return baseOffset;
    final localOffset = _localOffsetForLocationInLayout(
      loaded.layout,
      location,
    );
    return baseOffset + widget.style.paddingTop + localOffset;
  }

  TileKey _chapterTileKey(TextPage tile) {
    return TileKey(
      chapterIndex: tile.chapterIndex,
      tileIndex: -1,
      startOffset: tile.startCharOffset,
      endOffset: tile.endCharOffset,
      layoutRevision: widget.runtime.state.layoutGeneration,
    );
  }

  TextPage _chapterTile(ChapterLayout layout) {
    final lines = layout.lines;
    final contentHeight =
        lines.isEmpty
            ? widget.runtime.state.layoutSpec.contentHeight
            : lines.last.bottom;
    final viewportHeight = contentHeight.clamp(1.0, double.infinity).toDouble();
    return TextPage(
      pageIndex: 0,
      chapterIndex: layout.chapterIndex,
      chapterSize: widget.runtime.chapterCount,
      pageSize: 1,
      title: layout.pages.isEmpty ? '' : layout.pages.first.title,
      lines: lines,
      startCharOffset:
          layout.pages.isEmpty ? 0 : layout.pages.first.startCharOffset,
      endCharOffset: layout.pages.isEmpty ? 0 : layout.pages.last.endCharOffset,
      contentHeight: viewportHeight,
      viewportHeight: viewportHeight,
      isChapterStart: true,
      isChapterEnd: true,
    );
  }

  Future<void> _ensureChapterLoaded(int chapterIndex) {
    final safeChapterIndex = chapterIndex.clamp(
      0,
      widget.runtime.chapterCount - 1,
    );
    if (_loadedChapters.containsKey(safeChapterIndex)) {
      return Future<void>.value();
    }
    final existing = _inFlightLoads[safeChapterIndex];
    if (existing != null) return existing;

    final previousExtent = _chapterExtent(safeChapterIndex);
    final task = () async {
      try {
        final anchorLocation =
            _lastReportedLocation ?? widget.runtime.state.visibleLocation;
        final anchorOffsetBefore =
            _controller.hasClients
                ? _globalOffsetForLocation(anchorLocation)
                : null;
        final layout = await widget.runtime.debugResolver.ensureLayout(
          safeChapterIndex,
        );
        if (!mounted) return;
        final tile = _chapterTile(layout);
        final loaded = _LoadedChapter(
          layout: layout,
          tile: tile,
          extent: tile.viewportHeight,
        );
        _loadedChapters[safeChapterIndex] = loaded;
        _chapterExtents[safeChapterIndex] = loaded.extent;
        final anchorOffsetAfter =
            _controller.hasClients
                ? _globalOffsetForLocation(anchorLocation)
                : null;
        final delta =
            anchorOffsetAfter == null || anchorOffsetBefore == null
                ? loaded.extent - previousExtent
                : anchorOffsetAfter - anchorOffsetBefore;
        if (_controller.hasClients && delta.abs() > 0.5) {
          _applyingProgrammaticScroll = true;
          _controller.jumpTo(
            (_controller.offset + delta).clamp(
              0.0,
              _controller.position.maxScrollExtent,
            ),
          );
          _applyingProgrammaticScroll = false;
        }
        if (mounted) setState(() {});
      } finally {
        _inFlightLoads.remove(safeChapterIndex);
      }
    }();
    _inFlightLoads[safeChapterIndex] = task;
    return task;
  }

  Future<void> _primeAroundChapter(int chapterIndex) async {
    if (widget.runtime.chapterCount <= 0) return;
    final futures = <Future<void>>[];
    for (var i = chapterIndex - 2; i <= chapterIndex + 2; i++) {
      if (i < 0 || i >= widget.runtime.chapterCount) continue;
      futures.add(_ensureChapterLoaded(i));
    }
    await Future.wait(futures);
  }

  double _targetOffsetForLocation(ReaderLocation location) {
    return _globalOffsetForLocation(location);
  }

  Future<void> _primeAndSyncToRuntimeLocation({bool force = false}) async {
    final location = widget.runtime.state.visibleLocation;
    await _primeAroundChapter(location.chapterIndex);
    if (!mounted || !_controller.hasClients) return;
    if (!force && _initialJumpCompleted && _lastSyncedLocation == location) {
      return;
    }
    final target = _targetOffsetForLocation(location);
    _applyingProgrammaticScroll = true;
    _controller.jumpTo(target.clamp(0.0, _controller.position.maxScrollExtent));
    _applyingProgrammaticScroll = false;
    _initialJumpCompleted = true;
    _lastSyncedLocation = location;
    _lastReportedLocation = location;
    if (mounted) setState(() {});
  }

  void _handleScroll() {
    if (!_controller.hasClients || widget.runtime.chapterCount <= 0) return;
    final viewportHeight =
        context.size?.height ??
        widget.runtime.state.layoutSpec.viewportSize.height;
    final anchor =
        _controller.offset + (viewportHeight * 0.2).clamp(24.0, 120.0);
    var chapterTop = 0.0;
    for (var i = 0; i < widget.runtime.chapterCount; i++) {
      final extent = _chapterExtent(i);
      final chapterBottom = chapterTop + extent;
      if (anchor < chapterBottom || i == widget.runtime.chapterCount - 1) {
        unawaited(_primeAroundChapter(i));
        final loaded = _loadedChapters[i];
        if (loaded != null) {
          final localOffset =
              (anchor - chapterTop - widget.style.paddingTop)
                  .clamp(0.0, loaded.extent)
                  .toDouble();
          final location = _locationForChapterLocalOffset(i, localOffset);
          _lastReportedLocation = location;
          widget.runtime.updateVisibleLocation(location);
        }
        break;
      }
      chapterTop = chapterBottom;
    }
  }

  void _animateScrollBy(double delta) {
    if (!_controller.hasClients || delta == 0) return;
    final target = (_controller.offset + delta).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    _applyingProgrammaticScroll = true;
    unawaited(
      _controller
          .animateTo(
            target,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() => _applyingProgrammaticScroll = false),
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

  Widget _buildChapterPlaceholder(int chapterIndex) {
    return SizedBox(
      height: _chapterExtent(chapterIndex),
      child: Center(
        child: Text(
          '載入中...',
          style: TextStyle(
            color: widget.textColor.withValues(alpha: 0.6),
            fontSize: widget.style.fontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildChapterItem(int chapterIndex) {
    final loaded = _loadedChapters[chapterIndex];
    if (loaded == null) {
      unawaited(_ensureChapterLoaded(chapterIndex));
      return _buildChapterPlaceholder(chapterIndex);
    }
    return ReaderTileLayer(
      tile: loaded.tile,
      tileKey: _chapterTileKey(loaded.tile),
      style: widget.style,
      backgroundColor: widget.backgroundColor,
      textColor: widget.textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.runtime.state;
    if (state.phase != ReaderPhase.ready && !_initialJumpCompleted) {
      return _buildLoadingState(state);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: widget.onTapUp,
      child: ColoredBox(
        color: widget.backgroundColor,
        child: ListView.builder(
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          itemCount: widget.runtime.chapterCount,
          itemBuilder: (context, index) {
            return _buildChapterItem(index);
          },
        ),
      ),
    );
  }
}
