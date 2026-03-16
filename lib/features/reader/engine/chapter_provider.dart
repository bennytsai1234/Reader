import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'text_page.dart';

class ChapterProvider {
  // 避頭點：不能出現在行首的符號
  static const String _lineStartForbidden = '。，、：；！？）》」』〉】〗;:!?)]}>';
  // 避尾點：不能出現在行尾的符號
  static const String _lineEndForbidden = '（《「『〈【〖([{<';

  static List<TextPage> paginate({
    required String content,
    required BookChapter chapter,
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
  }) {
    final width = viewSize.width - (padding * 2);
    final height = viewSize.height - 80; // 預留上下邊距 40

    final pages = <TextPage>[];
    var currentLines = <TextLine>[];
    double currentHeight = 0;
    var chapterPos = 0;

    void addPage() {
      if (currentLines.isEmpty) return;
      pages.add(TextPage(
        index: pages.length,
        lines: List.from(currentLines),
        title: chapter.title,
        chapterIndex: chapterIndex,
        chapterSize: chapterSize,
      ));
      currentLines = [];
      currentHeight = 0;
    }

    // 1. 處理標題
    final titlePainter = TextPainter(
      text: TextSpan(text: chapter.title, style: titleStyle),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: width);
    
    final titleLines = titlePainter.computeLineMetrics();
    currentHeight += titleTopSpacing;
    for (var i = 0; i < titleLines.length; i++) {
      final metric = titleLines[i];
      if (currentHeight + metric.height > height) addPage();

      currentLines.add(TextLine(
        text: i == 0 ? chapter.title : '', 
        width: metric.width,
        height: metric.height,
        isTitle: true,
        lineTop: currentHeight,
        lineBottom: currentHeight + metric.height,
        chapterPosition: chapterPos,
      ));
      currentHeight += metric.height;
    }
    chapterPos += chapter.title.length;
    currentHeight += titleBottomSpacing;

    // 2. 處理段落
    final paragraphs = content.split('\n');
    final indentStr = '　' * textIndent;

    for (var pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      final p = paragraphs[pIdx].trim();
      if (p.isEmpty) {
        chapterPos += 1;
        continue;
      }
      
      final text = indentStr + p;
      var start = 0;
      var isFirstLineOfParagraph = true;

      while (start < text.length) {
        final tp = TextPainter(
          text: TextSpan(text: text.substring(start), style: contentStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: width);
        
        var end = tp.getPositionForOffset(Offset(width, 0)).offset;
        if (end <= 0) break;

        // 避頭尾處理
        if (start + end < text.length) {
          final nextChar = text.substring(start + end, start + end + 1);
          if (_lineStartForbidden.contains(nextChar) && end > 1) {
            end--;
          }
        }
        if (end > 1) {
          final lastChar = text.substring(start + end - 1, start + end);
          if (_lineEndForbidden.contains(lastChar)) {
            end--;
          }
        }

        final lineText = text.substring(start, start + end);
        final isLastLine = (start + end == text.length);
        final lineHeight = contentStyle.fontSize! * (contentStyle.height ?? 1.2);
        
        if (currentHeight + lineHeight > height) addPage();

        currentLines.add(TextLine(
          text: lineText,
          width: width,
          height: lineHeight,
          isParagraphStart: isFirstLineOfParagraph,
          isParagraphEnd: isLastLine,
          shouldJustify: textFullJustify && !isLastLine,
          chapterPosition: chapterPos,
          lineTop: currentHeight,
          lineBottom: currentHeight + lineHeight,
          paragraphNum: pIdx,
        ));

        start += end;
        chapterPos += end;
        currentHeight += lineHeight;
        isFirstLineOfParagraph = false;
      }
      chapterPos += 1; // 段落換行
      currentHeight += (contentStyle.fontSize! * (paragraphSpacing - 1.0)).clamp(0, 50.0);
    }

    addPage();

    return pages.asMap().entries.map((e) => e.value.copyWith(index: e.key, pageSize: pages.length)).toList();
  }
}
