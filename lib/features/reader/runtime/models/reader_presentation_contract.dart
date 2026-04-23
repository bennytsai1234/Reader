import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

class ReaderPresentationAnchor {
  final ReaderLocation location;
  final bool fromEnd;

  const ReaderPresentationAnchor({
    required this.location,
    this.fromEnd = false,
  });

  ReaderPresentationAnchor normalized() {
    return ReaderPresentationAnchor(
      location: location.normalized(),
      fromEnd: fromEnd,
    );
  }
}

class ReaderPresentationRequest {
  final ReaderPresentationAnchor anchor;
  final bool isScrollMode;
  final List<TextPage> chapterPages;
  final List<TextPage> slidePages;
  final ReaderChapter? runtimeChapter;

  const ReaderPresentationRequest({
    required this.anchor,
    required this.isScrollMode,
    required this.chapterPages,
    required this.slidePages,
    required this.runtimeChapter,
  });

  int get chapterIndex => anchor.location.chapterIndex;
  int get persistedCharOffset => anchor.location.charOffset;
  bool get fromEnd => anchor.fromEnd;
}

class ReaderSlideTargetRequest {
  final ReaderPresentationAnchor? pinnedAnchor;
  final int? previousMappedIndex;
  final ReaderLocation durableLocation;
  final List<TextPage> slidePages;
  final ReaderSlideTargetResolutionMode resolutionMode;
  final ReaderChapter? Function(int chapterIndex) chapterAt;
  final List<TextPage> Function(int chapterIndex) pagesForChapter;

  const ReaderSlideTargetRequest({
    required this.pinnedAnchor,
    required this.previousMappedIndex,
    required this.durableLocation,
    required this.slidePages,
    required this.resolutionMode,
    required this.chapterAt,
    required this.pagesForChapter,
  });
}

enum ReaderSlideTargetResolutionMode { startupRestore, recenter }
