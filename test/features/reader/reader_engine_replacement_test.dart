import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/book_content.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_layout.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';
import 'package:inkpage_reader/features/reader/engine/layout_engine.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/page_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/page_window.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_preload_scheduler.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';

class _FakeBookDao extends Fake implements BookDao {
  int writes = 0;
  ReaderLocation? lastLocation;

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

class _ThrowingSourceDao extends Fake implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async {
    return BookSource(bookSourceUrl: url, bookSourceName: 'broken');
  }
}

class _ThrowingBookSourceService extends BookSourceService {
  @override
  Future<String> getContent(
    BookSource source,
    Book book,
    BookChapter chapter, {
    String? nextChapterUrl,
    int? pageConcurrency,
  }) async {
    throw StateError('network failed');
  }
}

class _FakeContentDao extends Fake implements ReaderChapterContentDao {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Legado-style reader engine replacement', () {
    test('ReaderLocation normalized clamps invalid values', () {
      expect(
        const ReaderLocation(chapterIndex: -2, charOffset: -9).normalized(),
        const ReaderLocation(chapterIndex: 0, charOffset: 0),
      );
      expect(
        const ReaderLocation(
          chapterIndex: 8,
          charOffset: 999,
        ).normalized(chapterCount: 3, chapterLength: 120),
        const ReaderLocation(chapterIndex: 2, charOffset: 120),
      );
    });

    test('LayoutEngine is deterministic and resolves location to TextPage', () {
      final engine = LayoutEngine();
      final content = BookContent.fromRaw(
        chapterIndex: 0,
        title: '第一章',
        rawText: List<String>.generate(
          24,
          (i) => '這是第$i段文字，用來測試穩定分頁與字元位置。',
        ).join('\n\n'),
      );
      final spec = _spec(fontSize: 18);

      final first = engine.layout(content, spec);
      final second = engine.layout(content, spec);

      expect(identical(first, second), isTrue);
      expect(first.pages, isNotEmpty);
      expect(first.lines, isNotEmpty);
      final page = first.pageForCharOffset(12);
      expect(page.containsCharOffset(12), isTrue);
      expect(
        page.lines.every((line) => line.startCharOffset <= line.endCharOffset),
        isTrue,
      );
    });

    test(
      'LayoutEngine applies body indent and disables justification flags',
      () {
        final engine = LayoutEngine();
        final content = BookContent.fromRaw(
          chapterIndex: 0,
          title: 'Title',
          rawText: '這是一段足夠長的正文，用來測試首行縮排、非末行兩端對齊，以及標題不應套用正文縮排。',
        );
        final justified = engine.layout(
          content,
          LayoutSpec.fromViewport(
            viewportSize: const Size(180, 360),
            style: const ReadStyle(
              fontSize: 18,
              lineHeight: 1.5,
              letterSpacing: 0,
              paragraphSpacing: 0.6,
              paddingTop: 12,
              paddingBottom: 12,
              paddingLeft: 16,
              paddingRight: 16,
              textIndent: 2,
              textFullJustify: true,
              pageMode: ReaderPageMode.scroll,
            ),
          ),
        );

        expect(justified.lines.first.isTitle, isTrue);
        expect(justified.lines.first.text.startsWith('　'), isFalse);
        final firstBodyLine = justified.lines.firstWhere(
          (line) => !line.isTitle,
        );
        expect(firstBodyLine.text.startsWith('　　'), isTrue);
        expect(firstBodyLine.startCharOffset, 0);
        expect(
          justified.lines
              .where((line) => !line.isTitle && !line.isParagraphEnd)
              .any((line) => line.shouldJustify),
          isFalse,
        );

        final ragged = engine.layout(
          content,
          LayoutSpec.fromViewport(
            viewportSize: const Size(180, 360),
            style: const ReadStyle(
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
              pageMode: ReaderPageMode.scroll,
            ),
          ),
        );
        expect(ragged.lines.any((line) => line.shouldJustify), isFalse);
      },
    );

