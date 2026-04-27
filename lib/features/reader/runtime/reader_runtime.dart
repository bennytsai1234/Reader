import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';
import 'package:inkpage_reader/features/reader/engine/layout_engine.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/page_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

import 'page_window.dart';
import 'reader_preload_scheduler.dart';
import 'reader_progress_controller.dart';
import 'reader_state.dart';

class ReaderRuntime extends ChangeNotifier {
  ReaderRuntime({
    required Book book,
    required this.repository,
    required LayoutEngine layoutEngine,
    required ReaderProgressController progressController,
    required LayoutSpec initialLayoutSpec,
    required ReaderMode initialMode,
  }) : _book = book,
       _layoutEngine = layoutEngine,
       _progressController = progressController,
       resolver = PageResolver(
         repository: repository,
         layoutEngine: layoutEngine,
         layoutSpec: initialLayoutSpec,
       ),
       state = ReaderState(
         mode: initialMode,
         phase: ReaderPhase.cold,
         committedLocation:
             ReaderLocation(
               chapterIndex: book.chapterIndex,
               charOffset: book.charOffset,
             ).normalized(),
         visibleLocation:
             ReaderLocation(
               chapterIndex: book.chapterIndex,
               charOffset: book.charOffset,
             ).normalized(),
         layoutSpec: initialLayoutSpec,
         layoutGeneration: 0,
       ) {
    preloadScheduler = ReaderPreloadScheduler(resolver: resolver);
  }

  final Book _book;
  final ChapterRepository repository;
  final LayoutEngine _layoutEngine;
  final ReaderProgressController _progressController;
  final PageResolver resolver;
  late final ReaderPreloadScheduler preloadScheduler;
  ReaderState state;

  bool _disposed = false;

