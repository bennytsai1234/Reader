import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/book_content.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';
import 'package:inkpage_reader/features/reader/engine/layout_engine.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/page_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

import 'page_window.dart';
import 'reader_preload_scheduler.dart';
import 'reader_progress_controller.dart';
import 'reader_state.dart';

typedef ReaderVisibleLocationCapture = ReaderLocation? Function();
typedef ReaderViewportRestore = Future<bool> Function(ReaderLocation location);

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
                     visualOffsetPx: book.visualOffsetPx,
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
                       visualOffsetPx: book.visualOffsetPx,
                     ))
                 .normalized(),
         visibleLocation:
             (initialLocation ??
                     ReaderLocation(
                       chapterIndex: book.chapterIndex,
                       charOffset: book.charOffset,
                       visualOffsetPx: book.visualOffsetPx,
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
  bool _restoreInProgress = false;
  Object? _visibleLocationCaptureOwner;
  ReaderVisibleLocationCapture? _visibleLocationCapture;
  Object? _viewportRestoreOwner;
  ReaderViewportRestore? _viewportRestore;
  PageAddress? _pendingNeighborAdvanceOrigin;
  int _pendingNeighborAdvanceDirection = 0;
  String? _pendingUserNotice;

  PageResolver get debugResolver => _resolver;

  int get chapterCount => _repository.chapterCount;

  List<BookChapter> get chapters => _repository.chapters;

  BookChapter? chapterAt(int index) => _repository.chapterAt(index);

  String titleFor(int index) => _repository.titleFor(index);

  String chapterUrlAt(int index) => chapterAt(index)?.url ?? '';

  void registerVisibleLocationCapture(
    Object owner,
    ReaderVisibleLocationCapture capture,
  ) {
    _visibleLocationCaptureOwner = owner;
    _visibleLocationCapture = capture;
  }

  void unregisterVisibleLocationCapture(Object owner) {
    if (!identical(_visibleLocationCaptureOwner, owner)) return;
    _visibleLocationCaptureOwner = null;
    _visibleLocationCapture = null;
  }

  void registerViewportRestore(Object owner, ReaderViewportRestore restore) {
    _viewportRestoreOwner = owner;
    _viewportRestore = restore;
  }

  void unregisterViewportRestore(Object owner) {
    if (!identical(_viewportRestoreOwner, owner)) return;
    _viewportRestoreOwner = null;
    _viewportRestore = null;
  }

  String? takeUserNotice() {
    final notice = _pendingUserNotice;
    _pendingUserNotice = null;
    return notice;
  }

  Future<void> openBook() async {
    _setState(state.copyWith(phase: ReaderPhase.loading, clearError: true));
    try {
      await _repository.ensureChapters();
      final location = _initialLocation.normalized(
        chapterCount: _repository.chapterCount,
      );
      if (_viewportRestore != null) {
        final restored = await restoreFromLocation(location);
        if (restored || state.phase == ReaderPhase.error) return;
      }
      await jumpToLocation(location, immediateSave: false);
    } catch (e) {
      _setState(
        state.copyWith(phase: ReaderPhase.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> updateLayoutSpec(LayoutSpec spec) async {
    if (state.layoutSpec.layoutSignature == spec.layoutSignature) return;
    final location = captureVisibleLocation() ?? state.visibleLocation;
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
    await jumpToLocation(location, immediateSave: false);
  }

  Future<void> applyPresentation({
    required LayoutSpec spec,
    required ReaderMode mode,
  }) async {
    final needLayout = state.layoutSpec.layoutSignature != spec.layoutSignature;
    final needMode = state.mode != mode;
    if (!needLayout && !needMode) return;

    _clearPendingNeighborAdvance();
    var generation = state.layoutGeneration;
    if (needLayout) {
      generation = _preloadScheduler.bumpGeneration();
      _resolver.updateLayoutSpec(spec);
      _layoutEngine.invalidateWhere((layout) {
        return layout.layoutSignature != spec.layoutSignature;
      });
    }

    final location = captureVisibleLocation() ?? state.visibleLocation;
    _setState(
      state.copyWith(
        phase: ReaderPhase.switchingMode,
        mode: mode,
        layoutSpec: spec,
        layoutGeneration: generation,
        clearError: true,
      ),
    );
    await jumpToLocation(location, immediateSave: false);
    if (!_disposed &&
        (state.mode != mode || state.phase != ReaderPhase.ready)) {
      _setState(state.copyWith(mode: mode, phase: ReaderPhase.ready));
    }
  }

  Future<void> updateStyle(ReadStyle style, Size viewportSize) {
    return updateLayoutSpec(
      LayoutSpec.fromViewport(viewportSize: viewportSize, style: style),
    );
  }

  Future<void> relayout(ReadStyle style, Size viewportSize) {
    return updateStyle(style, viewportSize);
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
        location.charOffset.clamp(0, content.displayText.length).toInt();
    return content.displayText.substring(safeOffset).trim();
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
    _clearPendingNeighborAdvance();
    final generation = state.layoutGeneration;
    _setState(
      state.copyWith(
        phase: ReaderPhase.layingOut,
        clearError: true,
        clearPageWindow: true,
        clearCurrentSlidePage: true,
      ),
    );
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
        visualOffsetPx: normalized.visualOffsetPx,
      );
      _setState(
        state.copyWith(
          phase: ReaderPhase.ready,
          visibleLocation: resolvedLocation,
          pageWindow: window,
          currentSlidePage: page,
          clearError: true,
        ),
      );
      unawaited(_preloadScheduler.scheduleJump(resolvedLocation.chapterIndex));
    } catch (e) {
      _setState(
        state.copyWith(phase: ReaderPhase.error, errorMessage: e.toString()),
      );
    }
  }

  Future<bool> restoreFromLocation(ReaderLocation location) async {
    if (_disposed || _viewportRestore == null) return false;
    _clearPendingNeighborAdvance();
    final generation = state.layoutGeneration;
    _restoreInProgress = true;
    _setState(
      state.copyWith(
        phase: ReaderPhase.restoring,
        clearError: true,
        clearPageWindow: true,
        clearCurrentSlidePage: true,
      ),
    );
    try {
      await _repository.ensureChapters();
      final normalized = await _normalizeRestoreLocation(location);
      final page = await _pageForRestoreLocation(normalized);
      if (_disposed || generation != state.layoutGeneration) return false;
      final window = await _windowAroundPage(page);
      if (_disposed || generation != state.layoutGeneration) return false;
      final restoreTarget = _locationForRestorePage(normalized, page);
      _setState(
        state.copyWith(
          phase: ReaderPhase.ready,
          pageWindow: window,
          currentSlidePage: page,
          clearError: true,
        ),
      );
      final restore = _viewportRestore;
      if (restore == null) return false;
      final positioned = await restore(restoreTarget);
      if (!positioned || _disposed) return false;
      final captured = _captureVisibleLocation(allowDuringRestore: true);
      return captured != null;
    } catch (e) {
      if (!_disposed) {
        _setState(
          state.copyWith(phase: ReaderPhase.error, errorMessage: e.toString()),
        );
      }
      return false;
    } finally {
      _restoreInProgress = false;
    }
  }

  Future<ReaderLocation> _normalizeRestoreLocation(
    ReaderLocation location,
  ) async {
    await _repository.ensureChapters();
    final chapterCount = _repository.chapterCount;
    final chapterIndex =
        chapterCount <= 0
            ? 0
            : location.chapterIndex.clamp(0, chapterCount - 1).toInt();
    final content = await _repository.loadContent(chapterIndex);
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: location.charOffset,
      visualOffsetPx: location.visualOffsetPx,
    ).normalized(
      chapterCount: chapterCount,
      chapterLength: content.displayText.length,
    );
  }

  Future<TextPage> _pageForRestoreLocation(ReaderLocation location) async {
    if (state.mode == ReaderMode.slide) {
      return _slidePageForRestoreLocation(location);
    }
    return _resolver.pageForLocation(location);
  }

  Future<TextPage> _slidePageForRestoreLocation(ReaderLocation location) async {
    final layout = await _resolver.ensureLayout(location.chapterIndex);
    if (layout.pages.isEmpty) return layout.pageForCharOffset(0);
    final basePage = layout.pageForCharOffset(location.charOffset);
    final anchorY = _anchorOffsetInViewport();
    final desiredLineTopOnPage =
        anchorY - state.layoutSpec.style.paddingTop - location.visualOffsetPx;
    TextPage? bestPage;
    int? bestCharDistance;
    double? bestVisualDistance;
    for (
      var index = basePage.pageIndex - 1;
      index <= basePage.pageIndex + 1;
      index++
    ) {
      if (index < 0 || index >= layout.pages.length) continue;
      final page = layout.pages[index];
      final nearestLine = _nearestLineOnPage(page, desiredLineTopOnPage);
      final charDistance =
          ((nearestLine?.startCharOffset ?? page.startCharOffset) -
                  location.charOffset)
              .abs();
      final visualDistance =
          nearestLine == null
              ? double.infinity
              : (nearestLine.top - desiredLineTopOnPage).abs();
      if (bestPage == null ||
          charDistance < bestCharDistance! ||
          (charDistance == bestCharDistance &&
              visualDistance < bestVisualDistance!)) {
        bestPage = page;
        bestCharDistance = charDistance;
        bestVisualDistance = visualDistance;
      }
    }
    return bestPage ?? basePage;
  }

  TextLine? _nearestLineOnPage(TextPage page, double pageY) {
    TextLine? nearest;
    var nearestDistance = double.infinity;
    for (final line in page.lines) {
      if (line.text.isEmpty) continue;
      if (pageY >= line.top && pageY <= line.bottom) return line;
      final distance =
          pageY < line.top ? line.top - pageY : pageY - line.bottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = line;
      }
    }
    return nearest;
  }

  Future<PageWindow> _windowAroundPage(TextPage page) async {
    final prev = await _resolver.prevPage(page, allowAsyncLoad: true);
    final next = await _resolver.nextPage(page, allowAsyncLoad: true);
    return PageWindow(
      prev: prev,
      current: page,
      next: next,
      lookAhead: const <TextPage>[],
    );
  }

  ReaderLocation _locationForRestorePage(
    ReaderLocation location,
    TextPage page,
  ) {
    return ReaderLocation(
      chapterIndex: page.chapterIndex,
      charOffset:
          location.charOffset
              .clamp(page.startCharOffset, page.endCharOffset)
              .toInt(),
      visualOffsetPx: location.visualOffsetPx,
    );
  }

  double _anchorOffsetInViewport() {
    final height = state.layoutSpec.viewportSize.height;
    final viewportHeight = height.isFinite && height > 0 ? height : 1.0;
    return (viewportHeight * 0.2).clamp(24.0, 120.0).toDouble();
  }

  PageCache pageCacheFor(TextPage page) {
    if (page.isPlaceholder) return page.toPageCache();
    final layout = _resolver.cachedLayout(page.chapterIndex);
    if (layout != null &&
        page.pageIndex >= 0 &&
        page.pageIndex < layout.pages.length) {
      final cachedPage = layout.pages[page.pageIndex];
      if (cachedPage.startCharOffset == page.startCharOffset &&
          cachedPage.endCharOffset == page.endCharOffset) {
        return cachedPage.toPageCache();
      }
    }
    return page.toPageCache();
  }

  Future<void> switchMode(ReaderMode mode) async {
    if (state.mode == mode) return;
    final location = captureVisibleLocation() ?? state.visibleLocation;
    _setState(
      state.copyWith(
        phase: ReaderPhase.switchingMode,
        mode: mode,
        clearPageWindow: true,
        clearCurrentSlidePage: true,
      ),
    );
    await jumpToLocation(location, immediateSave: false);
    _setState(state.copyWith(mode: mode, phase: ReaderPhase.ready));
  }

  bool moveToNextPage() {
    final window = state.pageWindow;
    final next = window?.next;
    if (window == null) return false;
    if (next == null) {
      _clearPendingNeighborAdvance();
      return false;
    }
    if (next.isPlaceholder) {
      if (next.isLoading) {
        _rememberPendingNeighborAdvance(current: window.current, forward: true);
      } else {
        _clearPendingNeighborAdvance();
        _emitUserNotice('下一章載入失敗，請再試一次或返回目錄');
      }
      _scheduleMissingNeighborPreload(forward: true);
      return false;
    }
    _clearPendingNeighborAdvance();
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
        phase: ReaderPhase.ready,
      ),
    );
    unawaited(_preloadScheduler.scheduleScrollSettled(next));
    return true;
  }

  bool moveToNextTile() => moveToNextPage();

  bool moveToPrevPage() {
    final window = state.pageWindow;
    final prev = window?.prev;
    if (window == null) return false;
    if (prev == null) {
      _clearPendingNeighborAdvance();
      return false;
    }
    if (prev.isPlaceholder) {
      if (prev.isLoading) {
        _rememberPendingNeighborAdvance(
          current: window.current,
          forward: false,
        );
      } else {
        _clearPendingNeighborAdvance();
        _emitUserNotice('上一章載入失敗，請再試一次或返回目錄');
      }
      _scheduleMissingNeighborPreload(forward: false);
      return false;
    }
    _clearPendingNeighborAdvance();
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
        phase: ReaderPhase.ready,
      ),
    );
    unawaited(_preloadScheduler.scheduleScrollSettled(prev));
    return true;
  }

  bool moveToPrevTile() => moveToPrevPage();

  Future<void> prefetchForward() async {
    final window = state.pageWindow;
    if (window == null) return;
    final next = window.next;
    if (next == null) return;
    if (next.isPlaceholder) {
      await _preloadScheduler.scheduleLayout(next.chapterIndex);
      if (!_disposed) {
        await refreshNeighbors();
      }
      return;
    }
    if (window.current.pageIndex >= window.current.pageSize - 2) {
      await _preloadScheduler.scheduleDirectional(
        fromChapterIndex: window.current.chapterIndex,
        forward: true,
      );
      if (!_disposed) {
        await refreshNeighbors();
      }
    }
  }

  Future<void> prefetchBackward() async {
    final window = state.pageWindow;
    if (window == null) return;
    final prev = window.prev;
    if (prev == null) return;
    if (prev.isPlaceholder) {
      await _preloadScheduler.scheduleLayout(prev.chapterIndex);
      if (!_disposed) {
        await refreshNeighbors();
      }
      return;
    }
    if (window.current.pageIndex <= 1) {
      await _preloadScheduler.scheduleDirectional(
        fromChapterIndex: window.current.chapterIndex,
        forward: false,
      );
      if (!_disposed) {
        await refreshNeighbors();
      }
    }
  }

  ReaderLocation resolveVisibleLocation({
    required double pageOffset,
    required double viewportHeight,
    double anchorFraction = 0.2,
  }) {
    final window = state.pageWindow;
    if (window == null) return state.visibleLocation;
    final anchorY = viewportHeight * anchorFraction;
    if (pageOffset > 0 && window.prev != null) {
      final prev = window.prev!;
      final prevTop = pageOffset - prev.viewportHeight;
      final prevBottom = pageOffset;
      if (anchorY >= prevTop && anchorY < prevBottom) {
        return _locationInPage(prev, anchorY - prevTop);
      }
    }

    var visualY = anchorY - pageOffset;
    for (final page in window.paintForwardPages) {
      if (visualY <= page.viewportHeight) {
        return _locationInPage(page, visualY);
      }
      visualY -= page.viewportHeight;
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
    _setState(state.copyWith(visibleLocation: normalized));
  }

  void handleSlidePageSettled(TextPage page) {
    final location = ReaderLocation(
      chapterIndex: page.chapterIndex,
      charOffset: page.startCharOffset,
    );
    _setState(
      state.copyWith(currentSlidePage: page, visibleLocation: location),
    );
    unawaited(saveProgress());
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
    _maybeAutoAdvancePendingNeighbor();
  }

  ReaderLocation? captureVisibleLocation() {
    return _captureVisibleLocation();
  }

  ReaderLocation? _captureVisibleLocation({bool allowDuringRestore = false}) {
    if (_disposed || state.phase != ReaderPhase.ready) return null;
    if (_restoreInProgress && !allowDuringRestore) return null;
    final capture = _visibleLocationCapture;
    if (capture == null) return null;
    final captured = _normalizeCapturedLocation(capture());
    if (captured == null) return null;
    if (captured == state.visibleLocation) return captured;
    _setState(state.copyWith(visibleLocation: captured));
    return captured;
  }

  Future<ReaderLocation?> saveProgress() async {
    if (_restoreInProgress) return null;
    final location = captureVisibleLocation();
    if (location == null) return null;
    if (location == state.committedLocation) return location;
    _setState(state.copyWith(committedLocation: location));
    await _progressController.saveImmediately(location);
    return location;
  }

  Future<ReaderLocation?> flushProgress() => saveProgress();

  ReaderLocation? _normalizeCapturedLocation(ReaderLocation? location) {
    if (location == null) return null;
    final visualOffset = location.visualOffsetPx;
    if (!visualOffset.isFinite || visualOffset.isNaN) return null;
    if (visualOffset < ReaderLocation.minVisualOffsetPx ||
        visualOffset > ReaderLocation.maxVisualOffsetPx) {
      return null;
    }
    return location.normalized(chapterCount: _repository.chapterCount);
  }

  ReaderLocation _locationInPage(TextPage page, double pageY) {
    final contentY =
        (pageY - state.layoutSpec.style.paddingTop)
            .clamp(0.0, page.contentHeight)
            .toDouble();
    if (page.lines.isEmpty) {
      return ReaderLocation(
        chapterIndex: page.chapterIndex,
        charOffset: page.startCharOffset,
        visualOffsetPx: 0,
      );
    }
    TextLine nearest = page.lines.first;
    var nearestDistance = double.infinity;
    for (final line in page.lines) {
      if (contentY >= line.top && contentY <= line.bottom) {
        return ReaderLocation(
          chapterIndex: page.chapterIndex,
          charOffset: line.startCharOffset,
          visualOffsetPx: contentY - line.top,
        );
      }
      final distance =
          contentY < line.top ? line.top - contentY : contentY - line.bottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = line;
      }
    }
    return ReaderLocation(
      chapterIndex: page.chapterIndex,
      charOffset: nearest.startCharOffset,
      visualOffsetPx: contentY - nearest.top,
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

  void _rememberPendingNeighborAdvance({
    required TextPage current,
    required bool forward,
  }) {
    _pendingNeighborAdvanceOrigin = _resolver.addressOf(current);
    _pendingNeighborAdvanceDirection = forward ? 1 : -1;
  }

  void _clearPendingNeighborAdvance() {
    _pendingNeighborAdvanceOrigin = null;
    _pendingNeighborAdvanceDirection = 0;
  }

  void _maybeAutoAdvancePendingNeighbor() {
    final direction = _pendingNeighborAdvanceDirection;
    final origin = _pendingNeighborAdvanceOrigin;
    final window = state.pageWindow;
    if (direction == 0 || origin == null || window == null) return;

    final currentAddress = _resolver.addressOf(window.current);
    if (currentAddress.chapterIndex != origin.chapterIndex ||
        currentAddress.pageIndex != origin.pageIndex) {
      _clearPendingNeighborAdvance();
      return;
    }

    final forward = direction > 0;
    final neighbor = forward ? window.next : window.prev;
    if (neighbor == null) {
      _clearPendingNeighborAdvance();
      return;
    }
    if (neighbor.isLoading) return;
    if (neighbor.errorMessage != null) {
      _clearPendingNeighborAdvance();
      _emitUserNotice(forward ? '下一章載入失敗，請再試一次或返回目錄' : '上一章載入失敗，請再試一次或返回目錄');
      return;
    }

    if (forward) {
      moveToNextPage();
    } else {
      moveToPrevPage();
    }
  }

  void _emitUserNotice(String message) {
    if (_disposed || message.isEmpty) return;
    _pendingUserNotice = message;
    notifyListeners();
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
