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
    final height = viewSize.height - 80;

    final pages = <TextPage>[];
    var currentLines = <TextLine>[];
    double currentHeight = 0;
    var chapterPos = 0;

    // 1. 處理標題
    final titlePainter = TextPainter(
      text: TextSpan(text: chapter.title, style: titleStyle),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: width);
    
    // 將標題拆分為行 (對標 Android 標題多行處理)
    final titleLines = titlePainter.computeLineMetrics();
    for (var i = 0; i < titleLines.length; i++) {
      final metric = titleLines[i];
      currentLines.add(TextLine(
        text: i == 0 ? chapter.title : '', // 標題互動邏輯通常綁定首行
        width: metric.width,
        height: metric.height,
        isTitle: true,
        lineTop: currentHeight + titleTopSpacing,
        lineBottom: currentHeight + titleTopSpacing + metric.height,
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
        
        // 獲取當前寬度能容納的字符數 (對位 Android breakStrategy)
        var end = tp.getPositionForOffset(Offset(width, 0)).offset;
        if (end <= 0) break;

        // 避頭尾處理 (精確版)
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
        
        // 判斷是否兩端對齊 (正文非末行需要對齊)
        final shouldJustify = textFullJustify && !isLastLine;

        currentLines.add(TextLine(
          text: lineText,
          width: width, // 佔滿可用寬度以支持 justify
          height: lineHeight,
          isParagraphStart: isFirstLineOfParagraph,
          isParagraphEnd: isLastLine,
          shouldJustify: shouldJustify,
          chapterPosition: chapterPos,
          lineTop: currentHeight,
          lineBottom: currentHeight + lineHeight,
          paragraphNum: pIdx,
        ));

        start += end;
        chapterPos += end;
        currentHeight += lineHeight;
        isFirstLineOfParagraph = false;

        // 檢查分頁 (預留足夠空間給頁碼或頁邊距)
        if (currentHeight + lineHeight > height) {
          pages.add(TextPage(
            index: pages.length,
            lines: List.from(currentLines),
            title: chapter.title,
            chapterIndex: chapterIndex,
            chapterSize: chapterSize,
          ));
          currentLines = [];
          currentHeight = 0; // 重置高度
        }
      }
      chapterPos += 1; // 段落換行
      // 段落間距 (對標 Android ReadBookConfig.paragraphSpacing)
      currentHeight += (contentStyle.fontSize! * (paragraphSpacing - 1.0)).clamp(0, 50.0);
    }

    if (currentLines.isNotEmpty) {
      pages.add(TextPage(
        index: pages.length,
        lines: currentLines,
        title: chapter.title,
        chapterIndex: chapterIndex,
        chapterSize: chapterSize,
      ));
    }

    return pages.asMap().entries.map((e) => e.value.copyWith(index: e.key, pageSize: pages.length)).toList();
  }
}

