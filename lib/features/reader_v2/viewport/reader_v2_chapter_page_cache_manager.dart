import 'package:inkpage_reader/features/reader_v2/render/reader_v2_page_cache.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_chapter_view.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_runtime.dart';

typedef ReaderV2ScrollPageExtentResolver =
    double Function(ReaderV2PageCache page);

class ReaderV2CachedChapterPages {
  ReaderV2CachedChapterPages({
    required this.layout,
    required List<ReaderV2PageCache> pages,
    required List<double> pageExtents,
  }) : pages = List<ReaderV2PageCache>.unmodifiable(pages),
       pageExtents = List<double>.unmodifiable(pageExtents),
       pagePrefixOffsets = List<double>.unmodifiable(
         _prefixOffsets(pageExtents),
       ),
       extent = _visualExtent(pageExtents);

  final ReaderV2ChapterView layout;
  final List<ReaderV2PageCache> pages;
  final List<double> pageExtents;
  final List<double> pagePrefixOffsets;
  final double extent;

  int get chapterIndex => layout.chapterIndex;

  ReaderV2PageCache? pageAt(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return null;
    return pages[pageIndex];
  }

  double pageExtentAt(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageExtents.length) return 1.0;
    final extent = pageExtents[pageIndex];
    return extent.isFinite && extent > 0 ? extent : 1.0;
  }

  double? pageOffsetTop(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return null;
    return pagePrefixOffsets[pageIndex];
  }

  static List<double> _prefixOffsets(List<double> pageExtents) {
    final offsets = <double>[];
    var top = 0.0;
    for (final extent in pageExtents) {
      offsets.add(top);
      top += _normalPageExtent(extent);
    }
    return offsets;
  }

  static double _visualExtent(List<double> pageExtents) {
    final extent = pageExtents.fold<double>(
      0.0,
      (total, pageExtent) => total + _normalPageExtent(pageExtent),
    );
    return extent <= 0 ? 1.0 : extent;
  }

  static double _normalPageExtent(double extent) {
    return extent.isFinite && extent > 0 ? extent : 1.0;
  }
}

class ReaderV2ChapterPageCacheWindow {
  const ReaderV2ChapterPageCacheWindow({
    required this.center,
    required this.previous,
    required this.next,
  });

  final ReaderV2CachedChapterPages center;
  final List<ReaderV2CachedChapterPages> previous;
  final List<ReaderV2CachedChapterPages> next;

  Set<int> get retainedChapterIndexes => <int>{
    center.chapterIndex,
    for (final chapter in previous) chapter.chapterIndex,
    for (final chapter in next) chapter.chapterIndex,
  };
}

class ReaderV2ChapterPageCacheManager {
  ReaderV2ChapterPageCacheManager({
    required this.runtime,
    required ReaderV2ScrollPageExtentResolver pageExtent,
  }) : _pageExtent = pageExtent;

  final ReaderV2Runtime runtime;
  final ReaderV2ScrollPageExtentResolver _pageExtent;

  final Map<int, ReaderV2CachedChapterPages> _chapters =
      <int, ReaderV2CachedChapterPages>{};
  final Map<int, Future<ReaderV2CachedChapterPages>> _inFlightLoads =
      <int, Future<ReaderV2CachedChapterPages>>{};
  final Set<int> _evictedChapters = <int>{};
  int _cacheGeneration = 0;
  int _revision = 0;
  String? _lastInvalidationReason;

  bool get hasChapters => _chapters.isNotEmpty;
  int get cacheGeneration => _cacheGeneration;
  int get revision => _revision;
  String? get lastInvalidationReason => _lastInvalidationReason;

  bool containsChapter(int chapterIndex) => _chapters.containsKey(chapterIndex);

  ReaderV2CachedChapterPages? chapterAt(int chapterIndex) {
    return _chapters[chapterIndex];
  }

  List<int> chapterIndexes() {
    return _chapters.keys.toList(growable: false)..sort();
  }

  Future<ReaderV2CachedChapterPages?> ensureChapter(
    int chapterIndex, {
    bool Function()? isCurrent,
  }) async {
    if (runtime.chapterCount <= 0) return null;
    final safeIndex = _safeChapterIndex(chapterIndex);
    final cached = _chapters[safeIndex];
    if (cached != null) return cached;
    _evictedChapters.remove(safeIndex);
    final generation = _cacheGeneration;
    try {
      final loaded = await _loadChapter(safeIndex);
      if (generation != _cacheGeneration ||
          _evictedChapters.contains(safeIndex) ||
          !(isCurrent?.call() ?? true)) {
        return null;
      }
      _chapters[safeIndex] = loaded;
      _bumpRevision();
      return loaded;
    } catch (_) {
      return null;
    }
  }

  Future<bool> ensureChapterLoaded(
    int chapterIndex, {
    bool Function()? isCurrent,
  }) async {
    final chapter = await ensureChapter(chapterIndex, isCurrent: isCurrent);
    return chapter != null;
  }

