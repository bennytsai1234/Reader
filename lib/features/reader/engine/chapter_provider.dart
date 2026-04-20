import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'text_page.dart';

class PaginationMetrics {
  final double width;
  final double height;
  final double titleTopSpacing;
  final double titleBottomSpacing;
  final double paragraphSpacing;
  final double contentLineHeight;
  final int chapterIndex;
  final int chapterSize;

  const PaginationMetrics({
    required this.width,
    required this.height,
    required this.titleTopSpacing,
    required this.titleBottomSpacing,
    required this.paragraphSpacing,
    required this.contentLineHeight,
    required this.chapterIndex,
    required this.chapterSize,
  });

  factory PaginationMetrics.fromInputs({
    required Size viewSize,
    required double padding,
    required double contentPaddingTop,
    required double contentPaddingBottom,
    required double titleTopSpacing,
    required double titleBottomSpacing,
    required double paragraphSpacing,
    required TextStyle contentStyle,
    required int chapterIndex,
    required int chapterSize,
  }) {
    return PaginationMetrics(
      width: viewSize.width - (padding * 2),
      height: (viewSize.height - contentPaddingTop - contentPaddingBottom)
          .clamp(1.0, double.infinity)
          .toDouble(),
      titleTopSpacing: titleTopSpacing,
      titleBottomSpacing: titleBottomSpacing,
      paragraphSpacing: paragraphSpacing,
      contentLineHeight: contentStyle.fontSize! * (contentStyle.height ?? 1.2),
      chapterIndex: chapterIndex,
      chapterSize: chapterSize,
    );
  }
}

class _DraftLine {
  final String text;
  final double width;
  final double height;
  final double spacingBefore;
  final bool isTitle;
  final bool isParagraphStart;
  final bool isParagraphEnd;
  final bool shouldJustify;
  final int chapterPosition;
  final int paragraphNum;
  final double spacingAfter;

  const _DraftLine({
    required this.text,
    required this.width,
    required this.height,
    required this.chapterPosition,
    this.spacingBefore = 0.0,
    this.isTitle = false,
    this.isParagraphStart = false,
    this.isParagraphEnd = false,
    this.shouldJustify = false,
    this.paragraphNum = 0,
    this.spacingAfter = 0.0,
  });
}

class _PaginationCursor {
  int chapterPos;

  _PaginationCursor() : chapterPos = 0;
}

class ChapterProvider {
  static const String _lineStartForbidden = '。，、：；！？）》」』〉】〗;:!?)]}>';
  static const String _lineEndForbidden = '（《「『〈【〖([{<';
  static const Duration _yieldBudget = Duration(milliseconds: 4);

  static Future<List<TextPage>> paginate({
    required String content,
    required BookChapter chapter,
    String? displayTitle,
    required int chapterIndex,
    required int chapterSize,
    required Size viewSize,
    required TextStyle titleStyle,
    required TextStyle contentStyle,
    double paragraphSpacing = 1.0,
    int textIndent = 2,
    double titleTopSpacing = 0.0,
    double titleBottomSpacing = 10.0,
    bool textFullJustify = true,
    double padding = 16.0,
    double contentPaddingTop = 0.0,
    double contentPaddingBottom = 0.0,
  }) async {
    final metrics = PaginationMetrics.fromInputs(
      viewSize: viewSize,
      padding: padding,
      contentPaddingTop: contentPaddingTop,
      contentPaddingBottom: contentPaddingBottom,
      titleTopSpacing: titleTopSpacing,
      titleBottomSpacing: titleBottomSpacing,
      paragraphSpacing: paragraphSpacing,
      contentStyle: contentStyle,
      chapterIndex: chapterIndex,
      chapterSize: chapterSize,
    );
    final cursor = _PaginationCursor();
    final resolvedTitle = displayTitle ?? chapter.title;
    final titleLines = _layoutTitle(resolvedTitle, titleStyle, metrics, cursor);
    final contentLines = await _layoutParagraphs(
      content,
      contentStyle,
      metrics,
      textIndent,
      textFullJustify,
      cursor,
    );
    return _assemblePages(
      titleLines: titleLines,
      contentLines: contentLines,
      chapter: chapter,
      displayTitle: resolvedTitle,
      metrics: metrics,
    );
  }

