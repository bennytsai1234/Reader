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
import 'package:inkpage_reader/features/reader/viewport/reader_screen.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_tile_layer.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_viewport_controller.dart';
import 'package:inkpage_reader/features/reader/viewport/scroll_reader_viewport.dart';
import 'package:inkpage_reader/features/reader/viewport/slide_reader_viewport.dart';

class _FakeBookDao extends Fake implements BookDao {
  ReaderLocation? lastLocation;
  int writes = 0;

  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos, {
    double visualOffsetPx = 0.0,
    String? readerAnchorJson,
  }) async {
    writes += 1;
    lastLocation = ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: pos,
      visualOffsetPx: visualOffsetPx,
    );
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
      var centerLayer = _centerSlideTileLayer(tester);
      expect(centerLayer.tile.lines, isNotEmpty);
      expect(
        '${centerLayer.tile.chapterIndex}:${centerLayer.tile.pageIndex}',
        '${env.runtime.state.pageWindow!.current.chapterIndex}:${env.runtime.state.pageWindow!.current.pageIndex}',
      );
      final after =
          '${env.runtime.state.pageWindow!.current.chapterIndex}:${env.runtime.state.pageWindow!.current.pageIndex}';

      await tester.pump();
      centerLayer = _centerSlideTileLayer(tester);
      expect(centerLayer.tile.lines, isNotEmpty);

      expect(
        '${env.runtime.state.pageWindow!.current.chapterIndex}:${env.runtime.state.pageWindow!.current.pageIndex}',
        after,
      );

      await env.runtime.flushProgress();
      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets(
      'slide viewport renders page cache tiles with slide placement',
      (tester) async {
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

        final viewport = find.byType(SlideReaderViewport);
        final layers = tester
            .widgetList<ReaderTileLayer>(
              find.descendant(
                of: viewport,
                matching: find.byType(ReaderTileLayer),
              ),
            )
            .toList(growable: false);
        final window = env.runtime.state.pageWindow!;
        final layout = env.runtime.debugResolver.cachedLayout(
          window.current.chapterIndex,
        );
        expect(layout, isNotNull);
        expect(layers, isNotEmpty);
        expect(layers.first.tile, layout!.pageCaches[window.current.pageIndex]);

        final transforms = tester
            .widgetList<Transform>(
              find.descendant(of: viewport, matching: find.byType(Transform)),
            )
            .toList(growable: false);
        final viewportWidth = tester.getSize(viewport).width;
        expect(transforms, hasLength(3));
        expect(transforms[0].transform.getTranslation().x, -viewportWidth);
        expect(transforms[1].transform.getTranslation().x, 0);
        expect(transforms[2].transform.getTranslation().x, viewportWidth);

        final captured = env.runtime.captureVisibleLocation();
        expect(captured, isNotNull);
        expect(
          captured!.visualOffsetPx,
          inInclusiveRange(
            ReaderLocation.minVisualOffsetPx,
            ReaderLocation.maxVisualOffsetPx,
          ),
        );
        expect(env.bookDao.writes, 0);

        env.runtime.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets('scroll viewport uses fixed canvas with page cache tiles', (
      tester,
    ) async {
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

      expect(find.byType(Scrollable), findsNothing);
      expect(find.byType(ReaderTileLayer), findsWidgets);
      final renderedHeight =
          tester.getSize(find.byType(ReaderTileLayer).first).height;
      final layout = env.runtime.debugResolver.cachedLayout(0);
      expect(layout, isNotNull);
      expect(layout!.pageCaches, isNotEmpty);
      expect(renderedHeight, 360);

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

      await firstEnv.runtime.flushProgress();
      final savedLocation = firstEnv.bookDao.lastLocation;
      expect(savedLocation, isNotNull);

      firstEnv.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));

      final restoredEnv = _RuntimeEnv(
        initialChapterIndex: savedLocation!.chapterIndex,
        initialCharOffset: savedLocation.charOffset,
        initialVisualOffsetPx: savedLocation.visualOffsetPx,
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

      expect(find.byType(Scrollable), findsNothing);
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
      expect(
        (restoredEnv.runtime.state.visibleLocation.visualOffsetPx -
                savedLocation.visualOffsetPx)
            .abs(),
        lessThanOrEqualTo(40),
      );

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

    testWidgets('scroll canvas saves progress only after scroll idle', (
      tester,
    ) async {
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
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ScrollReaderViewport)),
      );
      await gesture.moveBy(const Offset(0, -220));
      await tester.pump();

      final duringDrag = env.runtime.state.visibleLocation;
      expect(
        duringDrag.chapterIndex > before.chapterIndex ||
            duringDrag.charOffset > before.charOffset,
        isTrue,
      );
      expect(env.bookDao.writes, 0);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(env.bookDao.writes, 1);
      expect(env.bookDao.lastLocation, env.runtime.state.committedLocation);

      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('scroll viewport controller scrollBy moves and settles', (
      tester,
    ) async {
      final env = _RuntimeEnv();
      final controller = ReaderViewportController();
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
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = env.runtime.state.visibleLocation;
      final moved = await controller.scrollBy!(240);
      await tester.pump();

      expect(moved, isTrue);
      expect(
        env.runtime.state.visibleLocation.chapterIndex > before.chapterIndex ||
            env.runtime.state.visibleLocation.charOffset > before.charOffset,
        isTrue,
      );
      expect(env.bookDao.writes, 1);
      expect(env.bookDao.lastLocation, env.runtime.state.committedLocation);

      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('scroll window shifts before short chapters clamp movement', (
      tester,
    ) async {
      final env = _RuntimeEnv(chapters: _shortChaptersFor('book', 4));
      final controller = ReaderViewportController();
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
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstMoved = await controller.scrollBy!(324);
      await tester.pumpAndSettle();
      expect(firstMoved, isTrue);
      expect(env.runtime.state.visibleLocation.chapterIndex, 1);

      final secondMoved = await controller.scrollBy!(324);
      await tester.pumpAndSettle();
      expect(secondMoved, isTrue);
      expect(env.runtime.state.visibleLocation.chapterIndex, 2);

      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('scroll viewport controller ensures char range visible', (
      tester,
    ) async {
      final env = _RuntimeEnv();
      final controller = ReaderViewportController();
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
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final targetPage = env.runtime.state.pageWindow!.next!;
      final follow = controller.ensureCharRangeVisible!(
        chapterIndex: targetPage.chapterIndex,
        startCharOffset: targetPage.startCharOffset,
        endCharOffset: targetPage.endCharOffset,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(await follow, isTrue);
      expect(
        env.runtime.state.visibleLocation.chapterIndex,
        targetPage.chapterIndex,
      );
      expect(
        env.runtime.state.visibleLocation.charOffset,
        lessThanOrEqualTo(targetPage.endCharOffset),
      );

      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('scroll window follows next and previous chapters', (
      tester,
    ) async {
      final env = _RuntimeEnv(initialChapterIndex: 1);
      final controller = ReaderViewportController();
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
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentLayout = env.runtime.debugResolver.cachedLayout(1);
      expect(currentLayout, isNotNull);

      final nextFollow = controller.ensureCharRangeVisible!(
        chapterIndex: 2,
        startCharOffset: 0,
        endCharOffset: 80,
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(await nextFollow, isTrue);
      expect(env.runtime.state.visibleLocation.chapterIndex, 2);

      final previousFollow = controller.ensureCharRangeVisible!(
        chapterIndex: 0,
        startCharOffset: 0,
        endCharOffset: 80,
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(await previousFollow, isTrue);
      expect(env.runtime.state.visibleLocation.chapterIndex, 0);

      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('app lifecycle pause flushes latest visible location', (
      tester,
    ) async {
      final env = _RuntimeEnv();
      await env.runtime.openBook();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: EngineReaderScreen(
              runtime: env.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(ReaderPageMode.scroll),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(EngineReaderScreen)),
      );
      await gesture.moveBy(const Offset(0, -220));
      await tester.pump();

      expect(env.bookDao.writes, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(env.bookDao.writes, 1);
      expect(env.bookDao.lastLocation, env.runtime.state.committedLocation);

      await gesture.up();
      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets(
      'scroll canvas restoreFromLocation positions without DB write',
      (tester) async {
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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        final targetPage = env.runtime.state.pageWindow!.next!;
        final restored = await tester.runAsync(
          () => env.runtime.restoreFromLocation(
            ReaderLocation(
              chapterIndex: targetPage.chapterIndex,
              charOffset: targetPage.startCharOffset,
              visualOffsetPx: 18,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));

        expect(restored, isTrue);
        expect(
          env.runtime.state.visibleLocation.chapterIndex,
          targetPage.chapterIndex,
        );
        expect(
          (env.runtime.state.visibleLocation.charOffset -
                  targetPage.startCharOffset)
              .abs(),
          lessThanOrEqualTo(80),
        );
        expect(env.bookDao.writes, 0);

        env.runtime.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 500));
      },
    );
  });
}

class _RuntimeEnv {
  _RuntimeEnv({
    ReaderMode mode = ReaderMode.scroll,
    List<BookChapter>? chapters,
    int initialChapterIndex = 0,
    int initialCharOffset = 0,
    double initialVisualOffsetPx = 0.0,
  }) : book = Book(
         bookUrl: 'book',
         origin: 'local',
         name: '測試書',
         chapterIndex: initialChapterIndex,
         charOffset: initialCharOffset,
         visualOffsetPx: initialVisualOffsetPx,
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

List<BookChapter> _shortChaptersFor(String bookUrl, int count) {
  return List<BookChapter>.generate(count, (chapterIndex) {
    return BookChapter(
      title: '短第$chapterIndex章',
      index: chapterIndex,
      bookUrl: bookUrl,
      content: '短段落，用來確認單頁章節不會卡在 scroll window 邊界。',
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

ReaderTileLayer _centerSlideTileLayer(WidgetTester tester) {
  final viewportBox = tester.renderObject<RenderBox>(
    find.byType(SlideReaderViewport),
  );
  final viewportLeft = viewportBox.localToGlobal(Offset.zero).dx;
  for (final element in find.byType(ReaderTileLayer).evaluate()) {
    final box = element.renderObject! as RenderBox;
    final left = box.localToGlobal(Offset.zero).dx;
    final size = box.size;
    if ((left - viewportLeft).abs() <= 0.5) {
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
      return element.widget as ReaderTileLayer;
    }
  }
  fail('No ReaderTileLayer is centered in the slide viewport.');
}
