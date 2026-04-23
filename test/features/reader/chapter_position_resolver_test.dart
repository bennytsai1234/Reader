import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

TextPage makePage({
  required int chapterIndex,
  required int index,
  required List<TextLine> lines,
}) {
  return TextPage(
    index: index,
    title: 'chapter-$chapterIndex',
    chapterIndex: chapterIndex,
    lines: lines,
  );
}

void main() {
  group('ChapterPositionResolver', () {
    final pages = <TextPage>[
      makePage(
        chapterIndex: 4,
        index: 0,
        lines: [
          TextLine(
            text: 'aaaa',
            width: 100,
            height: 40,
            chapterPosition: 0,
            lineTop: 0,
            lineBottom: 40,
          ),
          TextLine(
            text: 'bbbb',
            width: 100,
            height: 50,
            chapterPosition: 4,
            lineTop: 40,
            lineBottom: 90,
          ),
        ],
      ),
      makePage(
        chapterIndex: 4,
        index: 1,
        lines: [
          TextLine(
            text: 'cccc',
            width: 100,
            height: 60,
            chapterPosition: 8,
            lineTop: 0,
            lineBottom: 60,
          ),
        ],
      ),
    ];

    test('charOffset 轉章內 local offset 正確', () {
      expect(ChapterPositionResolver.charOffsetToLocalOffset(pages, 4), 40);
      expect(ChapterPositionResolver.charOffsetToLocalOffset(pages, 5), 40);
      expect(ChapterPositionResolver.charOffsetToLocalOffset(pages, 8), 90);
    });

    test('local offset 轉 charOffset 正確', () {
      expect(ChapterPositionResolver.localOffsetToCharOffset(pages, 10), 0);
      expect(ChapterPositionResolver.localOffsetToCharOffset(pages, 45), 4);
      expect(ChapterPositionResolver.localOffsetToCharOffset(pages, 100), 8);
      expect(ChapterPositionResolver.localOffsetToCharOffset(pages, 200), 12);
    });

    test('頁面索引與頁面首字元定位正確', () {
      expect(ChapterPositionResolver.findPageIndexByCharOffset(pages, 8), 1);
      expect(ChapterPositionResolver.pageIndexAtLocalOffset(pages, 95), 1);
      expect(ChapterPositionResolver.getCharOffsetForPage(pages, 1), 8);
    });
  });
}
