import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_presentation_contract.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_command.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime_controller.dart';

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
  group('ReaderRuntimeController', () {
    late ReaderChapter chapter0;
    late ReaderChapter chapter1;
    late List<TextPage> slidePages;
    late ReaderRuntimeController controller;

    setUp(() {
      chapter0 = _chapter(0, [0]);
      chapter1 = _chapter(1, [0, 8, 16]);
      slidePages = [...chapter0.pages, ...chapter1.pages];
      controller = ReaderRuntimeController(
        chapterAt: (chapterIndex) {
          switch (chapterIndex) {
            case 0:
              return chapter0;
            case 1:
              return chapter1;
            default:
              return null;
          }
        },
        pagesForChapter: (chapterIndex) {
          switch (chapterIndex) {
            case 0:
              return chapter0.pages;
            case 1:
              return chapter1.pages;
            default:
              return const <TextPage>[];
          }
        },
        slidePages: () => slidePages,
      );
    });

    test(
      'scroll anchor 會以 visible chapter/localOffset 擷取 durable location',
      () {
        final localOffset = chapter1.localOffsetFromCharOffset(8);

        final anchor = controller.capturePresentationAnchor(
          isScrollMode: true,
          currentChapterIndex: 1,
          visibleChapterIndex: 1,
          visibleChapterLocalOffset: localOffset,
          currentPageIndex: 0,
          fallbackLocation: const ReaderLocation(
            chapterIndex: 0,
            charOffset: 0,
          ),
        );

        expect(
          anchor.location,
          const ReaderLocation(chapterIndex: 1, charOffset: 8),
        );
        expect(anchor.fromEnd, isFalse);
      },
    );

    test('slide anchor 會以目前全域頁索引回推章節 charOffset', () {
      final anchor = controller.capturePresentationAnchor(
        isScrollMode: false,
        currentChapterIndex: 1,
        visibleChapterIndex: 0,
        visibleChapterLocalOffset: 0,
        currentPageIndex: 2,
        fallbackLocation: const ReaderLocation(chapterIndex: 0, charOffset: 0),
      );

      expect(
        anchor.location,
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      );
    });

    test('scroll viewport command 會把 anchor 轉成 scroll target', () {
      final command = controller.resolveViewportCommand(
        isScrollMode: true,
        anchor: const ReaderPresentationAnchor(
          location: ReaderLocation(chapterIndex: 1, charOffset: 8),
        ),
        reason: ReaderCommandReason.restore,
      );

      expect(command, isA<ReaderScrollViewportCommand>());
      final scrollCommand = command as ReaderScrollViewportCommand;
      expect(
        scrollCommand.location,
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      );
      expect(scrollCommand.reason, ReaderCommandReason.restore);
      expect(scrollCommand.target.chapterIndex, 1);
      expect(
        scrollCommand.target.localOffset,
        chapter1.localOffsetFromCharOffset(8),
      );
      expect(scrollCommand.anchor.pageIndexSnapshot, 1);
      expect(
        scrollCommand.anchor.localOffsetSnapshot,
        chapter1.localOffsetFromCharOffset(8),
      );
    });

    test('slide viewport command 會把 anchor 轉成對應全域頁索引', () {
      final command = controller.resolveViewportCommand(
        isScrollMode: false,
        anchor: const ReaderPresentationAnchor(
          location: ReaderLocation(chapterIndex: 1, charOffset: 8),
        ),
        reason: ReaderCommandReason.settingsRepaginate,
      );

      expect(command, isA<ReaderSlideViewportCommand>());
      final slideCommand = command as ReaderSlideViewportCommand;
      expect(
        slideCommand.location,
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      );
      expect(slideCommand.reason, ReaderCommandReason.settingsRepaginate);
      expect(slideCommand.target.globalPageIndex, 2);
      expect(slideCommand.target.chapterIndex, 1);
      expect(slideCommand.target.chapterPageIndex, 1);
      expect(slideCommand.anchor.pageIndexSnapshot, 2);
    });

    test('slide page snapshot 只有在目前視窗仍指向同一章頁時才會重用', () {
      expect(
        controller.matchingSlidePageIndexSnapshot(
          location: const ReaderLocation(chapterIndex: 1, charOffset: 8),
          pageIndexSnapshot: 2,
        ),
        2,
      );

      slidePages = [...chapter1.pages];

      expect(
        controller.matchingSlidePageIndexSnapshot(
          location: const ReaderLocation(chapterIndex: 1, charOffset: 8),
          pageIndexSnapshot: 2,
        ),
        isNull,
      );
    });

    test('globalSlidePageIndexForLocation 找不到目標頁時回傳 null', () {
      expect(
        controller.globalSlidePageIndexForLocation(
          const ReaderLocation(chapterIndex: 1, charOffset: 8),
        ),
        2,
      );

      slidePages = [...chapter0.pages];

      expect(
        controller.globalSlidePageIndexForLocation(
          const ReaderLocation(chapterIndex: 1, charOffset: 8),
        ),
        isNull,
      );
    });

    test('viewport command 會保留 source anchor metadata', () {
      final command = controller.resolveViewportCommand(
        isScrollMode: true,
        anchor: const ReaderPresentationAnchor(
          location: ReaderLocation(chapterIndex: 1, charOffset: 8),
        ),
        sourceAnchor: const ReaderAnchor(
          location: ReaderLocation(chapterIndex: 1, charOffset: 8),
          layoutSignature: 'scroll:320x640',
        ),
      );

      expect(
        command.anchor.location,
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      );
      expect(command.anchor.layoutSignature, 'scroll:320x640');
      expect(command.anchor.pageIndexSnapshot, 1);
      expect(
        command.anchor.localOffsetSnapshot,
        chapter1.localOffsetFromCharOffset(8),
      );
    });
  });
}
