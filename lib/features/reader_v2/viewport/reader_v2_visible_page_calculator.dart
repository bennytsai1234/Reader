import 'package:inkpage_reader/features/reader_v2/render/reader_v2_page_cache.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_chapter_view.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_chapter_page_cache_manager.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_infinite_segment_strip.dart';

class ReaderV2VisiblePage {
  const ReaderV2VisiblePage({
    required this.layout,
    required this.page,
    required this.worldTop,
    required this.extent,
  });

  final ReaderV2ChapterView layout;
  final ReaderV2PageCache page;
  final double worldTop;
  final double extent;

  double get worldBottom => worldTop + extent;

  double screenY(double readingY) => worldTop - readingY;
}

class ReaderV2VisiblePageCalculator {
  ReaderV2VisiblePageCalculator({
    required ReaderV2ChapterPageCacheManager cacheManager,
    required ReaderV2InfiniteSegmentStrip strip,
  }) : _cacheManager = cacheManager,
       _strip = strip;

  final ReaderV2ChapterPageCacheManager _cacheManager;
  final ReaderV2InfiniteSegmentStrip _strip;
  List<ReaderV2VisiblePage>? _cachedAllPages;
  int? _cachedCacheRevision;
  int? _cachedStripRevision;

  bool get hasPages => allPages().isNotEmpty;

  List<ReaderV2VisiblePage> allPages() {
    final cacheRevision = _cacheManager.revision;
    final stripRevision = _strip.revision;
    final cached = _cachedAllPages;
    if (cached != null &&
        _cachedCacheRevision == cacheRevision &&
        _cachedStripRevision == stripRevision) {
      return cached;
    }

    final placements = <ReaderV2VisiblePage>[];
    for (final chapterIndex in _cacheManager.chapterIndexes()) {
      final chapter = _cacheManager.chapterAt(chapterIndex);
      final chapterTop = _strip.chapterTop(chapterIndex);
      if (chapter == null || chapterTop == null) continue;
      for (var pageIndex = 0; pageIndex < chapter.pages.length; pageIndex++) {
        final page = chapter.pages[pageIndex];
        final extent = chapter.pageExtentAt(pageIndex);
        final pageOffset = chapter.pageOffsetTop(pageIndex);
        if (pageOffset == null) continue;
        placements.add(
          ReaderV2VisiblePage(
            layout: chapter.layout,
            page: page,
            worldTop: chapterTop + pageOffset,
            extent: extent,
          ),
        );
      }
    }
    placements.sort((a, b) => a.worldTop.compareTo(b.worldTop));
    final result = List<ReaderV2VisiblePage>.unmodifiable(placements);
    _cachedAllPages = result;
    _cachedCacheRevision = cacheRevision;
    _cachedStripRevision = stripRevision;
    return result;
  }

  List<ReaderV2VisiblePage> visiblePages({
    required double readingY,
    required double viewportHeight,
  }) {
    final visibleTop = readingY;
    final visibleBottom = readingY + viewportHeight;
    return allPages()
        .where(
          (placement) =>
              placement.worldTop < visibleBottom &&
              placement.worldBottom > visibleTop,
        )
        .toList(growable: false);
  }

  ReaderV2VisiblePage? placementAtWorldY(double worldY) {
    ReaderV2VisiblePage? nearest;
    var nearestDistance = double.infinity;
    for (final placement in allPages()) {
      if (worldY >= placement.worldTop && worldY < placement.worldBottom) {
        return placement;
      }
      final distance =
          worldY < placement.worldTop
              ? placement.worldTop - worldY
              : worldY - placement.worldBottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = placement;
      }
    }
    return nearest;
  }
}
