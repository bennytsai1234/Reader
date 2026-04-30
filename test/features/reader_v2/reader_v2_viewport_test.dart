import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader_v2/content/reader_v2_chapter_repository.dart';
import 'package:inkpage_reader/features/reader_v2/content/reader_v2_content.dart';
import 'package:inkpage_reader/features/reader_v2/features/auto_page/reader_v2_auto_page_controller.dart';
import 'package:inkpage_reader/features/reader_v2/features/tts/reader_v2_tts_controller.dart';
import 'package:inkpage_reader/features/reader_v2/features/tts/reader_v2_tts_highlight.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_engine.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_spec.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_style.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_page_cache.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_render_page.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_tts_highlight_overlay_layer.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_location.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_progress_controller.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_runtime.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_state.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_chapter_page_cache_manager.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_viewport_controller.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/scroll_reader_v2_viewport.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/slide_reader_v2_viewport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scroll viewport syncs to runtime location changes', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.scroll,
      chapterCount: 3,
      paragraphsPerChapter: 18,
    );
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: ScrollReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: ReaderV2ViewportController(),
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    expect(runtime.captureVisibleLocation()?.chapterIndex, 0);

    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 1, charOffset: 24),
      immediateSave: false,
    );
    await _pumpViewport(tester);

    expect(runtime.captureVisibleLocation()?.chapterIndex, 1);

    runtime.dispose();
  });

  testWidgets(
    'scroll viewport ensureCharRangeVisible accepts visible TTS range',
    (tester) async {
      final runtime = _runtime(
        initialMode: ReaderV2Mode.scroll,
        chapterCount: 2,
        paragraphsPerChapter: 12,
      );
      final controller = ReaderV2ViewportController();
      await runtime.jumpToLocation(
        const ReaderV2Location(chapterIndex: 0, charOffset: 0),
        immediateSave: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 260,
            height: 360,
            child: ScrollReaderV2Viewport(
              runtime: runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(),
              controller: controller,
            ),
          ),
        ),
      );
      await _pumpViewport(tester);

      final ensureVisible = controller.ensureCharRangeVisible;
      expect(ensureVisible, isNotNull);
      final captured = runtime.captureVisibleLocation();
      expect(captured, isNotNull);
      final visible = await ensureVisible!(
        chapterIndex: captured!.chapterIndex,
        startCharOffset: captured.charOffset,
        endCharOffset: captured.charOffset + 6,
      );

      expect(visible, isTrue);

      runtime.dispose();
    },
  );

  test(
    'scroll cache window covers adjacent extent beyond center chapter',
    () async {
      final runtime = _runtime(
        initialMode: ReaderV2Mode.scroll,
        chapterCount: 8,
        paragraphsPerChapter: 2,
      );
      await runtime.jumpToLocation(
        const ReaderV2Location(chapterIndex: 2, charOffset: 0),
        immediateSave: false,
      );
      final manager = ReaderV2ChapterPageCacheManager(
        runtime: runtime,
        pageExtent: (page) => page.height,
      );
      final center = await manager.ensureChapter(2);
      expect(center, isNotNull);

      final window = await manager.ensureWindowAround(
        centerChapterIndex: 2,
        backwardExtent: center!.extent * 1.5,
        forwardExtent: center.extent * 2.5,
      );

      expect(window, isNotNull);
      expect(window!.previous.length, greaterThanOrEqualTo(2));
      expect(window.next.length, greaterThanOrEqualTo(3));

      runtime.dispose();
    },
  );

  testWidgets('scroll viewport survives a fast multi-page jump', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.scroll,
      chapterCount: 12,
      paragraphsPerChapter: 3,
    );
    final controller = ReaderV2ViewportController();
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: ScrollReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: controller,
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    final moved = await controller.scrollBy!(360 * 8);
    await _pumpViewport(tester);

    expect(moved, isTrue);
    expect(tester.takeException(), isNull);
    expect(runtime.captureVisibleLocation(), isNotNull);

    runtime.dispose();
  });

  testWidgets('slide viewport ensureCharRangeVisible jumps to TTS page', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 3,
      paragraphsPerChapter: 10,
    );
    final controller = ReaderV2ViewportController();
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: SlideReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: controller,
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    final ensureVisible = controller.ensureCharRangeVisible;
    expect(ensureVisible, isNotNull);
    final moved = await ensureVisible!(
      chapterIndex: 1,
      startCharOffset: 8,
      endCharOffset: 16,
    );
    await _pumpViewport(tester);

    expect(moved, isTrue);
    expect(runtime.state.pageWindow?.current.chapterIndex, 1);

    runtime.dispose();
  });

  testWidgets('slide viewport syncs to runtime location changes', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 3,
      paragraphsPerChapter: 10,
    );
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: SlideReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: ReaderV2ViewportController(),
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 2, charOffset: 12),
      immediateSave: false,
    );
    await _pumpViewport(tester);

    expect(runtime.captureVisibleLocation()?.chapterIndex, 2);

    runtime.dispose();
  });

  testWidgets('slide viewport shows placeholders at book edges', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 1,
      paragraphsPerChapter: 1,
    );
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: SlideReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: ReaderV2ViewportController(),
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    expect(find.text('已經是第一頁'), findsOneWidget);
    expect(find.text('已經是最後一頁'), findsOneWidget);

    runtime.dispose();
  });

  testWidgets('slide jump keeps current page when neighbor chapter fails', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 2,
      paragraphsPerChapter: 1,
      failingChapters: <int>{1},
    );

    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    expect(runtime.state.phase, ReaderV2Phase.ready);
    expect(runtime.state.pageWindow?.current.chapterIndex, 0);
    expect(runtime.state.pageWindow?.next?.chapterIndex, 1);
    expect(runtime.state.pageWindow?.next?.isPlaceholder, isTrue);

    runtime.dispose();
  });

  testWidgets('slide neighbor warmup refreshes chapter boundary placeholder', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 2,
      paragraphsPerChapter: 20,
    );
    final firstLayout = await runtime.debugResolver.ensureLayout(0);
    final lastPage = firstLayout.pages.last;

    await runtime.jumpToLocation(
      ReaderV2Location(chapterIndex: 0, charOffset: lastPage.startCharOffset),
      immediateSave: false,
    );

    expect(runtime.state.pageWindow?.current.isChapterEnd, isTrue);
    expect(runtime.state.pageWindow?.next?.isPlaceholder, isTrue);

    runtime.preloadSlideNeighbor(forward: true);
    for (var i = 0; i < 10; i++) {
      if (runtime.state.pageWindow?.next?.isPlaceholder == false) break;
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(runtime.state.pageWindow?.next?.chapterIndex, 1);
    expect(runtime.state.pageWindow?.next?.isPlaceholder, isFalse);

    runtime.dispose();
  });

  testWidgets('slide viewport serializes rapid page commands', (tester) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 1,
      paragraphsPerChapter: 80,
    );
    final layout = await runtime.debugResolver.ensureLayout(0);
    expect(layout.pages.length, greaterThan(2));
    final controller = ReaderV2ViewportController();
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: SlideReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: controller,
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    final first = controller.moveToNextPage!();
    final second = controller.moveToNextPage!();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(runtime.state.pageWindow?.current.pageIndex, 2);

    runtime.dispose();
  });

  test(
    'auto page uses scroll animateBy and ignores overlapping ticks',
    () async {
      final runtime = _runtime(
        initialMode: ReaderV2Mode.scroll,
        chapterCount: 2,
        paragraphsPerChapter: 20,
      );
      await runtime.jumpToLocation(
        const ReaderV2Location(chapterIndex: 0, charOffset: 0),
        immediateSave: false,
      );
      final gate = Completer<bool>();
      var animateCalls = 0;
      var scrollCalls = 0;
      final viewportController =
          ReaderV2ViewportController()
            ..animateBy = (delta) {
              animateCalls += 1;
              expect(delta, greaterThan(0));
              return gate.future;
            }
            ..scrollBy = (delta) async {
              scrollCalls += 1;
              return true;
            };
      final autoPage = ReaderV2AutoPageController(
        runtime: runtime,
        viewportController: viewportController,
        viewportExtent: () => 400,
      );

      final first = autoPage.stepAsync();
      final second = await autoPage.stepAsync();
      expect(second, isFalse);
      expect(animateCalls, 1);
      expect(scrollCalls, 0);

      gate.complete(true);
      expect(await first, isTrue);

      autoPage.dispose();
      runtime.dispose();
    },
  );

  test('auto page uses slide moveToNextPage command', () async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 2,
      paragraphsPerChapter: 20,
    );
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );
    var pageCommands = 0;
    final viewportController =
        ReaderV2ViewportController()
          ..moveToNextPage = () async {
            pageCommands += 1;
            return true;
          };
    final autoPage = ReaderV2AutoPageController(
      runtime: runtime,
      viewportController: viewportController,
    );

    expect(await autoPage.stepAsync(), isTrue);
    expect(pageCommands, 1);

    autoPage.dispose();
    runtime.dispose();
  });

  test(
    'tts starts from visible location and supports pause resume stop',
    () async {
      final runtime = _runtime(
        initialMode: ReaderV2Mode.scroll,
        chapterCount: 1,
        paragraphsPerChapter: 4,
      );
      await runtime.jumpToLocation(
        const ReaderV2Location(chapterIndex: 0, charOffset: 0),
        immediateSave: false,
      );
      final engine = _FakeTtsEngine();
      final tts = ReaderV2TtsController(runtime: runtime, tts: engine);

      await tts.startFromVisibleLocation();
      expect(engine.speakCount, 1);
      expect(engine.currentSpokenText, isNotEmpty);
      expect(tts.isPlaying, isTrue);
      expect(tts.speechStartLocation?.chapterIndex, 0);

      engine.emitProgress(2, 5);
      expect(tts.currentHighlight?.highlightStart, 2);
      expect(tts.currentHighlight?.highlightEnd, 5);

      await tts.toggle();
      expect(engine.pauseCount, 1);
      expect(tts.isPlaying, isFalse);

      await tts.toggle();
      expect(engine.resumeCount, 1);
      expect(tts.isPlaying, isTrue);

      await tts.stop();
      expect(tts.speechStartLocation, isNull);
      expect(tts.currentHighlight, isNull);

      tts.dispose();
      runtime.dispose();
    },
  );

  test('tts highlight overlay repaints only affected tiles', () {
    final tile = ReaderV2PageCacheFactory.fromRenderPage(
      ReaderV2RenderPage(
        pageIndex: 0,
        chapterIndex: 0,
        chapterSize: 1,
        pageSize: 1,
        contentHeight: 80,
        viewportHeight: 100,
        localStartY: 0,
        localEndY: 80,
        lines: <ReaderV2RenderLine>[
          ReaderV2RenderLine(
            text: '0123456789',
            width: 120,
            lineTop: 0,
            lineBottom: 20,
            startCharOffset: 0,
            endCharOffset: 10,
          ),
        ],
      ),
    );
    ReaderV2TtsHighlightOverlayPainter painter(ReaderV2TtsHighlight highlight) {
      return ReaderV2TtsHighlightOverlayPainter(
        tile: tile,
        style: _style(),
        textColor: Colors.black,
        highlight: highlight,
      );
    }

    final oldUnrelated = painter(
      const ReaderV2TtsHighlight(
        chapterIndex: 1,
        highlightStart: 0,
        highlightEnd: 1,
      ),
    );
    final newUnrelated = painter(
      const ReaderV2TtsHighlight(
        chapterIndex: 0,
        highlightStart: 20,
        highlightEnd: 22,
      ),
    );
    final newAffected = painter(
      const ReaderV2TtsHighlight(
        chapterIndex: 0,
        highlightStart: 2,
        highlightEnd: 5,
      ),
    );

    expect(newUnrelated.shouldRepaint(oldUnrelated), isFalse);
    expect(newAffected.shouldRepaint(oldUnrelated), isTrue);
  });
}

