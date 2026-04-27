import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_host_base.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_coordinate_mapper.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_command.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';

class ReaderRuntimeController {
  final ReaderCoordinateMapper _mapper;

  ReaderRuntimeController({
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
    required List<TextPage> Function() slidePages,
  }) : _mapper = ReaderCoordinateMapper(
         chapterAt: chapterAt,
         pagesForChapter: pagesForChapter,
         slidePages: slidePages,
       );

  ReaderLocation resolveVisibleScrollLocation({
    required int chapterIndex,
    required double localOffset,
  }) {
    return _mapper.locationFromScrollOffset(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
    );
  }

  ReaderLocation resolveSlideLocation({
    required int chapterIndex,
    required int pageIndex,
  }) {
    return _mapper.locationFromSlidePage(
      chapterIndex: chapterIndex,
      pageIndex: pageIndex,
    );
  }

  ReaderLocation captureReadingLocation({
    required bool isScrollMode,
    required int currentChapterIndex,
    required int visibleChapterIndex,
    required double visibleChapterLocalOffset,
    required int currentPageIndex,
    required ReaderLocation fallbackLocation,
  }) {
    if (isScrollMode) {
      return resolveVisibleScrollLocation(
        chapterIndex: visibleChapterIndex,
        localOffset: visibleChapterLocalOffset,
      );
    }

    final slidePages = _mapper.slidePages();
    if (currentPageIndex >= 0 && currentPageIndex < slidePages.length) {
      return resolveSlideLocation(
        chapterIndex: currentChapterIndex,
        pageIndex: currentPageIndex,
      );
    }
    return fallbackLocation.normalized();
  }

  ReaderPresentationAnchor capturePresentationAnchor({
    required bool isScrollMode,
    required int currentChapterIndex,
    required int visibleChapterIndex,
    required double visibleChapterLocalOffset,
    required int currentPageIndex,
    required ReaderLocation fallbackLocation,
    bool fromEnd = false,
  }) {
    return ReaderPresentationAnchor(
      location: captureReadingLocation(
        isScrollMode: isScrollMode,
        currentChapterIndex: currentChapterIndex,
        visibleChapterIndex: visibleChapterIndex,
        visibleChapterLocalOffset: visibleChapterLocalOffset,
        currentPageIndex: currentPageIndex,
        fallbackLocation: fallbackLocation,
      ),
      fromEnd: fromEnd,
    ).normalized();
  }

  double localOffsetForLocation(ReaderLocation location) {
    return _mapper.localOffsetForLocation(location);
  }

  int? pageIndexForLocation(ReaderLocation location) {
    return _mapper.pageIndexForLocation(location);
  }

  int? matchingSlidePageIndexSnapshot({
    required ReaderLocation location,
    required int? pageIndexSnapshot,
  }) {
    if (pageIndexSnapshot == null) return null;
    final slidePages = _mapper.slidePages();
    if (pageIndexSnapshot < 0 || pageIndexSnapshot >= slidePages.length) {
      return null;
    }
    final chapterPageIndex = pageIndexForLocation(location);
    if (chapterPageIndex == null) return null;
    final page = slidePages[pageIndexSnapshot];
    if (page.chapterIndex != location.chapterIndex ||
        page.index != chapterPageIndex) {
      return null;
    }
    return pageIndexSnapshot;
  }

  int? globalSlidePageIndexForLocation(ReaderLocation location) {
    final normalized = location.normalized();
    final chapterPageIndex = pageIndexForLocation(normalized);
    if (chapterPageIndex == null) return null;

    final slidePages = _mapper.slidePages();
    final globalIndex = slidePages.indexWhere(
      (page) =>
          page.chapterIndex == normalized.chapterIndex &&
          page.index == chapterPageIndex,
    );
    return globalIndex >= 0 ? globalIndex : null;
  }

  ReaderViewportCommand resolveViewportCommand({
    required bool isScrollMode,
    required ReaderPresentationAnchor anchor,
    ReaderAnchor? sourceAnchor,
    int? globalPageIndex,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    final normalizedAnchor = anchor.normalized();
    final resolvedSourceAnchor =
        (sourceAnchor ?? ReaderAnchor.location(normalizedAnchor.location))
            .normalized();
    if (isScrollMode) {
      final target = _mapper.scrollTargetForLocation(normalizedAnchor.location);
      return ReaderScrollViewportCommand(
        anchor: resolvedSourceAnchor
            .copyWith(
              location: normalizedAnchor.location,
              pageIndexSnapshot: pageIndexForLocation(
                normalizedAnchor.location,
              ),
            )
            .withLocalOffsetSnapshot(null),
        reason: reason,
        target: target,
      );
    }

    final target = _mapper.slideTargetForLocation(
      location: normalizedAnchor.location,
      globalPageIndex: globalPageIndex,
      targetChapterIndex: normalizedAnchor.location.chapterIndex,
    );
    return ReaderSlideViewportCommand(
      anchor: resolvedSourceAnchor.copyWith(
        location: normalizedAnchor.location,
        pageIndexSnapshot: target.globalPageIndex,
      ),
      reason: reason,
      target: target,
    );
  }
}
