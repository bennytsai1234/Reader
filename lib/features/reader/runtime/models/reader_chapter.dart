import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter_metrics.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_paragraph.dart';

class ReaderChapter {
  final BookChapter chapter;
  final int index;
  final String title;
  final List<TextPage> pages;
  final int contentLength;
  final List<int> pageStartOffsets;
  final List<int> pageEndOffsets;
  final ReaderChapterMetrics metrics;

  ReaderChapter({
    required this.chapter,
    required this.index,
    required this.title,
    required this.pages,
    int? contentLength,
    List<int>? pageStartOffsets,
    List<int>? pageEndOffsets,
    ReaderChapterMetrics? metrics,
  }) : pageStartOffsets = List<int>.unmodifiable(
         pageStartOffsets ??
             pages
                 .map(ChapterPositionResolver.firstCharOffset)
                 .toList(growable: false),
       ),
       pageEndOffsets = List<int>.unmodifiable(
         pageEndOffsets ??
             pages
                 .map(ChapterPositionResolver.pageEndCharOffset)
                 .toList(growable: false),
       ),
       contentLength =
           contentLength ??
           (pages.isEmpty
               ? 0
               : ChapterPositionResolver.pageEndCharOffset(pages.last)),
       metrics = metrics ?? ReaderChapterMetrics.fromPages(pages);

  int get pageCount => pages.length;
  int get lastIndex => pages.isEmpty ? -1 : pages.length - 1;
  bool get isEmpty => pages.isEmpty;
  TextPage? get firstPage => pages.isEmpty ? null : pages.first;
  TextPage? get lastPage => pages.isEmpty ? null : pages.last;
  int get lastReadLength => getReadLength(lastIndex);
  double get chapterHeight => metrics.contentHeight;
  late final List<TextLine> _allTextLines = allLines();

  late final List<ReaderParagraph> paragraphs = _buildParagraphs();
  late final List<ReaderParagraph> pageParagraphs = _buildPageParagraphs();

  TextPage? pageAt(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return null;
    return pages[pageIndex];
  }

  TextPage? getPageByReadPos(int readPos) {
    final index = getPageIndexByCharIndex(readPos);
    if (index < 0) return null;
    return pageAt(index);
  }

  TextPage? pageAtLocalOffset(double localOffset) {
    final pageIndex = pageIndexAtLocalOffset(localOffset);
    if (pageIndex < 0) return null;
    return pageAt(pageIndex);
  }

  int getReadLength(int pageIndex) {
    if (pages.isEmpty || pageIndex < 0) return 0;
    final safeIndex = pageIndex.clamp(0, pages.length - 1);
    return pageStartOffsets[safeIndex];
  }

  int getPageIndexByCharIndex(int charIndex) {
    if (pages.isEmpty) return -1;
    var best = 0;
    for (var i = 0; i < pageStartOffsets.length; i++) {
      if (pageStartOffsets[i] <= charIndex) {
        best = i;
      } else {
        break;
      }
    }
    return best;
  }

  TextLine? lineAtCharOffset(int charOffset) {
    for (final line in _allTextLines) {
      if (line.image != null) continue;
      final lineEnd = line.chapterPosition + line.text.length;
      if (charOffset >= line.chapterPosition && charOffset < lineEnd) {
        return line;
      }
    }
    return null;
  }

  ReaderParagraph? paragraphAtCharOffset(
    int charOffset, {
    bool pageSplit = false,
  }) {
    for (final paragraph in getParagraphs(pageSplit: pageSplit)) {
      if (paragraph.containsCharOffset(charOffset)) {
        return paragraph;
      }
    }
    return null;
  }