  static Stream<List<TextPage>> paginateProgressive({
    required String content,
    required BookChapter chapter,
    String? displayTitle,
    required int chapterIndex,
    required int chapterSize,
    required Size viewSize,
    required TextStyle titleStyle,
    required TextStyle contentStyle,
    double paragraphSpacing = 1.0,
    int textIndent = 2,
    double titleTopSpacing = 0.0,
    double titleBottomSpacing = 10.0,
    bool textFullJustify = true,
    double padding = 16.0,
    double contentPaddingTop = 0.0,
    double contentPaddingBottom = 0.0,
  }) async* {
    final metrics = PaginationMetrics.fromInputs(
      viewSize: viewSize,
      padding: padding,
      contentPaddingTop: contentPaddingTop,
      contentPaddingBottom: contentPaddingBottom,
      titleTopSpacing: titleTopSpacing,
      titleBottomSpacing: titleBottomSpacing,
      paragraphSpacing: paragraphSpacing,
      contentStyle: contentStyle,
      chapterIndex: chapterIndex,
      chapterSize: chapterSize,
    );
    final cursor = _PaginationCursor();
    final resolvedTitle = displayTitle ?? chapter.title;
    final titleDrafts = _layoutTitle(
      resolvedTitle,
      titleStyle,
      metrics,
      cursor,
    );
    final pages = <TextPage>[];
    var currentLines = <TextLine>[];
    double currentHeight = 0.0;
    var lastYieldedSignature = '';

    List<TextPage> snapshotPages() {
      final output = <TextPage>[...pages];
      if (currentLines.isNotEmpty) {
        output.add(
          TextPage(
            index: output.length,
            lines: List<TextLine>.from(currentLines),
            title: resolvedTitle,
            chapterIndex: metrics.chapterIndex,
            chapterSize: metrics.chapterSize,
          ),
        );
      }
      return output
          .asMap()
          .entries
          .map(
            (entry) =>
                entry.value.copyWith(index: entry.key, pageSize: output.length),
          )
          .toList();
    }

    void flushPage() {
      if (currentLines.isEmpty) return;
      pages.add(
        TextPage(
          index: pages.length,
          lines: List<TextLine>.from(currentLines),
          title: resolvedTitle,
          chapterIndex: metrics.chapterIndex,
          chapterSize: metrics.chapterSize,
        ),
      );
      currentLines = [];
      currentHeight = 0.0;
    }

    void consumeDraft(_DraftLine draft) {
      if (currentHeight + draft.spacingBefore + draft.height > metrics.height) {
        flushPage();
      }
      currentHeight += draft.spacingBefore;
      currentLines.add(
        TextLine(
          text: draft.text,
          width: draft.width,
          height: draft.height,
          isTitle: draft.isTitle,
          isParagraphStart: draft.isParagraphStart,
          isParagraphEnd: draft.isParagraphEnd,
          shouldJustify: draft.shouldJustify,
          chapterPosition: draft.chapterPosition,
          lineTop: currentHeight,
          lineBottom: currentHeight + draft.height,
          paragraphNum: draft.paragraphNum,
        ),
      );
      currentHeight += draft.height + draft.spacingAfter;
    }

    List<TextPage>? initialYield;

    void emitIfChanged() {
      final snapshot = snapshotPages();
      if (snapshot.isEmpty) return;
      final signature =
          '${snapshot.length}:${snapshot.last.lines.length}:${snapshot.last.lineSize}:${snapshot.last.lines.last.chapterPosition}';
      if (signature == lastYieldedSignature) return;
      lastYieldedSignature = signature;
      initialYield = snapshot;
    }

    for (final draft in titleDrafts) {
      consumeDraft(draft);
    }
    emitIfChanged();
    if (initialYield != null) {
      yield initialYield!;
      initialYield = null;
    }

    final paragraphs = content.split('\n');
    final indentStr = '　' * textIndent;
    final indentLen = indentStr.length;
    final painter = TextPainter(textDirection: TextDirection.ltr);
    final yieldWatch = Stopwatch()..start();
    List<TextPage>? pendingYield;

    for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      if (yieldWatch.elapsed >= _yieldBudget) {
        final snapshot = snapshotPages();
        final signature =
            snapshot.isEmpty
                ? ''
                : '${snapshot.length}:${snapshot.last.lines.length}:${snapshot.last.lineSize}:${snapshot.last.lines.last.chapterPosition}';
        if (snapshot.isNotEmpty && signature != lastYieldedSignature) {
          lastYieldedSignature = signature;
          pendingYield = snapshot;
        }
        if (pendingYield != null) {
          yield pendingYield;
          pendingYield = null;
        }
        await Future.delayed(Duration.zero);
        yieldWatch
          ..reset()
          ..start();
      }

      final paragraph = paragraphs[pIdx].trim();
      if (paragraph.isEmpty) {
        cursor.chapterPos += 1;
        continue;
      }

      final text = indentStr + paragraph;
      int start = 0;
      int contentStart = indentLen;
      bool isFirstLine = true;

      while (start < text.length) {
        final remaining = text.substring(start);
        final (lineText, charsConsumed) = _breakOneLine(
          painter,
          remaining,
          contentStyle,
          metrics.width,
        );
        if (charsConsumed <= 0) break;

        final isLastLine = start + charsConsumed == text.length;
        consumeDraft(
          _DraftLine(
            text: lineText,
            width: metrics.width,
            height: metrics.contentLineHeight,
            isParagraphStart: isFirstLine,
            isParagraphEnd: isLastLine,
            shouldJustify: textFullJustify && !isLastLine,
            chapterPosition: cursor.chapterPos,
            paragraphNum: pIdx,
            spacingAfter:
                isLastLine
                    ? (contentStyle.fontSize! *
                            (metrics.paragraphSpacing - 1.0))
                        .clamp(0, 50.0)
                        .toDouble()
                    : 0.0,
          ),
        );

        start += charsConsumed;
        final charsInIndent =
            contentStart > 0
                ? (charsConsumed > contentStart ? contentStart : charsConsumed)
                : 0;
        cursor.chapterPos += charsConsumed - charsInIndent;
        contentStart = (contentStart - charsConsumed).clamp(0, indentLen);
        isFirstLine = false;
      }

      cursor.chapterPos += 1;
    }

