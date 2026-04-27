import 'package:flutter/material.dart';

import 'book_content.dart';
import 'chapter_layout.dart';
import 'layout_spec.dart';
import 'text_page.dart';

class LayoutEngine {
  final Map<String, ChapterLayout> _cache = <String, ChapterLayout>{};

  ChapterLayout layout(
    BookContent content,
    LayoutSpec spec, {
    int chapterSize = 0,
  }) {
    final cacheKey =
        '${content.chapterIndex}:$chapterSize:${content.contentHash}:${spec.layoutSignature}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final lines = <TextLine>[];
    var y = 0.0;
    var paragraphOffset = 0;
    var paragraphNum = 0;

    if (content.title.isNotEmpty) {
      final titleStyle = _titleTextStyle(spec);
      final titleLines = _layoutBlock(
        text: content.title,
        style: titleStyle,
        maxWidth: spec.contentWidth,
        top: y,
        startOffset: 0,
        isTitle: true,
        paragraphNum: -1,
      );
      lines.addAll(titleLines);
      if (titleLines.isNotEmpty) {
        y = titleLines.last.bottom + spec.style.paragraphSpacing * 8;
      }
    }

    for (final paragraph in content.paragraphs) {
      final paragraphLines = _layoutBlock(
        text: paragraph,
        style: _contentTextStyle(spec),
        maxWidth: spec.contentWidth,
        top: y,
        startOffset: paragraphOffset,
        paragraphNum: paragraphNum,
        textIndent: spec.style.textIndent,
        textFullJustify: spec.style.textFullJustify,
      );
      lines.addAll(paragraphLines);
      if (paragraphLines.isNotEmpty) {
        y = paragraphLines.last.bottom + _paragraphSpacingPixels(spec);
      }
      paragraphOffset += paragraph.length + 2;
      paragraphNum += 1;
    }

    final pages = _paginate(
      lines: lines,
      spec: spec,
      content: content,
      chapterSize: chapterSize,
    );
    final layout = ChapterLayout(
      chapterIndex: content.chapterIndex,
      contentHash: content.contentHash,
      layoutSignature: spec.layoutSignature,
      lines: List<TextLine>.unmodifiable(lines),
      pages: List<TextPage>.unmodifiable(pages),
    );
    _cache[cacheKey] = layout;
    return layout;
  }

  void clear() => _cache.clear();

  void invalidateWhere(bool Function(ChapterLayout layout) test) {
    _cache.removeWhere((_, layout) => test(layout));
  }

  TextStyle _contentTextStyle(LayoutSpec spec) {
    return TextStyle(
      fontSize: spec.style.fontSize,
      height: spec.style.lineHeight,
      letterSpacing: spec.style.letterSpacing,
      fontFamily: spec.style.fontFamily,
      fontWeight: spec.style.bold ? FontWeight.bold : FontWeight.normal,
    );
  }

  TextStyle _titleTextStyle(LayoutSpec spec) {
    return TextStyle(
      fontSize: spec.style.fontSize + 4,
      height: spec.style.lineHeight,
      letterSpacing: spec.style.letterSpacing,
      fontFamily: spec.style.fontFamily,
      fontWeight: FontWeight.bold,
    );
  }

  double _paragraphSpacingPixels(LayoutSpec spec) {
    return (spec.style.fontSize * spec.style.lineHeight) *
        spec.style.paragraphSpacing;
  }