    test(
      'ChapterLayout.pageForCharOffset skips title-only pages for durable offset restore',
      () {
        final layout = ChapterLayout(
          chapterIndex: 0,
          contentHash: 'hash',
          layoutSignature: 'sig',
          lines: const <TextLine>[],
          pages: <TextPage>[
            TextPage(
              index: 0,
              title: 'long title',
              chapterIndex: 0,
              startCharOffset: 0,
              endCharOffset: 8,
              lines: <TextLine>[
                TextLine(
                  text: '很長很長的章節標題',
                  width: 100,
                  height: 40,
                  isTitle: true,
                  chapterPosition: 0,
                  lineTop: 0,
                  lineBottom: 40,
                  startCharOffset: 0,
                  endCharOffset: 8,
                ),
              ],
            ),
            TextPage(
              index: 1,
              title: 'long title',
              chapterIndex: 0,
              startCharOffset: 0,
              endCharOffset: 12,
              lines: <TextLine>[
                TextLine(
                  text: '正文第一行',
                  width: 100,
                  height: 40,
                  chapterPosition: 0,
                  lineTop: 0,
                  lineBottom: 40,
                  startCharOffset: 0,
                  endCharOffset: 4,
                ),
              ],
            ),
          ],
        );

        expect(layout.pageForCharOffset(0).pageIndex, 1);
      },
    );

    test(
      'ChapterLayout.pageForCharOffset respects page end boundaries before falling back to start offsets',
      () {
        final layout = ChapterLayout(
          chapterIndex: 0,
          contentHash: 'hash',
          layoutSignature: 'sig',
          lines: const <TextLine>[],
          pages: <TextPage>[
            TextPage(
              index: 0,
              title: 'chapter',
              chapterIndex: 0,
              startCharOffset: 0,
              endCharOffset: 20,
              isChapterEnd: false,
              lines: <TextLine>[
                TextLine(
                  text: '第一頁內容',
                  width: 100,
                  height: 20,
                  chapterPosition: 0,
                  lineTop: 0,
                  lineBottom: 20,
                  startCharOffset: 0,
                  endCharOffset: 20,
                ),
              ],
            ),
            TextPage(
              index: 1,
              title: 'chapter',
              chapterIndex: 0,
              startCharOffset: 20,
              endCharOffset: 40,
              isChapterEnd: true,
              lines: <TextLine>[
                TextLine(
                  text: '第二頁內容',
                  width: 100,
                  height: 20,
                  chapterPosition: 20,
                  lineTop: 0,
                  lineBottom: 20,
                  startCharOffset: 20,
                  endCharOffset: 40,
                ),
              ],
            ),
          ],
        );

        expect(layout.pageForCharOffset(19).pageIndex, 0);
        expect(layout.pageForCharOffset(20).pageIndex, 1);
        expect(layout.pageForCharOffset(39).pageIndex, 1);
      },
    );

    test(
      'runtime opens only current window and keeps lookAhead optional',
      () async {
        final env = _RuntimeEnv();
        final runtime = env.runtime;

        await runtime.openBook();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(runtime.state.phase, ReaderPhase.ready);
        expect(runtime.state.pageWindow, isNotNull);
        expect(runtime.state.pageWindow!.current.chapterIndex, 0);
        expect(
          runtime.state.pageWindow!.current.chapterSize,
          runtime.chapterCount,
        );
        expect(runtime.state.pageWindow!.lookAhead, isEmpty);
        expect(runtime.debugResolver.cachedLayout(0), isNotNull);
        expect(runtime.debugResolver.cachedLayout(1), isNotNull);
        expect(runtime.debugResolver.cachedLayout(2), isNull);
      },
    );

    test('ReaderPreloadScheduler builds centered preload order', () {
      expect(
        ReaderPreloadScheduler.buildCenteredOrder(
          chapterCount: 5,
          centerChapterIndex: 2,
          radius: 2,
        ),
        <int>[2, 3, 1, 4, 0],
      );
    });