    final finalSnapshot = snapshotPages();
    if (finalSnapshot.isNotEmpty) {
      final signature =
          '${finalSnapshot.length}:${finalSnapshot.last.lines.length}:${finalSnapshot.last.lineSize}:${finalSnapshot.last.lines.last.chapterPosition}';
      if (signature != lastYieldedSignature) {
        yield finalSnapshot;
      }
    }
  }

  static List<_DraftLine> _layoutTitle(
    String title,
    TextStyle titleStyle,
    PaginationMetrics metrics,
    _PaginationCursor cursor,
  ) {
    if (title.isEmpty) return const [];

    final titlePainter = TextPainter(
      text: TextSpan(text: title, style: titleStyle),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: metrics.width);
    final titleLines = titlePainter.computeLineMetrics();
    if (titleLines.isEmpty) return const [];

    final drafts = <_DraftLine>[];
    for (int i = 0; i < titleLines.length; i++) {
      final metric = titleLines[i];
      drafts.add(
        _DraftLine(
          text: i == 0 ? title : '',
          width: metric.width,
          height: metric.height,
          spacingBefore: i == 0 ? metrics.titleTopSpacing : 0.0,
          isTitle: true,
          chapterPosition: cursor.chapterPos,
          spacingAfter:
              i == titleLines.length - 1 ? metrics.titleBottomSpacing : 0.0,
        ),
      );
    }
    cursor.chapterPos += title.length;
    return drafts;
  }

  static Future<List<_DraftLine>> _layoutParagraphs(
    String content,
    TextStyle contentStyle,
    PaginationMetrics metrics,
    int textIndent,
    bool textFullJustify,
    _PaginationCursor cursor,
  ) async {
    final drafts = <_DraftLine>[];
    final paragraphs = content.split('\n');
    final indentStr = '　' * textIndent;
    final indentLen = indentStr.length;
    final painter = TextPainter(textDirection: TextDirection.ltr);
    final yieldWatch = Stopwatch()..start();

    for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      if (yieldWatch.elapsed >= _yieldBudget) {
        await Future.delayed(Duration.zero);
        yieldWatch
          ..reset()
          ..start();
      }

      final paragraph = paragraphs[pIdx].trim();
      if (paragraph.isEmpty) {
        cursor.chapterPos += 1;
        continue;
      }

      final text = indentStr + paragraph;
      int start = 0;
      int contentStart = indentLen;
      bool isFirstLine = true;

      while (start < text.length) {
        final remaining = text.substring(start);
        final (lineText, charsConsumed) = _breakOneLine(
          painter,
          remaining,
          contentStyle,
          metrics.width,
        );
        if (charsConsumed <= 0) break;

        final isLastLine = start + charsConsumed == text.length;
        drafts.add(
          _DraftLine(
            text: lineText,
            width: metrics.width,
            height: metrics.contentLineHeight,
            isParagraphStart: isFirstLine,
            isParagraphEnd: isLastLine,
            shouldJustify: textFullJustify && !isLastLine,
            chapterPosition: cursor.chapterPos,
            paragraphNum: pIdx,
            spacingAfter:
                isLastLine
                    ? (contentStyle.fontSize! *
                            (metrics.paragraphSpacing - 1.0))
                        .clamp(0, 50.0)
                        .toDouble()
                    : 0.0,
          ),
        );

        start += charsConsumed;
        final charsInIndent =
            contentStart > 0
                ? (charsConsumed > contentStart ? contentStart : charsConsumed)
                : 0;
        cursor.chapterPos += charsConsumed - charsInIndent;
        contentStart = (contentStart - charsConsumed).clamp(0, indentLen);
        isFirstLine = false;
      }

      cursor.chapterPos += 1;
    }

    return drafts;
  }

  static List<TextPage> _assemblePages({
    required List<_DraftLine> titleLines,
    required List<_DraftLine> contentLines,
    required BookChapter chapter,
    required String displayTitle,
    required PaginationMetrics metrics,
  }) {
    final drafts = <_DraftLine>[...titleLines, ...contentLines];
    final pages = <TextPage>[];
    var currentLines = <TextLine>[];
    double currentHeight = 0.0;

    void flushPage() {
      if (currentLines.isEmpty) return;
      pages.add(
        TextPage(
          index: pages.length,
          lines: List<TextLine>.from(currentLines),
          title: displayTitle,
          chapterIndex: metrics.chapterIndex,
          chapterSize: metrics.chapterSize,
        ),
      );
      currentLines = [];
      currentHeight = 0.0;
    }

    for (final draft in drafts) {
      if (currentHeight + draft.spacingBefore + draft.height > metrics.height) {
        flushPage();
      }
      currentHeight += draft.spacingBefore;

      currentLines.add(
        TextLine(
          text: draft.text,
          width: draft.width,
          height: draft.height,
          isTitle: draft.isTitle,
          isParagraphStart: draft.isParagraphStart,
          isParagraphEnd: draft.isParagraphEnd,
          shouldJustify: draft.shouldJustify,
          chapterPosition: draft.chapterPosition,
          lineTop: currentHeight,
          lineBottom: currentHeight + draft.height,
          paragraphNum: draft.paragraphNum,
        ),
      );
      currentHeight += draft.height + draft.spacingAfter;
    }

    flushPage();

    return pages
        .asMap()
        .entries
        .map(
          (entry) =>
              entry.value.copyWith(index: entry.key, pageSize: pages.length),
        )
        .toList();
  }

  static (String lineText, int charsConsumed) _breakOneLine(
    TextPainter painter,
    String remaining,
    TextStyle style,
    double maxWidth,
  ) {
    painter.text = TextSpan(text: remaining, style: style);
    painter.layout(maxWidth: maxWidth);

    final boundary = painter.getLineBoundary(const TextPosition(offset: 0));
    int end = boundary.end;
    if (end <= 0) {
      return ('', 0);
    }

    if (end < remaining.length) {
      final nextChar = remaining.substring(end, end + 1);
      if (_lineStartForbidden.contains(nextChar) && end > 1) {
        end--;
      }
    }
    if (end > 1) {
      final lastChar = remaining.substring(end - 1, end);
      if (_lineEndForbidden.contains(lastChar)) {
        end--;
      }
    }
    if (end <= 0) {
      end = 1;
    }

    return (remaining.substring(0, end), end);
  }
}
