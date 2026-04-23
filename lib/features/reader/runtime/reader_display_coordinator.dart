import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_position_resolver.dart';

class ReaderDisplayInstruction {
  final ReaderLocation location;
  final ReaderScrollTarget? scrollTarget;
  final int? slidePageIndex;

  const ReaderDisplayInstruction({
    required this.location,
    this.scrollTarget,
    this.slidePageIndex,
  });
}

class ReaderDisplayCoordinator {
  const ReaderDisplayCoordinator();

  ReaderDisplayInstruction resolveDisplayInstruction(
    ReaderPresentationRequest request,
  ) {
    final location =
        ReaderLocation(
          chapterIndex: request.chapterIndex,
          charOffset:
              request.fromEnd && request.chapterPages.isNotEmpty
                  ? ChapterPositionResolver.getCharOffsetForPage(
                    request.chapterPages,
                    request.chapterPages.length - 1,
                  )
                  : request.persistedCharOffset,
        ).normalized();

    if (request.isScrollMode) {
      return ReaderDisplayInstruction(
        location: location,
        scrollTarget: ReaderPositionResolver.resolveScrollTarget(
          location: location,
          runtimeChapter: request.runtimeChapter,
          pages: request.chapterPages,
        ),
      );
    }

    return ReaderDisplayInstruction(
      location: location,
      slidePageIndex:
          ReaderPositionResolver.resolveSlideTarget(
            location: location,
            runtimeChapter: request.runtimeChapter,
            chapterPages: request.chapterPages,
            slidePages: request.slidePages,
            targetChapterIndex: request.chapterIndex,
          ).globalPageIndex,
    );
  }

  int resolveSlideTargetIndex(ReaderSlideTargetRequest request) {
    final pinnedAnchor = request.pinnedAnchor?.normalized();
    if (pinnedAnchor != null) {
      if (pinnedAnchor.fromEnd) {
        for (var i = request.slidePages.length - 1; i >= 0; i--) {
          if (request.slidePages[i].chapterIndex ==
              pinnedAnchor.location.chapterIndex) {
            return i;
          }
        }
      }
      return ReaderPositionResolver.resolveSlideTarget(
        location: pinnedAnchor.location,
        runtimeChapter: request.chapterAt(pinnedAnchor.location.chapterIndex),
        chapterPages: request.pagesForChapter(
          pinnedAnchor.location.chapterIndex,
        ),
        slidePages: request.slidePages,
        targetChapterIndex: pinnedAnchor.location.chapterIndex,
      ).globalPageIndex;
    }

    if (request.previousMappedIndex != null &&
        request.previousMappedIndex! >= 0 &&
        request.resolutionMode == ReaderSlideTargetResolutionMode.recenter) {
      return request.previousMappedIndex!;
    }

    return ReaderPositionResolver.resolveSlideTarget(
      location: ReaderLocation(
        chapterIndex: request.durableLocation.chapterIndex,
        charOffset: request.durableLocation.charOffset,
      ),
      runtimeChapter: request.chapterAt(request.durableLocation.chapterIndex),
      chapterPages: request.pagesForChapter(
        request.durableLocation.chapterIndex,
      ),
      slidePages: request.slidePages,
      targetChapterIndex: request.durableLocation.chapterIndex,
    ).globalPageIndex;
  }

  String formatReadProgress({
    required int chapterIndex,
    required int totalChapters,
    required int pageIndex,
    required int totalPages,
  }) {
    if (totalChapters <= 0) return '0.0%';
    final safeChapterIndex = chapterIndex.clamp(0, totalChapters - 1);
    if (totalPages <= 0) {
      return '${(((safeChapterIndex + 1) / totalChapters) * 100).toStringAsFixed(1)}%';
    }
    final safePageIndex = pageIndex.clamp(0, totalPages - 1);
    final percent =
        (safeChapterIndex / totalChapters) +
        (1.0 / totalChapters) * ((safePageIndex + 1) / totalPages);
    var formatted = '${(percent * 100).toStringAsFixed(1)}%';
    if (formatted == '100.0%' &&
        (safeChapterIndex + 1 != totalChapters ||
            safePageIndex + 1 != totalPages)) {
      formatted = '99.9%';
    }
    return formatted;
  }

  String formatPageLabel(int pageIndex, int totalPages) {
    if (totalPages <= 0) return '0/0';
    final page = (pageIndex + 1).clamp(1, totalPages);
    return '$page/$totalPages';
  }

  int resolveScrubChapterIndex({
    required dynamic value,
    required int totalChapters,
  }) {
    if (totalChapters <= 0) return 0;
    final int rawIndex =
        value is double ? (value * (totalChapters - 1)).round() : value as int;
    return rawIndex.clamp(0, totalChapters - 1);
  }
}