    test(
      'ReaderPreloadScheduler content queue preloads BookContent without layout',
      () async {
        final env = _RuntimeEnv();
        final scheduler = ReaderPreloadScheduler(
          resolver: env.runtime.debugResolver,
        );

        await scheduler.scheduleAround(1, contentRadius: 1, layoutRadius: -1);

        expect(env.repository.cachedContent(0), isNotNull);
        expect(env.repository.cachedContent(1), isNotNull);
        expect(env.repository.cachedContent(2), isNotNull);
        expect(env.runtime.debugResolver.cachedLayout(0), isNull);
        expect(env.runtime.debugResolver.cachedLayout(1), isNull);
        expect(env.runtime.debugResolver.cachedLayout(2), isNull);

        scheduler.dispose();
      },
    );

    test(
      'ReaderPreloadScheduler layout queue only lays out the requested window',
      () async {
        final env = _RuntimeEnv();
        final scheduler = ReaderPreloadScheduler(
          resolver: env.runtime.debugResolver,
        );

        await scheduler.scheduleAround(1, contentRadius: -1, layoutRadius: 1);

        expect(env.runtime.debugResolver.cachedLayout(0), isNotNull);
        expect(env.runtime.debugResolver.cachedLayout(1), isNotNull);
        expect(env.runtime.debugResolver.cachedLayout(2), isNotNull);
        expect(env.runtime.debugResolver.cachedLayout(3), isNull);

        scheduler.dispose();
      },
    );

    test(
      'ReaderPreloadScheduler content queue uses centered order and serializes work',
      () async {
        final book = Book(bookUrl: 'queued-book', origin: 'local', name: 'q');
        final chapters = _chaptersFor(book.bookUrl, 5);
        final repository = _QueuedChapterRepository(
          book: book,
          chapters: chapters,
        );
        final resolver = PageResolver(
          repository: repository,
          layoutEngine: LayoutEngine(),
          layoutSpec: _spec(fontSize: 18),
        );
        final scheduler = ReaderPreloadScheduler(
          resolver: resolver,
          maxConcurrentContentTasks: 1,
        );

        final done = scheduler.scheduleAround(
          2,
          contentRadius: 2,
          layoutRadius: -1,
        );

        await Future<void>.delayed(Duration.zero);
        expect(repository.loadOrder, <int>[2]);

        repository.complete(2);
        await Future<void>.delayed(Duration.zero);
        expect(repository.loadOrder, <int>[2, 3]);

        repository.complete(3);
        await Future<void>.delayed(Duration.zero);
        expect(repository.loadOrder, <int>[2, 3, 1]);

        repository.complete(1);
        await Future<void>.delayed(Duration.zero);
        expect(repository.loadOrder, <int>[2, 3, 1, 4]);

        repository.complete(4);
        await Future<void>.delayed(Duration.zero);
        expect(repository.loadOrder, <int>[2, 3, 1, 4, 0]);

        repository.complete(0);
        await done;
        scheduler.dispose();
      },
    );

    test(
      'ReaderPreloadScheduler generation prevents stale layout from caching',
      () async {
        final book = Book(bookUrl: 'stale-layout-book', origin: 'local');
        final bookDao = _FakeBookDao();
        final gate = Completer<void>();
        final chapters = _chaptersFor(book.bookUrl, 3);
        final repository = _DelayedChapterRepository(
          book: book,
          chapters: chapters,
          delayedChapterIndex: 1,
          gate: gate,
          bookDao: bookDao,
        );
        final resolver = PageResolver(
          repository: repository,
          layoutEngine: LayoutEngine(),
          layoutSpec: _spec(fontSize: 18),
        );
        final scheduler = ReaderPreloadScheduler(resolver: resolver);

        final stale = scheduler.scheduleLayout(1);
        await Future<void>.delayed(Duration.zero);
        expect(repository.loadAttempts[1], 1);

        scheduler.bumpGeneration();
        resolver.updateLayoutSpec(_spec(fontSize: 22));

        await scheduler.scheduleLayout(2);
        expect(resolver.cachedLayout(2), isNotNull);

        gate.complete();
        await stale;
        expect(resolver.cachedLayout(1), isNull);

        scheduler.dispose();
      },
    );

