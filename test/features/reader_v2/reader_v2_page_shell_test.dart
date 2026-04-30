import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/reader_v2/features/menu/reader_v2_bottom_menu.dart';
import 'package:inkpage_reader/features/reader_v2/shell/reader_v2_chapters_drawer.dart';
import 'package:inkpage_reader/features/reader_v2/shell/reader_v2_page_shell.dart';

void main() {
  testWidgets(
    'controls overlay tap dismisses without passing through content',
    (tester) async {
      var dismissCalls = 0;
      var contentTapCalls = 0;

      final shell = MaterialApp(
        home: ReaderV2PageShell(
          book: Book(bookUrl: 'test://book', name: '測試書', originName: '本地'),
          scaffoldKey: GlobalKey<ScaffoldState>(),
          content: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => contentTapCalls += 1,
            child: const SizedBox.expand(),
          ),
          drawer: ReaderV2ChaptersDrawer(
            chapters: const [],
            currentChapterIndex: 0,
            titleFor: (_) => '',
            onChapterTap: (_) async {},
          ),
          backgroundColor: Colors.white,
          textColor: Colors.black,
          controlsVisible: true,
          readBarStyleFollowPage: true,
          showReadTitleAddition: false,
          hasVisibleContent: true,
          isLoading: false,
          chapterTitle: '第一章',
          chapterUrl: '',
          originName: '本地',
          displayPageLabel: '1/1',
          displayChapterPercentLabel: '10%',
          navigation: ReaderV2ChapterNavigationState(
            chapterCount: 1,
            currentIndex: 0,
            isScrubbing: false,
            scrubIndex: 0,
            pendingIndex: null,
            titleFor: (_) => '',
          ),
          isAutoPaging: false,
          dayNightIcon: Icons.light_mode,
          dayNightTooltip: '日夜切換',
          onExitIntent: () {},
          onMore: () {},
          onOpenDrawer: () {},
          onTts: () {},
          onInterface: () {},
          onSettings: () {},
          onAutoPage: () {},
          onToggleDayNight: () {},
          onReplaceRule: () {},
          onShowControls: () {},
          onDismissControls: () => dismissCalls += 1,
          onPrevChapter: () {},
          onNextChapter: () {},
          onScrubStart: () {},
          onScrubbing: (_) {},
          onScrubEnd: (_) {},
        ),
      );

      await tester.pumpWidget(shell);
      await tester.tapAt(const Offset(120, 220));
      await tester.pump();

      expect(dismissCalls, 1);
      expect(contentTapCalls, 0);
    },
  );

  testWidgets('permanent info bar tap shows controls', (tester) async {
    var showCalls = 0;
    var dismissCalls = 0;
    var contentTapCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ReaderV2PageShell(
          book: Book(bookUrl: 'test://book', name: '測試書', originName: '本地'),
          scaffoldKey: GlobalKey<ScaffoldState>(),
          content: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => contentTapCalls += 1,
            child: const SizedBox.expand(),
          ),
          drawer: ReaderV2ChaptersDrawer(
            chapters: const [],
            currentChapterIndex: 0,
            titleFor: (_) => '',
            onChapterTap: (_) async {},
          ),
          backgroundColor: Colors.white,
          textColor: Colors.black,
          controlsVisible: false,
          readBarStyleFollowPage: true,
          showReadTitleAddition: true,
          hasVisibleContent: true,
          isLoading: false,
          chapterTitle: '第一章',
          chapterUrl: '',
          originName: '本地',
          displayPageLabel: '1/1',
          displayChapterPercentLabel: '10%',
          navigation: ReaderV2ChapterNavigationState(
            chapterCount: 1,
            currentIndex: 0,
            isScrubbing: false,
            scrubIndex: 0,
            pendingIndex: null,
            titleFor: (_) => '',
          ),
          isAutoPaging: false,
          dayNightIcon: Icons.light_mode,
          dayNightTooltip: '日夜切換',
          onExitIntent: () {},
          onMore: () {},
          onOpenDrawer: () {},
          onTts: () {},
          onInterface: () {},
          onSettings: () {},
          onAutoPage: () {},
          onToggleDayNight: () {},
          onReplaceRule: () {},
          onShowControls: () => showCalls += 1,
          onDismissControls: () => dismissCalls += 1,
          onPrevChapter: () {},
          onNextChapter: () {},
          onScrubStart: () {},
          onScrubbing: (_) {},
          onScrubEnd: (_) {},
        ),
      ),
    );

    final scaffoldSize = tester.getSize(find.byType(Scaffold));
    await tester.tapAt(Offset(scaffoldSize.width / 2, scaffoldSize.height - 8));
    await tester.pump();

    expect(showCalls, 1);
    expect(dismissCalls, 0);
    expect(contentTapCalls, 0);
  });

  testWidgets('top system inset is reserved outside reader content', (
    tester,
  ) async {
    const contentKey = ValueKey<String>('reader-content');

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(top: 24),
          ),
          child: ReaderV2PageShell(
            book: Book(bookUrl: 'test://book', name: '測試書', originName: '本地'),
            scaffoldKey: GlobalKey<ScaffoldState>(),
            content: const ColoredBox(key: contentKey, color: Colors.white),
            drawer: ReaderV2ChaptersDrawer(
              chapters: const [],
              currentChapterIndex: 0,
              titleFor: (_) => '',
              onChapterTap: (_) async {},
            ),
            backgroundColor: Colors.white,
            textColor: Colors.black,
            controlsVisible: false,
            readBarStyleFollowPage: true,
            showReadTitleAddition: false,
            hasVisibleContent: true,
            isLoading: false,
            chapterTitle: '第一章',
            chapterUrl: '',
            originName: '本地',
            displayPageLabel: '1/1',
            displayChapterPercentLabel: '10%',
            navigation: ReaderV2ChapterNavigationState(
              chapterCount: 1,
              currentIndex: 0,
              isScrubbing: false,
              scrubIndex: 0,
              pendingIndex: null,
              titleFor: (_) => '',
            ),
            isAutoPaging: false,
            dayNightIcon: Icons.light_mode,
            dayNightTooltip: '日夜切換',
            onExitIntent: () {},
            onMore: () {},
            onOpenDrawer: () {},
            onTts: () {},
            onInterface: () {},
            onSettings: () {},
            onAutoPage: () {},
            onToggleDayNight: () {},
            onReplaceRule: () {},
            onShowControls: () {},
            onDismissControls: () {},
            onPrevChapter: () {},
            onNextChapter: () {},
            onScrubStart: () {},
            onScrubbing: (_) {},
            onScrubEnd: (_) {},
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(contentKey)).dy, 24);
  });

  testWidgets('top system inset tap shows controls', (tester) async {
    var showCalls = 0;
    var dismissCalls = 0;
    var contentTapCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(top: 24),
          ),
          child: ReaderV2PageShell(
            book: Book(bookUrl: 'test://book', name: '測試書', originName: '本地'),
            scaffoldKey: GlobalKey<ScaffoldState>(),
            content: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => contentTapCalls += 1,
              child: const SizedBox.expand(),
            ),
            drawer: ReaderV2ChaptersDrawer(
              chapters: const [],
              currentChapterIndex: 0,
              titleFor: (_) => '',
              onChapterTap: (_) async {},
            ),
            backgroundColor: Colors.white,
            textColor: Colors.black,
            controlsVisible: false,
            readBarStyleFollowPage: true,
            showReadTitleAddition: false,
            hasVisibleContent: true,
            isLoading: false,
            chapterTitle: '第一章',
            chapterUrl: '',
            originName: '本地',
            displayPageLabel: '1/1',
            displayChapterPercentLabel: '10%',
            navigation: ReaderV2ChapterNavigationState(
              chapterCount: 1,
              currentIndex: 0,
              isScrubbing: false,
              scrubIndex: 0,
              pendingIndex: null,
              titleFor: (_) => '',
            ),
            isAutoPaging: false,
            dayNightIcon: Icons.light_mode,
            dayNightTooltip: '日夜切換',
            onExitIntent: () {},
            onMore: () {},
            onOpenDrawer: () {},
            onTts: () {},
            onInterface: () {},
            onSettings: () {},
            onAutoPage: () {},
            onToggleDayNight: () {},
            onReplaceRule: () {},
            onShowControls: () => showCalls += 1,
            onDismissControls: () => dismissCalls += 1,
            onPrevChapter: () {},
            onNextChapter: () {},
            onScrubStart: () {},
            onScrubbing: (_) {},
            onScrubEnd: (_) {},
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(120, 8));
    await tester.pump();

    expect(showCalls, 1);
    expect(dismissCalls, 0);
    expect(contentTapCalls, 0);
  });
}
