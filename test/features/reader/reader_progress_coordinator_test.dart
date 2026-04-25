import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_coordinator.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';

Book _makeBook() => Book(
  bookUrl: 'http://test.com/book',
  name: 'Test Book',
  author: 'Author',
  origin: 'local',
  durChapterIndex: 0,
  durChapterPos: 0,
);

ReaderProgressCoordinator _makeCoordinator({
  Book? book,
  Future<void> Function(ReaderLocation location)? onPersistLocation,
  bool Function()? shouldPersist,
  List<TextPage> Function(int chapterIndex)? pagesForChapter,
}) {
  final b = book ?? _makeBook();
  return ReaderProgressCoordinator(
    chapterAt: (_) => null,
    pagesForChapter: pagesForChapter ?? (_) => const [],
    store: ReaderProgressStore(),
    durableLocation:
        () => ReaderLocation(
          chapterIndex: b.durChapterIndex,
          charOffset: b.durChapterPos,
        ),
    shouldPersistVisiblePosition: shouldPersist ?? () => true,
    updateVisibleLocation: (_) {},
    updateCommittedLocation: (_) {},
    persistLocation: onPersistLocation ?? (_) async {},
  );
}

List<TextPage> _buildScrollPages() => [
  TextPage(
    index: 0,
    title: 'c0',
    chapterIndex: 0,
    pageSize: 1,
    lines: [
      TextLine(
        text: 'line',
        width: 200,
        height: 20,
        chapterPosition: 48,
        lineTop: 0,
        lineBottom: 24,
        paragraphNum: 0,
        isParagraphEnd: true,
      ),
    ],
  ),
];