    test(
      'rolling scroll next page swaps prev/current/next without global offset',
      () async {
        final env = _RuntimeEnv();
        final runtime = env.runtime;
        await runtime.openBook();
        final before = runtime.state.pageWindow!;
        final oldCurrent = before.current;
        final oldNext = before.next!;

        final moved = runtime.moveToNextPage();

        expect(moved, isTrue);
        final after = runtime.state.pageWindow!;
        expect(after.prev, oldCurrent);
        expect(after.current, oldNext);
        expect(
          runtime.state.visibleLocation.chapterIndex,
          oldNext.chapterIndex,
        );
        expect(
          runtime.state.visibleLocation.charOffset,
          oldNext.startCharOffset,
        );
      },
    );

    test('rolling scroll prev page swaps next/current/prev', () async {
      final env = _RuntimeEnv();
      final runtime = env.runtime;
      await runtime.openBook();
      runtime.moveToNextPage();
      final before = runtime.state.pageWindow!;
      final oldCurrent = before.current;
      final oldPrev = before.prev!;

      final moved = runtime.moveToPrevPage();

      expect(moved, isTrue);
      final after = runtime.state.pageWindow!;
      expect(after.next, oldCurrent);
      expect(after.current, oldPrev);
    });

    test('scroll visible location can resolve into previous page', () async {
      final env = _RuntimeEnv();
      final runtime = env.runtime;
      await runtime.openBook();
      final firstPage = runtime.state.pageWindow!.current;
      expect(runtime.moveToNextPage(), isTrue);

      final location = runtime.resolveVisibleLocation(
        pageOffset: 50,
        viewportHeight: 360,
        anchorFraction: 0.05,
      );

      expect(location.chapterIndex, firstPage.chapterIndex);
      expect(firstPage.containsCharOffset(location.charOffset), isTrue);
    });

    test(
      'scroll visible location uses viewport height instead of content height',
      () async {
        final env = _RuntimeEnv();
        final runtime = env.runtime;
        await runtime.openBook();

        final current = TextPage(
          pageIndex: 0,
          chapterIndex: 0,
          startCharOffset: 10,
          endCharOffset: 20,
          contentHeight: 100,
          viewportHeight: 360,
          lines: <TextLine>[
            TextLine(
              text: 'current',
              width: 80,
              height: 20,
              chapterPosition: 10,
              startCharOffset: 10,
              endCharOffset: 20,
              lineTop: 48,
              lineBottom: 68,
            ),
          ],
        );
        final next = TextPage(
          pageIndex: 1,
          chapterIndex: 0,
          startCharOffset: 30,
          endCharOffset: 40,
          contentHeight: 100,
          viewportHeight: 360,
          lines: <TextLine>[
            TextLine(
              text: 'next',
              width: 80,
              height: 20,
              chapterPosition: 30,
              startCharOffset: 30,
              endCharOffset: 40,
              lineTop: 10,
              lineBottom: 30,
            ),
          ],
        );
        runtime.state = runtime.state.copyWith(
          pageWindow: PageWindow(prev: null, current: current, next: next),
        );

        final location = runtime.resolveVisibleLocation(
          pageOffset: -200,
          viewportHeight: 360,
        );

        expect(location.chapterIndex, current.chapterIndex);
        expect(location.charOffset, current.startCharOffset);
      },
    );

    test('rolling window crosses chapter tail into next chapter', () async {
      final env = _RuntimeEnv();
      final runtime = env.runtime;
      await runtime.openBook();
      await runtime.debugResolver.ensureLayout(1);
      await runtime.refreshNeighbors();

      var guard = 0;
      while (runtime.state.pageWindow!.current.chapterIndex == 0 &&
          guard < 40) {
        expect(runtime.moveToNextPage(), isTrue);
        guard += 1;
      }

      expect(runtime.state.pageWindow!.current.chapterIndex, 1);
      expect(runtime.state.visibleLocation.chapterIndex, 1);
    });

    test(
      'loading placeholder is drawable but never durable progress',
      () async {
        final env = _RuntimeEnv();
        final runtime = env.runtime;
        await runtime.openBook();
        final current = runtime.state.pageWindow!.current;
        final before = runtime.state.visibleLocation;
        runtime.state = runtime.state.copyWith(
          pageWindow: PageWindow(
            prev: null,
            current: current,
            next: runtime.debugResolver.placeholderPageFor(1),
          ),
        );

        expect(runtime.state.pageWindow!.next!.isLoading, isTrue);
        expect(runtime.moveToNextPage(), isFalse);
        expect(runtime.state.visibleLocation, before);
        await runtime.flushProgress();
        expect(env.bookDao.writes, 0);
      },
    );