  Future<void> openBook() async {
    _setState(state.copyWith(phase: ReaderPhase.loading, clearError: true));
    try {
      await repository.ensureChapters();
      final location = ReaderLocation(
        chapterIndex: _book.chapterIndex,
        charOffset: _book.charOffset,
      ).normalized(chapterCount: repository.chapterCount);
      await jumpToLocation(location, immediateSave: false);
      preloadScheduler.preloadAround(location.chapterIndex, radius: 1);
    } catch (e) {
      _setState(
        state.copyWith(phase: ReaderPhase.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> updateLayoutSpec(LayoutSpec spec) async {
    if (state.layoutSpec.layoutSignature == spec.layoutSignature) return;
    final generation = preloadScheduler.bumpGeneration();
    resolver.updateLayoutSpec(spec);
    _layoutEngine.invalidateWhere((layout) {
      return layout.layoutSignature != spec.layoutSignature;
    });
    _setState(
      state.copyWith(
        phase: ReaderPhase.layingOut,
        layoutSpec: spec,
        layoutGeneration: generation,
      ),
    );
    await jumpToLocation(state.visibleLocation, immediateSave: false);
  }

  Future<void> updateStyle(ReadStyle style, Size viewportSize) {
    return updateLayoutSpec(
      LayoutSpec.fromViewport(viewportSize: viewportSize, style: style),
    );
  }

  Future<void> jumpToChapter(int chapterIndex) {
    return jumpToLocation(
      ReaderLocation(chapterIndex: chapterIndex, charOffset: 0),
      immediateSave: true,
    );
  }

  Future<void> jumpToLocation(
    ReaderLocation location, {
    bool immediateSave = true,
  }) async {
    final generation = state.layoutGeneration;
    _setState(state.copyWith(phase: ReaderPhase.layingOut, clearError: true));
    try {
      final normalized = location.normalized(
        chapterCount: repository.chapterCount,
      );
      final page = await resolver.pageForLocation(normalized);
      if (generation != state.layoutGeneration) return;
      final window = await resolver.buildWindowAround(normalized);
      if (generation != state.layoutGeneration) return;
      final resolvedLocation = ReaderLocation(
        chapterIndex: page.chapterIndex,
        charOffset:
            normalized.charOffset
                .clamp(page.startCharOffset, page.endCharOffset)
                .toInt(),
      );
      _setState(
        state.copyWith(
          phase: ReaderPhase.ready,
          committedLocation: resolvedLocation,
          visibleLocation: resolvedLocation,
          pageWindow: window,
          currentSlidePage: page,
          clearError: true,
        ),
      );
      if (immediateSave) {
        await _progressController.saveImmediately(resolvedLocation);
      }
      preloadScheduler.preloadAround(resolvedLocation.chapterIndex, radius: 1);
    } catch (e) {
      _setState(
        state.copyWith(phase: ReaderPhase.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> switchMode(ReaderMode mode) async {
    if (state.mode == mode) return;
    _setState(state.copyWith(phase: ReaderPhase.switchingMode, mode: mode));
    await jumpToLocation(state.visibleLocation, immediateSave: false);
    _setState(state.copyWith(mode: mode, phase: ReaderPhase.ready));
  }

  bool moveToNextPage() {
    final window = state.pageWindow;
    final next = window?.next;
    if (window == null || next == null || next.isPlaceholder) {
      _scheduleMissingNeighborPreload(forward: true);
      return false;
    }
    final newNext = resolver.nextPageOrPlaceholder(next);
    final newWindow = PageWindow(
      prev: window.current,
      current: next,
      next: newNext,
      lookAhead: const <TextPage>[],
    );
    final location = ReaderLocation(
      chapterIndex: next.chapterIndex,
      charOffset: next.startCharOffset,
    );
    _setState(
      state.copyWith(
        pageWindow: newWindow,
        currentSlidePage: next,
        visibleLocation: location,
        committedLocation: location,
        phase: ReaderPhase.ready,
      ),
    );
    _progressController.schedule(location);
    _scheduleMissingNeighborPreload(forward: true);
    return true;
  }

  bool moveToPrevPage() {
    final window = state.pageWindow;
    final prev = window?.prev;
    if (window == null || prev == null || prev.isPlaceholder) {
      _scheduleMissingNeighborPreload(forward: false);
      return false;
    }
    final newPrev = resolver.prevPageOrPlaceholder(prev);
    final newWindow = PageWindow(
      prev: newPrev,
      current: prev,
      next: window.current,
      lookAhead: const <TextPage>[],
    );
    final location = ReaderLocation(
      chapterIndex: prev.chapterIndex,
      charOffset: prev.startCharOffset,
    );
    _setState(
      state.copyWith(
        pageWindow: newWindow,
        currentSlidePage: prev,
        visibleLocation: location,
        committedLocation: location,
        phase: ReaderPhase.ready,
      ),
    );
    _progressController.schedule(location);
    _scheduleMissingNeighborPreload(forward: false);
    return true;
  }

  ReaderLocation resolveVisibleLocation({
    required double pageOffset,
    required double viewportHeight,
    double anchorFraction = 0.2,
  }) {
    final window = state.pageWindow;
    if (window == null) return state.visibleLocation;
    final anchorY = viewportHeight * anchorFraction;
    var visualY = -pageOffset + anchorY;
    for (final page in window.paintForwardPages) {
      if (visualY <= page.height) {
        return _locationInPage(page, visualY);
      }
      visualY -= page.height;
    }
    return _locationInPage(window.paintForwardPages.last, visualY);
  }

  void updateVisibleLocation(
    ReaderLocation location, {
    bool debounceSave = true,
  }) {
    final normalized = location.normalized(
      chapterCount: repository.chapterCount,
    );
    _setState(
      state.copyWith(
        visibleLocation: normalized,
        committedLocation: normalized,
      ),
    );
    if (debounceSave) {
      _progressController.schedule(normalized);
    }
  }

  void handleSlidePageSettled(TextPage page) {
    final location = ReaderLocation(
      chapterIndex: page.chapterIndex,
      charOffset: page.startCharOffset,
    );
    _setState(
      state.copyWith(
        currentSlidePage: page,
        visibleLocation: location,
        committedLocation: location,
      ),
    );
    _progressController.schedule(location);
    if (page.pageIndex >= page.pageSize - 2) {
      preloadScheduler.preloadAround(page.chapterIndex + 1, radius: 0);
    } else if (page.pageIndex <= 1) {
      preloadScheduler.preloadAround(page.chapterIndex - 1, radius: 0);
    }
  }

  Future<void> refreshNeighbors() async {
    final window = state.pageWindow;
    if (window == null) return;
    final prev =
        resolver.prevPageSync(window.current) ??
        await resolver.prevPage(window.current, allowAsyncLoad: false);
    final next =
        resolver.nextPageSync(window.current) ??
        await resolver.nextPage(window.current, allowAsyncLoad: false);
    _setState(
      state.copyWith(
        pageWindow: PageWindow(
          prev: prev ?? resolver.prevPageOrPlaceholder(window.current),
          current: window.current,
          next: next ?? resolver.nextPageOrPlaceholder(window.current),
          lookAhead: const <TextPage>[],
        ),
      ),
    );
  }

  Future<void> flushProgress() => _progressController.flush();

  ReaderLocation _locationInPage(TextPage page, double pageY) {
    if (page.lines.isEmpty) {
      return ReaderLocation(
        chapterIndex: page.chapterIndex,
        charOffset: page.startCharOffset,
      );
    }
    TextLine nearest = page.lines.first;
    var nearestDistance = double.infinity;
    for (final line in page.lines) {
      if (pageY >= line.top && pageY <= line.bottom) {
        return ReaderLocation(
          chapterIndex: page.chapterIndex,
          charOffset: line.startCharOffset,
        );
      }
      final distance =
          pageY < line.top ? line.top - pageY : pageY - line.bottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = line;
      }
    }
    return ReaderLocation(
      chapterIndex: page.chapterIndex,
      charOffset: nearest.startCharOffset,
    );
  }

  void _scheduleMissingNeighborPreload({required bool forward}) {
    final window = state.pageWindow;
    if (window == null) return;
    final target = window.current.chapterIndex + (forward ? 1 : -1);
    if (target < 0 || target >= repository.chapterCount) return;
    unawaited(
      resolver
          .ensureLayout(target)
          .then((_) {
            if (!_disposed) unawaited(refreshNeighbors());
          })
          .catchError((_) {
            if (!_disposed) unawaited(refreshNeighbors());
          }),
    );
  }

  void _setState(ReaderState next) {
    if (_disposed) return;
    state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _progressController.dispose();
    super.dispose();
  }
}
