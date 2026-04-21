import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

typedef ReaderVisibleScrollUpdate =
    ({
      int chapterIndex,
      double localOffset,
      double alignment,
      List<int> visibleChapterIndexes,
    });

class ReaderViewportLayoutUpdate {
  final bool shouldRepaginate;
  final Size? nextViewSize;

  const ReaderViewportLayoutUpdate({
    this.shouldRepaginate = false,
    this.nextViewSize,
  });
}

class ReaderViewportExecutionBridge {
  const ReaderViewportExecutionBridge();

  ReaderViewportLayoutUpdate resolveLayoutUpdate({
    required Size size,
    required bool contentInsetsChanged,
    required bool scrollInsetsChanged,
    required Size? currentViewSize,
    required bool isReady,
  }) {
    return ReaderViewportLayoutUpdate(
      shouldRepaginate:
          (contentInsetsChanged || scrollInsetsChanged) &&
          currentViewSize == size &&
          isReady,
      nextViewSize: currentViewSize != size ? size : null,
    );
  }

  ReaderVisibleScrollUpdate? resolveVisibleScrollUpdate({
    required Iterable<ItemPosition> positions,
    required double viewportHeight,
    required double Function(int chapterIndex) chapterHeightFor,
  }) {
    final sorted =
        positions.toList()
          ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    if (sorted.isEmpty) return null;

    final visible =
        sorted
            .where(
              (item) => item.itemTrailingEdge > 0 && item.itemLeadingEdge < 1,
            )
            .toList();
    if (visible.isEmpty) return null;

    final focusItem = visible.first;
    final normalizedViewportHeight = viewportHeight <= 0 ? 1.0 : viewportHeight;
    final rawLocalOffset =
        (-focusItem.itemLeadingEdge * normalizedViewportHeight)
            .clamp(0.0, double.infinity)
            .toDouble();
    final chapterHeight = chapterHeightFor(focusItem.index);
    final localOffset =
        chapterHeight > 0
            ? rawLocalOffset.clamp(0.0, chapterHeight).toDouble()
            : rawLocalOffset;

    return (
      chapterIndex: focusItem.index,
      localOffset: localOffset,
      alignment: 0.0,
      visibleChapterIndexes: visible.map((item) => item.index).toList(),
    );
  }
}
