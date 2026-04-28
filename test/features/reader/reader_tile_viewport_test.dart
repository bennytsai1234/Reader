import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';
import 'package:inkpage_reader/features/reader/engine/layout_engine.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_tile_layer.dart';
import 'package:inkpage_reader/features/reader/viewport/scroll_reader_viewport.dart';
import 'package:inkpage_reader/features/reader/viewport/slide_reader_viewport.dart';

class _FakeBookDao extends Fake implements BookDao {
  ReaderLocation? lastLocation;

  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos, {
    String? readerAnchorJson,
  }) async {
    lastLocation = ReaderLocation(chapterIndex: chapterIndex, charOffset: pos);
  }
}

class _FakeChapterDao extends Fake implements ChapterDao {
  _FakeChapterDao(this.chapterList);

  final List<BookChapter> chapterList;

  @override
  Future<List<BookChapter>> getByBook(String bookUrl) async => chapterList;
}

class _FakeSourceDao extends Fake implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async => null;
}

class _FakeContentDao extends Fake implements ReaderChapterContentDao {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tile-based reader viewports', () {
    testWidgets('scroll drag updates visible location forward', (tester) async {
      final env = _RuntimeEnv();
      await env.runtime.openBook();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: ScrollReaderViewport(
              runtime: env.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(ReaderPageMode.scroll),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = env.runtime.state.visibleLocation;
      await tester.drag(
        find.byType(ScrollReaderViewport),
        const Offset(0, -240),
      );
      await tester.pumpAndSettle();

      final after = env.runtime.state.visibleLocation;
      expect(after.chapterIndex, greaterThanOrEqualTo(before.chapterIndex));
      expect(
        after.chapterIndex > before.chapterIndex ||
            after.charOffset > before.charOffset,
        isTrue,
      );

      await env.runtime.flushProgress();
      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('slide drag commits the next tile window once', (tester) async {
      final env = _RuntimeEnv(mode: ReaderMode.slide);
      await env.runtime.openBook();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: SlideReaderViewport(
              runtime: env.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(ReaderPageMode.slide),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = env.runtime.state.pageWindow!.current;
      await tester.drag(
        find.byType(SlideReaderViewport),
        const Offset(-220, 0),
      );
      await tester.pumpAndSettle();

      expect(
        '${env.runtime.state.pageWindow!.current.chapterIndex}:${env.runtime.state.pageWindow!.current.pageIndex}',
        isNot('${before.chapterIndex}:${before.pageIndex}'),
      );
      final after =
          '${env.runtime.state.pageWindow!.current.chapterIndex}:${env.runtime.state.pageWindow!.current.pageIndex}';

      await tester.pump();

      expect(
        '${env.runtime.state.pageWindow!.current.chapterIndex}:${env.runtime.state.pageWindow!.current.pageIndex}',
        after,
      );

      await env.runtime.flushProgress();
      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('scroll viewport builds chapter-sized tiles', (tester) async {
      final env = _RuntimeEnv();
      await env.runtime.openBook();
      final style = _style(ReaderPageMode.scroll);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: ScrollReaderViewport(
              runtime: env.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: style,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReaderTileLayer), findsWidgets);
      final renderedHeight =
          tester.getSize(find.byType(ReaderTileLayer).first).height;
      final layout = env.runtime.debugResolver.cachedLayout(0);
      expect(layout, isNotNull);
      final contentHeight =
          layout!.lines.isEmpty ? 0.0 : layout.lines.last.bottom;
      expect(
        renderedHeight,
        greaterThanOrEqualTo(
          contentHeight + style.paddingTop + style.paddingBottom,
        ),
      );

      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('scroll viewport keeps title-only chapter stable at bounds', (
      tester,
    ) async {
      final env = _RuntimeEnv(
        chapters: <BookChapter>[
          BookChapter(title: '只有標題', index: 0, bookUrl: 'book', content: ''),
        ],
      );
      await env.runtime.openBook();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: ScrollReaderViewport(
              runtime: env.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(ReaderPageMode.scroll),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(ScrollReaderViewport),
        const Offset(0, -240),
      );
      await tester.pumpAndSettle();

      expect(env.runtime.state.visibleLocation.chapterIndex, 0);
      expect(env.runtime.state.visibleLocation.charOffset, 0);

      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('scroll restores reading position after reopen', (
      tester,
    ) async {
      final firstEnv = _RuntimeEnv();
      await firstEnv.runtime.openBook();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: ScrollReaderViewport(
              runtime: firstEnv.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(ReaderPageMode.scroll),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(ScrollReaderViewport),
        const Offset(0, -480),
      );
      await tester.pumpAndSettle();

      final firstScrollable = tester.widget<Scrollable>(
        find.byType(Scrollable),
      );
      final offsetBeforeExit = firstScrollable.controller!.offset;
      await firstEnv.runtime.flushProgress();
      final savedLocation = firstEnv.bookDao.lastLocation;
      expect(savedLocation, isNotNull);

      firstEnv.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));

      final restoredEnv = _RuntimeEnv(
        initialChapterIndex: savedLocation!.chapterIndex,
        initialCharOffset: savedLocation.charOffset,
      );
      await restoredEnv.runtime.openBook();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: ScrollReaderViewport(
              runtime: restoredEnv.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(ReaderPageMode.scroll),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final restoredScrollable = tester.widget<Scrollable>(
        find.byType(Scrollable),
      );
      final restoredOffset = restoredScrollable.controller!.offset;
      expect(
        restoredEnv.runtime.state.visibleLocation.chapterIndex,
        savedLocation.chapterIndex,
      );
      expect(
        (restoredEnv.runtime.state.visibleLocation.charOffset -
                savedLocation.charOffset)
            .abs(),
        lessThanOrEqualTo(80),
      );
      expect((restoredOffset - offsetBeforeExit).abs(), lessThanOrEqualTo(120));

      restoredEnv.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('scroll keeps reading anchor after relayout', (tester) async {
      final env = _RuntimeEnv();
      await env.runtime.openBook();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: ScrollReaderViewport(
              runtime: env.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(ReaderPageMode.scroll),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(ScrollReaderViewport),
        const Offset(0, -520),
      );
      await tester.pumpAndSettle();

      final before = env.runtime.state.visibleLocation;

      await env.runtime.updateStyle(
        _style(ReaderPageMode.scroll).copyWith(fontSize: 22, lineHeight: 1.7),
        const Size(320, 360),
      );
      await tester.pumpAndSettle();

      final after = env.runtime.state.visibleLocation;
      expect(after.chapterIndex, before.chapterIndex);
      expect(
        (after.charOffset - before.charOffset).abs(),
        lessThanOrEqualTo(80),
      );

      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}

class _RuntimeEnv {
  _RuntimeEnv({
    ReaderMode mode = ReaderMode.scroll,
    List<BookChapter>? chapters,
    int initialChapterIndex = 0,
    int initialCharOffset = 0,
  }) : book = Book(
         bookUrl: 'book',
         origin: 'local',
         name: '測試書',
         chapterIndex: initialChapterIndex,
         charOffset: initialCharOffset,
       ),
       bookDao = _FakeBookDao() {
    final resolvedChapters = chapters ?? _chaptersFor(book.bookUrl, 4);
    repository = ChapterRepository(
      book: book,
      initialChapters: resolvedChapters,
      bookDao: bookDao,
      chapterDao: _FakeChapterDao(resolvedChapters),
      sourceDao: _FakeSourceDao(),
      contentDao: _FakeContentDao(),
    );
    runtime = ReaderRuntime(
      book: book,
      repository: repository,
      layoutEngine: LayoutEngine(),
      progressController: ReaderProgressController(
        book: book,
        repository: repository,
        bookDao: bookDao,
      ),
      initialLayoutSpec: _spec(),
      initialMode: mode,
    );
  }

  final Book book;
  final _FakeBookDao bookDao;
  late final ChapterRepository repository;
  late final ReaderRuntime runtime;
}

List<BookChapter> _chaptersFor(String bookUrl, int count) {
  return List<BookChapter>.generate(count, (chapterIndex) {
    return BookChapter(
      title: '第$chapterIndex章',
      index: chapterIndex,
      bookUrl: bookUrl,
      content: List<String>.generate(
        40,
        (i) => '第$chapterIndex章第$i段，這是一段足夠長的文字，用於產生多個 TextPage。',
      ).join('\n\n'),
    );
  });
}

LayoutSpec _spec() {
  return LayoutSpec.fromViewport(
    viewportSize: const Size(320, 360),
    style: _style(ReaderPageMode.scroll),
  );
}

ReadStyle _style(ReaderPageMode mode) {
  return ReadStyle(
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
    pageMode: mode,
  );
}
