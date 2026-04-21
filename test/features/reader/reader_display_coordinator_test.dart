import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_display_coordinator.dart';

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
  group('ReaderDisplayCoordinator', () {
    const coordinator = ReaderDisplayCoordinator();

    test('scroll 顯示指令會產生對應的 durable location 與 scroll target', () {
      final chapter = _chapter(1, [0, 8, 16]);

      final instruction = coordinator.resolveDisplayInstruction(
        ReaderPresentationRequest(
          anchor: const ReaderPresentationAnchor(
            location: ReaderLocation(chapterIndex: 1, charOffset: 9),
          ),
          isScrollMode: true,
          chapterPages: chapter.pages,
          slidePages: chapter.pages,
          runtimeChapter: chapter,
        ),
      );

      expect(instruction.location, isA<ReaderLocation>());
      expect(instruction.location.chapterIndex, 1);
      expect(instruction.location.charOffset, 9);
      expect(instruction.scrollTarget, isNotNull);
      expect(instruction.slidePageIndex, isNull);
    });

    test('slide 顯示指令會將 durable location 解析為全域頁索引', () {
      final chapter0 = _chapter(0, [0]);
      final chapter1 = _chapter(1, [0, 8, 16]);
      final slidePages = [...chapter0.pages, ...chapter1.pages];

      final instruction = coordinator.resolveDisplayInstruction(
        ReaderPresentationRequest(
          anchor: const ReaderPresentationAnchor(
            location: ReaderLocation(chapterIndex: 1, charOffset: 0),
          ),
          isScrollMode: false,
          chapterPages: chapter1.pages,
          slidePages: slidePages,
          runtimeChapter: chapter1,
        ),
      );

      expect(instruction.location.chapterIndex, 1);
      expect(instruction.location.charOffset, 0);
      expect(instruction.scrollTarget, isNull);
      expect(instruction.slidePageIndex, 1);
    });

    test(
      'slide target index 會優先使用 pinned location，其次回退 previous mapping 或 durable location',
      () {
        final chapter0 = _chapter(0, [0]);
        final chapter1 = _chapter(1, [0, 8, 16]);
        final slidePages = [...chapter0.pages, ...chapter1.pages];

        final pinned = coordinator.resolveSlideTargetIndex(
          ReaderSlideTargetRequest(
            pinnedAnchor: const ReaderPresentationAnchor(
              location: ReaderLocation(chapterIndex: 1, charOffset: 8),
            ),
            previousMappedIndex: 0,
            durableLocation: const ReaderLocation(
              chapterIndex: 0,
              charOffset: 0,
            ),
            slidePages: slidePages,
            chapterAt: (index) => index == 0 ? chapter0 : chapter1,
            pagesForChapter:
                (index) => index == 0 ? chapter0.pages : chapter1.pages,
          ),
        );
        final fallback = coordinator.resolveSlideTargetIndex(
          ReaderSlideTargetRequest(
            pinnedAnchor: null,
            previousMappedIndex: null,
            durableLocation: const ReaderLocation(
              chapterIndex: 1,
              charOffset: 8,
            ),
            slidePages: slidePages,
            chapterAt: (index) => index == 0 ? chapter0 : chapter1,
            pagesForChapter:
                (index) => index == 0 ? chapter0.pages : chapter1.pages,
          ),
        );

        expect(pinned, 2);
        expect(fallback, 2);
      },
    );
  });
}