    test(
      'missing cross-chapter neighbor auto-advances after loading completes',
      () async {
        final book = Book(bookUrl: 'delayed-book', origin: 'local', name: 'd');
        final bookDao = _FakeBookDao();
        final gate = Completer<void>();
        final chapters = <BookChapter>[
          BookChapter(
            title: 'c0',
            index: 0,
            bookUrl: book.bookUrl,
            content: List<String>.generate(
              36,
              (i) => '第一章第$i段，這段文字用來讓第一章產生多頁。',
            ).join('\n\n'),
          ),
          BookChapter(
            title: 'c1',
            index: 1,
            bookUrl: book.bookUrl,
            content: List<String>.generate(
              12,
              (i) => '第二章第$i段，這段文字在延遲載入完成後接上。',
            ).join('\n\n'),
          ),
        ];
        final repository = _DelayedChapterRepository(
          book: book,
          chapters: chapters,
          delayedChapterIndex: 1,
          gate: gate,
          bookDao: bookDao,
        );
        final runtime = ReaderRuntime(
          book: book,
          repository: repository,
          layoutEngine: LayoutEngine(),
          progressController: ReaderProgressController(
            book: book,
            repository: repository,
            bookDao: bookDao,
          ),
          initialLayoutSpec: _spec(fontSize: 18),
          initialMode: ReaderMode.scroll,
        );

        await runtime.openBook();
        await Future<void>.delayed(Duration.zero);

        final chapterZero = await runtime.debugResolver.ensureLayout(0);
        final tail = chapterZero.pages.last;
        final location = ReaderLocation(
          chapterIndex: tail.chapterIndex,
          charOffset: tail.startCharOffset,
        );
        runtime.state = runtime.state.copyWith(
          pageWindow: PageWindow(
            prev: runtime.debugResolver.prevPageSync(tail),
            current: tail,
            next: runtime.debugResolver.placeholderPageFor(1),
          ),
          visibleLocation: location,
          committedLocation: location,
        );

        expect(runtime.moveToNextPage(), isFalse);
        expect(runtime.state.pageWindow!.next!.isLoading, isTrue);
        expect(repository.loadAttempts[1], 1);

        gate.complete();
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (runtime.state.pageWindow!.current.chapterIndex == 1) break;
        }

        expect(runtime.state.pageWindow!.current.chapterIndex, 1);
        expect(runtime.state.visibleLocation.chapterIndex, 1);

        runtime.dispose();
      },
    );

    test(
      'error placeholder emits actionable notice instead of moving',
      () async {
        final env = _RuntimeEnv();
        final runtime = env.runtime;
        await runtime.openBook();
        final current = runtime.state.pageWindow!.current;
        final before = runtime.state.visibleLocation;
        runtime.state = runtime.state.copyWith(
          pageWindow: PageWindow(
            prev: null,
            current: current,
            next: TextPage(
              index: 0,
              chapterIndex: 1,
              title: 'c1',
              isLoading: false,
              errorMessage: 'boom',
              height: current.height,
              startCharOffset: 0,
              endCharOffset: 0,
              lines: <TextLine>[
                TextLine(
                  text: '章節載入失敗，翻頁重試',
                  width: 120,
                  height: 20,
                  isTitle: true,
                  chapterPosition: 0,
                  startCharOffset: 0,
                  endCharOffset: 0,
                  lineTop: current.height / 2,
                  lineBottom: current.height / 2 + 20,
                ),
              ],
            ),
          ),
        );

        expect(runtime.moveToNextPage(), isFalse);
        expect(runtime.state.visibleLocation, before);
        expect(runtime.takeUserNotice(), '下一章載入失敗，請再試一次或返回目錄');
      },
    );

    test(
      'remote content loader unavailable falls back without network fetch',
      () async {
        final book = Book(
          bookUrl: 'remote-book',
          origin: 'source://broken',
          name: 'broken',
        );
        final chapters = <BookChapter>[
          BookChapter(
            title: 'broken chapter',
            index: 0,
            bookUrl: book.bookUrl,
            url: 'https://example.com/chapter',
          ),
        ];
        final repository = ChapterRepository(
          book: book,
          initialChapters: chapters,
          bookDao: _FakeBookDao(),
          chapterDao: _FakeChapterDao(chapters),
          sourceDao: _ThrowingSourceDao(),
          contentDao: null,
          service: _ThrowingBookSourceService(),
        );
        final resolver = PageResolver(
          repository: repository,
          layoutEngine: LayoutEngine(),
          layoutSpec: _spec(fontSize: 18),
        );

        final layout = await resolver.ensureLayout(0);

        expect(layout.pages, isNotEmpty);
        expect(
          layout.pages.first.lines.map((line) => line.text).join('\n'),
          allOf(contains('broken'), contains('chapter')),
        );
      },
    );

    test(
      'slide mode settles by writing ReaderLocation, not PageView index',
      () async {
        final env = _RuntimeEnv(mode: ReaderMode.slide);
        final runtime = env.runtime;
        await runtime.openBook();
        final next = runtime.state.pageWindow!.next!;
        runtime.moveToNextPage();
        runtime.handleSlidePageSettled(next);

        expect(
          runtime.state.visibleLocation,
          ReaderLocation(
            chapterIndex: next.chapterIndex,
            charOffset: next.startCharOffset,
          ),
        );
        await runtime.flushProgress();
        expect(env.bookDao.lastLocation, runtime.state.visibleLocation);
      },
    );

    test('mode switch round trips through ReaderLocation', () async {
      final env = _RuntimeEnv();
      final runtime = env.runtime;
      await runtime.openBook();
      runtime.moveToNextPage();
      final location = runtime.state.visibleLocation;

      await runtime.switchMode(ReaderMode.slide);
      expect(runtime.state.mode, ReaderMode.slide);
      expect(runtime.state.visibleLocation.chapterIndex, location.chapterIndex);
      expect(runtime.state.visibleLocation.charOffset, location.charOffset);
      expect(runtime.state.currentSlidePage, isNotNull);
      expect(
        runtime.state.currentSlidePage!.containsCharOffset(location.charOffset),
        isTrue,
      );

      await runtime.switchMode(ReaderMode.scroll);
      expect(runtime.state.mode, ReaderMode.scroll);
      expect(runtime.state.visibleLocation.chapterIndex, location.chapterIndex);
      expect(runtime.state.visibleLocation.charOffset, location.charOffset);
    });

    test(
      'layoutSignature change relayouts while preserving ReaderLocation',
      () async {
        final env = _RuntimeEnv();
        final runtime = env.runtime;
        await runtime.openBook();
        runtime.moveToNextPage();
        final location = runtime.state.visibleLocation;
        final oldSignature = runtime.state.layoutSpec.layoutSignature;

        await runtime.updateLayoutSpec(_spec(fontSize: 22));

        expect(runtime.state.layoutSpec.layoutSignature, isNot(oldSignature));
        expect(
          runtime.state.visibleLocation.chapterIndex,
          location.chapterIndex,
        );
        expect(runtime.state.visibleLocation.charOffset, location.charOffset);
      },
    );

    test(
      'runtime exposes chapter metadata and visible-location text',
      () async {
        final env = _RuntimeEnv();
        final runtime = env.runtime;

        await runtime.openBook();
        final text = await runtime.textFromVisibleLocation();

        expect(runtime.chapterCount, 4);
        expect(runtime.chapters, hasLength(4));
        expect(runtime.chapterAt(0)?.title, '第0章');
        expect(runtime.titleFor(1), '第1章');
        expect(runtime.chapterUrlAt(99), '');
        expect(text, contains('第0章第0段'));
      },
    );

    test(
      'reloadContentPreservingLocation clears content and layout then restores visible location',
      () async {
        final env = _RuntimeEnv();
        final runtime = env.runtime;
        await runtime.openBook();
        runtime.moveToNextPage();
        final location = runtime.state.visibleLocation;

        await runtime.reloadContentPreservingLocation();

        expect(runtime.state.phase, ReaderPhase.ready);
        expect(
          runtime.state.visibleLocation.chapterIndex,
          location.chapterIndex,
        );
        expect(runtime.state.visibleLocation.charOffset, location.charOffset);
      },
    );

    test('scroll movement debounces DB writes until flushed', () async {
      final env = _RuntimeEnv();
      final runtime = env.runtime;
      await runtime.openBook();

      runtime.moveToNextPage();
      runtime.moveToNextPage();

      expect(env.bookDao.writes, 0);
      await runtime.flushProgress();
      expect(env.bookDao.writes, 1);
      expect(env.bookDao.lastLocation, runtime.state.visibleLocation);
    });
  });
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