void main() {
  group('ReaderProgressCoordinator', () {
    test(
      'updateVisibleChapterPosition 會更新 session location，不直接依賴 book 作為暫時位置',
      () {
        ReaderLocation? committedLocation;
        final book =
            _makeBook()
              ..durChapterIndex = 0
              ..durChapterPos = 0;

        final coordinator = ReaderProgressCoordinator(
          chapterAt: (_) => null,
          pagesForChapter: (_) => const [],
          store: ReaderProgressStore(),
          durableLocation:
              () => ReaderLocation(
                chapterIndex: book.durChapterIndex,
                charOffset: book.durChapterPos,
              ),
          shouldPersistVisiblePosition: () => true,
          updateVisibleLocation: (_) {},
          updateCommittedLocation: (location) => committedLocation = location,
          persistLocation: (_) async {},
        );

        coordinator.updateVisibleChapterPosition(
          chapterIndex: 0,
          localOffset: 120.0,
          alignment: 0.0,
          pageTurnMode: PageAnim.scroll,
          isLoading: false,
          currentPageIndex: 0,
          allowProgressCommit: true,
          updateVisible: (_, __, ___) {},
          updateCurrentChapterIndex: (_) {},
        );

        expect(committedLocation, isNotNull);
        expect(committedLocation!.chapterIndex, 0);
        expect(book.durChapterPos, 0);
        coordinator.dispose();
      },
    );

    test('dispose 時取消 scrollSaveTimer，不會觸發 persist', () async {
      var persistCalled = false;
      final coordinator = _makeCoordinator(
        onPersistLocation: (_) async {
          persistCalled = true;
        },
      );

      coordinator.updateVisibleChapterPosition(
        chapterIndex: 0,
        localOffset: 100.0,
        alignment: 0.0,
        pageTurnMode: PageAnim.scroll,
        isLoading: false,
        currentPageIndex: 0,
        allowProgressCommit: true,
        updateVisible: (_, __, ___) {},
        updateCurrentChapterIndex: (_) {},
      );

      coordinator.dispose();
      await Future.delayed(const Duration(milliseconds: 600));
      expect(persistCalled, isFalse);
    });

    test('flushPendingProgress 會寫出 debounce 中的最後位置', () async {
      final book =
          _makeBook()
            ..durChapterIndex = 0
            ..durChapterPos = 20;
      final store = ReaderProgressStore();
      await store.persistCharOffset(
        write: (_, __, ___, ____) async {},
        book: book,
        chapters: [
          BookChapter(title: 'c0', index: 0, bookUrl: 'http://test.com/book'),
        ],
        chapterIndex: 0,
        charOffset: 20,
      );

      ReaderLocation? persistedLocation;
      final coordinator = ReaderProgressCoordinator(
        chapterAt: (_) => null,
        pagesForChapter: (_) => _buildScrollPages(),
        store: store,
        durableLocation:
            () => ReaderLocation(
              chapterIndex: book.durChapterIndex,
              charOffset: book.durChapterPos,
            ),
        shouldPersistVisiblePosition: () => true,
        updateVisibleLocation: (_) {},
        updateCommittedLocation: (_) {},
        persistLocation: (location) async {
          persistedLocation = location;
        },
      );

      coordinator.updateVisibleChapterPosition(
        chapterIndex: 0,
        localOffset: 100.0,
        alignment: 0.0,
        pageTurnMode: PageAnim.scroll,
        isLoading: false,
        currentPageIndex: 0,
        allowProgressCommit: true,
        updateVisible: (_, __, ___) {},
        updateCurrentChapterIndex: (_) {},
      );

      final flushed = await coordinator.flushPendingProgress();

      expect(flushed, isNotNull);
      expect(flushed!.chapterIndex, 0);
      expect(flushed.charOffset, 52);
      expect(persistedLocation, flushed);
      coordinator.dispose();
    });

    test('isLoading 時不觸發持久化', () {
      var persistCalled = false;
      final coordinator = _makeCoordinator(
        onPersistLocation: (_) async {
          persistCalled = true;
        },
      );

      coordinator.updateVisibleChapterPosition(
        chapterIndex: 0,
        localOffset: 50.0,
        alignment: 0.0,
        pageTurnMode: PageAnim.scroll,
        isLoading: true,
        currentPageIndex: 0,
        allowProgressCommit: true,
        updateVisible: (_, __, ___) {},
        updateCurrentChapterIndex: (_) {},
      );

      expect(persistCalled, isFalse);
      coordinator.dispose();
    });

    test('shouldPersistVisiblePosition 為 false 時不持久化', () {
      var persistCalled = false;
      final coordinator = _makeCoordinator(
        shouldPersist: () => false,
        onPersistLocation: (_) async {
          persistCalled = true;
        },
      );

      coordinator.updateVisibleChapterPosition(
        chapterIndex: 0,
        localOffset: 50.0,
        alignment: 0.0,
        pageTurnMode: PageAnim.scroll,
        isLoading: false,
        currentPageIndex: 0,
        allowProgressCommit: true,
        updateVisible: (_, __, ___) {},
        updateCurrentChapterIndex: (_) {},
      );

      expect(persistCalled, isFalse);
      coordinator.dispose();
    });

    test('不允許 progress commit 時只更新 UI 暫態，不寫 session progress', () async {
      int? transientChapterIndex;
      double? transientLocalOffset;
      double? transientAlignment;
      ReaderLocation? visibleLocation;
      ReaderLocation? committedLocation;
      ReaderLocation? persistedLocation;
      var persistCalled = false;

      final coordinator = ReaderProgressCoordinator(
        chapterAt: (_) => null,
        pagesForChapter: (_) => _buildScrollPages(),
        store: ReaderProgressStore(),
        durableLocation:
            () => const ReaderLocation(chapterIndex: 0, charOffset: 0),
        shouldPersistVisiblePosition: () => true,
        updateVisibleLocation: (location) => visibleLocation = location,
        updateCommittedLocation: (location) => committedLocation = location,
        persistLocation: (location) async {
          persistedLocation = location;
          persistCalled = true;
        },
      );

      coordinator.updateVisibleChapterPosition(
        chapterIndex: 0,
        localOffset: 50.0,
        alignment: 0.0,
        pageTurnMode: PageAnim.scroll,
        isLoading: false,
        currentPageIndex: 0,
        allowProgressCommit: false,
        updateVisible: (chapterIndex, localOffset, alignment) {
          transientChapterIndex = chapterIndex;
          transientLocalOffset = localOffset;
          transientAlignment = alignment;
        },
        updateCurrentChapterIndex: (_) {},
      );

      await Future.delayed(const Duration(milliseconds: 600));

      expect(transientChapterIndex, 0);
      expect(transientLocalOffset, 50.0);
      expect(transientAlignment, 0.0);
      expect(visibleLocation, isNull);
      expect(committedLocation, isNull);
      expect(persistedLocation, isNull);
      expect(persistCalled, isFalse);
      coordinator.dispose();
    });

    test('跨章節時立即持久化（不走 debounce）', () {
      var persistCalled = false;
      final book =
          _makeBook()
            ..durChapterIndex = 0
            ..durChapterPos = 0;

      final coordinator = ReaderProgressCoordinator(
        chapterAt: (_) => null,
        pagesForChapter: (_) => const [],
        store: ReaderProgressStore(),
        durableLocation:
            () => ReaderLocation(
              chapterIndex: book.durChapterIndex,
              charOffset: book.durChapterPos,
            ),
        shouldPersistVisiblePosition: () => true,
        updateVisibleLocation: (_) {},
        updateCommittedLocation: (_) {},
        persistLocation: (_) async {
          persistCalled = true;
        },
      );

      // 切到第 1 章 → 跨章節，應立即持久化
      coordinator.updateVisibleChapterPosition(
        chapterIndex: 1,
        localOffset: 0.0,
        alignment: 0.0,
        pageTurnMode: PageAnim.scroll,
        isLoading: false,
        currentPageIndex: 0,
        allowProgressCommit: true,
        updateVisible: (_, __, ___) {},
        updateCurrentChapterIndex: (_) {},
      );

      expect(persistCalled, isTrue);
      coordinator.dispose();
    });

    test(
      'updateScrollPageIndex 正確設定 currentPageIndex 與 currentChapterIndex',
      () {
        final coordinator = _makeCoordinator(onPersistLocation: (_) async {});

        int setPage = -1;
        int setVisible = -1;
        int setCurrent = -1;

        coordinator.updateScrollPageIndex(
          chapterIndex: 2,
          localOffset: 0.0,
          setCurrentPageIndex: (i) => setPage = i,
          setVisibleChapterIndex: (i) => setVisible = i,
          setCurrentChapterIndex: (i) => setCurrent = i,
        );

        expect(setVisible, equals(2));
        expect(setCurrent, equals(2));
        // 空頁面 → pageIndex = 0
        expect(setPage, equals(0));
        coordinator.dispose();
      },
    );
  });
}