Future<void> _pumpViewport(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
}

ReaderV2Runtime _runtime({
  required ReaderV2Mode initialMode,
  required int chapterCount,
  required int paragraphsPerChapter,
  Set<int> failingChapters = const <int>{},
}) {
  final book = Book(
    bookUrl: 'test://viewport',
    origin: 'local',
    originName: 'fixture',
    name: '測試書',
  );
  final chapters = _chapters(
    bookUrl: book.bookUrl,
    count: chapterCount,
    paragraphsPerChapter: paragraphsPerChapter,
  );
  final bookDao = _FakeBookDao();
  final chapterDao = _FakeChapterDao(chapters);
  final sourceDao = _FakeSourceDao();
  final repository =
      failingChapters.isEmpty
          ? ReaderV2ChapterRepository(
            book: book,
            initialChapters: chapters,
            bookDao: bookDao,
            chapterDao: chapterDao,
            sourceDao: sourceDao,
            contentDao: null,
          )
          : _FailingChapterRepository(
            book: book,
            initialChapters: chapters,
            bookDao: bookDao,
            chapterDao: chapterDao,
            sourceDao: sourceDao,
            failingChapters: failingChapters,
          );
  return ReaderV2Runtime(
    book: book,
    repository: repository,
    layoutEngine: ReaderV2LayoutEngine(),
    progressController: ReaderV2ProgressController(
      book: book,
      repository: repository,
      bookDao: bookDao,
    ),
    initialLayoutSpec: _spec(),
    initialMode: initialMode,
    initialLocation: const ReaderV2Location(chapterIndex: 0, charOffset: 0),
  );
}