class _RuntimeEnv {
  _RuntimeEnv({ReaderMode mode = ReaderMode.scroll})
    : book = Book(
        bookUrl: 'book',
        origin: 'local',
        name: '測試書',
        chapterIndex: 0,
        charOffset: 0,
      ),
      bookDao = _FakeBookDao() {
    final chapters = _chaptersFor(book.bookUrl, 4);
    repository = ChapterRepository(
      book: book,
      initialChapters: chapters,
      bookDao: bookDao,
      chapterDao: _FakeChapterDao(chapters),
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
      initialLayoutSpec: _spec(fontSize: 18),
      initialMode: mode,
    );
  }

  final Book book;
  final _FakeBookDao bookDao;
  late final ChapterRepository repository;
  late final ReaderRuntime runtime;
}

class _QueuedChapterRepository extends ChapterRepository {
  _QueuedChapterRepository({
    required super.book,
    required List<BookChapter> chapters,
  }) : super(
         initialChapters: chapters,
         bookDao: _FakeBookDao(),
         chapterDao: _FakeChapterDao(chapters),
         sourceDao: _FakeSourceDao(),
       );

  final List<int> loadOrder = <int>[];
  final Map<int, Completer<BookContent>> _completers =
      <int, Completer<BookContent>>{};

  @override
  Future<BookContent> loadContent(int chapterIndex) {
    loadOrder.add(chapterIndex);
    final completer = _completers[chapterIndex] ??= Completer<BookContent>();
    return completer.future;
  }

