import 'package:flutter/material.dart';

import 'book_content.dart';
import 'chapter_layout.dart';
import 'layout_spec.dart';
import 'text_page.dart';

class LayoutEngine {
  static const String _lineStartForbidden = '。，、：；！？）》」』〉】〗;:!?)]}>';
  static const String _lineEndForbidden = '（《「『〈【〖([{<';
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
  }) {
    if (text.isEmpty) return const <TextLine>[];
    final indentText =
        !isTitle && textIndent > 0 ? '　' * textIndent.clamp(0, 8) : '';
    final laidOutText = indentText.isEmpty ? text : '$indentText$text';
    final indentLength = indentText.length;
    final painter = TextPainter(
      text: const TextSpan(text: ''),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: null,
    );
    final lines = <TextLine>[];
    var localStart = 0;
    var lineTop = top;
    var lineIndex = 0;

    while (localStart < laidOutText.length) {
      final remaining = laidOutText.substring(localStart);
      painter.text = TextSpan(text: remaining, style: style);
      painter.layout(maxWidth: maxWidth);
      final metrics = painter.computeLineMetrics();
      if (metrics.isEmpty) break;
      final metric = metrics.first;
      var charsConsumed = _lineCharsConsumed(
        painter: painter,
        remaining: remaining,
      );
      if (metric.width > maxWidth + 0.5) {
        charsConsumed = _maxFittingPrefix(
          text: remaining,
          style: style,
          maxWidth: maxWidth,
        );
      }
      if (charsConsumed <= 0) break;
      final localEnd =
          (localStart + charsConsumed)
              .clamp(localStart + 1, laidOutText.length)
              .toInt();
      final lineText = laidOutText.substring(localStart, localEnd);
      final contentStart =
          (localStart - indentLength).clamp(0, text.length).toInt();
      final contentEnd =
          (localEnd - indentLength).clamp(contentStart, text.length).toInt();
      final lineHeight =
          metric.height > 0
              ? metric.height
              : (style.fontSize ?? 0) * (style.height ?? 1.0);
      final lineBottom = lineTop + lineHeight;
      final isParagraphEnd = localEnd >= laidOutText.length;
      final lineWidth = _measureLineWidth(lineText, style);
      lines.add(
        TextLine(
          text: lineText,
          width: lineWidth,
          height: lineHeight,
          isTitle: isTitle,
          isParagraphStart: lineIndex == 0,
          isParagraphEnd: isParagraphEnd,
          shouldJustify: false,
          chapterPosition: startOffset + contentStart,
          lineTop: lineTop,
          lineBottom: lineBottom,
          paragraphNum: paragraphNum,
          startCharOffset: startOffset + contentStart,
          endCharOffset: startOffset + contentEnd,
          baseline: lineTop + metric.baseline,
        ),
      );
      localStart = localEnd;
      lineTop = lineBottom;
      lineIndex += 1;
    }
    return lines;
  }

  int _lineCharsConsumed({
    required TextPainter painter,
    required String remaining,
  }) {
    if (remaining.isEmpty) return 0;
    var boundary = painter.getLineBoundary(const TextPosition(offset: 0));
    var end = boundary.end.clamp(0, remaining.length).toInt();
    if (end <= 0 && remaining.length > 1) {
      boundary = painter.getLineBoundary(const TextPosition(offset: 1));
      end = boundary.end.clamp(0, remaining.length).toInt();
    }
    if (end <= 0) return 0;

    if (end < remaining.length) {
      final nextChar = remaining.substring(end, end + 1);
      if (_lineStartForbidden.contains(nextChar) && end > 1) {
        end -= 1;
      }
    }
    if (end > 1) {
      final lastChar = remaining.substring(end - 1, end);
      if (_lineEndForbidden.contains(lastChar)) {
        end -= 1;
      }
    }
    if (end <= 0) {
      end = remaining.isEmpty ? 0 : 1;
    }
    return end.clamp(0, remaining.length).toInt();
  }

  int _maxFittingPrefix({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final clusters = text.characters.toList(growable: false);
    if (clusters.isEmpty) return 0;

    var low = 1;
    var high = clusters.length;
    var best = 1;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    );

    while (low <= high) {
      final mid = (low + high) >> 1;
      final candidate = clusters.take(mid).join();
      painter.text = TextSpan(text: candidate, style: style);
      painter.layout(maxWidth: double.infinity);
      if (painter.width <= maxWidth) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return clusters.take(best).join().length;
  }

  double _measureLineWidth(String text, TextStyle style) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);
    return painter.width;
  }

  List<TextPage> _paginate({
    required List<TextLine> lines,
    required LayoutSpec spec,
    required BookContent content,
    required int chapterSize,
  }) {
    final contentHeight = spec.contentHeight <= 0 ? 1.0 : spec.contentHeight;
    final viewportHeight =
        spec.viewportSize.height <= 0
            ? contentHeight
            : spec.viewportSize.height;
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
          contentHeight: contentHeight,
          viewportHeight: viewportHeight,
          isChapterStart: true,
          isChapterEnd: true,
        ),
      ];
    }

    final rawPages = <TextPage>[];
    final currentLines = <TextLine>[];
    var currentHeight = 0.0;
    TextLine? previousGlobalLine;

    void flushPage() {
      final pageIndex = rawPages.length;
      final pageLines = List<TextLine>.unmodifiable(currentLines);
      rawPages.add(
        TextPage(
          pageIndex: pageIndex,
          chapterIndex: content.chapterIndex,
          chapterSize: chapterSize,
          pageSize: 0,
          title: content.title,
          lines: pageLines,
          startCharOffset:
              pageLines.isEmpty
                  ? (rawPages.isEmpty ? 0 : rawPages.last.endCharOffset)
                  : pageLines.first.startCharOffset,
          endCharOffset:
              pageLines.isEmpty
                  ? (rawPages.isEmpty ? 0 : rawPages.last.endCharOffset)
                  : pageLines.last.endCharOffset,
          contentHeight: contentHeight,
          viewportHeight: viewportHeight,
          isChapterStart: pageIndex == 0,
          isChapterEnd: false,
        ),
      );
      currentLines.clear();
      currentHeight = 0.0;
    }

    for (final line in lines) {
      final gap =
          previousGlobalLine == null
              ? 0.0
              : (line.top - previousGlobalLine.bottom)
                  .clamp(0.0, double.infinity)
                  .toDouble();
      final proposedTop = currentLines.isEmpty ? 0.0 : currentHeight + gap;
      final proposedBottom = proposedTop + line.height;
      final needsNewPage =
          currentLines.isNotEmpty && proposedBottom > contentHeight + 0.01;

      if (needsNewPage) {
        flushPage();
      }

      final pageTop = currentLines.isEmpty ? 0.0 : currentHeight + gap;
      final localLine = line.copyWith(
        lineTop: pageTop,
        lineBottom: pageTop + line.height,
        baseline: pageTop + (line.baseline - line.top),
      );
      currentLines.add(localLine);
      currentHeight = localLine.bottom;
      previousGlobalLine = line;
    }

    if (currentLines.isNotEmpty || rawPages.isEmpty) {
      flushPage();
    }

    final pageCount = rawPages.length;
    final pages = <TextPage>[];
    for (var index = 0; index < pageCount; index++) {
      pages.add(
        rawPages[index].copyWith(
          pageSize: pageCount,
          isChapterStart: index == 0,
          isChapterEnd: index == pageCount - 1,
        ),
      );
    }
    return pages;
  }
}
