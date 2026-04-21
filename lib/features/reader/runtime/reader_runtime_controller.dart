import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_command.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_position_resolver.dart';

class ReaderRuntimeController {
  final ReaderChapter? Function(int chapterIndex) _chapterAt;
  final List<TextPage> Function(int chapterIndex) _pagesForChapter;
  final List<TextPage> Function() _slidePages;

  ReaderRuntimeController({
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
    required List<TextPage> Function() slidePages,
  }) : _chapterAt = chapterAt,
       _pagesForChapter = pagesForChapter,
       _slidePages = slidePages;

  ReaderLocation resolveVisibleScrollLocation({
    required int chapterIndex,
    required double localOffset,
  }) {
    final runtimeChapter = _chapterAt(chapterIndex);
    final pages = _pagesForChapter(chapterIndex);
    final charOffset =
        runtimeChapter != null
            ? runtimeChapter.charOffsetFromLocalOffset(localOffset)
            : ChapterPositionResolver.localOffsetToCharOffset(
              pages,
              localOffset,
            );
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    ).normalized();
  }

  ReaderLocation resolveSlideLocation({
    required int chapterIndex,
    required int pageIndex,
  }) {
    final slidePages = _slidePages();
    if (pageIndex >= 0 && pageIndex < slidePages.length) {
      final page = slidePages[pageIndex];
      final runtimeChapter = _chapterAt(page.chapterIndex);
      final chapterPages = _pagesForChapter(page.chapterIndex);
      final charOffset =
          runtimeChapter != null
              ? runtimeChapter.charOffsetForPageIndex(page.index)
              : ChapterPositionResolver.getCharOffsetForPage(
                chapterPages,
                page.index,
              );
      return ReaderLocation(
        chapterIndex: page.chapterIndex,
        charOffset: charOffset,
      ).normalized();
    }

    final runtimeChapter = _chapterAt(chapterIndex);
    final chapterPages = _pagesForChapter(chapterIndex);
    final safePageIndex =
        chapterPages.isEmpty ? 0 : pageIndex.clamp(0, chapterPages.length - 1);
    final charOffset =
        runtimeChapter != null
            ? runtimeChapter.charOffsetForPageIndex(safePageIndex)
            : ChapterPositionResolver.getCharOffsetForPage(
              chapterPages,
              safePageIndex,
            );
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    ).normalized();
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

    final slidePages = _slidePages();
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
    final normalized = location.normalized();
    final runtimeChapter = _chapterAt(normalized.chapterIndex);
    if (runtimeChapter != null) {
      return runtimeChapter.localOffsetFromCharOffset(normalized.charOffset);
    }
    return ChapterPositionResolver.charOffsetToLocalOffset(
      _pagesForChapter(normalized.chapterIndex),
      normalized.charOffset,
    );
  }

  ReaderViewportCommand resolveViewportCommand({
    required bool isScrollMode,
    required ReaderPresentationAnchor anchor,
    int? globalPageIndex,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    final normalizedAnchor = anchor.normalized();
    if (isScrollMode) {
      final target = ReaderPositionResolver.resolveScrollTarget(
        location: normalizedAnchor.location,
        runtimeChapter: _chapterAt(normalizedAnchor.location.chapterIndex),
        pages: _pagesForChapter(normalizedAnchor.location.chapterIndex),
      );
      return ReaderScrollViewportCommand(
        location: normalizedAnchor.location,
        reason: reason,
        target: target,
      );
    }

    final target = ReaderPositionResolver.resolveSlideTarget(
      location: normalizedAnchor.location,
      globalPageIndex: globalPageIndex,
      runtimeChapter: _chapterAt(normalizedAnchor.location.chapterIndex),
      chapterPages: _pagesForChapter(normalizedAnchor.location.chapterIndex),
      slidePages: _slidePages(),
      targetChapterIndex: normalizedAnchor.location.chapterIndex,
    );
    return ReaderSlideViewportCommand(
      location: normalizedAnchor.location,
      reason: reason,
      target: target,
    );
  }
}
