import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'text_page.dart';

class ChapterProvider {
  // 避頭點：不能出現在行首的符號
  static const String _lineStartForbidden = '。，、：；！？）》」』〉】〗;:!?)]}>';
  // 避尾點：不能出現在行尾的符號
  static const String _lineEndForbidden = '（《「『〈【〖([{<';

  static Future<List<TextPage>> paginate({
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
  }) async {
    final width = viewSize.width - (padding * 2);
    final height = viewSize.height - 80;

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
    final indentLen = indentStr.length;

    // 優化：在迴圈外宣告單一實例，大幅降低物件建立的 GC 與記憶體開銷
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      // 效能優化：每處理 10 個段落就讓出主執行緒 (Yield)，防止 UI 卡頓掉幀
      if (pIdx > 0 && pIdx % 10 == 0) {
        await Future.delayed(Duration.zero);
      }

      final p = paragraphs[pIdx].trim();
      if (p.isEmpty) {
        chapterPos += 1;
        continue;
      }
      
      final text = indentStr + p;
      var start = 0;
      var contentStart = indentLen; 
      var isFirstLineOfParagraph = true;

      while (start < text.length) {
        tp.text = TextSpan(text: text.substring(start), style: contentStyle);
        tp.layout(maxWidth: width);
        
        final boundary = tp.getLineBoundary(const TextPosition(offset: 0));
        var end = boundary.end;
        if (end <= 0) break;

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
        if (end <= 0) end = 1;

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
        final int charsInIndent = (contentStart > 0)
            ? (end > contentStart ? contentStart : end)
            : 0;
        chapterPos += (end - charsInIndent);
        contentStart = (contentStart - end).clamp(0, indentLen);
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
