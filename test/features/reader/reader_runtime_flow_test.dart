import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:legado_reader/features/reader/runtime/reader_navigation_controller.dart';
import 'package:legado_reader/features/reader/runtime/reader_progress_coordinator.dart';
import 'package:legado_reader/features/reader/runtime/reader_progress_store.dart';
import 'package:legado_reader/features/reader/runtime/reader_restore_coordinator.dart';
import 'package:legado_reader/features/reader/runtime/reader_scroll_visibility_coordinator.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/provider/content_callbacks.dart';

class _FakeBookDao implements BookDao {
  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos,
  ) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChapterDao implements ChapterDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeReplaceRuleDao implements ReplaceRuleDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookSourceDao implements BookSourceDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookmarkDao implements BookmarkDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void _setupReaderRuntimeTestDi() {
  if (getIt.isRegistered<BookDao>()) {
    getIt.unregister<BookDao>();
  }
  if (getIt.isRegistered<ChapterDao>()) {
    getIt.unregister<ChapterDao>();
  }
  if (getIt.isRegistered<ReplaceRuleDao>()) {
    getIt.unregister<ReplaceRuleDao>();
  }
  if (getIt.isRegistered<BookSourceDao>()) {
    getIt.unregister<BookSourceDao>();
  }
  if (getIt.isRegistered<BookmarkDao>()) {
    getIt.unregister<BookmarkDao>();
  }

  getIt.registerLazySingleton<BookDao>(() => _FakeBookDao());
  getIt.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
  getIt.registerLazySingleton<ReplaceRuleDao>(() => _FakeReplaceRuleDao());
  getIt.registerLazySingleton<BookSourceDao>(() => _FakeBookSourceDao());
  getIt.registerLazySingleton<BookmarkDao>(() => _FakeBookmarkDao());
}

