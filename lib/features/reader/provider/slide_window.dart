import 'package:legado_reader/features/reader/engine/text_page.dart';

/// A segment within the slide window, representing one chapter's pages.
class SlideSegment {
  final int chapterIndex;
  final List<TextPage> pages;

  const SlideSegment({required this.chapterIndex, required this.pages});

  int get length => pages.length;
  bool get isEmpty => pages.isEmpty;
  bool get isNotEmpty => pages.isNotEmpty;
}

/// Resolved position within a [SlideWindow].
typedef SlidePosition = ({int segmentIdx, int localIdx, int chapterIndex});

/// Manages a sliding 3-chapter window for PageView-based page turning.
///
/// Instead of a flat merged list, tracks each chapter's pages as a separate
/// [SlideSegment] with offset arithmetic for global↔local index mapping.
class SlideWindow {
  final List<SlideSegment> segments;

  const SlideWindow(this.segments);

  static const empty = SlideWindow([]);

  int get totalPages => segments.fold(0, (sum, s) => sum + s.length);
  bool get isEmpty => segments.isEmpty || totalPages == 0;
  bool get isNotEmpty => !isEmpty;

  /// All pages as a flat list (for backward compatibility with PageView).
  List<TextPage> get flatPages =>
      segments.expand((s) => s.pages).toList(growable: false);

  /// The chapter index of the center segment (the "current" chapter).
  int? get centerChapterIndex {
    if (segments.isEmpty) return null;
    if (segments.length == 1) return segments[0].chapterIndex;
    return segments[segments.length ~/ 2].chapterIndex;
  }

  /// Resolve a global page index to its segment and local page index.
  SlidePosition resolve(int globalIndex) {
    int offset = 0;
    for (int i = 0; i < segments.length; i++) {
      if (globalIndex < offset + segments[i].length) {
        return (
          segmentIdx: i,
          localIdx: globalIndex - offset,
          chapterIndex: segments[i].chapterIndex,
        );
      }
      offset += segments[i].length;
    }
    if (segments.isEmpty) {
      return (segmentIdx: 0, localIdx: 0, chapterIndex: -1);
    }
    final last = segments.last;
    return (
      segmentIdx: segments.length - 1,
      localIdx: last.length - 1,
      chapterIndex: last.chapterIndex,
    );
  }

  /// Map (chapterIndex, localPageIndex) to a global index within this window.
  /// Returns -1 if the chapter is not in the window.
  int toGlobal(int chapterIndex, int localPageIndex) {
    int offset = 0;
    for (final seg in segments) {
      if (seg.chapterIndex == chapterIndex) {
        return offset + localPageIndex.clamp(0, seg.length - 1);
      }
      offset += seg.length;
    }
    return -1;
  }

  /// Find the global index of a page by matching chapterIndex and TextPage.index.
  int findByPage(TextPage page) {
    int offset = 0;
    for (final seg in segments) {
      if (seg.chapterIndex == page.chapterIndex) {
        for (int i = 0; i < seg.pages.length; i++) {
          if (seg.pages[i].index == page.index) {
            return offset + i;
          }
        }
        return offset;
      }
      offset += seg.length;
    }
    return -1;
  }

  /// Whether the given chapter is part of this window.
  bool containsChapter(int chapterIndex) =>
      segments.any((s) => s.chapterIndex == chapterIndex);

  /// Build a new window centered on [centerChapterIndex].
  ///
  /// Returns the new window and the remapped global index for [currentPage]
  /// so the PageView can jump to the correct position in the new window.
  static ({SlideWindow window, int mappedIndex}) build({
    required int centerChapterIndex,
    required TextPage? currentPage,
    required Map<int, List<TextPage>> cache,
    required int totalChapters,
  }) {
    final prevIdx = centerChapterIndex - 1;
    final nextIdx = centerChapterIndex + 1;

    final newSegments = <SlideSegment>[
      if (prevIdx >= 0 && (cache[prevIdx]?.isNotEmpty ?? false))
        SlideSegment(chapterIndex: prevIdx, pages: cache[prevIdx]!),
      if (cache[centerChapterIndex]?.isNotEmpty ?? false)
        SlideSegment(
            chapterIndex: centerChapterIndex,
            pages: cache[centerChapterIndex]!),
      if (nextIdx < totalChapters && (cache[nextIdx]?.isNotEmpty ?? false))
        SlideSegment(chapterIndex: nextIdx, pages: cache[nextIdx]!),
    ];

    final newWindow = SlideWindow(newSegments);

    int mappedIndex = 0;
    if (currentPage != null) {
      final found = newWindow.findByPage(currentPage);
      if (found >= 0) {
        mappedIndex = found;
      }
    }

    return (window: newWindow, mappedIndex: mappedIndex);
  }
}
