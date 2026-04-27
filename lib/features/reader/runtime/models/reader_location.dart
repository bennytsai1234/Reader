export 'package:inkpage_reader/features/reader/engine/reader_location.dart';

class ReaderScrollTarget {
  final int chapterIndex;
  final double localOffset;
  final double alignment;

  const ReaderScrollTarget({
    required this.chapterIndex,
    required this.localOffset,
    required this.alignment,
  });
}

class ReaderSlideTarget {
  final int globalPageIndex;
  final int chapterIndex;
  final int chapterPageIndex;

  const ReaderSlideTarget({
    required this.globalPageIndex,
    required this.chapterIndex,
    required this.chapterPageIndex,
  });
}
