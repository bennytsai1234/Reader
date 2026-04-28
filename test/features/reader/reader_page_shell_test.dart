import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/reader_layout.dart';
import 'package:inkpage_reader/features/reader/widgets/reader/reader_bottom_menu.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_page_shell.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_chapters_drawer.dart';

void main() {
  testWidgets('permanent info bar reserves an independent bottom strip', (
    tester,
  ) async {
    final contentKey = GlobalKey();
    const bottomPadding = 20.0;
    const viewportHeight = 480.0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, viewportHeight),
            padding: EdgeInsets.only(bottom: bottomPadding),
          ),
          child: SizedBox(
            width: 320,
            height: viewportHeight,
            child: _shell(
              content: ColoredBox(key: contentKey, color: Colors.white),
            ),
          ),
        ),
      ),
    );

    final shellHeight = tester.getSize(find.byType(Scaffold)).height;
    final contentSize = tester.getSize(find.byKey(contentKey));

    expect(
      contentSize.height,
      shellHeight - bottomPadding - kReaderPermanentInfoReservedHeight,
    );
  });

  testWidgets('permanent info strip is reserved while reader is loading', (
    tester,
  ) async {
    final contentKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 480,
          child: _shell(
            content: ColoredBox(key: contentKey, color: Colors.white),
            hasVisibleContent: false,
            isLoading: true,
          ),
        ),
      ),
    );

    final shellHeight = tester.getSize(find.byType(Scaffold)).height;
    final contentSize = tester.getSize(find.byKey(contentKey));

    expect(
      contentSize.height,
      shellHeight - kReaderPermanentInfoReservedHeight,
    );
  });
}

ReaderPageShell _shell({
  required Widget content,
  bool hasVisibleContent = true,
  bool isLoading = false,
}) {
  return ReaderPageShell(
    book: Book(bookUrl: 'book', origin: 'local', name: '測試書'),
    scaffoldKey: GlobalKey<ScaffoldState>(),
    content: content,
    drawer: ReaderChaptersDrawer(
      chapters: <BookChapter>[
        BookChapter(title: '第一章', index: 0, bookUrl: 'book'),
      ],
      currentChapterIndex: 0,
      titleFor: (_) => '第一章',
      onChapterTap: (_) async {},
    ),
    backgroundColor: Colors.white,
    textColor: Colors.black,
    controlsVisible: false,
    readBarStyleFollowPage: false,
    showReadTitleAddition: true,
    hasVisibleContent: hasVisibleContent,
    isLoading: isLoading,
    chapterTitle: '第一章',
    chapterUrl: '',
    originName: '',
    displayPageLabel: '1/1',
    displayChapterPercentLabel: '0.0%',
    navigation: ReaderChapterNavigationState(
      chapterCount: 1,
      currentIndex: 0,
      isScrubbing: false,
      scrubIndex: 0,
      pendingIndex: null,
      titleFor: (_) => '第一章',
    ),
    isAutoPaging: false,
    dayNightIcon: Icons.dark_mode_rounded,
    dayNightTooltip: '切換主題',
    onExitIntent: () {},
    onMore: () {},
    onOpenDrawer: () {},
    onTts: () {},
    onInterface: () {},
    onSettings: () {},
    onAutoPage: () {},
    onToggleDayNight: () {},
    onSearch: () {},
    onReplaceRule: () {},
    onToggleControls: () {},
    onPrevChapter: () {},
    onNextChapter: () {},
    onScrubStart: () {},
    onScrubbing: (_) {},
    onScrubEnd: (_) {},
  );
}
