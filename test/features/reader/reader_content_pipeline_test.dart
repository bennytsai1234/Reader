import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_content_pipeline.dart';

List<TextPage> _buildPages(
  int chapterIndex,
  List<int> pageStarts, {
  String title = 'chapter',
}) {
  return List.generate(pageStarts.length, (pageIndex) {
    final start = pageStarts[pageIndex];
    final nextStart =
        pageIndex + 1 < pageStarts.length
            ? pageStarts[pageIndex + 1]
            : start + 8;
    final length = (nextStart - start).clamp(4, 12);
    return TextPage(
      index: pageIndex,
      title: title,
      chapterIndex: chapterIndex,
      pageSize: pageStarts.length,
      lines: [
        TextLine(
          text: List.filled(length, 'X').join(),
          width: 100,
          height: 20,
          chapterPosition: start,
          lineTop: pageIndex * 100,
          lineBottom: pageIndex * 100 + 40,
          paragraphNum: pageIndex + 1,
          isParagraphEnd: true,
        ),
      ],
    );
  });
}

ReaderChapter _chapter(int index, List<int> pageStarts) {
  return ReaderChapter(
    chapter: BookChapter(title: 'c$index', index: index),
    index: index,
    title: 'c$index',
    pages: _buildPages(index, pageStarts, title: 'c$index'),
  );
}

void main() {
  group('ReaderContentPipeline', () {
    late ReaderChapter chapter0;
    late ReaderChapter chapter1;
    late ReaderChapter chapter2;
    late ReaderContentPipeline pipeline;

    ReaderChapter? chapterAt(int chapterIndex) {
      switch (chapterIndex) {
        case 0:
          return chapter0;
        case 1:
          return chapter1;
        case 2:
          return chapter2;
        default:
          return null;
      }
    }

    List<TextPage> pagesForChapter(int chapterIndex) {
      return chapterAt(chapterIndex)?.pages ?? const <TextPage>[];
    }

    setUp(() {
      chapter0 = _chapter(0, [0]);
      chapter1 = _chapter(1, [0, 8, 16]);
      chapter2 = _chapter(2, [0]);
      pipeline = ReaderContentPipeline();
    });

    test('rebuildSlidePages 會優先落到 pinned slide target', () {
      final slidePages = [...chapter0.pages, ...chapter1.pages];
      pipeline.pinSlideTarget(chapterIndex: 1, charOffset: 8);

      final update = pipeline.rebuildSlidePages(
        currentChapterIndex: 1,
        currentPageIndex: 0,
        currentSlidePages: slidePages,
        runtimePages: slidePages,
        chapterPagesCache: {0: chapter0.pages, 1: chapter1.pages},
        totalChapters: 2,
        durableLocation: const ReaderLocation(chapterIndex: 0, charOffset: 0),
        chapterAt: chapterAt,
        pagesForChapter: pagesForChapter,
      );

      expect(update.currentPageIndex, 2);
      expect(update.shouldRequestJump, isTrue);
      expect(update.slidePages, hasLength(4));
      expect(pipeline.slideWindow.centerChapterIndex, 1);
    });

    test('handleSlidePageChanged 跨章時會標記 deferred recenter', () {
      final slidePages = [...chapter0.pages, ...chapter1.pages];

      final change = pipeline.handleSlidePageChanged(
        pageIndex: 2,
        slidePages: slidePages,
        currentChapterIndex: 0,
        pagesForChapter: pagesForChapter,
        chapterAt: chapterAt,
      );

      expect(change, isNotNull);
      expect(change!.chapterIndex, 1);
      expect(change.needsRecenter, isTrue);
      expect(change.localOffset, chapter1.localOffsetFromCharOffset(8));
      expect(pipeline.hasPendingSlideRecenter, isTrue);
    });

    test('applyPendingSlideRecenter 會重建以新章節為中心的 slide window', () {
      final slidePages = [
        ...chapter0.pages,
        ...chapter1.pages,
        ...chapter2.pages,
      ];
      final change = pipeline.handleSlidePageChanged(
        pageIndex: 4,
        slidePages: slidePages,
        currentChapterIndex: 1,
        pagesForChapter: pagesForChapter,
        chapterAt: chapterAt,
      );

      expect(change, isNotNull);
      expect(change!.chapterIndex, 2);
      expect(change.needsRecenter, isTrue);

      final update = pipeline.applyPendingSlideRecenter(
        currentPageIndex: 4,
        currentSlidePages: slidePages,
        chapterPagesCache: {
          0: chapter0.pages,
          1: chapter1.pages,
          2: chapter2.pages,
        },
        totalChapters: 3,
      );

      expect(update, isNotNull);
      expect(update!.currentPageIndex, 3);
      expect(update.slidePages.map((page) => page.chapterIndex), [1, 1, 1, 2]);
      expect(update.shouldRequestJump, isFalse);
      expect(pipeline.slideWindow.centerChapterIndex, 2);
      expect(pipeline.hasPendingSlideRecenter, isFalse);
    });
  });
}
