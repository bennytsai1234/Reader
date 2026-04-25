import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';

void main() {
  ReaderChapter makeChapter() {
    final pages = <TextPage>[
      TextPage(
        index: 0,
        title: 'chapter',
        chapterIndex: 0,
        pageSize: 2,
        lines: [
          TextLine(
            text: 'AAAA',
            width: 100,
            height: 20,
            chapterPosition: 0,
            lineTop: 0,
            lineBottom: 20,
            paragraphNum: 1,
          ),
          TextLine(
            text: 'BBBB',
            width: 100,
            height: 20,
            chapterPosition: 4,
            lineTop: 20,
            lineBottom: 40,
            paragraphNum: 1,
            isParagraphEnd: true,
          ),
        ],
      ),
      TextPage(
        index: 1,
        title: 'chapter',
        chapterIndex: 0,
        pageSize: 2,
        lines: [
          TextLine(
            text: 'CCCC',
            width: 100,
            height: 20,
            chapterPosition: 8,
            lineTop: 40,
            lineBottom: 60,
            paragraphNum: 2,
          ),
          TextLine(
            text: 'DDDD',
            width: 100,
            height: 20,
            chapterPosition: 12,
            lineTop: 60,
            lineBottom: 80,
            paragraphNum: 2,
            isParagraphEnd: true,
          ),
        ],
      ),
    ];

    return ReaderChapter(
      chapter: BookChapter(title: 'chapter', index: 0),
      index: 0,
      title: 'chapter',
      pages: pages,
    );
  }

  group('ReaderChapter runtime helpers', () {
    test('charOffsetForPageIndex 會回傳每頁起始偏移', () {
      final chapter = makeChapter();

      expect(chapter.charOffsetForPageIndex(0), 0);
      expect(chapter.charOffsetForPageIndex(1), 8);
    });

    test('pageIndexAtLocalOffset 與 resolveLocalOffsetTarget 會對齊頁面資訊', () {
      final chapter = makeChapter();

      expect(chapter.pageIndexAtLocalOffset(10), 0);
      expect(chapter.pageIndexAtLocalOffset(55), 1);

      final target = chapter.resolveLocalOffsetTarget(55);
      expect(target.pageIndex, 1);
      expect(target.pageStartCharOffset, 8);
      expect(target.pageStartLocalOffset, 80);
      expect(target.intraPageOffset, 0);
    });

    test('localOffsetFromCharOffset 會命中當前行而不是跳到下一行', () {
      final chapter = makeChapter();

      expect(chapter.localOffsetFromCharOffset(9), 80);
      expect(chapter.localOffsetFromCharOffset(13), 100);
    });

    test('buildReadAloudData 會從指定偏移開始組裝朗讀內容', () {
      final chapter = makeChapter();

      final data = chapter.buildReadAloudData(startCharOffset: 8);
      expect(data, isNotNull);
      expect(data!.baseOffset, 8);
      expect(data.text, contains('CCCC'));
      expect(data.offsetMap.first.chapterOffset, 8);
    });

    test('buildReadAloudSegments 會保留分段與章內位置資訊', () {
      final chapter = makeChapter();

      final result = chapter.buildReadAloudSegments(startCharOffset: 9);
      expect(result, isNotNull);
      expect(result!.chapterIndex, 0);
      expect(result.startCharOffset, 9);
      expect(result.segments, hasLength(2));
      expect(result.segments.first.text, 'CCC');
      expect(result.segments.first.pageIndex, 1);
      expect(result.segments.first.lineIndex, 0);
      expect(result.segments.first.chapterStart, 9);
      expect(result.segments.first.chapterEnd, 12);
      expect(result.segments.last.text, 'DDDD');
      expect(result.segments.last.chapterStart, 12);
      expect(result.segments.last.chapterEnd, 16);
    });

    test('buildParagraphReadAloudSegments 會以段落分段並保留 offset map', () {
      final chapter = makeChapter();

      final result = chapter.buildParagraphReadAloudSegments(
        startCharOffset: 9,
      );

      expect(result, isNotNull);
      expect(result!.chapterIndex, 0);
      expect(result.startCharOffset, 9);
      expect(result.segments, hasLength(1));

      final segment = result.segments.single;
      expect(segment.text, 'CCCDDDD');
      expect(segment.pageIndex, 1);
      expect(segment.lineIndex, 0);
      expect(segment.chapterStart, 9);
      expect(segment.chapterEnd, 16);
      expect(segment.offsetMap, hasLength(2));
      expect(segment.offsetMap.first.ttsOffset, 0);
      expect(segment.offsetMap.first.chapterOffset, 9);
      expect(segment.offsetMap.last.ttsOffset, 3);
      expect(segment.offsetMap.last.chapterOffset, 12);
      expect(segment.chapterOffsetForTtsOffset(0), 9);
      expect(segment.chapterOffsetForTtsOffset(2), 11);
      expect(segment.chapterOffsetForTtsOffset(3), 12);
      expect(segment.chapterOffsetForTtsOffset(4), 13);
    });

    test('line 與 paragraph query 會對齊 char offset', () {
      final chapter = makeChapter();

      final line = chapter.lineAtCharOffset(9);
      final paragraph = chapter.paragraphAtCharOffset(9);

      expect(line, isNotNull);
      expect(line!.text, 'CCCC');
      expect(paragraph, isNotNull);
      expect(paragraph!.text, 'CCCCDDDD');
    });

    test('前後頁與可見性 helper 會回傳一致結果', () {
      final chapter = makeChapter();

      expect(chapter.nextPageStartCharOffset(2), 8);
      expect(chapter.prevPageStartCharOffset(10), 0);
      expect(chapter.isCharOffsetVisibleInPage(10, 1), isTrue);
      expect(chapter.isCharOffsetVisibleInPage(10, 0), isFalse);
    });

    test('highlight 與 restore helper 會共用章內定位語義', () {
      final chapter = makeChapter();

      final highlight = chapter.resolveHighlightRange(9);
      expect(highlight.start, 8);
      expect(highlight.end, 16);
      expect(highlight.pageIndex, 1);

      final restore = chapter.resolveRestoreTarget(charOffset: 9);
      expect(restore.pageIndex, 1);
      expect(restore.pageStartCharOffset, 8);
      expect(restore.targetLocalOffset, 80);

      final anchor = chapter.resolveScrollAnchor(9, anchorPadding: 10);
      expect(anchor.pageIndex, 1);
      expect(anchor.localOffset, 70);
    });
  });
}