  void complete(int chapterIndex) {
    final completer = _completers[chapterIndex];
    if (completer == null || completer.isCompleted) return;
    completer.complete(
      BookContent.fromRaw(
        chapterIndex: chapterIndex,
        title: 'c$chapterIndex',
        rawText: 'chapter $chapterIndex',
      ),
    );
  }
}

class _DelayedChapterRepository extends ChapterRepository {
  _DelayedChapterRepository({
    required super.book,
    required List<BookChapter> chapters,
    required this.delayedChapterIndex,
    required this.gate,
    required _FakeBookDao bookDao,
  }) : super(
         initialChapters: chapters,
         bookDao: bookDao,
         chapterDao: _FakeChapterDao(chapters),
         sourceDao: _FakeSourceDao(),
         contentDao: _FakeContentDao(),
       );

  final int delayedChapterIndex;
  final Completer<void> gate;
  final Map<int, int> loadAttempts = <int, int>{};

  @override
  Future<BookContent> loadContent(int chapterIndex) async {
    loadAttempts.update(chapterIndex, (value) => value + 1, ifAbsent: () => 1);
    if (chapterIndex == delayedChapterIndex) {
      await gate.future;
    }
    return super.loadContent(chapterIndex);
  }
}

LayoutSpec _spec({required double fontSize}) {
  return LayoutSpec.fromViewport(
    viewportSize: const Size(320, 360),
    style: ReadStyle(
      fontSize: fontSize,
      lineHeight: 1.5,
      letterSpacing: 0,
      paragraphSpacing: 0.6,
      paddingTop: 12,
      paddingBottom: 12,
      paddingLeft: 16,
      paddingRight: 16,
      pageMode: ReaderPageMode.scroll,
    ),
  );
}
