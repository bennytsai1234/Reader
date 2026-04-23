import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_chapter_fingerprint.dart';

TextLine _line(
  int chapterPosition,
  int length, {
  double lineTop = 0,
  double lineBottom = 20,
  int paragraphNum = 1,
}) {
  return TextLine(
    text: List.filled(length, 'X').join(),
    width: 100,
    height: 20,
    chapterPosition: chapterPosition,
    lineTop: lineTop,
    lineBottom: lineBottom,
    paragraphNum: paragraphNum,
    isParagraphEnd: true,
  );
}

void main() {
  group('ReaderChapterFingerprint', () {
    test('structureDigest 會區分 coarse metadata 相同但行結構不同的章節', () {
      final original = <TextPage>[
        TextPage(
          index: 0,
          title: 'c0',
          chapterIndex: 0,
          pageSize: 2,
          lines: <TextLine>[
            _line(0, 4, paragraphNum: 1),
            _line(4, 4, lineTop: 24, lineBottom: 44, paragraphNum: 2),
          ],
        ),
        TextPage(
          index: 1,
          title: 'c0',
          chapterIndex: 0,
          pageSize: 2,
          lines: <TextLine>[
            _line(8, 4, paragraphNum: 3),
            _line(12, 4, lineTop: 24, lineBottom: 44, paragraphNum: 4),
          ],
        ),
      ];
      final rewritten = <TextPage>[
        TextPage(
          index: 0,
          title: 'c0',
          chapterIndex: 0,
          pageSize: 2,
          lines: <TextLine>[
            _line(0, 2, paragraphNum: 1),
            _line(2, 6, lineTop: 24, lineBottom: 44, paragraphNum: 2),
          ],
        ),
        TextPage(
          index: 1,
          title: 'c0',
          chapterIndex: 0,
          pageSize: 2,
          lines: <TextLine>[
            _line(8, 4, paragraphNum: 3),
            _line(12, 4, lineTop: 24, lineBottom: 44, paragraphNum: 4),
          ],
        ),
      ];

      expect(
        ReaderChapterFingerprint.structureDigest(
          chapterIndex: 0,
          pages: original,
        ),
        isNot(
          ReaderChapterFingerprint.structureDigest(
            chapterIndex: 0,
            pages: rewritten,
          ),
        ),
      );
    });
  });
}