  Future<ReaderV2ChapterPageCacheWindow?> ensureWindowAround({
    required int centerChapterIndex,
    required double backwardExtent,
    required double forwardExtent,
    bool Function()? isCurrent,
  }) async {
    if (runtime.chapterCount <= 0) return null;
    final generation = _cacheGeneration;
    bool stillCurrent() {
      return generation == _cacheGeneration && (isCurrent?.call() ?? true);
    }

    final center = await ensureChapter(
      centerChapterIndex,
      isCurrent: stillCurrent,
    );
    if (center == null || !stillCurrent()) return null;

    final previous = <ReaderV2CachedChapterPages>[];
    var previousIndex = center.chapterIndex - 1;
    var loadedPreviousCount = 0;
    var backwardCoveredExtent = 0.0;
    while (previousIndex >= 0 &&
        (loadedPreviousCount == 0 ||
            backwardCoveredExtent < _normalExtent(backwardExtent))) {
      final chapter = await ensureChapter(
        previousIndex,
        isCurrent: stillCurrent,
      );
      if (!stillCurrent()) return null;
      if (chapter != null) {
        previous.add(chapter);
        backwardCoveredExtent += chapter.extent;
      }
      loadedPreviousCount += 1;
      previousIndex -= 1;
    }

    final next = <ReaderV2CachedChapterPages>[];
    var nextIndex = center.chapterIndex + 1;
    var loadedNextCount = 0;
    var forwardCoveredExtent = 0.0;
    while (nextIndex < runtime.chapterCount &&
        (loadedNextCount == 0 ||
            forwardCoveredExtent < _normalExtent(forwardExtent))) {
      final chapter = await ensureChapter(nextIndex, isCurrent: stillCurrent);
      if (!stillCurrent()) return null;
      if (chapter != null) {
        next.add(chapter);
        forwardCoveredExtent += chapter.extent;
      }
      loadedNextCount += 1;
      nextIndex += 1;
    }

    if (!stillCurrent()) return null;
    final window = ReaderV2ChapterPageCacheWindow(
      center: center,
      previous: List<ReaderV2CachedChapterPages>.unmodifiable(previous),
      next: List<ReaderV2CachedChapterPages>.unmodifiable(next),
    );
    evictOutsideWindow(window.retainedChapterIndexes);
    return window;
  }

  Future<ReaderV2ChapterPageCacheWindow?> preloadAround({
    required int centerChapterIndex,
    required double backwardExtent,
    required double forwardExtent,
    bool Function()? isCurrent,
  }) {
    return ensureWindowAround(
      centerChapterIndex: centerChapterIndex,
      backwardExtent: backwardExtent,
      forwardExtent: forwardExtent,
      isCurrent: isCurrent,
    );
  }

  void evictOutsideWindow(Set<int> retained) {
    final retainedSafeIndexes = retained.map(_safeChapterIndex).toSet();
    final evicted = <int>{};
    for (final chapterIndex in _chapters.keys) {
      if (!retainedSafeIndexes.contains(chapterIndex)) {
        evicted.add(chapterIndex);
      }
    }
    for (final chapterIndex in _inFlightLoads.keys) {
      if (!retainedSafeIndexes.contains(chapterIndex)) {
        evicted.add(chapterIndex);
      }
    }
    final hadEvictions = evicted.isNotEmpty;
    _evictedChapters
      ..addAll(evicted)
      ..removeWhere(retainedSafeIndexes.contains);
    _chapters.removeWhere(
      (chapterIndex, _) => !retainedSafeIndexes.contains(chapterIndex),
    );
    _inFlightLoads.removeWhere(
      (chapterIndex, _) => !retainedSafeIndexes.contains(chapterIndex),
    );
    if (hadEvictions) _bumpRevision();
    runtime.debugResolver.retainLayoutsFor(retainedSafeIndexes);
  }

  void retainChapters(Set<int> retained) {
    evictOutsideWindow(retained);
  }

  void evictFarFrom({
    required int centerChapterIndex,
    required int chapterRadius,
  }) {
    final center = _safeChapterIndex(centerChapterIndex);
    final radius = chapterRadius < 0 ? 0 : chapterRadius;
    evictOutsideWindow(<int>{
      for (
        var chapterIndex = center - radius;
        chapterIndex <= center + radius;
        chapterIndex++
      )
        if (_isValidChapterIndex(chapterIndex)) chapterIndex,
    });
  }

  void invalidateAll({String? reason}) {
    _cacheGeneration += 1;
    _bumpRevision();
    _lastInvalidationReason = reason;
    _chapters.clear();
    _inFlightLoads.clear();
    _evictedChapters.clear();
  }

  void clear() {
    invalidateAll(reason: 'clear');
  }

  int _safeChapterIndex(int chapterIndex) {
    final chapterCount = runtime.chapterCount;
    if (chapterCount <= 0) return 0;
    return chapterIndex.clamp(0, chapterCount - 1).toInt();
  }

  bool _isValidChapterIndex(int chapterIndex) {
    return chapterIndex >= 0 && chapterIndex < runtime.chapterCount;
  }

  double _normalExtent(double extent) {
    if (!extent.isFinite || extent <= 0) return 1.0;
    return extent;
  }

  void _bumpRevision() {
    _revision += 1;
  }

  Future<ReaderV2CachedChapterPages> _loadChapter(int chapterIndex) {
    final safeIndex = _safeChapterIndex(chapterIndex);
    final existing = _inFlightLoads[safeIndex];
    if (existing != null) return existing;

    late final Future<ReaderV2CachedChapterPages> task;
    task = () async {
      try {
        final layout = await runtime.debugResolver.ensureLayout(
          safeIndex,
          retryOnStale: false,
        );
        final pages = ReaderV2PageCacheFactory.fromRenderPages(layout.pages);
        final pageExtents = pages.map(_pageExtent).toList(growable: false);
        return ReaderV2CachedChapterPages(
          layout: layout,
          pages: pages,
          pageExtents: pageExtents,
        );
      } finally {
        if (identical(_inFlightLoads[safeIndex], task)) {
          _inFlightLoads.remove(safeIndex);
        }
      }
    }();
    _inFlightLoads[safeIndex] = task;
    return task;
  }
}
