import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/slide_window.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_content_coordinator.dart';

class ReaderSlideWindowUpdate {
  final List<TextPage> slidePages;
  final int currentPageIndex;
  final bool shouldRequestJump;

  const ReaderSlideWindowUpdate({
    required this.slidePages,
    required this.currentPageIndex,
    required this.shouldRequestJump,
  });
}

class ReaderSlidePageChange {
  final int chapterIndex;
  final double localOffset;
  final bool needsRecenter;

  const ReaderSlidePageChange({
    required this.chapterIndex,
    required this.localOffset,
    required this.needsRecenter,
  });
}

class ReaderContentPipeline {
  final ReaderContentCoordinator _contentCoordinator;
  SlideWindow _slideWindow = SlideWindow.empty;
  ReaderPresentationAnchor? _pinnedSlideAnchor;
  int? _pendingRecenterChapterIndex;

  ReaderContentPipeline({
    ReaderContentCoordinator contentCoordinator =
        const ReaderContentCoordinator(),
  }) : _contentCoordinator = contentCoordinator;

  SlideWindow get slideWindow => _slideWindow;
  bool get hasPendingSlideRecenter => _pendingRecenterChapterIndex != null;

  ReaderContentPresentation resolvePresentation(
    ReaderPresentationRequest request,
  ) {
    return _contentCoordinator.resolvePresentation(request);
  }

  void reset() {
    _slideWindow = SlideWindow.empty;
    _pinnedSlideAnchor = null;
    _pendingRecenterChapterIndex = null;
  }

  void clearPendingSlideRecenter() {
    _pendingRecenterChapterIndex = null;
  }

  void pinSlideTarget({
    required int chapterIndex,
    required int charOffset,
    bool fromEnd = false,
  }) {
    _pinnedSlideAnchor =
        ReaderPresentationAnchor(
          location: ReaderLocation(
            chapterIndex: chapterIndex,
            charOffset: charOffset,
          ),
          fromEnd: fromEnd,
        ).normalized();
  }

  ReaderSlideWindowUpdate? applyPendingSlideRecenter({
    required int currentPageIndex,
    required List<TextPage> currentSlidePages,
    required Map<int, List<TextPage>> chapterPagesCache,
    required int totalChapters,
  }) {
    final chapterIndex = _pendingRecenterChapterIndex;
    if (chapterIndex == null) return null;
    _pendingRecenterChapterIndex = null;

    final currentPage =
        currentPageIndex >= 0 && currentPageIndex < currentSlidePages.length
            ? currentSlidePages[currentPageIndex]
            : null;
    final result = SlideWindow.build(
      centerChapterIndex: chapterIndex,
      currentPage: currentPage,
      cache: chapterPagesCache,
      totalChapters: totalChapters,
    );
    _slideWindow = result.window;
    final slidePages = result.window.flatPages;
    final nextPageIndex =
        slidePages.isEmpty
            ? 0
            : result.mappedIndex.clamp(0, slidePages.length - 1);
    return ReaderSlideWindowUpdate(
      slidePages: slidePages,
      currentPageIndex: nextPageIndex,
      shouldRequestJump: false,
    );
  }

  ReaderSlideWindowUpdate rebuildSlidePages({
    required int currentChapterIndex,
    required int currentPageIndex,
    required List<TextPage> currentSlidePages,
    required List<TextPage>? runtimePages,
    required Map<int, List<TextPage>> chapterPagesCache,
    required int totalChapters,
    required ReaderLocation durableLocation,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    final currentPage =
        currentPageIndex >= 0 && currentPageIndex < currentSlidePages.length
            ? currentSlidePages[currentPageIndex]
            : null;

    final ({SlideWindow window, List<TextPage> slidePages, int mappedIndex})
    display;

    if (runtimePages != null && runtimePages.isNotEmpty) {
      final segmentMap = <int, List<TextPage>>{};
      for (final page in runtimePages) {
        segmentMap.putIfAbsent(page.chapterIndex, () => []).add(page);
      }
      final window = SlideWindow(
        segmentMap.entries.map((entry) {
          return SlideSegment(chapterIndex: entry.key, pages: entry.value);
        }).toList(),
      );
      display = (
        window: window,
        slidePages: runtimePages,
        mappedIndex: currentPage != null ? window.findByPage(currentPage) : -1,
      );
    } else {
      final result = SlideWindow.build(
        centerChapterIndex: currentChapterIndex,
        currentPage: currentPage,
        cache: chapterPagesCache,
        totalChapters: totalChapters,
      );
      display = (
        window: result.window,
        slidePages: result.window.flatPages,
        mappedIndex: result.mappedIndex,
      );
    }

    _slideWindow = display.window;
    if (display.slidePages.isEmpty) {
      return const ReaderSlideWindowUpdate(
        slidePages: <TextPage>[],
        currentPageIndex: 0,
        shouldRequestJump: false,
      );
    }

    final targetIndex = _contentCoordinator.resolveSlideTargetIndex(
      ReaderSlideTargetRequest(
        pinnedAnchor: _pinnedSlideAnchor,
        previousMappedIndex:
            display.mappedIndex >= 0 ? display.mappedIndex : null,
        durableLocation: durableLocation.normalized(),
        slidePages: display.slidePages,
        resolutionMode:
            currentPage == null
                ? ReaderSlideTargetResolutionMode.startupRestore
                : ReaderSlideTargetResolutionMode.recenter,
        chapterAt: chapterAt,
        pagesForChapter: pagesForChapter,
      ),
    );
    final nextPageIndex = targetIndex.clamp(0, display.slidePages.length - 1);
    return ReaderSlideWindowUpdate(
      slidePages: display.slidePages,
      currentPageIndex: nextPageIndex,
      shouldRequestJump: nextPageIndex != currentPageIndex,
    );
  }

  ReaderSlidePageChange? handleSlidePageChanged({
    required int pageIndex,
    required List<TextPage> slidePages,
    required int currentChapterIndex,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
  }) {
    if (pageIndex < 0 || pageIndex >= slidePages.length) return null;
    final page = slidePages[pageIndex];
    final newChapterIndex = page.chapterIndex;
    final localOffset = ChapterPositionResolver.charOffsetToLocalOffset(
      pagesForChapter(newChapterIndex),
      ChapterPositionResolver.getCharOffsetForPage(
        pagesForChapter(newChapterIndex),
        page.index,
      ),
    );

    if (_isPinnedSlideTargetReached(
      currentPageIndex: pageIndex,
      slidePages: slidePages,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
    )) {
      _pinnedSlideAnchor = null;
    }

    final needsRecenter = newChapterIndex != currentChapterIndex;
    if (needsRecenter) {
      _pendingRecenterChapterIndex = newChapterIndex;
    }
    return ReaderSlidePageChange(
      chapterIndex: newChapterIndex,
      localOffset: localOffset,
      needsRecenter: needsRecenter,
    );
  }

  bool _isPinnedSlideTargetReached({
    required int currentPageIndex,
    required List<TextPage> slidePages,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    final pinnedAnchor = _pinnedSlideAnchor;
    if (pinnedAnchor == null || slidePages.isEmpty) return true;
    final targetIndex = _contentCoordinator.resolveSlideTargetIndex(
      ReaderSlideTargetRequest(
        pinnedAnchor: pinnedAnchor,
        previousMappedIndex: null,
        durableLocation: pinnedAnchor.location,
        slidePages: slidePages,
        resolutionMode: ReaderSlideTargetResolutionMode.startupRestore,
        chapterAt: chapterAt,
        pagesForChapter: pagesForChapter,
      ),
    );
    return currentPageIndex == targetIndex;
  }
}
