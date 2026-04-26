import 'package:inkpage_reader/features/reader/engine/line_layout.dart';
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
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    final chapterIndex = _pendingRecenterChapterIndex;
    if (chapterIndex == null) return null;
    _pendingRecenterChapterIndex = null;

    final currentPage =
        currentPageIndex >= 0 && currentPageIndex < currentSlidePages.length
            ? currentSlidePages[currentPageIndex]
            : null;
    final currentLocation =
        currentPage == null ? null : _locationForSlidePage(currentPage);
    final result = SlideWindow.build(
      centerChapterIndex: chapterIndex,
      currentPage: currentPage,
      cache: chapterPagesCache,
      totalChapters: totalChapters,
    );
    _slideWindow = result.window;
    final slidePages = result.window.flatPages;
    final mappedByLocation =
        currentLocation == null
            ? null
            : _globalSlidePageIndexForLocation(
              location: currentLocation,
              slidePages: slidePages,
              chapterAt: chapterAt,
              pagesForChapter: pagesForChapter,
            );
    final nextPageIndex =
        slidePages.isEmpty
            ? 0
            : (mappedByLocation ?? result.mappedIndex).clamp(
              0,
              slidePages.length - 1,
            );
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
    final layout = _lineLayoutForChapter(
      chapterIndex: newChapterIndex,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
    );
    final charOffset = layout?.charOffsetForPageIndex(page.index) ?? 0;
    final localOffset = layout?.localOffsetForCharOffset(charOffset) ?? 0.0;

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

  bool clearPinnedSlideTargetIfReached({
    required int currentPageIndex,
    required List<TextPage> slidePages,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    if (_pinnedSlideAnchor == null) return false;
    if (_isPinnedSlideTargetReached(
      currentPageIndex: currentPageIndex,
      slidePages: slidePages,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
    )) {
      _pinnedSlideAnchor = null;
      return true;
    }
    return false;
  }

  bool _isPinnedSlideTargetReached({
    required int currentPageIndex,
    required List<TextPage> slidePages,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    final pinnedAnchor = _pinnedSlideAnchor;
    if (pinnedAnchor == null) return true;
    if (slidePages.isEmpty) return false;
    final targetIndex = _globalSlidePageIndexForLocation(
      location: pinnedAnchor.location,
      slidePages: slidePages,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
    );
    return targetIndex != null && currentPageIndex == targetIndex;
  }

  int? _globalSlidePageIndexForLocation({
    required ReaderLocation location,
    required List<TextPage> slidePages,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    final normalized = location.normalized();
    final layout = _lineLayoutForChapter(
      chapterIndex: normalized.chapterIndex,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
    );
    final chapterPageIndex = layout?.findPageIndexByCharOffset(
      normalized.charOffset,
    );
    if (chapterPageIndex == null) return null;
    final globalIndex = slidePages.indexWhere(
      (page) =>
          page.chapterIndex == normalized.chapterIndex &&
          page.index == chapterPageIndex,
    );
    return globalIndex >= 0 ? globalIndex : null;
  }

  LineLayout? _lineLayoutForChapter({
    required int chapterIndex,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    final runtimeChapter = chapterAt(chapterIndex);
    if (runtimeChapter != null) return runtimeChapter.lineLayout;
    final pages = pagesForChapter(chapterIndex);
    if (pages.isEmpty) return null;
    return LineLayout.fromPages(pages, chapterIndex: chapterIndex);
  }

  ReaderLocation _locationForSlidePage(TextPage page) {
    final layout = LineLayout.fromPages([
      page,
    ], chapterIndex: page.chapterIndex);
    return ReaderLocation(
      chapterIndex: page.chapterIndex,
      charOffset: layout.firstCharOffset,
    ).normalized();
  }
}