class _ReaderRuntimeHarness extends ReaderProviderBase
    with ReaderSettingsMixin, ReaderContentMixin {
  final ReaderProgressStore _store = ReaderProgressStore();
  late final ReaderProgressCoordinator _progressCoordinator;
  final Map<int, ReaderChapter> _runtimeChapters = {};
  final List<({
    int chapterIndex,
    int pageIndex,
    ReaderCommandReason reason,
  })> persistedRequests = [];

  ({
    int chapterIndex,
    double localOffset,
    double alignment,
    ReaderCommandReason reason,
  })? lastChapterJump;
  int? lastSlideJump;
  ReaderCommandReason? lastSlideJumpReason;
  bool persistVisiblePosition = true;

  _ReaderRuntimeHarness({
    required Book book,
    required List<BookChapter> chapters,
  }) : super(book) {
    this.chapters = chapters;
    _progressCoordinator = ReaderProgressCoordinator(
      book: () => this.book,
      chapters: () => this.chapters,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      store: _store,
      shouldPersistVisiblePosition: () => persistVisiblePosition,
      persistCurrentProgress: ({
        required chapterIndex,
        pageIndex,
        required reason,
      }) =>
          persistCurrentProgress(
            chapterIndex: chapterIndex,
            pageIndex: pageIndex,
            reason: reason,
          ),
    );
    contentCallbacks = ContentCallbacks(
      refreshChapterRuntime: (_) {},
      buildSlideRuntimePages: () => buildSlideRuntimePages() as List<dynamic>? ?? [],
      jumpToSlidePage: (pageIndex, {required reason}) =>
          jumpToSlidePage(pageIndex, reason: reason as ReaderCommandReason),
      jumpToChapterLocalOffset: ({
        required chapterIndex,
        required localOffset,
        required alignment,
        required reason,
      }) =>
          jumpToChapterLocalOffset(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        alignment: alignment,
        reason: reason as ReaderCommandReason,
      ),
      jumpToChapterCharOffset: ({
        required chapterIndex,
        required charOffset,
        required reason,
        bool isRestoringJump = false,
      }) =>
          jumpToChapterCharOffset(
        chapterIndex: chapterIndex,
        charOffset: charOffset,
        reason: reason as ReaderCommandReason,
        isRestoringJump: isRestoringJump,
      ),
      chapterAt: (index) => chapterAt(index),
      pagesForChapter: (index) => pagesForChapter(index),
      progressStore: _store,
      shouldPersistVisiblePosition: () => persistVisiblePosition,
      persistCurrentProgress: ({
        required chapterIndex,
        int? pageIndex,
        required reason,
      }) =>
          persistCurrentProgress(
        chapterIndex: chapterIndex,
        pageIndex: pageIndex,
        reason: reason as ReaderCommandReason,
      ),
    );
  }

  ReaderProgressStore get progressStore => _store;

  ReaderChapter? chapterAt(int index) => _runtimeChapters[index];

  List<TextPage> pagesForChapter(int index) =>
      _runtimeChapters[index]?.pages ??
      chapterPagesCache[index] ??
      const <TextPage>[];

  void setChapterPages(int index, List<TextPage> pages) {
    chapterPagesCache[index] = pages;
    _runtimeChapters[index] = ReaderChapter(
      chapter: chapters[index],
      index: index,
      title: chapters[index].title,
      pages: pages,
    );
  }

  void setSlidePages(List<TextPage> pages) {
    slidePages = pages;
  }

  List<TextPage>? buildSlideRuntimePages() => null;

  bool shouldPersistVisiblePosition() => persistVisiblePosition;

  void jumpToSlidePage(
    int pageIndex, {
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    lastSlideJump = pageIndex;
    lastSlideJumpReason = reason;
    requestJumpToPage(pageIndex, reason: reason);
  }

  void jumpToChapterLocalOffset({
    required int chapterIndex,
    required double localOffset,
    double alignment = 0.0,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    lastChapterJump = (
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      alignment: alignment,
      reason: reason,
    );
    requestJumpToChapter(
      chapterIndex: chapterIndex,
      alignment: alignment,
      localOffset: localOffset,
      reason: reason,
    );
  }

  void jumpToChapterCharOffset({
    required int chapterIndex,
    required int charOffset,
    ReaderCommandReason reason = ReaderCommandReason.system,
    bool isRestoringJump = false,
  }) {
    jumpToPosition(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
      isRestoringJump: isRestoringJump,
    );
  }

  void persistCurrentProgress({
    required int chapterIndex,
    int? pageIndex,
    ReaderCommandReason reason = ReaderCommandReason.system,
  }) {
    persistedRequests.add(
      (
        chapterIndex: chapterIndex,
        pageIndex: pageIndex ?? currentPageIndex,
        reason: reason,
      ),
    );
  }

  void jumpToPosition({
    int? chapterIndex,
    int? charOffset,
    int? pageIndex,
    bool isRestoringJump = false,
  }) {
    final targetChapter = chapterIndex ?? currentChapterIndex;
    if (pageTurnMode == PageAnim.scroll) {
      final pages = pagesForChapter(targetChapter);
      final targetCharOffset = charOffset ?? 0;
      final localOffset = ChapterPositionResolver.charOffsetToLocalOffset(
          pages, targetCharOffset);
      final alignment = ChapterPositionResolver.charOffsetToAlignment(
          pages, targetCharOffset);
      jumpToChapterLocalOffset(
        chapterIndex: targetChapter,
        localOffset: localOffset,
        alignment: alignment,
        reason: isRestoringJump
            ? ReaderCommandReason.restore
            : ReaderCommandReason.system,
      );
      notifyListeners();
      return;
    }
    final pages = pagesForChapter(targetChapter);
    var targetPage = 0;
    if (charOffset != null && charOffset > 0) {
      final localPageIndex = ChapterPositionResolver.findPageIndexByCharOffset(
          pages, charOffset);
      final globalIndex = slidePages.indexWhere(
        (page) =>
            page.chapterIndex == targetChapter && page.index == localPageIndex,
      );
      targetPage = globalIndex >= 0 ? globalIndex : 0;
    } else if (pageIndex != null && slidePages.isNotEmpty) {
      targetPage = pageIndex.clamp(0, slidePages.length - 1);
    }
    currentPageIndex = targetPage;
    jumpToSlidePage(
      targetPage,
      reason: isRestoringJump
          ? ReaderCommandReason.restore
          : ReaderCommandReason.system,
    );
    notifyListeners();
  }

  void updateVisibleChapterPosition({
    required int chapterIndex,
    required double localOffset,
    double alignment = 0.0,
  }) {
    _progressCoordinator.updateVisibleChapterPosition(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      alignment: alignment,
      pageTurnMode: pageTurnMode,
      isLoading: isLoading,
      currentPageIndex: currentPageIndex,
      updateVisible: (ci, lo, al) {
        visibleChapterIndex = ci;
        visibleChapterLocalOffset = lo;
        visibleChapterAlignment = al;
      },
      updateCurrentChapterIndex: (ci) => currentChapterIndex = ci,
    );
  }
}

List<TextPage> _buildPages(
  int chapterIndex,
  List<int> pageStarts, {
  String title = 'chapter',
}) {
  return List.generate(pageStarts.length, (pageIndex) {
    final start = pageStarts[pageIndex];
    final nextStart = pageIndex + 1 < pageStarts.length
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

void main() {
  setUpAll(_setupReaderRuntimeTestDi);

  ReaderChapter makeChapter() {
    return ReaderChapter(
      chapter: BookChapter(title: 'chapter', index: 0),
      index: 0,
      title: 'chapter',
      pages: [
        TextPage(
          index: 0,
          title: 'chapter',
          chapterIndex: 0,
          pageSize: 2,
          lines: [
            TextLine(
              text: 'AAAA',
              width: 100,
              height: 20,
              chapterPosition: 0,
              lineTop: 0,
              lineBottom: 20,
              paragraphNum: 1,
            ),
            TextLine(
              text: 'BBBB',
              width: 100,
              height: 20,
              chapterPosition: 4,
              lineTop: 20,
              lineBottom: 40,
              paragraphNum: 1,
              isParagraphEnd: true,
            ),
          ],
        ),
      ],
    );
  }

  group('Reader runtime flow', () {
    test('restore command 會抑制 visible progress 並保留 restore target', () {
      final navigation = ReaderNavigationController();
      final restore = ReaderRestoreCoordinator();

      expect(navigation.beginChapterJump(ReaderCommandReason.restore), isTrue);
      expect(navigation.shouldPersistVisiblePosition(DateTime.now()), isFalse);

      final token = restore.registerPendingScrollRestore(
        chapterIndex: 2,
        localOffset: 88,
      );

      expect(restore.matchesPendingScrollRestore(token), isTrue);
      final target = restore.consumePendingScrollRestore();
      expect(target, isNotNull);
      expect(target!.chapterIndex, 2);
      expect(target.localOffset, 88);
    });

    test('auto page step 與 visible preload 會共享同一個 top chapter', () {
      final navigation = ReaderNavigationController();
      final visibility = ReaderScrollVisibilityCoordinator();
      final chapter = makeChapter();

      final step = navigation.evaluateScrollAutoPageStep(
        isAutoPaging: true,
        isAutoPagePaused: false,
        isLoading: false,
        pageTurnMode: PageAnim.scroll,
        viewSize: const Size(300, 500),
        visibleChapterIndex: 1,
        visibleChapterLocalOffset: 0,
        scrollDeltaPerFrame: (_, __) => 12,
        chapterAt: (_) => chapter,
        pagesForChapter: (_) => chapter.pages,
        dtSeconds: 0.016,
      );
      final update = visibility.evaluate(
        visibleChapterIndexes: const [1, 2],
        currentChapterIndex: 1,
        hasRuntimeChapter: (_) => false,
        isLoadingChapter: (_) => false,
      );

      expect(step, isNotNull);
      expect(step!.chapterIndex, 1);
      expect(update.preloadCenterChapter, 1);
      expect(update.chaptersToEnsure, [1, 2]);
    });

    test('user command 可以打斷 autoPage 與 tts command', () {
      final navigation = ReaderNavigationController();

      expect(navigation.beginSlideJump(ReaderCommandReason.autoPage), isTrue);
      expect(navigation.beginChapterJump(ReaderCommandReason.user), isTrue);
      expect(navigation.activeCommandReason, ReaderCommandReason.user);

      navigation.clear(ReaderCommandReason.user);

      expect(navigation.beginChapterJump(ReaderCommandReason.tts), isTrue);
      expect(navigation.beginChapterJump(ReaderCommandReason.user), isTrue);
      expect(navigation.activeCommandReason, ReaderCommandReason.user);
    });

    test('scroll restore 會還原到指定 chapterIndex 與 localOffset', () {
      final harness = _ReaderRuntimeHarness(
        book: Book(bookUrl: 'book', name: 'Book'),
        chapters: [
          BookChapter(title: 'c0', index: 0, bookUrl: 'book'),
          BookChapter(title: 'c1', index: 1, bookUrl: 'book'),
        ],
      );
      harness.pageTurnMode = PageAnim.scroll;
      harness.currentChapterIndex = 1;
      harness.setChapterPages(1, _buildPages(1, [0, 8, 16], title: 'c1'));
      final expectedLocalOffset =
          harness.chapterAt(1)!.localOffsetFromCharOffset(9);
      final expectedAlignment = harness.chapterAt(1)!.alignmentForCharOffset(9);

      harness.jumpToPosition(
        chapterIndex: 1,
        charOffset: 9,
        isRestoringJump: true,
      );

      expect(harness.lifecycle, ReaderLifecycle.loading);
      expect(harness.lastChapterJump, isNotNull);
      expect(harness.lastChapterJump!.chapterIndex, 1);
      expect(harness.lastChapterJump!.localOffset, expectedLocalOffset);
      expect(harness.lastChapterJump!.alignment, expectedAlignment);
      expect(harness.lastChapterJump!.reason, ReaderCommandReason.restore);
    });

    test('slide restore 會導向指定 pageIndex', () {
      final harness = _ReaderRuntimeHarness(
        book: Book(bookUrl: 'book', name: 'Book'),
        chapters: [
          BookChapter(title: 'c0', index: 0, bookUrl: 'book'),
          BookChapter(title: 'c1', index: 1, bookUrl: 'book'),
        ],
      );
      harness.pageTurnMode = PageAnim.slide;
      harness.setChapterPages(0, _buildPages(0, [0], title: 'c0'));
      harness.setChapterPages(1, _buildPages(1, [0, 8, 16], title: 'c1'));
      harness.setSlidePages([
        ...harness.pagesForChapter(0),
        ...harness.pagesForChapter(1),
      ]);

      harness.jumpToPosition(
        chapterIndex: 1,
        pageIndex: 2,
        isRestoringJump: true,
      );

      expect(harness.currentPageIndex, 2);
      expect(harness.lastSlideJump, 2);
      expect(harness.lastSlideJumpReason, ReaderCommandReason.restore);
      expect(harness.consumePendingSlidePageIndex(), 2);
    });

    test('repaginate 後 restore 仍以 charOffset 對齊，不會漂移到舊 pageIndex', () {
      final harness = _ReaderRuntimeHarness(
        book: Book(bookUrl: 'book', name: 'Book', durChapterPos: 12),
        chapters: [
          BookChapter(title: 'c1', index: 0, bookUrl: 'book'),
        ],
      );
      harness.pageTurnMode = PageAnim.slide;
      harness.currentChapterIndex = 0;
      harness.setChapterPages(0, _buildPages(0, [0, 10], title: 'c1'));
      harness.setSlidePages(harness.pagesForChapter(0));

      harness.jumpToPosition(
        chapterIndex: 0,
        charOffset: 12,
        isRestoringJump: true,
      );
      final firstPageTarget = harness.lastSlideJump;

      harness.setChapterPages(0, _buildPages(0, [0, 6, 12], title: 'c1'));
      harness.setSlidePages(harness.pagesForChapter(0));
      harness.jumpToPosition(
        chapterIndex: 0,
        charOffset: 12,
        isRestoringJump: true,
      );

      expect(firstPageTarget, 1);
      expect(harness.lastSlideJump, 2);
      expect(harness.book.durChapterPos, 12);
    });

    test('restore 期間 updateVisibleChapterPosition 不會寫 visible progress', () {
      final harness = _ReaderRuntimeHarness(
        book: Book(
          bookUrl: 'book',
          name: 'Book',
          durChapterIndex: 0,
          durChapterPos: 0,
        ),
        chapters: [
          BookChapter(title: 'c0', index: 0, bookUrl: 'book'),
        ],
      );
      harness.pageTurnMode = PageAnim.scroll;
      harness.persistVisiblePosition = false;
      harness.setChapterPages(0, _buildPages(0, [0, 8], title: 'c0'));

      harness.updateVisibleChapterPosition(
        chapterIndex: 0,
        localOffset: 20,
        alignment: 0.0,
      );

      expect(harness.book.durChapterIndex, 0);
      expect(harness.book.durChapterPos, 0);
      expect(harness.persistedRequests, isEmpty);
    });

    test('slide refresh 在切章期間會優先落到 pinned target，不會 remap 回舊章頁面', () {
      final harness = _ReaderRuntimeHarness(
        book: Book(bookUrl: 'book', name: 'Book'),
        chapters: [
          BookChapter(title: 'c0', index: 0, bookUrl: 'book'),
          BookChapter(title: 'c1', index: 1, bookUrl: 'book'),
          BookChapter(title: 'c2', index: 2, bookUrl: 'book'),
        ],
      );
      harness.pageTurnMode = PageAnim.slide;
      harness.setChapterPages(0, _buildPages(0, [0, 8], title: 'c0'));
      harness.setChapterPages(1, _buildPages(1, [0, 8], title: 'c1'));
      harness.setChapterPages(2, _buildPages(2, [0, 8], title: 'c2'));
      harness.setSlidePages([
        ...harness.pagesForChapter(0),
        ...harness.pagesForChapter(1),
      ]);

      harness.currentPageIndex = 1;
      harness.currentChapterIndex = 1;

      harness.refreshSlidePagesForTesting(
        anchorChapterIndex: 1,
        charOffset: 0,
      );

      expect(harness.slidePages[harness.currentPageIndex].chapterIndex, 1);
      expect(harness.slidePages[harness.currentPageIndex].index, 0);
      expect(harness.currentPageIndex, 2);
    });
  });
}
