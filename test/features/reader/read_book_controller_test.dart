import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/engine/page_view_widget.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_layout.dart';
import 'package:inkpage_reader/features/reader/widgets/reader/reader_bottom_menu.dart';
import 'package:inkpage_reader/features/reader/widgets/reader/reader_top_menu.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake DAOs ────────────────────────────────────────────────────────────────

class _FakeBookDao implements BookDao {
  static final List<({int chapterIndex, String chapterTitle, int pos})>
  updates = [];
  static final List<Book> upserts = [];

  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos,
  ) async {
    updates.add((
      chapterIndex: chapterIndex,
      chapterTitle: chapterTitle,
      pos: pos,
    ));
  }

  @override
  Future<void> upsert(Book book) async {
    upserts.add(book.copyWith());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChapterDao implements ChapterDao {
  static final List<List<BookChapter>> insertedBatches = [];

  @override
  Future<List<BookChapter>> getChapters(String bookUrl) async =>
      _fakeChaptersFromDao;

  @override
  Future<void> insertChapters(List<BookChapter> chapterList) async {
    insertedBatches.add(List<BookChapter>.from(chapterList));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeReplaceRuleDao implements ReplaceRuleDao {
  @override
  Future<List<ReplaceRule>> getEnabled() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookSourceDao implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookmarkDao implements BookmarkDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PendingNavigationReaderProvider extends ReaderProvider {
  _PendingNavigationReaderProvider({
    required super.book,
    required super.initialChapters,
  });

  final List<({int chapterIndex, bool fromEnd, ReaderCommandReason reason})>
  loadRequests = [];
  final List<Set<int>> retainedSnapshots = [];
  final List<Set<int>> focusedRetainedSnapshots = [];
  Completer<void>? loadCompleter;

  @override
  Future<void> loadChapter(
    int index, {
    bool fromEnd = false,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
    int? navigationToken,
  }) async {
    loadRequests.add((chapterIndex: index, fromEnd: fromEnd, reason: reason));
    retainedSnapshots.add(retainedChapterIndexes());
    focusedRetainedSnapshots.add(
      retainedChapterIndexes(focusChapterIndex: index),
    );
    final completer = loadCompleter ??= Completer<void>();
    await completer.future;
    currentChapterIndex = index;
    visibleChapterIndex = index;
  }
}

void _setupDi() {
  for (final unregister in [
    () {
      if (getIt.isRegistered<BookDao>()) getIt.unregister<BookDao>();
    },
    () {
      if (getIt.isRegistered<ChapterDao>()) getIt.unregister<ChapterDao>();
    },
    () {
      if (getIt.isRegistered<ReplaceRuleDao>()) {
        getIt.unregister<ReplaceRuleDao>();
      }
    },
    () {
      if (getIt.isRegistered<BookSourceDao>()) {
        getIt.unregister<BookSourceDao>();
      }
    },
    () {
      if (getIt.isRegistered<BookmarkDao>()) getIt.unregister<BookmarkDao>();
    },
  ]) {
    unregister();
  }
  getIt.registerLazySingleton<BookDao>(() => _FakeBookDao());
  getIt.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
  getIt.registerLazySingleton<ReplaceRuleDao>(() => _FakeReplaceRuleDao());
  getIt.registerLazySingleton<BookSourceDao>(() => _FakeBookSourceDao());
  getIt.registerLazySingleton<BookmarkDao>(() => _FakeBookmarkDao());
}

Book _makeBook() => Book(
  bookUrl: 'http://test.com/book',
  name: 'Test Book',
  author: 'Author',
  origin: 'local',
  durChapterIndex: 0,
  durChapterPos: 0,
);

List<BookChapter> _fakeChaptersFromDao = [];

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

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _setupDi();
  });

  setUp(() {
    _fakeChaptersFromDao = [];
    _FakeBookDao.updates.clear();
    _FakeBookDao.upserts.clear();
    _FakeChapterDao.insertedBatches.clear();
    // Mock flutter_tts / audio_service platform channels
    // so TTS calls don't crash in tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_service.methods'),
          (call) async => null,
        );
  });

  group('ReadBookController lifecycle', () {
    test('可以建立並立即 dispose，不會拋例外', () {
      final controller = ReadBookController(book: _makeBook());
      expect(() => controller.dispose(), returnsNormally);
    });

    test('dispose 後 isDisposed 為 true', () {
      final controller = ReadBookController(book: _makeBook());
      controller.dispose();
      expect(controller.isDisposed, isTrue);
    });

    test('dispose 後 lifecycle 為 disposed', () {
      final controller = ReadBookController(book: _makeBook());
      controller.dispose();
      expect(controller.lifecycle, equals(ReaderLifecycle.disposed));
    });

    test('dispose 後呼叫 notifyListeners 不會拋例外', () {
      final controller = ReadBookController(book: _makeBook());
      controller.dispose();
      // ReaderProviderBase.notifyListeners() 有 isDisposed 保護
      expect(() => controller.notifyListeners(), returnsNormally);
    });

    test('初始狀態：lifecycle 為 loading', () {
      final controller = ReadBookController(book: _makeBook());
      expect(controller.lifecycle, equals(ReaderLifecycle.loading));
      controller.dispose();
    });

    test('初始狀態：isReady 為 false', () {
      final controller = ReadBookController(book: _makeBook());
      expect(controller.isReady, isFalse);
      controller.dispose();
    });

    test('未設定打點區時預設為九宮格全部喚起選單', () async {
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.clickActions, List<int>.filled(9, 0));
      controller.dispose();
    });

    test('帶入 initialChapters 時不會被空 DAO 覆蓋成暫無章節', () async {
      _fakeChaptersFromDao = [];
      final initialChapters = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
        BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: initialChapters,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.chapters, hasLength(2));
      expect(controller.chapters.first.title, 'c0');
      controller.dispose();
    });

    test('ReaderProvider 預設會從書籍 durable location resume', () async {
      final book =
          _makeBook()
            ..durChapterIndex = 2
            ..durChapterPos = 144;
      final controller = ReaderProvider(book: book);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.currentChapterIndex, 2);
      expect(
        controller.committedLocation,
        const ReaderLocation(chapterIndex: 2, charOffset: 144),
      );
      controller.dispose();
    });

    test('章節高度 cache 會在 runtime evict 後保留最後真實高度', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);
      expect(controller.cachedChapterContentHeight(0), closeTo(420.0, 0.1));

      controller.chapterPagesCache.remove(0);
      controller.refreshChapterRuntime(0);

      expect(controller.chapterAt(0), isNull);
      expect(controller.estimatedChapterContentHeight(0), closeTo(420.0, 0.1));
      controller.dispose();
    });

    test('clearChapterRuntimeCacheEntry 會同步清掉章節高度 cache', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);
      expect(controller.cachedChapterContentHeight(0), isNotNull);

      controller.clearChapterRuntimeCacheEntry(0);

      expect(controller.chapterAt(0), isNull);
      expect(controller.cachedChapterContentHeight(0), isNull);
      controller.dispose();
    });

    test('dispose 後 isLoading 中的章節集合仍可安全讀取', () {
      final controller = ReadBookController(book: _makeBook());
      controller.dispose();
      expect(() => controller.loadingChapters.isEmpty, returnsNormally);
    });

    test('reader-specific 排版與 shell 偏好會從同一組 prefs 還原', () async {
      SharedPreferences.setMockInitialValues({
        PreferKey.readerLetterSpacing: 1.25,
        PreferKey.readerTextFullJustify: false,
        PreferKey.showReadTitleAddition: false,
        PreferKey.readBarStyleFollowPage: true,
        PreferKey.textSelectAble: false,
      });

      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.letterSpacing, 1.25);
      expect(controller.textFullJustify, isFalse);
      expect(controller.showReadTitleAddition, isFalse);
      expect(controller.readBarStyleFollowPage, isTrue);
      expect(controller.selectText, isFalse);

      controller.dispose();
    });

    test('slide 模式章首 restore 會定位到目標章第一頁，不會跳回全域第 0 頁', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
        BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialLocation: const ReaderLocation(chapterIndex: 1, charOffset: 0),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.slide;
      controller.chapterPagesCache[0] = _buildPages(0, [0], title: 'c0');
      controller.chapterPagesCache[1] = _buildPages(1, [0, 8, 16], title: 'c1');
      controller.slidePages = [
        ...controller.chapterPagesCache[0]!,
        ...controller.chapterPagesCache[1]!,
      ];

      controller.jumpToPosition(
        chapterIndex: 1,
        charOffset: 0,
        isRestoringJump: true,
      );

      expect(controller.currentPageIndex, 1);
      expect(controller.consumePendingSlidePageIndex(), 1);
      controller.dispose();
    });

    test(
      'slide 模式 charOffset restore 會保留 restore reason 給 page change',
      () async {
        _fakeChaptersFromDao = [
          BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
          BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
        ];
        final controller = ReadBookController(
          book: _makeBook(),
          initialLocation: const ReaderLocation(chapterIndex: 1, charOffset: 0),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        controller.pageTurnMode = PageAnim.slide;
        controller.chapterPagesCache[0] = _buildPages(0, [0], title: 'c0');
        controller.chapterPagesCache[1] = _buildPages(1, [
          0,
          8,
          16,
        ], title: 'c1');
        controller.slidePages = [
          ...controller.chapterPagesCache[0]!,
          ...controller.chapterPagesCache[1]!,
        ];

        controller.jumpToChapterCharOffset(
          chapterIndex: 1,
          charOffset: 8,
          reason: ReaderCommandReason.restore,
          isRestoringJump: true,
        );

        expect(controller.currentPageIndex, 2);
        expect(controller.consumePendingSlidePageIndex(), 2);
        expect(
          controller.consumePendingSlideJumpReason(),
          ReaderCommandReason.restore,
        );
        controller.dispose();
      },
    );

    test('slide 模式跨章節 jump 會以目標章節作為 presentation anchor', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
        BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.slide;
      controller.chapterPagesCache[0] = _buildPages(0, [0], title: 'c0');
      controller.chapterPagesCache[1] = _buildPages(1, [0, 8], title: 'c1');
      controller.refreshChapterRuntime(0);
      controller.refreshChapterRuntime(1);
      controller.slidePages = [
        ...controller.chapterPagesCache[0]!,
        ...controller.chapterPagesCache[1]!,
      ];
      controller.currentChapterIndex = 0;
      controller.visibleChapterIndex = 0;
      controller.updateCommittedLocationForAuxiliary(
        const ReaderLocation(chapterIndex: 0, charOffset: 8),
      );

      await controller.jumpToChapter(1);

      expect(controller.currentPageIndex, 1);
      expect(controller.consumePendingSlidePageIndex(), 1);
      expect(
        controller.committedLocation,
        const ReaderLocation(chapterIndex: 1, charOffset: 0),
      );
      controller.dispose();
    });

    test(
      'failure chapter load 會進入 transient viewport state，不污染 committed/durable location',
      () async {
        final remoteBook = Book(
          bookUrl: 'http://test.com/book',
          name: 'Test Book',
          author: 'Author',
          origin: 'source://missing',
          durChapterIndex: 0,
          durChapterPos: 0,
        );
        final controller = ReadBookController(
          book: remoteBook,
          initialChapters: [
            BookChapter(
              title: 'c0',
              index: 0,
              bookUrl: 'http://test.com/book',
              content: '第一章正文',
            ),
            BookChapter(
              title: 'c1',
              index: 1,
              bookUrl: 'http://test.com/book',
              content: '加載章節失敗: 測試錯誤',
            ),
          ],
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        await controller.loadChapter(1);

        expect(controller.transientViewportState?.message, '加載章節失敗: 測試錯誤');
        expect(controller.transientViewportChapterIndex, 1);
        expect(
          controller.committedLocation,
          const ReaderLocation(chapterIndex: 0, charOffset: 0),
        );
        expect(
          controller.durableLocation,
          const ReaderLocation(chapterIndex: 0, charOffset: 0),
        );
        expect(controller.currentChapterIndex, 0);
        controller.dispose();
      },
    );

    test(
      'scroll 模式 charOffset repaginate 會暫時抑制 visible progress persist',
      () async {
        _fakeChaptersFromDao = [
          BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
        ];
        final controller = ReadBookController(book: _makeBook());
        await Future<void>.delayed(const Duration(milliseconds: 10));

        controller.pageTurnMode = PageAnim.scroll;
        controller.chapterPagesCache[0] = _buildPages(0, [
          0,
          8,
          16,
        ], title: 'c0');
        controller.refreshChapterRuntime(0);

        controller.jumpToChapterCharOffset(
          chapterIndex: 0,
          charOffset: 8,
          reason: ReaderCommandReason.settingsRepaginate,
        );

        expect(controller.shouldPersistVisiblePosition(), isFalse);
        controller.dispose();
      },
    );

    test('scroll target 到達前不會釋放 transaction，到達後才恢復 persistence', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);

      controller.jumpToChapterCharOffset(
        chapterIndex: 0,
        charOffset: 8,
        reason: ReaderCommandReason.settingsRepaginate,
      );

      expect(controller.shouldPersistVisiblePosition(), isFalse);

      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: 0,
        alignment: 0,
        visibleChapterIndexes: const [0],
      );
      expect(controller.shouldPersistVisiblePosition(), isFalse);

      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: controller.chapterAt(0)!.localOffsetFromCharOffset(8),
        alignment: 0,
        visibleChapterIndexes: const [0],
      );
      expect(controller.shouldPersistVisiblePosition(), isTrue);
      controller.dispose();
    });

    test('slide user page change 只會持久化一次正確進度', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.slide;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.slidePages = [...controller.chapterPagesCache[0]!];
      controller.currentChapterIndex = 0;

      controller.handleSlidePageChanged(1);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(_FakeBookDao.updates, hasLength(1));
      expect(_FakeBookDao.updates.single.chapterIndex, 0);
      expect(_FakeBookDao.updates.single.pos, 8);
      controller.dispose();
    });

    test('slide restore page change 不會被誤持久化成 user progress', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.slide;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.slidePages = [...controller.chapterPagesCache[0]!];
      controller.currentChapterIndex = 0;

      controller.jumpToSlidePage(1, reason: ReaderCommandReason.restore);
      final pending = controller.consumePendingJump();
      expect(pending, 1);
      controller.consumePendingSlideJumpReason();
      controller.handleSlidePageChanged(1);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(_FakeBookDao.updates, isEmpty);
      controller.dispose();
    });

    test('slide 切換到 scroll 會保留 charOffset 語意並建立 chapter jump', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.slide;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);
      controller.slidePages = [...controller.chapterPagesCache[0]!];
      controller.currentPageIndex = 1;
      controller.currentChapterIndex = 0;

      controller.setPageTurnMode(PageAnim.scroll);

      final pending = controller.consumePendingChapterJump();
      expect(controller.pageTurnMode, PageAnim.scroll);
      expect(pending, isNotNull);
      expect(pending!.chapterIndex, 0);
      expect(pending.reason, ReaderCommandReason.settingsRepaginate);
      expect(
        controller.committedLocation,
        const ReaderLocation(chapterIndex: 0, charOffset: 8),
      );
      controller.dispose();
    });

    test('scroll 切換到 slide 會保留 charOffset 語意並建立 slide jump', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);
      controller.visibleChapterIndex = 0;
      controller.currentChapterIndex = 0;
      controller.visibleChapterLocalOffset = controller
          .chapterAt(0)!
          .localOffsetFromCharOffset(8);

      controller.setPageTurnMode(PageAnim.slide);

      expect(controller.pageTurnMode, PageAnim.slide);
      expect(controller.currentPageIndex, 1);
      expect(controller.consumePendingSlidePageIndex(), 1);
      expect(
        controller.consumePendingSlideJumpReason(),
        ReaderCommandReason.settingsRepaginate,
      );
      expect(
        controller.committedLocation,
        const ReaderLocation(chapterIndex: 0, charOffset: 8),
      );
      controller.dispose();
    });

    test('auto page 開啟時切換模式會重啟進度計時', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.slide;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.slidePages = [...controller.chapterPagesCache[0]!];
      controller.toggleAutoPage();
      controller.autoPageProgressNotifier.value = 0.7;

      controller.setPageTurnMode(PageAnim.scroll);

      expect(controller.isAutoPaging, isTrue);
      expect(controller.autoPageProgressNotifier.value, 0.0);
      controller.stopAutoPage();
      controller.dispose();
    });

    test('切換主選單時會暫停並恢復 auto page', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.toggleAutoPage();
      expect(controller.isAutoPaging, isTrue);
      expect(controller.isAutoPagePaused, isFalse);

      controller.toggleControls();
      expect(controller.showControls, isTrue);
      expect(controller.isAutoPagePaused, isTrue);

      controller.toggleControls();
      expect(controller.showControls, isFalse);
      expect(controller.isAutoPaging, isTrue);
      expect(controller.isAutoPagePaused, isFalse);

      controller.stopAutoPage();
      controller.dispose();
    });

    test('日夜切換會在保存的白天與夜間主題之間切換', () async {
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.lastDayThemeIndex = 0;
      controller.lastNightThemeIndex = 1;
      controller.themeIndex = 0;

      controller.toggleDayNightTheme();
      expect(controller.themeIndex, 1);
      expect(controller.willToggleToDarkTheme, isFalse);

      controller.toggleDayNightTheme();
      expect(controller.themeIndex, 0);
      expect(controller.willToggleToDarkTheme, isTrue);

      controller.dispose();
    });

    test('scroll 模式下一頁會按 viewport 步進，不直接切章', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
        BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.viewSize = const Size(400, 400);
      controller.scrollViewportTopInset = 40;
      controller.scrollViewportBottomInset = 40;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.chapterPagesCache[1] = _buildPages(1, [0, 8, 16], title: 'c1');
      controller.refreshChapterRuntime(0);
      controller.refreshChapterRuntime(1);
      controller.visibleChapterIndex = 0;
      controller.currentChapterIndex = 0;
      controller.visibleChapterLocalOffset = 40;

      controller.nextPage();

      final pending = controller.consumePendingChapterJump();
      expect(pending, isNotNull);
      expect(pending!.chapterIndex, 0);
      expect(pending.localOffset, closeTo(321.6, 0.1));
      expect(pending.reason, ReaderCommandReason.userScroll);
      controller.dispose();
    });

    test('scroll 模式跨章下一頁會保留剩餘 offset', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
        BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.viewSize = const Size(400, 400);
      controller.scrollViewportTopInset = 40;
      controller.scrollViewportBottomInset = 40;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.chapterPagesCache[1] = _buildPages(1, [0, 8, 16], title: 'c1');
      controller.refreshChapterRuntime(0);
      controller.refreshChapterRuntime(1);
      controller.visibleChapterIndex = 0;
      controller.currentChapterIndex = 0;
      controller.visibleChapterLocalOffset = 380;

      controller.nextPage();

      final pending = controller.consumePendingChapterJump();
      final separatorExtent = ReaderScrollLayout.chapterSeparatorExtent(
        fontSize: controller.fontSize,
        lineHeight: controller.lineHeight,
      );
      final expectedLocalOffset =
          (((400 - 40 - 40) * 0.88) - (420 - 380) - separatorExtent);
      expect(pending, isNotNull);
      expect(pending!.chapterIndex, 1);
      expect(pending.localOffset, closeTo(expectedLocalOffset, 0.1));
      expect(pending.reason, ReaderCommandReason.userScroll);
      controller.dispose();
    });

    test('沒有 page anchor confirmation 時不會釋放 scroll transaction', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);

      controller.jumpToChapterCharOffset(
        chapterIndex: 0,
        charOffset: 8,
        reason: ReaderCommandReason.settingsRepaginate,
      );
      expect(controller.shouldPersistVisiblePosition(), isFalse);

      final localOffset = controller.chapterAt(0)!.localOffsetFromCharOffset(8);
      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: localOffset,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
        isAnchorConfirmed: false,
      );

      expect(controller.shouldPersistVisiblePosition(), isFalse);

      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: localOffset,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
      );

      expect(controller.shouldPersistVisiblePosition(), isTrue);
      controller.dispose();
    });

    test('scroll target 章節 ready 後會重送對應 localOffset jump', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.jumpToChapterCharOffset(
        chapterIndex: 0,
        charOffset: 8,
        reason: ReaderCommandReason.settingsRepaginate,
      );

      final initialJump = controller.consumePendingChapterJump();
      expect(initialJump, isNotNull);
      expect(initialJump!.localOffset, 0.0);

      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.handleChapterReadyEvent(0);

      final repairedJump = controller.consumePendingChapterJump();
      expect(repairedJump, isNotNull);
      expect(repairedJump!.chapterIndex, 0);
      expect(repairedJump.localOffset, closeTo(140.0, 0.1));
      expect(repairedJump.reason, ReaderCommandReason.settingsRepaginate);
      controller.dispose();
    });

    test('visible placeholder 章節 ready 後會依相對進度 re-anchor', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.recordEstimatedPlaceholderChapterContentHeight(
        0,
        contentHeight: 600,
      );
      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: 300,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
        isAnchorConfirmed: false,
      );

      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.handleChapterReadyEvent(0);

      final correctedJump = controller.consumePendingChapterJump();
      expect(correctedJump, isNotNull);
      expect(correctedJump!.chapterIndex, 0);
      expect(correctedJump.localOffset, closeTo(210.0, 0.1));
      expect(correctedJump.reason, ReaderCommandReason.system);
      controller.dispose();
    });

    test('使用者拖動期間會延後 visible placeholder re-anchor', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.recordEstimatedPlaceholderChapterContentHeight(
        0,
        contentHeight: 600,
      );
      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: 300,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
        isAnchorConfirmed: false,
      );
      controller.setScrollInteractionActive(true);

      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.handleChapterReadyEvent(0);

      expect(controller.consumePendingChapterJump(), isNull);

      controller.setScrollInteractionActive(false);

      final correctedJump = controller.consumePendingChapterJump();
      expect(correctedJump, isNotNull);
      expect(correctedJump!.chapterIndex, 0);
      expect(correctedJump.localOffset, closeTo(210.0, 0.1));
      expect(correctedJump.reason, ReaderCommandReason.system);
      controller.dispose();
    });

    test('chapter navigation pending 期間會忽略重入', () async {
      final controller = _PendingNavigationReaderProvider(
        book: _makeBook(),
        initialChapters: [
          BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
          BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
          BookChapter(title: 'c2', index: 2, bookUrl: 'http://test.com/book'),
        ],
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.currentChapterIndex = 0;
      controller.visibleChapterIndex = 0;

      final firstJump = controller.jumpToChapter(2);
      await Future<void>.delayed(Duration.zero);

      expect(controller.hasPendingChapterNavigation, isTrue);
      expect(controller.pendingChapterNavigationIndex, 2);
      expect(controller.loadRequests, hasLength(1));
      expect(controller.retainedSnapshots.single, containsAll(<int>{0, 1, 2}));
      expect(
        controller.focusedRetainedSnapshots.single,
        containsAll(<int>{0, 1, 2}),
      );

      unawaited(controller.nextChapter());
      await Future<void>.delayed(Duration.zero);
      expect(controller.loadRequests, hasLength(1));

      controller.loadCompleter!.complete();
      await firstJump;

      expect(controller.hasPendingChapterNavigation, isFalse);
      expect(controller.pendingChapterNavigationIndex, isNull);
      controller.dispose();
    });

    test('retainedChapterIndexes 會保留 pending scroll restore target', () async {
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: List.generate(
          6,
          (index) => BookChapter(
            title: 'c$index',
            index: index,
            bookUrl: 'http://test.com/book',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.currentChapterIndex = 2;
      controller.visibleChapterIndex = 2;
      controller.pageTurnMode = PageAnim.scroll;
      controller.registerPendingScrollRestore(chapterIndex: 5, localOffset: 42);

      expect(
        controller.retainedChapterIndexes(),
        containsAll(<int>{1, 2, 3, 4, 5}),
      );
      controller.dispose();
    });

    test('retainedChapterIndexes 會保留 TTS 目前章與下一章', () async {
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: List.generate(
          5,
          (index) => BookChapter(
            title: 'c$index',
            index: index,
            bookUrl: 'http://test.com/book',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.currentChapterIndex = 3;
      controller.visibleChapterIndex = 3;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8], title: 'c0');
      controller.chapterPagesCache[1] = _buildPages(1, [0, 8], title: 'c1');
      controller.chapterPagesCache[3] = _buildPages(3, [0, 8], title: 'c3');
      controller.refreshChapterRuntime(0);
      controller.refreshChapterRuntime(1);
      controller.refreshChapterRuntime(3);

      controller.startTtsFromOffset(0, chapterIndex: 0);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.retainedChapterIndexes(),
        containsAll(<int>{0, 1, 2, 3, 4}),
      );

      controller.stopTts();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
    });

    test('app pause 前會 flush 目前 slide session progress', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.slide;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.slidePages = [...controller.chapterPagesCache[0]!];
      controller.currentPageIndex = 1;
      controller.currentChapterIndex = 0;

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(_FakeBookDao.updates, isNotEmpty);
      expect(_FakeBookDao.updates.last.chapterIndex, 0);
      expect(_FakeBookDao.updates.last.pos, 8);
      expect(controller.durableLocation.charOffset, 8);
      controller.dispose();
    });

    test('dispose fallback 會 flush debounce 中的 scroll progress', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);
      final firstOffset = controller.chapterAt(0)!.localOffsetFromCharOffset(8);
      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: firstOffset,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(_FakeBookDao.updates.last.pos, 8);

      final secondOffset = controller
          .chapterAt(0)!
          .localOffsetFromCharOffset(16);
      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: secondOffset,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
      );

      controller.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(_FakeBookDao.updates.last.pos, 16);
      expect(
        controller.durableLocation,
        const ReaderLocation(chapterIndex: 0, charOffset: 16),
      );
    });

    test('persistExitProgress 在 scroll 模式會保存目前可見 charOffset', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);
      final localOffset = controller.chapterAt(0)!.localOffsetFromCharOffset(8);
      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: localOffset,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
      );

      await controller.persistExitProgress();

      expect(_FakeBookDao.updates, isNotEmpty);
      expect(_FakeBookDao.updates.last.chapterIndex, 0);
      expect(_FakeBookDao.updates.last.pos, 8);
      expect(
        controller.durableLocation,
        const ReaderLocation(chapterIndex: 0, charOffset: 8),
      );
      controller.dispose();
    });

    test('app pause 與 persistExitProgress 會共用同一條 flush，不重複寫入', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);
      final firstOffset = controller.chapterAt(0)!.localOffsetFromCharOffset(8);
      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: firstOffset,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final secondOffset = controller
          .chapterAt(0)!
          .localOffsetFromCharOffset(16);
      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: secondOffset,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
      );

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await controller.persistExitProgress();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        _FakeBookDao.updates.where((update) => update.pos == 16),
        hasLength(1),
      );
      expect(
        controller.durableLocation,
        const ReaderLocation(chapterIndex: 0, charOffset: 16),
      );
      controller.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        _FakeBookDao.updates.where((update) => update.pos == 16),
        hasLength(1),
      );
    });

    test(
      'replaceChapterSource 會透過 content facade 失效舊 cache 與 runtime',
      () async {
        _fakeChaptersFromDao = [
          BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
          BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
        ];
        final controller = ReadBookController(
          book: _makeBook(),
          initialChapters: _fakeChaptersFromDao,
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        controller.chapterPagesCache[1] = _buildPages(1, [0, 12], title: 'c1');
        controller.refreshChapterRuntime(1);

        expect(controller.chapterAt(1), isNotNull);

        controller.replaceChapterSource(1, BookSource(), 'updated content');

        expect(controller.chapters[1].content, 'updated content');
        expect(controller.chapterPagesCache.containsKey(1), isFalse);
        expect(controller.chapterAt(1), isNull);
        controller.dispose();
      },
    );

    test('未加入書架且已有閱讀進度時，退出會建議加入書架', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.slide;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 12], title: 'c0');
      controller.slidePages = [...controller.chapterPagesCache[0]!];
      controller.currentPageIndex = 1;

      expect(controller.shouldPromptAddToBookshelfOnExit(), isTrue);
      controller.dispose();
    });

    test('退出時加入書架會保存目前進度並寫入章節', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.slide;
      controller.chapterPagesCache[0] = _buildPages(0, [0, 18], title: 'c0');
      controller.slidePages = [...controller.chapterPagesCache[0]!];
      controller.currentPageIndex = 1;

      await controller.addCurrentBookToBookshelf();

      expect(controller.book.isInBookshelf, isTrue);
      expect(controller.book.durChapterIndex, 0);
      expect(controller.book.durChapterPos, 18);
      expect(controller.book.durChapterTitle, 'c0');
      expect(_FakeBookDao.upserts, hasLength(1));
      expect(_FakeChapterDao.insertedBatches, hasLength(1));
      expect(_FakeChapterDao.insertedBatches.single, hasLength(1));
      controller.dispose();
    });
  });

  testWidgets('PageViewWidget 會依 selectText 開關 SelectionArea', (tester) async {
    final controller = ReaderProvider(book: _makeBook());
    await tester.pump(const Duration(milliseconds: 10));
    final page = _buildPages(0, [0], title: 'c0').single;

    controller.selectText = false;
    await tester.pumpWidget(
      ChangeNotifierProvider<ReaderProvider>.value(
        value: controller,
        child: MaterialApp(
          home: SizedBox(
            width: 320,
            height: 480,
            child: PageViewWidget(
              page: page,
              contentStyle: const TextStyle(fontSize: 18),
              titleStyle: const TextStyle(fontSize: 22),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SelectionArea), findsNothing);

    controller.setSelectText(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(SelectionArea), findsOneWidget);
    controller.dispose();
  });

  testWidgets('PageViewWidget 會透過 onPageTapUp 分發點擊', (tester) async {
    final controller = ReaderProvider(book: _makeBook());
    await tester.pump(const Duration(milliseconds: 10));
    final page = _buildPages(0, [0], title: 'c0').single;
    var tapCount = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider<ReaderProvider>.value(
        value: controller,
        child: MaterialApp(
          home: SizedBox(
            width: 320,
            height: 480,
            child: PageViewWidget(
              page: page,
              contentStyle: const TextStyle(fontSize: 18),
              titleStyle: const TextStyle(fontSize: 22),
              onPageTapUp: (_) => tapCount++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PageViewWidget));
    await tester.pump();

    expect(tapCount, 1);
    controller.dispose();
  });

  testWidgets('PageViewWidget 開啟 selectText 後仍會透過 onPageTapUp 分發點擊', (
    tester,
  ) async {
    final controller = ReaderProvider(book: _makeBook());
    await tester.pump(const Duration(milliseconds: 10));
    final page = _buildPages(0, [0], title: 'c0').single;
    var tapCount = 0;
    controller.setSelectText(true);

    await tester.pumpWidget(
      ChangeNotifierProvider<ReaderProvider>.value(
        value: controller,
        child: MaterialApp(
          home: SizedBox(
            width: 320,
            height: 480,
            child: PageViewWidget(
              page: page,
              contentStyle: const TextStyle(fontSize: 18),
              titleStyle: const TextStyle(fontSize: 22),
              onPageTapUp: (_) => tapCount++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SelectionArea), findsOneWidget);

    await tester.tap(find.byType(PageViewWidget));
    await tester.pump();

    expect(tapCount, 1);
    controller.dispose();
  });

  testWidgets('showReadTitleAddition 會控制 top menu 的章節附加資訊', (tester) async {
    final book = _makeBook().copyWith(originName: '測試來源');
    final controller = ReaderProvider(
      book: book,
      initialChapters: [
        BookChapter(
          title: '章節標題',
          index: 0,
          url: 'chapter-0',
          bookUrl: book.bookUrl,
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 10));
    controller.showControls = true;
    controller.currentChapterIndex = 0;
    controller.showReadTitleAddition = false;
    expect(controller.currentChapterTitle, '章節標題');

    await tester.pumpWidget(
      ChangeNotifierProvider<ReaderProvider>.value(
        value: controller,
        child: MaterialApp(
          home: Stack(
            children: [
              Consumer<ReaderProvider>(
                builder:
                    (context, provider, child) => ReaderTopMenu(
                      provider: provider,
                      onBack: () {},
                      onMore: () {},
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('章節標題'), findsNothing);
    expect(find.text('測試來源'), findsNothing);

    controller.setShowReadTitleAddition(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('章節標題'), findsOneWidget);
    expect(find.text('測試來源'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('ReaderBottomMenu 在 pending chapter navigation 時禁用章節切換', (
    tester,
  ) async {
    final controller = _PendingNavigationReaderProvider(
      book: _makeBook(),
      initialChapters: [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
        BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
      ],
    );
    await tester.pump(const Duration(milliseconds: 10));
    controller.showControls = true;

    unawaited(controller.jumpToChapter(1));
    await tester.pump();

    await tester.pumpWidget(
      ChangeNotifierProvider<ReaderProvider>.value(
        value: controller,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: Stack(
                children: [
                  ReaderBottomMenu(
                    provider: controller,
                    onOpenDrawer: () {},
                    onTts: () {},
                    onInterface: () {},
                    onSettings: () {},
                    onAutoPage: () {},
                    onToggleDayNight: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '上一章'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '下一章'))
          .onPressed,
      isNull,
    );

    controller.loadCompleter!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    controller.dispose();
  });
}
