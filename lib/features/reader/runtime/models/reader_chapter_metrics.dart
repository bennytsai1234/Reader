import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

class ReaderChapterMetrics {
  final double contentHeight;
  final double separatorExtent;
  final double itemExtent;
  final List<double> pageTopOffsets;
  final bool isEstimated;

  const ReaderChapterMetrics({
    required this.contentHeight,
    required this.separatorExtent,
    required this.itemExtent,
    required this.pageTopOffsets,
    this.isEstimated = false,
  });

  factory ReaderChapterMetrics.fromPages(
    List<TextPage> pages, {
    double separatorExtent = 0.0,
    bool isEstimated = false,
  }) {
    final normalizedSeparatorExtent =
        separatorExtent.clamp(0.0, double.infinity).toDouble();
    final contentHeight = ChapterPositionResolver.chapterHeight(pages);
    return ReaderChapterMetrics(
      contentHeight: contentHeight,
      separatorExtent: normalizedSeparatorExtent,
      itemExtent: contentHeight + normalizedSeparatorExtent,
      pageTopOffsets: ChapterPositionResolver.pageTopOffsets(pages),
      isEstimated: isEstimated,
    );
  }

  ReaderChapterMetrics copyWith({
    double? contentHeight,
    double? separatorExtent,
    List<double>? pageTopOffsets,
    bool? isEstimated,
  }) {
    final nextContentHeight = contentHeight ?? this.contentHeight;
    final nextSeparatorExtent = separatorExtent ?? this.separatorExtent;
    return ReaderChapterMetrics(
      contentHeight: nextContentHeight,
      separatorExtent: nextSeparatorExtent,
      itemExtent: nextContentHeight + nextSeparatorExtent,
      pageTopOffsets: pageTopOffsets ?? this.pageTopOffsets,
      isEstimated: isEstimated ?? this.isEstimated,
    );
  }
}
