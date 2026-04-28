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
  });
}

LayoutSpec _spec({required double width, required double height}) {
  return LayoutSpec.fromViewport(
    viewportSize: Size(width, height),
    style: const ReadStyle(
      fontSize: 18,
      lineHeight: 1.5,
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
