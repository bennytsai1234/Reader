import 'dart:ui';

import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

import 'reader_v2_layout.dart';
import 'reader_v2_text_adapter.dart';

class ReaderV2ChapterView {
  ReaderV2ChapterView(
    this.layout, {
    required this.chapterSize,
    required this.title,
  })
    : pages =
          layout.pages
              .map(
                (slice) => readerV2PageSliceToTextPage(
                  layout: layout,
                  slice: slice,
                  chapterSize: chapterSize,
                  title: title,
                ),
              )
              .toList(growable: false),
      lines =
          layout.lines
              .map(readerV2TextLineToTextLine)
              .toList(growable: false);

  final ReaderV2ChapterLayout layout;
  final int chapterSize;
  final String title;
  final List<TextPage> pages;
  final List<TextLine> lines;

  int get chapterIndex => layout.chapterIndex;
  String get displayText => layout.displayText;
  String get contentHash => layout.contentHash;
  String get layoutSignature => layout.layoutSignature;
  double get contentHeight => layout.contentHeight;

  List<PageCache> get pageCaches {
    return pages
        .map((page) => PageCache.fromTextPage(page))
        .toList(growable: false);
  }

  TextPage pageForCharOffset(int charOffset) {
    if (pages.isEmpty) {
      return TextPage(
        pageIndex: 0,
        chapterIndex: chapterIndex,
        lines: const <TextLine>[],
        height: 1,
      );
    }
    for (final page in pages) {
      if (page.containsCharOffset(charOffset)) return page;
    }
    final line = lineForCharOffset(charOffset);
    if (line != null) {
      final page = pageForLocalY(line.top);
      if (page != null) return page;
    }
    if (charOffset <= pages.first.startCharOffset) return pages.first;
    var best = pages.first;
    for (final page in pages) {
      if (page.startCharOffset <= charOffset) {
        best = page;
      } else {
        break;
      }
    }
    return best;
  }

  TextLine? lineForCharOffset(int charOffset) {
    final queryLines = lines;
    if (queryLines.isEmpty) return null;
    TextLine? previous;
    for (var index = 0; index < queryLines.length; index++) {
      final line = queryLines[index];
      if (line.text.isEmpty) continue;
      final effectiveEnd = _effectiveLineEnd(queryLines, index);
      if (charOffset >= line.startCharOffset && charOffset < effectiveEnd) {
        return line;
      }
      if (charOffset < line.startCharOffset) return line;
      previous = line;
    }
    return previous;
  }

  TextPage? pageForLine(TextLine line) => pageForLocalY(line.top);

  TextLine? lineAtOrNearLocalY(double localY) {
    TextLine? nearest;
    var nearestDistance = double.infinity;
    for (final line in lines) {
      if (line.text.isEmpty) continue;
      if (localY >= line.top && localY <= line.bottom) return line;
      final distance =
          localY < line.top ? line.top - localY : localY - line.bottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = line;
      }
    }
    return nearest;
  }

  TextPage? pageForLocalY(double localY) {
    if (pages.isEmpty) return null;
    if (localY <= pages.first.localStartY) return pages.first;
    var best = pages.first;
    for (final page in pages) {
      if (page.localStartY <= localY) {
        best = page;
      } else {
        break;
      }
    }
    return best;
  }

  List<TextLine> linesForRange(int startCharOffset, int endCharOffset) {
    final start =
        startCharOffset <= endCharOffset ? startCharOffset : endCharOffset;
    final end =
        startCharOffset <= endCharOffset ? endCharOffset : startCharOffset;
    if (start == end) {
      final line = lineForCharOffset(start);
      return line == null ? const <TextLine>[] : <TextLine>[line];
    }
    final queryLines = lines;
    return queryLines
        .asMap()
        .entries
        .where((entry) {
          final line = entry.value;
          if (line.text.isEmpty) return false;
          return _effectiveLineEnd(queryLines, entry.key) > start &&
              line.startCharOffset < end;
        })
        .map((entry) => entry.value)
        .toList(growable: false);
  }

  List<Rect> fullLineRectsForRange({
    required int startCharOffset,
    required int endCharOffset,
    double pageTopOnScreen = 0.0,
  }) {
    return linesForRange(startCharOffset, endCharOffset)
        .map((line) {
          final page = pageForLocalY(line.top);
          final pageTop = page?.localStartY ?? 0.0;
          final width = (page?.width ?? 0) > 0 ? page!.width : line.width;
          return Rect.fromLTRB(
            0,
            pageTopOnScreen + line.top - pageTop,
            width,
            pageTopOnScreen + line.bottom - pageTop,
          );
        })
        .toList(growable: false);
  }

  int _effectiveLineEnd(List<TextLine> queryLines, int index) {
    final line = queryLines[index];
    for (var nextIndex = index + 1; nextIndex < queryLines.length; nextIndex++) {
      final next = queryLines[nextIndex];
      if (next.text.isEmpty) continue;
      if (next.startCharOffset > line.endCharOffset) {
        return next.startCharOffset;
      }
      break;
    }
    return line.endCharOffset;
  }
}
