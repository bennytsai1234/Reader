import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_command.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_session_runtime.dart';

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
  group('ReaderSessionRuntime', () {
    late ReaderChapter chapter0;
    late ReaderChapter chapter1;
    late List<TextPage> slidePages;
    late ReaderRuntimeController controller;
    late List<ReaderLocation> sessionUpdates;
    late List<ReaderLocation> visibleUpdates;
    late List<ReaderLocation> persistedLocations;
    late List<ReaderViewportCommand> dispatchedCommands;
    late ReaderSessionRuntime runtime;
    late ReaderLocation committedLocation;

    ReaderChapter? chapterAt(int chapterIndex) {
      switch (chapterIndex) {
        case 0:
          return chapter0;
        case 1:
          return chapter1;
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
      slidePages = [...chapter0.pages, ...chapter1.pages];
      controller = ReaderRuntimeController(
        chapterAt: chapterAt,
        pagesForChapter: pagesForChapter,
        slidePages: () => slidePages,
      );
      committedLocation = const ReaderLocation(chapterIndex: 0, charOffset: 0);
      sessionUpdates = <ReaderLocation>[];
      visibleUpdates = <ReaderLocation>[];
      persistedLocations = <ReaderLocation>[];
      dispatchedCommands = <ReaderViewportCommand>[];
      runtime = ReaderSessionRuntime(
        runtimeController: controller,
        committedLocation: () => committedLocation,
        updateCommittedLocation: (location) {
          committedLocation = location;
          sessionUpdates.add(location);
        },
        updateVisibleLocation: visibleUpdates.add,
        persistLocation: (location) async {
          persistedLocations.add(location);
        },
        dispatchViewportCommand: dispatchedCommands.add,
      );
    });

    test('prepareSettingsRepaginateAnchor 會同步 session 與 visible location', () {
      final prepared = runtime.prepareSettingsRepaginateAnchor(
        const ReaderSessionRuntimeContext(
          isScrollMode: false,
          currentChapterIndex: 1,
          visibleChapterIndex: 0,
          visibleChapterLocalOffset: 0,
          currentPageIndex: 2,
        ),
      );

      expect(
        prepared.location,
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      );
      expect(prepared.localOffset, chapter1.localOffsetFromCharOffset(8));
      expect(sessionUpdates, [
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      ]);
      expect(visibleUpdates, [
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      ]);
    });

    test(
      'resolveExitLocation scroll 會以 visible localOffset 重新計算 charOffset',
      () {
        final location = runtime.resolveExitLocation(
          ReaderSessionRuntimeContext(
            isScrollMode: true,
            currentChapterIndex: 0,
            visibleChapterIndex: 1,
            visibleChapterLocalOffset: chapter1.localOffsetFromCharOffset(8),
            currentPageIndex: 0,
          ),
        );

        expect(location, const ReaderLocation(chapterIndex: 1, charOffset: 8));
        expect(visibleUpdates, [
          const ReaderLocation(chapterIndex: 1, charOffset: 8),
        ]);
      },
    );

    test('jumpToPosition scroll 會 dispatch scroll viewport command', () {
      runtime.jumpToPosition(
        isScrollMode: true,
        currentChapterIndex: 1,
        chapterIndex: 1,
        charOffset: 8,
        reason: ReaderCommandReason.restore,
      );

      expect(dispatchedCommands, hasLength(1));
      expect(dispatchedCommands.single, isA<ReaderScrollViewportCommand>());
      final command = dispatchedCommands.single as ReaderScrollViewportCommand;
      expect(
        command.location,
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      );
      expect(command.reason, ReaderCommandReason.restore);
      expect(command.target.chapterIndex, 1);
      expect(command.target.localOffset, chapter1.localOffsetFromCharOffset(8));
    });

    test('jumpToPosition slide 會 dispatch slide viewport command', () {
      runtime.jumpToPosition(
        isScrollMode: false,
        currentChapterIndex: 1,
        chapterIndex: 1,
        charOffset: 8,
        reason: ReaderCommandReason.settingsRepaginate,
      );

      expect(dispatchedCommands, hasLength(1));
      expect(dispatchedCommands.single, isA<ReaderSlideViewportCommand>());
      final command = dispatchedCommands.single as ReaderSlideViewportCommand;
      expect(
        command.location,
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      );
      expect(command.reason, ReaderCommandReason.settingsRepaginate);
      expect(command.target.globalPageIndex, 2);
      expect(command.target.chapterIndex, 1);
      expect(command.target.chapterPageIndex, 1);
    });

    test('persistExitProgress 會把 exit location 寫回 store', () async {
      await runtime.persistExitProgress(
        ReaderSessionRuntimeContext(
          isScrollMode: true,
          currentChapterIndex: 0,
          visibleChapterIndex: 1,
          visibleChapterLocalOffset: chapter1.localOffsetFromCharOffset(8),
          currentPageIndex: 0,
        ),
      );

      expect(persistedLocations, [
        const ReaderLocation(chapterIndex: 1, charOffset: 8),
      ]);
    });
  });
}
