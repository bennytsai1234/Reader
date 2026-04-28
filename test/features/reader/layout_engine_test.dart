import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/engine/book_content.dart';
import 'package:inkpage_reader/features/reader/engine/layout_engine.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';

void main() {
  group('LayoutEngine', () {
    test('reconstructs title and paragraphs without duplicated lines', () {
      final content = BookContent.fromRaw(
        chapterIndex: 0,
        title: '第一章：『雨夜與門扉』在很窄的寬度下也不能重複切行',
        rawText: '''
「門外的雨聲很密。」她停了一下，低聲說道：「如果你現在開門，就再也回不去了。」

他看著那盞快要熄滅的燈，忽然笑了起來，像是想起很久以前、很遠很遠的一句話。

短句。再一個短句？最後補上一個帶引號的收尾：「走吧。」
''',
      );
      final layout = LayoutEngine().layout(
        content,
        _spec(width: 164, height: 280),
      );

      final title =
          layout.lines
              .where((line) => line.isTitle)
              .map((line) => line.text)
              .join();
      expect(title, content.title);

      final paragraphs = <int, StringBuffer>{};
      for (final line in layout.lines.where((line) => !line.isTitle)) {
        final buffer = paragraphs.putIfAbsent(
          line.paragraphNum,
          StringBuffer.new,
        );
        final text =
            line.isParagraphStart
                ? line.text.replaceFirst(RegExp(r'^[\s　]+'), '')
                : line.text;
        buffer.write(text);
      }

      final rebuilt =
          paragraphs.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      expect(
        rebuilt.map((entry) => entry.value.toString()).toList(growable: false),
        content.paragraphs,
      );
    });

    test('line offsets stay monotonic across punctuation-heavy paragraphs', () {
      final content = BookContent.fromRaw(
        chapterIndex: 2,
        title: '標題',
        rawText: List<String>.generate(
          4,
          (index) => '第$index段：這裡有逗號，句號。還有引號「這一段很長，需要在多個位置換行」，以及括號（不要卡住）。',
        ).join('\n\n'),
      );
      final layout = LayoutEngine().layout(
        content,
        _spec(width: 156, height: 260),
      );

      var previousStart = -1;
      var previousEnd = -1;
      for (final line in layout.lines) {
        expect(line.startCharOffset, greaterThanOrEqualTo(previousStart));
        expect(line.endCharOffset, greaterThanOrEqualTo(line.startCharOffset));
        expect(line.endCharOffset, greaterThanOrEqualTo(previousEnd));
        previousStart = line.startCharOffset;
        previousEnd = line.endCharOffset;
      }

      var previousPageStart = -1;
      var previousPageEnd = -1;
      for (final page in layout.pages) {
        expect(page.startCharOffset, greaterThanOrEqualTo(previousPageStart));
        expect(page.endCharOffset, greaterThanOrEqualTo(page.startCharOffset));
        expect(page.endCharOffset, greaterThanOrEqualTo(previousPageEnd));
        previousPageStart = page.startCharOffset;
        previousPageEnd = page.endCharOffset;
      }
    });

    test('uses display text offsets and exposes shared layout queries', () {
      final content = BookContent.fromRaw(
        chapterIndex: 4,
        title: '標題',
        rawText: '第一段文字\n\n第二段文字',
      );
      final spec = _spec(width: 168, height: 220);
      final layout = LayoutEngine().layout(content, spec);

      expect(content.displayText, '標題\n\n第一段文字\n\n第二段文字');
      expect(content.bodyStartOffset, 4);
      expect(layout.displayText, content.displayText);
      expect(layout.contentHeight, greaterThan(0));

      final titleLine = layout.lines.firstWhere((line) => line.isTitle);
      final firstBodyLine = layout.lines.firstWhere((line) => !line.isTitle);
      expect(titleLine.startCharOffset, 0);
      expect(firstBodyLine.startCharOffset, content.bodyStartOffset);
      expect(layout.lineForCharOffset(0), titleLine);
      expect(layout.lineForCharOffset(content.bodyStartOffset), firstBodyLine);

      for (var index = 0; index < layout.lines.length; index++) {
        expect(layout.lines[index].chapterIndex, content.chapterIndex);
        expect(layout.lines[index].lineIndex, index);
      }

      expect(layout.pages.every((page) => page.hasExplicitLocalRange), isTrue);
      expect(
        layout.pages.every((page) => page.width == spec.contentWidth),
        isTrue,
      );
      expect(layout.pageForLocalY(firstBodyLine.top), isNotNull);
      expect(layout.pageForCharOffset(0).containsCharOffset(0), isTrue);
      expect(
        layout.linesForRange(0, content.bodyStartOffset + 1),
        containsAll(<Object>[titleLine, firstBodyLine]),
      );

      final rects = layout.fullLineRectsForRange(
        startCharOffset: 0,
        endCharOffset: content.bodyStartOffset + 1,
        pageTopOnScreen: 12,
      );
      expect(rects, isNotEmpty);
      expect(rects.first.top, greaterThanOrEqualTo(12));
    });

    test('supports title-only and empty chapters without bogus body lines', () {
      final titleOnly = LayoutEngine().layout(
        BookContent.fromRaw(
          chapterIndex: 1,
          title: '只有標題，沒有正文，但標題本身非常長非常長，需要跨頁顯示。',
          rawText: '',
        ),
        _spec(width: 140, height: 180),
      );
      expect(titleOnly.pages, isNotEmpty);
      expect(titleOnly.lines.every((line) => line.isTitle), isTrue);

      final empty = LayoutEngine().layout(
        BookContent.fromRaw(chapterIndex: 3, title: '', rawText: ''),
        _spec(width: 180, height: 220),
      );
      expect(empty.pages, hasLength(1));
      expect(empty.lines, isEmpty);
      expect(empty.pages.single.lines, isEmpty);
      expect(empty.pages.single.startCharOffset, 0);
      expect(empty.pages.single.endCharOffset, 0);
    });

    test('breaks long unspaced tokens within content width', () {
      final cases = <String>[
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'https://example.com/very/long/path/without/breakpoints/aaaaaaaaaaaaaaaaaaaa',
        '123456789012345678901234567890123456789012345678901234567890',
        '這是一句沒有空格但是非常非常長的中文句子，用來確認橫向放不下時不會把整段塞回同一行造成重疊重繪。',
      ];

      for (final rawText in cases) {
        final spec = _spec(width: 180, height: 280);
        final layout = LayoutEngine().layout(
          BookContent.fromRaw(chapterIndex: 0, title: '標題', rawText: rawText),
          spec,
        );
        final bodyLines = layout.lines.where((line) => !line.isTitle).toList();

        expect(bodyLines, isNotEmpty);
        for (final line in bodyLines) {
          expect(line.width, lessThanOrEqualTo(spec.contentWidth + 0.5));
        }

        final rebuilt =
            bodyLines.map((line) {
              return line.isParagraphStart
                  ? line.text.replaceFirst(RegExp(r'^[\s　]+'), '')
                  : line.text;
            }).join();
        expect(rebuilt, rawText);
      }
    });

    test(
      'page-local line boxes stay within content height without overlap',
      () {
        final content = BookContent.fromRaw(
          chapterIndex: 0,
          title: '很長很長的標題也要正確換頁',
          rawText: List<String>.generate(
            60,
            (i) => '第$i段，這是一段會讓頁尾容易卡行的長文字，必須整行移到下一頁，不能上下重疊。',
          ).join('\n\n'),
        );
        final spec = _spec(width: 180, height: 180);
        final layout = LayoutEngine().layout(content, spec);

        for (final page in layout.pages) {
          var previousBottom = -double.infinity;
          for (final line in page.lines) {
            expect(line.top, greaterThanOrEqualTo(0));
            expect(line.bottom, lessThanOrEqualTo(page.contentHeight + 0.01));
            expect(line.top, greaterThanOrEqualTo(previousBottom - 0.01));
            previousBottom = line.bottom;
          }
        }
      },
    );

    test('keeps tail lines out of the page bottom clipping zone', () {
      final content = BookContent.fromRaw(
        chapterIndex: 0,
        title: '',
        rawText: '這是一段足夠長的正文，用來產生多個可換行的文字行，確認頁尾放不完整時會移到下一頁。',
      );
      final warmup = LayoutEngine().layout(
        content,
        _spec(width: 150, height: 320),
      );
      final lineHeight = warmup.lines.first.height;
      final tightLayout = LayoutEngine().layout(
        content,
        _spec(width: 150, height: 24 + (lineHeight * 2) + 1),
      );

      expect(warmup.lines.length, greaterThanOrEqualTo(2));
      expect(tightLayout.pages.length, greaterThanOrEqualTo(2));
      expect(tightLayout.pages.first.lines, hasLength(1));
    });

    test('tight line height is normalized before layout', () {
      final content = BookContent.fromRaw(
        chapterIndex: 0,
        title: '標題',
        rawText: '第一段文字用來確認過低行高不會產生互相壓住的 line box。\n\n第二段文字。',
      );
      final tightLayout = LayoutEngine().layout(
        content,
        _spec(width: 180, height: 220, lineHeight: 1.0),
      );
      final safeLayout = LayoutEngine().layout(
        content,
        _spec(
          width: 180,
          height: 220,
          lineHeight: ReadStyle.minReadableLineHeight,
        ),
      );

      expect(tightLayout.lines, hasLength(safeLayout.lines.length));
      for (var index = 0; index < tightLayout.lines.length; index++) {
        expect(tightLayout.lines[index].top, safeLayout.lines[index].top);
        expect(tightLayout.lines[index].bottom, safeLayout.lines[index].bottom);
      }
    });
  });
}

LayoutSpec _spec({
  required double width,
  required double height,
  double lineHeight = 1.5,
}) {
  return LayoutSpec.fromViewport(
    viewportSize: Size(width, height),
    style: ReadStyle(
      fontSize: 18,
      lineHeight: lineHeight,
      letterSpacing: 0,
      paragraphSpacing: 0.6,
      paddingTop: 12,
      paddingBottom: 12,
      paddingLeft: 16,
      paddingRight: 16,
      textIndent: 2,
      textFullJustify: false,
      pageMode: ReaderPageMode.scroll,
    ),
  );
}