  int charOffsetFromLocalOffset(double localOffset) {
    if (pages.isEmpty) return 0;
    final safeLocalOffset = localOffset.clamp(0.0, chapterHeight).toDouble();
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final pageTop = metrics.pageTopOffsets[i];
      for (final line in page.lines) {
        if (line.image != null) continue;
        if (pageTop + line.lineBottom > safeLocalOffset) {
          return line.chapterPosition;
        }
      }
    }
    return contentLength;
  }

  double localOffsetFromCharOffset(int charOffset) {
    if (pages.isEmpty) return 0.0;
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      final pageTop = metrics.pageTopOffsets[i];
      for (final line in page.lines) {
        if (line.image != null) continue;
        if (line.chapterPosition >= charOffset) {
          return pageTop + line.lineTop;
        }
      }
    }
    return chapterHeight;
  }

  double alignmentForCharOffset(int charOffset) {
    final total = chapterHeight;
    if (total <= 0) return 0.0;
    return (localOffsetFromCharOffset(charOffset) / total).clamp(0.0, 1.0);
  }

  int pageIndexAtLocalOffset(double localOffset) {
    if (pages.isEmpty) return -1;
    final safeLocalOffset = localOffset.clamp(0.0, chapterHeight).toDouble();
    for (var i = 0; i < pages.length; i++) {
      final pageHeight = pageHeightAt(i);
      if (metrics.pageTopOffsets[i] + pageHeight > safeLocalOffset) {
        return i;
      }
    }
    return pages.length - 1;
  }

  int charOffsetForPageIndex(int pageIndex) {
    if (pages.isEmpty) return 0;
    final safeIndex = pageIndex.clamp(0, pages.length - 1);
    return pageStartOffsets[safeIndex];
  }

  int nextPageStartCharOffset(int charOffset) {
    final pageIndex = getPageIndexByCharIndex(charOffset);
    if (pageIndex < 0 || pageIndex >= lastIndex) return -1;
    return charOffsetForPageIndex(pageIndex + 1);
  }

  int prevPageStartCharOffset(int charOffset) {
    final pageIndex = getPageIndexByCharIndex(charOffset);
    if (pageIndex <= 0) return -1;
    return charOffsetForPageIndex(pageIndex - 1);
  }

  double localOffsetForPageIndex(int pageIndex) {
    if (pages.isEmpty) return 0.0;
    final charOffset = charOffsetForPageIndex(pageIndex);
    return localOffsetFromCharOffset(charOffset);
  }

  double pageHeightAt(int pageIndex) {
    final page = pageAt(pageIndex);
    if (page == null) return 0.0;
    return ChapterPositionResolver.pageHeight(page);
  }

  bool isCharOffsetVisibleInPage(int charOffset, int pageIndex) {
    final page = pageAt(pageIndex);
    if (page == null) return false;
    final start = firstCharOffset(page);
    final end = pageEndCharOffset(page);
    return charOffset >= start && charOffset <= end;
  }

  ({
    int pageIndex,
    int pageStartCharOffset,
    double pageStartLocalOffset,
    double intraPageOffset,
  })
  resolveLocalOffsetTarget(double localOffset) {
    final pageIndex = pageIndexAtLocalOffset(localOffset);
    final safePageIndex = pageIndex < 0 ? 0 : pageIndex;
    final pageStartCharOffset = charOffsetForPageIndex(safePageIndex);
    final pageStartLocalOffset = localOffsetFromCharOffset(pageStartCharOffset);
    final intraPageOffset = (localOffset - pageStartLocalOffset).clamp(
      0.0,
      double.infinity,
    );
    return (
      pageIndex: safePageIndex,
      pageStartCharOffset: pageStartCharOffset,
      pageStartLocalOffset: pageStartLocalOffset,
      intraPageOffset: intraPageOffset,
    );
  }

  ({int start, int end, int pageIndex, int paragraphNum}) resolveHighlightRange(
    int charOffset, {
    bool pageSplit = true,
  }) {
    final pageIndex = getPageIndexByCharIndex(charOffset);
    final safePageIndex = pageIndex < 0 ? 0 : pageIndex;
    final paragraph = paragraphAtCharOffset(charOffset, pageSplit: pageSplit);
    if (paragraph == null) {
      return (
        start: charOffset,
        end: charOffset + 1,
        pageIndex: safePageIndex,
        paragraphNum: -1,
      );
    }
    return (
      start: paragraph.chapterPosition,
      end: paragraph.chapterEndPosition,
      pageIndex: safePageIndex,
      paragraphNum: paragraph.num,
    );
  }

  ({
    int pageIndex,
    int pageStartCharOffset,
    double pageStartLocalOffset,
    double targetLocalOffset,
    double intraPageOffset,
    double alignment,
  })
  resolveRestoreTarget({int? charOffset, double? localOffset}) {
    final targetLocalOffset =
        localOffset ?? localOffsetFromCharOffset(charOffset ?? 0);
    final target = resolveLocalOffsetTarget(targetLocalOffset);
    return (
      pageIndex: target.pageIndex,
      pageStartCharOffset: target.pageStartCharOffset,
      pageStartLocalOffset: target.pageStartLocalOffset,
      targetLocalOffset: targetLocalOffset,
      intraPageOffset: target.intraPageOffset,
      alignment: alignmentForCharOffset(
        charOffset ?? target.pageStartCharOffset,
      ),
    );
  }

  ({int pageIndex, double localOffset, double alignment}) resolveScrollAnchor(
    int charOffset, {
    double anchorPadding = 0.0,
  }) {
    final localOffset = localOffsetFromCharOffset(charOffset);
    final targetLocalOffset = (localOffset - anchorPadding).clamp(
      0.0,
      double.infinity,
    );
    return (
      pageIndex: pageIndexAtLocalOffset(localOffset),
      localOffset: targetLocalOffset,
      alignment: alignmentForCharOffset(charOffset),
    );
  }

  int getNextPageLength(int charIndex) {
    final pageIndex = getPageIndexByCharIndex(charIndex);
    if (pageIndex + 1 >= pages.length) return -1;
    return getReadLength(pageIndex + 1);
  }

  int getPrevPageLength(int charIndex) {
    final pageIndex = getPageIndexByCharIndex(charIndex);
    if (pageIndex - 1 < 0) return -1;
    return getReadLength(pageIndex - 1);
  }

  int firstCharOffset(TextPage page) {
    return ChapterPositionResolver.firstCharOffset(page);
  }

  List<TextLine> allLines() {
    final lines = <TextLine>[];
    for (final page in pages) {
      lines.addAll(page.lines);
    }
    return lines;
  }

  String getContent() {
    return pages
        .expand((page) => page.lines)
        .where((line) => line.image == null)
        .map((line) => line.text + (line.isParagraphEnd ? '\n' : ''))
        .join();
  }

  String getUnRead(int pageIndex) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex > lastIndex) return '';
    return pages
        .skip(pageIndex)
        .expand((page) => page.lines)
        .where((line) => line.image == null)
        .map((line) => line.text + (line.isParagraphEnd ? '\n' : ''))
        .join();
  }

  String getNeedReadAloud({
    required int pageIndex,
    required bool pageSplit,
    required int startPos,
    int? pageEndIndex,
  }) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex > lastIndex) return '';
    final endIndex = (pageEndIndex ?? lastIndex).clamp(pageIndex, lastIndex);
    final buffer = StringBuffer();
    for (var index = pageIndex; index <= endIndex; index++) {
      final page = pages[index];
      for (final line in page.lines) {
        if (line.image != null) continue;
        buffer.write(line.text);
        if (line.isParagraphEnd || pageSplit) {
          buffer.write('\n');
        }
      }
    }
    final text = buffer.toString();
    if (startPos <= 0) return text;
    if (startPos >= text.length) return '';
    return text.substring(startPos);
  }

  int getParagraphNum(int position, {required bool pageSplit}) {
    for (final paragraph in getParagraphs(pageSplit: pageSplit)) {
      if (paragraph.containsCharOffset(position)) {
        return paragraph.num;
      }
    }
    return -1;
  }

  List<ReaderParagraph> getParagraphs({required bool pageSplit}) {
    return pageSplit ? pageParagraphs : paragraphs;
  }

  int getLastParagraphPosition() {
    if (pageParagraphs.isEmpty) return 0;
    return pageParagraphs.last.chapterPosition;
  }

  bool containsCharOffset(int charOffset) {
    if (pages.isEmpty) return false;
    final first = firstCharOffset(pages.first);
    final last = pageEndCharOffset(pages.last);
    return charOffset >= first && charOffset <= last;
  }

  int pageEndCharOffset(TextPage page) {
    return ChapterPositionResolver.pageEndCharOffset(page);
  }

  List<TextLine> visibleLinesFrom(int startCharOffset) {
    final lines = <TextLine>[];
    for (final page in pages) {
      for (final line in page.lines) {
        if (line.image != null) continue;
        if (line.chapterPosition >= startCharOffset) {
          lines.add(line);
        }
      }
    }
    return lines;
  }

  ({
    String text,
    int baseOffset,
    List<({int ttsOffset, int chapterOffset})> offsetMap,
  })?
  buildReadAloudData({required int startCharOffset}) {
    final visibleSegments = <({TextLine line, int startOffset})>[];
    for (final page in pages) {
      for (final line in page.lines) {
        if (line.image != null) continue;
        final lineStart = line.chapterPosition;
        final lineEnd = lineStart + line.text.length;
        if (startCharOffset <= lineStart) {
          visibleSegments.add((line: line, startOffset: 0));
          continue;
        }
        if (startCharOffset > lineStart && startCharOffset < lineEnd) {
          visibleSegments.add((
            line: line,
            startOffset: startCharOffset - lineStart,
          ));
        }
      }
    }
    if (visibleSegments.isEmpty) return null;

    final buffer = StringBuffer();
    final map = <({int ttsOffset, int chapterOffset})>[];
    var ttsPos = 0;
    var lastParagraphNum = -1;
    for (final segment in visibleSegments) {
      final line = segment.line;
      final startOffset = segment.startOffset;
      if (lastParagraphNum != -1 && line.paragraphNum != lastParagraphNum) {
        buffer.write('\n');
        ttsPos += 1;
      }
      final text =
          startOffset <= 0 ? line.text : line.text.substring(startOffset);
      if (text.isEmpty) {
        lastParagraphNum = line.paragraphNum;
        continue;
      }
      map.add((
        ttsOffset: ttsPos,
        chapterOffset: line.chapterPosition + startOffset,
      ));
      buffer.write(text);
      ttsPos += text.length;
      lastParagraphNum = line.paragraphNum;
    }
    if (map.isEmpty || buffer.isEmpty) return null;
    return (
      text: buffer.toString(),
      baseOffset: map.first.chapterOffset,
      offsetMap: map,
    );
  }

  List<ReaderParagraph> _buildParagraphs() {
    final grouped = <int, List<TextLine>>{};
    for (final line in allLines()) {
      if (line.image != null || line.paragraphNum <= 0) continue;
      grouped.putIfAbsent(line.paragraphNum, () => <TextLine>[]).add(line);
    }
    final entries =
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) => ReaderParagraph(num: entry.key, textLines: entry.value))
        .toList();
  }

  List<ReaderParagraph> _buildPageParagraphs() {
    final paragraphs = <ReaderParagraph>[];
    for (final page in pages) {
      final grouped = <int, List<TextLine>>{};
      for (final line in page.lines) {
        if (line.image != null || line.paragraphNum <= 0) continue;
        grouped.putIfAbsent(line.paragraphNum, () => <TextLine>[]).add(line);
      }
      final pageParagraphs =
          grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in pageParagraphs) {
        paragraphs.add(
          ReaderParagraph(num: paragraphs.length + 1, textLines: entry.value),
        );
      }
    }
    return paragraphs;
  }
}
