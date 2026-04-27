import 'dart:async';
import 'dart:io';

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
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';
import 'package:inkpage_reader/features/reader/engine/layout_engine.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/page_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/page_window.dart';
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
    String? readerAnchorJson,
  }) async {
    writes += 1;
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
      'runtime opens only current window and keeps lookAhead optional',
      () async {
        final env = _RuntimeEnv();
        final runtime = env.runtime;

        await runtime.openBook();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(runtime.state.phase, ReaderPhase.ready);
        expect(runtime.state.pageWindow, isNotNull);
        expect(runtime.state.pageWindow!.current.chapterIndex, 0);
        expect(runtime.state.pageWindow!.lookAhead, isEmpty);
        expect(runtime.resolver.cachedLayout(0), isNotNull);
        expect(runtime.resolver.cachedLayout(1), isNotNull);
        expect(runtime.resolver.cachedLayout(2), isNull);
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

    test('rolling window crosses chapter tail into next chapter', () async {
      final env = _RuntimeEnv();
      final runtime = env.runtime;
      await runtime.openBook();
      await runtime.resolver.ensureLayout(1);
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
            next: runtime.resolver.placeholderPageFor(1),
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
      'missing cross-chapter neighbor refreshes after loading completes',
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

        final chapterZero = await runtime.resolver.ensureLayout(0);
        final tail = chapterZero.pages.last;
        final location = ReaderLocation(
          chapterIndex: tail.chapterIndex,
          charOffset: tail.startCharOffset,
        );
        runtime.state = runtime.state.copyWith(
          pageWindow: PageWindow(
            prev: runtime.resolver.prevPageSync(tail),
            current: tail,
            next: runtime.resolver.placeholderPageFor(1),
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
          if (runtime.state.pageWindow!.next?.isPlaceholder == false) break;
        }

        final next = runtime.state.pageWindow!.next!;
        expect(next.isPlaceholder, isFalse);
        expect(next.chapterIndex, 1);
        expect(runtime.moveToNextPage(), isTrue);
        expect(runtime.state.visibleLocation.chapterIndex, 1);

        runtime.dispose();
      },
    );

    test(
      'layout failure is represented as an error placeholder page',
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

        await expectLater(resolver.ensureLayout(0), throwsStateError);
        final placeholder = resolver.placeholderPageFor(0);

        expect(placeholder.isPlaceholder, isTrue);
        expect(placeholder.isLoading, isFalse);
        expect(placeholder.errorMessage, contains('network failed'));
        expect(placeholder.lines.single.text, '章節載入失敗');
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

      await runtime.switchMode(ReaderMode.scroll);
      expect(runtime.state.mode, ReaderMode.scroll);
      expect(runtime.state.visibleLocation.chapterIndex, location.chapterIndex);
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

    test('new ReadViewRuntime does not use old scroll restore primitives', () {
      final source =
          File(
            'lib/features/reader/view/read_view_runtime.dart',
          ).readAsStringSync();

      expect(source, isNot(contains('ScrollablePositionedList')));
      expect(source, isNot(contains('ensureVisible')));
      expect(source, isNot(contains('GlobalKey')));
      expect(source, isNot(contains('ScrollRestoreRunner')));
    });
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
    final chapters = List<BookChapter>.generate(4, (chapterIndex) {
      return BookChapter(
        title: '第$chapterIndex章',
        index: chapterIndex,
        bookUrl: 'book',
        content: List<String>.generate(
          40,
          (i) => '第$chapterIndex章第$i段，這是一段足夠長的文字，用於產生多個 TextPage。',
        ).join('\n\n'),
      );
    });
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