List<BookChapter> _chapters({
  required String bookUrl,
  required int count,
  required int paragraphsPerChapter,
}) {
  return List<BookChapter>.generate(count, (index) {
    return BookChapter(
      index: index,
      bookUrl: bookUrl,
      title: '第${index + 1}章',
      content: List<String>.filled(
        paragraphsPerChapter,
        '這是第${index + 1}章的測試內容，用於建立 viewport 測試所需的文字。',
      ).join('\n\n'),
    );
  });
}

ReaderV2LayoutSpec _spec() {
  return ReaderV2LayoutSpec.fromViewport(
    viewportSize: const Size(260, 360),
    style: ReaderV2LayoutStyle(
      fontSize: 18,
      lineHeight: 1.5,
      letterSpacing: 0,
      paragraphSpacing: 0.8,
      paddingTop: 12,
      paddingBottom: 12,
      paddingLeft: 12,
      paddingRight: 12,
      textIndent: 2,
    ),
  );
}

ReaderV2Style _style() {
  return const ReaderV2Style(
    fontSize: 18,
    lineHeight: 1.5,
    letterSpacing: 0,
    paragraphSpacing: 0.8,
    paddingTop: 12,
    paddingBottom: 12,
    paddingLeft: 12,
    paddingRight: 12,
    textIndent: 2,
    pageMode: ReaderV2PageMode.slide,
  );
}