  List<TextLine> _layoutBlock({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double top,
    required int startOffset,
    bool isTitle = false,
    int paragraphNum = 0,
    int textIndent = 0,
    bool textFullJustify = false,
  }) {
    if (text.isEmpty) return const <TextLine>[];
    final indentText =
        !isTitle && textIndent > 0 ? '　' * textIndent.clamp(0, 8) : '';
    final laidOutText = indentText.isEmpty ? text : '$indentText$text';
    final indentLength = indentText.length;
    final painter = TextPainter(
      text: TextSpan(text: laidOutText, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    final metrics = painter.computeLineMetrics();
    final lines = <TextLine>[];

    var searchOffset = 0;
    for (var i = 0; i < metrics.length; i++) {
      final metric = metrics[i];
      final boundary = painter.getLineBoundary(
        TextPosition(offset: searchOffset.clamp(0, laidOutText.length)),
      );
      final localStart = boundary.start.clamp(0, laidOutText.length).toInt();
      final localEnd =
          boundary.end.clamp(localStart, laidOutText.length).toInt();
      searchOffset =
          localEnd >= laidOutText.length ? laidOutText.length : localEnd;
      final lineText = laidOutText.substring(localStart, localEnd);
      final contentStart =
          (localStart - indentLength).clamp(0, text.length).toInt();
      final contentEnd =
          (localEnd - indentLength).clamp(contentStart, text.length).toInt();
      final lineTop = top + metric.baseline - metric.ascent;
      final lineBottom = top + metric.baseline + metric.descent;
      lines.add(
        TextLine(
          text: lineText,
          width: metric.width,
          height: lineBottom - lineTop,
          isTitle: isTitle,
          isParagraphStart: i == 0,
          isParagraphEnd: i == metrics.length - 1,
          shouldJustify: !isTitle && textFullJustify && i < metrics.length - 1,
          chapterPosition: startOffset + contentStart,
          lineTop: lineTop,
          lineBottom: lineBottom,
          paragraphNum: paragraphNum,
          startCharOffset: startOffset + contentStart,
          endCharOffset: startOffset + contentEnd,
          baseline: top + metric.baseline,
        ),
      );
      if (searchOffset >= laidOutText.length) break;
    }
    return lines;
  }

  List<TextPage> _paginate({
    required List<TextLine> lines,
    required LayoutSpec spec,
    required BookContent content,
    required int chapterSize,
  }) {
    final pageHeight = spec.contentHeight <= 0 ? 1.0 : spec.contentHeight;
    if (lines.isEmpty) {
      return <TextPage>[
        TextPage(
          pageIndex: 0,
          chapterIndex: content.chapterIndex,
          chapterSize: chapterSize,
          pageSize: 1,
          title: content.title,
          lines: const <TextLine>[],
          startCharOffset: 0,
          endCharOffset: content.plainText.length,
          height: pageHeight,
          isChapterStart: true,
          isChapterEnd: true,
        ),
      ];
    }

    final buckets = <int, List<TextLine>>{};
    for (final line in lines) {
      final pageIndex = (line.top / pageHeight).floor().clamp(0, 1 << 30);
      buckets.putIfAbsent(pageIndex, () => <TextLine>[]).add(line);
    }
    final maxPageIndex = buckets.keys.fold<int>(0, (max, value) {
      return value > max ? value : max;
    });
    final pages = <TextPage>[];
    for (var pageIndex = 0; pageIndex <= maxPageIndex; pageIndex++) {
      final pageTop = pageIndex * pageHeight;
      final pageLines = (buckets[pageIndex] ?? const <TextLine>[])
          .map((line) => line.toPageLocal(pageTop))
          .toList(growable: false);
      pages.add(
        TextPage(
          pageIndex: pageIndex,
          chapterIndex: content.chapterIndex,
          chapterSize: chapterSize,
          pageSize: maxPageIndex + 1,
          title: content.title,
          lines: pageLines,
          startCharOffset:
              pageLines.isEmpty
                  ? (pages.isEmpty ? 0 : pages.last.endCharOffset)
                  : pageLines.first.startCharOffset,
          endCharOffset:
              pageLines.isEmpty
                  ? (pages.isEmpty ? 0 : pages.last.endCharOffset)
                  : pageLines.last.endCharOffset,
          height: pageHeight,
          isChapterStart: pageIndex == 0,
          isChapterEnd: pageIndex == maxPageIndex,
        ),
      );
    }
    return pages;
  }
}
