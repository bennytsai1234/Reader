import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/book_content.dart';
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
    required ChapterRepository repository,
    required LayoutEngine layoutEngine,
    required ReaderProgressController progressController,
    required LayoutSpec initialLayoutSpec,
    required ReaderMode initialMode,
    ReaderLocation? initialLocation,
  }) : _layoutEngine = layoutEngine,
       _repository = repository,
       _progressController = progressController,
       _initialLocation =
           (initialLocation ??
                   ReaderLocation(
                     chapterIndex: book.chapterIndex,
                     charOffset: book.charOffset,
                   ))
               .normalized(),
       _resolver = PageResolver(
         repository: repository,
         layoutEngine: layoutEngine,
         layoutSpec: initialLayoutSpec,
       ),
       state = ReaderState(
         mode: initialMode,
         phase: ReaderPhase.cold,
         committedLocation:
             (initialLocation ??
                     ReaderLocation(
                       chapterIndex: book.chapterIndex,
                       charOffset: book.charOffset,
                     ))
                 .normalized(),
         visibleLocation:
             (initialLocation ??
                     ReaderLocation(
                       chapterIndex: book.chapterIndex,
                       charOffset: book.charOffset,
                     ))
                 .normalized(),
         layoutSpec: initialLayoutSpec,
         layoutGeneration: 0,
       ) {
    _preloadScheduler = ReaderPreloadScheduler(resolver: _resolver);
  }

  final ChapterRepository _repository;
  final LayoutEngine _layoutEngine;
  final ReaderProgressController _progressController;
  final ReaderLocation _initialLocation;
  final PageResolver _resolver;
  late final ReaderPreloadScheduler _preloadScheduler;
  ReaderState state;

  bool _disposed = false;

  PageResolver get debugResolver => _resolver;

  int get chapterCount => _repository.chapterCount;

  List<BookChapter> get chapters => _repository.chapters;

  BookChapter? chapterAt(int index) => _repository.chapterAt(index);

  String titleFor(int index) => _repository.titleFor(index);

  String chapterUrlAt(int index) => chapterAt(index)?.url ?? '';

  Future<void> openBook() async {
    _setState(state.copyWith(phase: ReaderPhase.loading, clearError: true));
    try {
      await _repository.ensureChapters();
      final location = _initialLocation.normalized(
        chapterCount: _repository.chapterCount,
      );
      await jumpToLocation(location, immediateSave: false);
    } catch (e) {
      _setState(
        state.copyWith(phase: ReaderPhase.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> updateLayoutSpec(LayoutSpec spec) async {
    if (state.layoutSpec.layoutSignature == spec.layoutSignature) return;
    final generation = _preloadScheduler.bumpGeneration();
    _resolver.updateLayoutSpec(spec);
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

  Future<void> reloadContentPreservingLocation() async {
    final location = state.visibleLocation;
    _repository.clearContentCache();
    _resolver.clearCachedLayouts();
    await jumpToLocation(location, immediateSave: false);
  }

  Future<String> textFromVisibleLocation() async {
    final location = state.visibleLocation.normalized(
      chapterCount: _repository.chapterCount,
    );
    final content = await loadContentForTts(location);
    final safeOffset =
        location.charOffset.clamp(0, content.plainText.length).toInt();
    return content.plainText.substring(safeOffset).trim();
  }

  Future<BookContent> loadContentForTts(ReaderLocation location) {
    final normalized = location.normalized(
      chapterCount: _repository.chapterCount,
    );
    return _repository.loadContent(normalized.chapterIndex);
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
        chapterCount: _repository.chapterCount,
      );
      final page = await _resolver.pageForLocation(normalized);
      if (generation != state.layoutGeneration) return;
      final window = await _resolver.buildWindowAround(normalized);
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
      unawaited(_preloadScheduler.scheduleJump(resolvedLocation.chapterIndex));
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
    final newNext = _resolver.nextPageOrPlaceholder(next);
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
    unawaited(_preloadScheduler.scheduleScrollSettled(next));
    return true;
  }

  bool moveToPrevPage() {
    final window = state.pageWindow;
    final prev = window?.prev;
    if (window == null || prev == null || prev.isPlaceholder) {
      _scheduleMissingNeighborPreload(forward: false);
      return false;
    }
    final newPrev = _resolver.prevPageOrPlaceholder(prev);
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
    unawaited(_preloadScheduler.scheduleScrollSettled(prev));
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
      chapterCount: _repository.chapterCount,
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
    unawaited(_preloadScheduler.scheduleSlidePageSettled(page));
  }

  Future<void> refreshNeighbors() async {
    final window = state.pageWindow;
    if (window == null) return;
    final prev =
        _resolver.prevPageSync(window.current) ??
        await _resolver.prevPage(window.current, allowAsyncLoad: false);
    final next =
        _resolver.nextPageSync(window.current) ??
        await _resolver.nextPage(window.current, allowAsyncLoad: false);
    _setState(
      state.copyWith(
        pageWindow: PageWindow(
          prev: prev ?? _resolver.prevPageOrPlaceholder(window.current),
          current: window.current,
          next: next ?? _resolver.nextPageOrPlaceholder(window.current),
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
    if (target < 0 || target >= _repository.chapterCount) return;
    unawaited(
      _preloadScheduler.scheduleLayout(target, priority: true).whenComplete(() {
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
    _preloadScheduler.dispose();
    _progressController.dispose();
    super.dispose();
  }
}
