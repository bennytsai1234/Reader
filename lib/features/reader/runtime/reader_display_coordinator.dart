import 'package:inkpage_reader/features/reader/engine/line_layout.dart';
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

  int _charOffsetForRequestAnchor(ReaderPresentationRequest request) {
    if (!request.fromEnd) return request.persistedCharOffset;
    final runtimeChapter = request.runtimeChapter;
    if (runtimeChapter != null) return runtimeChapter.lineLayout.endCharOffset;
    if (request.chapterPages.isEmpty) return request.persistedCharOffset;
    return LineLayout.fromPages(
      request.chapterPages,
      chapterIndex: request.chapterIndex,
    ).endCharOffset;
  }

  ReaderDisplayInstruction resolveDisplayInstruction(
    ReaderPresentationRequest request,
  ) {
    final location =
        ReaderLocation(
          chapterIndex: request.chapterIndex,
          charOffset: _charOffsetForRequestAnchor(request),
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
    required int charOffset,
    required int chapterEndCharOffset,
  }) {
    if (totalChapters <= 0) return '0.0%';
    final safeChapterIndex = chapterIndex.clamp(0, totalChapters - 1);
    final chapterProgress =
        chapterEndCharOffset <= 0
            ? 0.0
            : (charOffset / chapterEndCharOffset).clamp(0.0, 1.0).toDouble();
    final percent =
        (safeChapterIndex + chapterProgress) / totalChapters.toDouble();
    var formatted = '${(percent * 100).toStringAsFixed(1)}%';
    if (formatted == '100.0%' &&
        (safeChapterIndex + 1 != totalChapters || chapterProgress < 1.0)) {
      formatted = '99.9%';
    }
    return formatted;
  }

  String formatChapterProgress({
    required int charOffset,
    required int chapterEndCharOffset,
  }) {
    if (chapterEndCharOffset <= 0) return '0.0%';
    final progress =
        (charOffset / chapterEndCharOffset).clamp(0.0, 1.0).toDouble();
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  String formatPageLabel(int pageIndex, int totalPages) {
    if (totalPages <= 0) return '0/0';
    final page = (pageIndex + 1).clamp(1, totalPages);
    return '$page/$totalPages';
  }

  String formatChapterLabel({
    required int chapterIndex,
    required int totalChapters,
  }) {
    if (totalChapters <= 0) return '0/0';
    final chapter = (chapterIndex + 1).clamp(1, totalChapters);
    return '$chapter/$totalChapters';
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
