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
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/reader_chapter_content.dart';
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
    int pos, {
    String? readerAnchorJson,
  }) async {
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
  Future<List<BookChapter>> getByBook(String bookUrl) async =>
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

class _FakeReaderChapterContentDao implements ReaderChapterContentDao {
  static final Map<String, String> contentByKey = <String, String>{};

  @override
  Future<String?> getContent({required String contentKey}) async {
    final content = contentByKey[contentKey];
    return content == null || content.isEmpty ? null : content;
  }

  @override
  Future<ReaderChapterContentEntry?> getEntry({
    required String contentKey,
  }) async {
    final content = await getContent(contentKey: contentKey);
    if (content == null) return null;
    return ReaderChapterContentEntry(
      contentKey: contentKey,
      origin: '',
      bookUrl: '',
      chapterUrl: '',
      chapterIndex: 0,
      status: ReaderChapterContentStatus.ready,
      content: content,
      updatedAt: 1,
    );
  }

  @override
  Future<void> saveContent({
    required String contentKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required String content,
    required int updatedAt,
    ReaderChapterContentStatus status = ReaderChapterContentStatus.ready,
    String? failureMessage,
  }) async {
    contentByKey[contentKey] = content;
  }

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

class _BlankRecoveryReaderProvider extends ReaderProvider {
  _BlankRecoveryReaderProvider({
    required super.book,
    required super.initialChapters,
  });

  final List<int> ensureRequests = [];
  final List<int> loadRequests = [];

  @override
  bool get hasContentManager => true;

  @override
  Future<List<TextPage>> ensureChapterCached(
    int index, {
    bool silent = true,
    bool prioritize = false,
    int preloadRadius = 1,
  }) async {
    ensureRequests.add(index);
    return _buildPages(index, [0]);
  }

  @override
  Future<void> loadChapterWithPreloadRadius(
    int index, {
    bool fromEnd = false,
    int preloadRadius = 2,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
    int? navigationToken,
  }) async {
    loadRequests.add(index);
  }
}

class _ScrollModeSeededReaderProvider extends ReaderProvider {
  _ScrollModeSeededReaderProvider({
    required super.book,
    required super.initialChapters,
    required this.seededPages,
  });

  final Map<int, List<TextPage>> seededPages;

  @override
  Future<void> loadSettings() async {
    await super.loadSettings();
    pageTurnMode = PageAnim.scroll;
  }

  @override
  void updatePaginationConfig() {}

  @override
  Future<void> loadChapterWithPreloadRadius(
    int index, {
    bool fromEnd = false,
    int preloadRadius = 2,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
    int? navigationToken,
  }) async {
    final pages = seededPages[index];
    if (pages != null) {
      chapterPagesCache[index] = pages;
      refreshChapterRuntime(index);
    }
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
    () {
      if (getIt.isRegistered<ReaderChapterContentDao>()) {
        getIt.unregister<ReaderChapterContentDao>();
      }
    },
  ]) {
    unregister();
  }
  _FakeReaderChapterContentDao.contentByKey.clear();
  getIt.registerLazySingleton<BookDao>(() => _FakeBookDao());
  getIt.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
  getIt.registerLazySingleton<ReaderChapterContentDao>(
    () => _FakeReaderChapterContentDao(),
  );
  getIt.registerLazySingleton<ReplaceRuleDao>(() => _FakeReplaceRuleDao());
  getIt.registerLazySingleton<BookSourceDao>(() => _FakeBookSourceDao());
  getIt.registerLazySingleton<BookmarkDao>(() => _FakeBookmarkDao());
}

Book _makeBook() => Book(
  bookUrl: 'http://test.com/book',
  name: 'Test Book',
  author: 'Author',
  origin: 'local',
  chapterIndex: 0,
  charOffset: 0,
);

Book _makeBookWithOrigin(String origin) => Book(
  bookUrl: 'http://test.com/$origin/book',
  name: 'Test Book',
  author: 'Author',
  origin: origin,
  chapterIndex: 0,
  charOffset: 0,
);

List<BookChapter> _fakeChaptersFromDao = [];

List<BookChapter> _buildChapters(
  int count, {
  required String bookUrl,
  bool includeContent = false,
}) {
  return List.generate(
    count,
    (index) => BookChapter(
      title: 'c$index',
      index: index,
      bookUrl: bookUrl,
      url: '$bookUrl/chapter-$index',
      content: includeContent ? 'chapter $index content' : null,
    ),
  );
}

void _seedChapterContent(Book book, Iterable<BookChapter> chapters) {
  for (final chapter in chapters) {
    final content = chapter.content;
    if (content == null || content.isEmpty) continue;
    _FakeReaderChapterContentDao
            .contentByKey[ReaderChapterContentDao.contentKey(
          origin: book.origin,
          bookUrl: book.bookUrl,
          chapterUrl: chapter.url,
        )] =
        content;
  }
}

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

List<TextPage> _buildSinglePageLinePages(
  int chapterIndex, {
  required int lineCount,
  required double lineHeight,
  required int charsPerLine,
  String title = 'chapter',
}) {
  return [
    TextPage(
      index: 0,
      title: title,
      chapterIndex: chapterIndex,
      pageSize: 1,
      lines: List.generate(lineCount, (lineIndex) {
        return TextLine(
          text: List.filled(charsPerLine, 'X').join(),
          width: 100,
          height: lineHeight,
          chapterPosition: lineIndex * charsPerLine,
          lineTop: lineIndex * lineHeight,
          lineBottom: (lineIndex + 1) * lineHeight,
          paragraphNum: lineIndex + 1,
          isParagraphEnd: true,
        );
      }),
    ),
  ];
}

Future<void> _expectScrollResumeRoundTripAtChapterTen({
  required Book book,
  required List<BookChapter> chapters,
}) async {
  const targetChapterIndex = 9;
  const lineHeight = 20.0;
  const charsPerLine = 20;
  const scrolledLines = 10.5;
  final targetPages = _buildSinglePageLinePages(
    targetChapterIndex,
    lineCount: 24,
    lineHeight: lineHeight,
    charsPerLine: charsPerLine,
    title: 'c$targetChapterIndex',
  );
  const scrolledLocalOffset = lineHeight * scrolledLines;
  const expectedCharOffset = 10 * charsPerLine;
  const expectedRestoredLocalOffset = lineHeight * 10;

  _fakeChaptersFromDao = chapters;
  _seedChapterContent(book, chapters);
  final firstController = _ScrollModeSeededReaderProvider(
    book: book,
    initialChapters: chapters,
    seededPages: {targetChapterIndex: targetPages},
  );
  firstController.setViewSize(const Size(400, 800));
  await Future<void>.delayed(const Duration(milliseconds: 10));

  firstController.chapterPagesCache[targetChapterIndex] = targetPages;
  firstController.refreshChapterRuntime(targetChapterIndex);
  firstController.handleVisibleScrollState(
    chapterIndex: targetChapterIndex,
    localOffset: scrolledLocalOffset,
    alignment: 0.0,
    visibleChapterIndexes: const [targetChapterIndex],
  );

  await firstController.persistExitProgress();

  expect(_FakeBookDao.updates, isNotEmpty);
  expect(_FakeBookDao.updates.last.chapterIndex, targetChapterIndex);
  expect(_FakeBookDao.updates.last.pos, expectedCharOffset);
  expect(book.chapterIndex, targetChapterIndex);
  expect(book.charOffset, expectedCharOffset);
  expect(book.readerAnchorJson, isNull);
  firstController.dispose();
  await Future<void>.delayed(const Duration(milliseconds: 10));

  final reopenedController = _ScrollModeSeededReaderProvider(
    book: book,
    initialChapters: chapters,
    seededPages: {targetChapterIndex: targetPages},
  );
  reopenedController.setViewSize(const Size(400, 800));
  await Future<void>.delayed(const Duration(milliseconds: 10));

  expect(reopenedController.pageTurnMode, PageAnim.scroll);
  expect(reopenedController.currentChapterIndex, targetChapterIndex);
  expect(reopenedController.visibleChapterIndex, targetChapterIndex);
  expect(
    reopenedController.committedLocation,
    const ReaderLocation(
      chapterIndex: targetChapterIndex,
      charOffset: expectedCharOffset,
    ),
  );
  expect(
    reopenedController.visibleChapterLocalOffset,
    closeTo(expectedRestoredLocalOffset, 0.1),
  );
  expect(reopenedController.hasPendingScrollRestore, isTrue);

  final restore = reopenedController.dispatchPendingScrollRestore();
  expect(restore, isNotNull);
  expect(restore!.chapterIndex, targetChapterIndex);
  expect(restore.localOffset, closeTo(expectedRestoredLocalOffset, 0.1));

  reopenedController.dispose();
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

    test(
      '初始狀態：lifecycle 為 loading',
      () {
        final controller = ReadBookController(book: _makeBook());
        expect(controller.lifecycle, equals(ReaderLifecycle.loading));
        controller.dispose();
      },
      skip:
          'obsolete: slide chapter jump is covered by ReaderRuntime ReaderLocation -> TextPage tests',
    );

    test(
      '初始狀態：isReady 為 false',
      () {
        final controller = ReadBookController(book: _makeBook());
        expect(controller.isReady, isFalse);
        controller.dispose();
      },
      skip: 'obsolete: slide chapter jump no longer uses global PageView index',
    );

    test('scroll 模式空白 viewport 會自動補載目前章節', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'chapter-0', index: 0),
        BookChapter(title: 'chapter-1', index: 1),
      ];
      final controller = _BlankRecoveryReaderProvider(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      controller
        ..chapters = _fakeChaptersFromDao
        ..pageTurnMode = PageAnim.scroll
        ..lifecycle = ReaderLifecycle.ready
        ..viewSize = const Size(400, 700)
        ..visibleChapterIndex = 1
        ..currentChapterIndex = 1;

      expect(controller.shouldRecoverBlankVisibleContent, isTrue);
      controller.recoverBlankVisibleContent();
      await Future<void>.delayed(Duration.zero);

      expect(controller.ensureRequests, [1]);
      expect(controller.loadRequests, isEmpty);
      controller.dispose();
    });

    test('slide 模式空白 viewport 會自動重新呈現目前章節', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'chapter-0', index: 0),
        BookChapter(title: 'chapter-1', index: 1),
      ];
      final controller = _BlankRecoveryReaderProvider(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      controller
        ..chapters = _fakeChaptersFromDao
        ..pageTurnMode = PageAnim.slide
        ..lifecycle = ReaderLifecycle.ready
        ..viewSize = const Size(400, 700)
        ..currentChapterIndex = 1;

      expect(controller.shouldRecoverBlankVisibleContent, isTrue);
      controller.recoverBlankVisibleContent();
      await Future<void>.delayed(Duration.zero);

      expect(controller.loadRequests, [1]);
      expect(controller.ensureRequests, isEmpty);
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
            ..chapterIndex = 2
            ..charOffset = 144;
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
      skip:
          'obsolete: transient provider viewport state was replaced by engine loading/error pages',
    );

    test(
      'slide restore controller reset 到目標頁後會清除 pinned target',
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

        controller.pageTurnMode = PageAnim.slide;
        controller.chapterPagesCache[0] = _buildPages(0, [0], title: 'c0');
        controller.chapterPagesCache[1] = _buildPages(1, [
          0,
          8,
          16,
        ], title: 'c1');
        controller.refreshChapterRuntime(0);
        controller.refreshChapterRuntime(1);
        controller.slidePages = [
          ...controller.chapterPagesCache[0]!,
          ...controller.chapterPagesCache[1]!,
        ];
        controller.currentChapterIndex = 0;
        controller.currentPageIndex = 0;

        controller.restoreInitialSlideLocationForTesting(
          chapterIndex: 1,
          charOffset: 8,
        );

        final initialPage = controller.currentPageIndex;

        expect(initialPage, 2);
        expect(controller.consumeControllerReset(), 2);
        expect(controller.consumePendingSlidePageIndex(), isNull);

        controller.handleSlidePageChanged(initialPage + 1);

        expect(controller.currentPageIndex, initialPage + 1);
        expect(controller.consumePendingSlidePageIndex(), isNull);
        controller.dispose();
      },
      skip:
          'obsolete: visible placeholder re-anchor belongs to removed scroll-item restore model',
    );

    test(
      'slide restore 找不到 target 時不會 fallback 到全域 page 0',
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

        controller.pageTurnMode = PageAnim.slide;
        controller.chapterPagesCache[0] = _buildPages(0, [0], title: 'c0');
        controller.chapterPagesCache[1] = _buildPages(1, [
          0,
          8,
          16,
        ], title: 'c1');
        controller.refreshChapterRuntime(0);
        controller.slidePages = [...controller.chapterPagesCache[0]!];
        controller.currentChapterIndex = 0;
        controller.currentPageIndex = 3;

        controller.restoreInitialSlideLocationForTesting(
          chapterIndex: 1,
          charOffset: 8,
        );

        expect(controller.currentPageIndex, 3);
        expect(controller.consumeControllerReset(), isNull);
        expect(controller.consumePendingSlidePageIndex(), isNull);
        controller.dispose();
      },
      skip:
          'obsolete: pending chapter navigation lock was removed from reader core',
    );

    test(
      'slide 模式跨章節 jump 會以目標章節作為 presentation anchor',
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
      },
      skip:
          'obsolete: loading chapter takeover was part of legacy provider navigation',
    );

    test(
      'slide 模式目錄重選目前章會回到章首',
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

        controller.pageTurnMode = PageAnim.slide;
        controller.chapterPagesCache[0] = _buildPages(0, [0], title: 'c0');
        controller.chapterPagesCache[1] = _buildPages(1, [
          0,
          8,
          16,
        ], title: 'c1');
        controller.refreshChapterRuntime(0);
        controller.refreshChapterRuntime(1);
        controller.slidePages = [
          ...controller.chapterPagesCache[0]!,
          ...controller.chapterPagesCache[1]!,
        ];
        controller.currentChapterIndex = 1;
        controller.visibleChapterIndex = 1;
        controller.currentPageIndex = 2;
        controller.updateCommittedLocationForAuxiliary(
          const ReaderLocation(chapterIndex: 1, charOffset: 8),
        );

        await controller.jumpToChapter(1);

        expect(controller.currentPageIndex, 1);
        expect(controller.consumePendingSlidePageIndex(), 1);
        expect(
          controller.committedLocation,
          const ReaderLocation(chapterIndex: 1, charOffset: 0),
        );
        controller.dispose();
      },
      skip:
          'obsolete: chapter navigation index is no longer derived from PageView global index',
    );

    test(
      'failure chapter load 會進入 transient viewport state，不污染 committed/durable location',
      () async {
        final remoteBook = Book(
          bookUrl: 'http://test.com/book',
          name: 'Test Book',
          author: 'Author',
          origin: 'source://missing',
          chapterIndex: 0,
          charOffset: 0,
        );
        final chapters = [
          BookChapter(
            title: 'c0',
            index: 0,
            bookUrl: 'http://test.com/book',
            url: 'http://test.com/book/chapter-0',
            content: '第一章正文',
          ),
          BookChapter(
            title: 'c1',
            index: 1,
            bookUrl: 'http://test.com/book',
            url: 'http://test.com/book/chapter-1',
            content: '加載章節失敗: 測試錯誤',
          ),
        ];
        _seedChapterContent(remoteBook, chapters);
        final controller = ReadBookController(
          book: remoteBook,
          initialChapters: chapters,
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
      skip:
          'obsolete: transient provider viewport state was replaced by engine error placeholder pages',
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

    test('slide 切換到 scroll 只用目前 page 的 charOffset 建立 chapter jump', () async {
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
      controller.visibleChapterLocalOffset = controller
          .chapterAt(0)!
          .localOffsetFromCharOffset(16);

      controller.setPageTurnMode(PageAnim.scroll);

      final pending = controller.consumePendingChapterJump();
      expect(controller.pageTurnMode, PageAnim.scroll);
      expect(pending, isNotNull);
      expect(pending!.chapterIndex, 0);
      expect(pending.reason, ReaderCommandReason.settingsRepaginate);
      expect(
        pending.localOffset,
        controller.chapterAt(0)!.localOffsetFromCharOffset(8),
      );
      expect(
        controller.committedLocation,
        const ReaderLocation(chapterIndex: 0, charOffset: 8),
      );
      controller.dispose();
    });

    test('scroll 切換到 slide 只用可見 line 的 charOffset 建立 slide jump', () async {
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
      controller.currentPageIndex = 2;
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

    test('scroll restore anchor padding 使用實際 scroll viewport 高度', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller
        ..pageTurnMode = PageAnim.scroll
        ..viewSize = const Size(400, 800)
        ..scrollViewportTopInset = 40
        ..scrollViewportBottomInset = 80;

      expect(
        controller.scrollRestoreAnchorPadding,
        closeTo((800 - 40 - 80) * ReaderScrollLayout.anchorRatio, 0.1),
      );
      controller.dispose();
    });

    test('scroll restore 章節 ready 後 confirmed anchor 會釋放 navigation', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(book: _makeBook());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller
        ..pageTurnMode = PageAnim.scroll
        ..viewSize = const Size(400, 800)
        ..scrollViewportTopInset = 40
        ..scrollViewportBottomInset = 80;

      controller.jumpToChapterCharOffset(
        chapterIndex: 0,
        charOffset: 8,
        reason: ReaderCommandReason.restore,
      );
      expect(controller.shouldPersistVisiblePosition(), isFalse);

      controller.chapterPagesCache[0] = _buildPages(0, [0, 8, 16], title: 'c0');
      controller.refreshChapterRuntime(0);
      controller.onScrollChapterReadyApplied(0, hasPages: true);

      final pending = controller.consumePendingChapterJump();
      expect(pending, isNotNull);
      expect(pending!.reason, ReaderCommandReason.restore);

      controller.handleVisibleScrollState(
        chapterIndex: pending.chapterIndex,
        localOffset: pending.localOffset,
        alignment: pending.alignment,
        visibleChapterIndexes: const [0],
        anchorPadding: controller.scrollRestoreAnchorPadding,
      );

      expect(controller.shouldPersistVisiblePosition(), isTrue);
      expect(controller.isScrollRestoreUnconfirmed, isFalse);
      controller.dispose();
    });

    test('scroll restore runner completion 會釋放 restore block', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller
        ..pageTurnMode = PageAnim.scroll
        ..viewSize = const Size(400, 800);
      controller.chapterPagesCache[0] = _buildSinglePageLinePages(
        0,
        lineCount: 24,
        lineHeight: 20,
        charsPerLine: 20,
        title: 'c0',
      );
      controller.refreshChapterRuntime(0);

      controller.restoreInitialScrollLocationForTesting(
        chapterIndex: 0,
        charOffset: 200,
      );

      final restoreToken = controller.pendingScrollRestoreToken;
      final navigationToken = controller.activeNavigationToken;
      expect(controller.shouldBlockScrollInputForRestore, isTrue);
      expect(navigationToken, isNotNull);

      controller.completeScrollRestoreFromViewport(
        restoreToken: restoreToken,
        navigationToken: navigationToken!,
        chapterIndex: 0,
        requestedLocalOffset: 210.0,
        measuredChapterIndex: 0,
        measuredLocalOffset: 212.0,
      );

      expect(controller.hasPendingScrollRestore, isFalse);
      expect(controller.shouldBlockScrollInputForRestore, isFalse);
      expect(controller.visibleChapterIndex, 0);
      expect(controller.visibleChapterLocalOffset, closeTo(212.0, 0.5));
      controller.dispose();
    });

    test('scroll restore completion 不依賴 item positions listener', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.chapterPagesCache[0] = _buildSinglePageLinePages(
        0,
        lineCount: 24,
        lineHeight: 20,
        charsPerLine: 20,
        title: 'c0',
      );
      controller.refreshChapterRuntime(0);

      controller.restoreInitialScrollLocationForTesting(
        chapterIndex: 0,
        charOffset: 200,
      );

      final restoreToken = controller.pendingScrollRestoreToken;
      final navigationToken = controller.activeNavigationToken;
      expect(controller.shouldBlockScrollInputForRestore, isTrue);
      expect(navigationToken, isNotNull);

      controller.completeScrollRestoreFromViewport(
        restoreToken: restoreToken,
        navigationToken: navigationToken!,
        chapterIndex: 0,
        requestedLocalOffset: 210.0,
      );

      expect(controller.hasPendingScrollRestore, isFalse);
      expect(controller.shouldBlockScrollInputForRestore, isFalse);
      expect(controller.visibleChapterLocalOffset, closeTo(210.0, 0.5));
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

    test(
      '使用者拖動期間會延後 visible placeholder re-anchor',
      () async {
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

        controller.chapterPagesCache[0] = _buildPages(0, [
          0,
          8,
          16,
        ], title: 'c0');
        controller.handleChapterReadyEvent(0);

        expect(controller.consumePendingChapterJump(), isNull);

        controller.setScrollInteractionActive(false);

        final correctedJump = controller.consumePendingChapterJump();
        expect(correctedJump, isNotNull);
        expect(correctedJump!.chapterIndex, 0);
        expect(correctedJump.localOffset, closeTo(210.0, 0.1));
        expect(correctedJump.reason, ReaderCommandReason.system);
        controller.dispose();
      },
      skip:
          'obsolete: visible placeholder re-anchor belongs to removed scroll-item restore model',
    );

    test(
      'chapter navigation pending 期間會忽略重入',
      () async {
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
        expect(
          controller.retainedSnapshots.single,
          containsAll(<int>{0, 1, 2}),
        );
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
      },
      skip:
          'obsolete: pending chapter navigation lock was removed from reader core',
    );

    test(
      'chapter navigation 會接管正在 loading 的目標章節',
      () async {
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
        controller.loadingChapters.add(2);

        final jump = controller.jumpToChapter(2);
        await Future<void>.delayed(Duration.zero);

        expect(controller.loadRequests, hasLength(1));
        expect(controller.loadRequests.single.chapterIndex, 2);
        expect(controller.pendingChapterNavigationIndex, 2);

        controller.loadCompleter!.complete();
        await jump;

        expect(controller.pendingChapterNavigationIndex, isNull);
        controller.dispose();
      },
      skip:
          'obsolete: loading chapter takeover is covered by ReaderRuntime jump/loading placeholder tests',
    );

    test(
      '底部上一章下一章與滑桿會以實際顯示章節為基準',
      () async {
        final controller = _PendingNavigationReaderProvider(
          book: _makeBook(),
          initialChapters: [
            BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
            BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
            BookChapter(title: 'c2', index: 2, bookUrl: 'http://test.com/book'),
            BookChapter(title: 'c3', index: 3, bookUrl: 'http://test.com/book'),
          ],
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        controller.pageTurnMode = PageAnim.slide;
        controller.slidePages = [
          ..._buildPages(0, [0], title: 'c0'),
          ..._buildPages(1, [0], title: 'c1'),
          ..._buildPages(2, [0], title: 'c2'),
          ..._buildPages(3, [0], title: 'c3'),
        ];
        controller.currentChapterIndex = 0;
        controller.visibleChapterIndex = 0;
        controller.currentPageIndex = 2;

        expect(controller.chapterNavigationIndex, 2);
        controller.onScrubStart();
        expect(controller.scrubIndex, 2);

        final nextJump = controller.nextChapter();
        await Future<void>.delayed(Duration.zero);
        expect(controller.loadRequests.single.chapterIndex, 3);
        controller.loadCompleter!.complete();
        await nextJump;

        controller.loadRequests.clear();
        controller.loadCompleter = Completer<void>();
        controller.currentChapterIndex = 0;
        controller.visibleChapterIndex = 0;
        controller.currentPageIndex = 2;

        final prevJump = controller.prevChapter(fromEnd: false);
        await Future<void>.delayed(Duration.zero);
        expect(controller.loadRequests.single.chapterIndex, 1);
        expect(controller.loadRequests.single.fromEnd, isFalse);
        controller.loadCompleter!.complete();
        await prevJump;

        controller.dispose();
      },
      skip:
          'obsolete: chapter navigation is now driven by ReaderLocation through ReaderRuntime',
    );

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

    test('使用者拖動會取消 pending scroll restore target', () async {
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: List.generate(
          3,
          (index) => BookChapter(
            title: 'c$index',
            index: index,
            bookUrl: 'http://test.com/book',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.registerPendingScrollRestore(chapterIndex: 2, localOffset: 42);

      expect(controller.hasPendingScrollRestore, isTrue);

      controller.cancelPendingScrollRestoreFromUserScroll();

      expect(controller.hasPendingScrollRestore, isFalse);
      controller.dispose();
    });

    test('restore 未完成時 flushNow 不會把暫態 scroll offset 寫成進度', () async {
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: List.generate(
          3,
          (index) => BookChapter(
            title: 'c$index',
            index: index,
            bookUrl: 'http://test.com/book',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.visibleChapterIndex = 1;
      controller.visibleChapterLocalOffset = 0;
      controller.registerPendingScrollRestore(chapterIndex: 1, localOffset: 0);

      await controller.flushNow();

      expect(_FakeBookDao.updates, isEmpty);
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

    test('scroll flush 不會在同一 charOffset 下重寫像素快照', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
      ];
      final book = _makeBook();
      final controller = ReadBookController(
        book: book,
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.chapterPagesCache[0] = _buildSinglePageLinePages(
        0,
        lineCount: 24,
        lineHeight: 20,
        charsPerLine: 20,
        title: 'c0',
      );
      controller.refreshChapterRuntime(0);

      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: 205.0,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
      );
      await controller.persistExitProgress();
      final updateCountAfterExit = _FakeBookDao.updates.length;

      controller.handleVisibleScrollState(
        chapterIndex: 0,
        localOffset: 216.5,
        alignment: 0.0,
        visibleChapterIndexes: const [0],
      );
      await controller.flushNow();

      expect(_FakeBookDao.updates.length, updateCountAfterExit);
      expect(book.chapterIndex, 0);
      expect(book.charOffset, 200);
      expect(book.readerAnchorJson, isNull);
      controller.dispose();
    });

    test('scroll unconfirmed placeholder state 不會覆蓋已確認進度', () async {
      _fakeChaptersFromDao = [
        BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
        BookChapter(title: 'c1', index: 1, bookUrl: 'http://test.com/book'),
      ];
      final controller = ReadBookController(
        book: _makeBook(),
        initialChapters: _fakeChaptersFromDao,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      controller.pageTurnMode = PageAnim.scroll;
      controller.chapterPagesCache[1] = _buildPages(1, [0, 8, 16], title: 'c1');
      controller.refreshChapterRuntime(1);

      final confirmedOffset = controller
          .chapterAt(1)!
          .localOffsetFromCharOffset(16);
      controller.handleVisibleScrollState(
        chapterIndex: 1,
        localOffset: confirmedOffset,
        alignment: 0.0,
        visibleChapterIndexes: const [1],
        isAnchorConfirmed: true,
      );

      await controller.flushNow();
      expect(_FakeBookDao.updates.last.chapterIndex, 1);
      expect(_FakeBookDao.updates.last.pos, 16);

      controller.handleVisibleScrollState(
        chapterIndex: 1,
        localOffset: 0.0,
        alignment: 0.0,
        visibleChapterIndexes: const [1],
        isAnchorConfirmed: false,
      );

      await controller.flushNow();

      expect(_FakeBookDao.updates.last.chapterIndex, 1);
      expect(_FakeBookDao.updates.last.pos, 16);
      expect(
        controller.durableLocation,
        const ReaderLocation(chapterIndex: 1, charOffset: 16),
      );
      controller.dispose();
    });

    test(
      '本地書 scroll 到第十章 10.5 行後退出再進入會還原章內位置',
      () async {
        final book = _makeBookWithOrigin('local');
        final chapters = _buildChapters(12, bookUrl: book.bookUrl);

        await _expectScrollResumeRoundTripAtChapterTen(
          book: book,
          chapters: chapters,
        );
      },
      skip:
          'obsolete: localOffset restore was replaced by ReaderLocation durable restore',
    );

    test(
      '網路書 scroll 到第十章 10.5 行後退出再進入會還原章內位置',
      () async {
        final book = _makeBookWithOrigin('https://source.test');
        final chapters = _buildChapters(
          12,
          bookUrl: book.bookUrl,
          includeContent: true,
        );

        await _expectScrollResumeRoundTripAtChapterTen(
          book: book,
          chapters: chapters,
        );
      },
      skip:
          'obsolete: localOffset restore was replaced by ReaderLocation durable restore',
    );

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

        expect(controller.chapters[1].content, isNull);
        expect(controller.chapterPagesCache.containsKey(1), isFalse);
        expect(controller.chapterAt(1), isNull);
        controller.dispose();
      },
      skip:
          'obsolete: legacy chapter runtime cache invalidation is no longer the reader engine contract',
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
      expect(controller.book.chapterIndex, 0);
      expect(controller.book.charOffset, 18);
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
  }, skip: true);
}