class _FakeBookDao extends Fake implements BookDao {
  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos, {
    double visualOffsetPx = 0.0,
    String? readerAnchorJson,
  }) async {}
}

class _FakeChapterDao extends Fake implements ChapterDao {
  _FakeChapterDao(this.storedChapters);

  final List<BookChapter> storedChapters;

  @override
  Future<List<BookChapter>> getByBook(String bookUrl) async => storedChapters;
}

class _FakeSourceDao extends Fake implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async => null;
}

class _FakeTtsEngine extends ReaderV2TtsEngine {
  bool _isPlaying = false;
  double _rate = 1.0;
  double _pitch = 1.0;
  String? _language = 'zh-TW';
  String _currentSpokenText = '';
  int _currentWordStart = -1;
  int _currentWordEnd = -1;
  int speakCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;

  @override
  bool get isPlaying => _isPlaying;

  @override
  double get rate => _rate;

  @override
  double get pitch => _pitch;

  @override
  String? get language => _language;

  @override
  String get currentSpokenText => _currentSpokenText;

  @override
  int get currentWordStart => _currentWordStart;

  @override
  int get currentWordEnd => _currentWordEnd;

  @override
  Future<void> speak(String text) async {
    speakCount += 1;
    _currentSpokenText = text;
    _currentWordStart = -1;
    _currentWordEnd = -1;
    _isPlaying = true;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    pauseCount += 1;
    _isPlaying = false;
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    resumeCount += 1;
    _isPlaying = true;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    _currentSpokenText = '';
    _currentWordStart = -1;
    _currentWordEnd = -1;
    _isPlaying = false;
    notifyListeners();
  }

  @override
  Future<void> setRate(double value) async {
    _rate = value;
    notifyListeners();
  }

  @override
  Future<void> setPitch(double value) async {
    _pitch = value;
    notifyListeners();
  }

  @override
  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
  }

  void emitProgress(int start, int end) {
    _currentWordStart = start;
    _currentWordEnd = end;
    notifyListeners();
  }
}

class _FailingChapterRepository extends ReaderV2ChapterRepository {
  _FailingChapterRepository({
    required Book book,
    required List<BookChapter> initialChapters,
    required BookDao bookDao,
    required ChapterDao chapterDao,
    required BookSourceDao sourceDao,
    required this.failingChapters,
  }) : super(
         book: book,
         initialChapters: initialChapters,
         bookDao: bookDao,
         chapterDao: chapterDao,
         sourceDao: sourceDao,
         contentDao: null,
       );

  final Set<int> failingChapters;

  @override
  Future<ReaderV2Content> loadContent(int chapterIndex) {
    if (failingChapters.contains(chapterIndex)) {
      throw const ReaderV2ChapterRepositoryException('fixture load failed');
    }
    return super.loadContent(chapterIndex);
  }
}
