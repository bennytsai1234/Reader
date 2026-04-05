import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/runtime/reader_progress_coordinator.dart';
import 'package:legado_reader/features/reader/runtime/reader_progress_store.dart';

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
  required void Function({
    required int chapterIndex,
    int? pageIndex,
    required ReaderCommandReason reason,
  }) onPersist,
  bool Function()? shouldPersist,
}) {
  final b = book ?? _makeBook();
  return ReaderProgressCoordinator(
    book: () => b,
    chapters: () => [BookChapter(url: 'ch1', title: 'Chapter 1', index: 0)],
    chapterAt: (_) => null,
    pagesForChapter: (_) => const [],
    store: ReaderProgressStore(),
    shouldPersistVisiblePosition: shouldPersist ?? () => true,
    persistCurrentProgress: onPersist,
  );
}

void main() {
  group('ReaderProgressCoordinator', () {
    test('dispose 時取消 scrollSaveTimer，不會觸發 persist', () async {
      var persistCalled = false;
      final coordinator = _makeCoordinator(
        onPersist: ({required chapterIndex, pageIndex, required reason}) {
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
        updateVisible: (_, __, ___) {},
        updateCurrentChapterIndex: (_) {},
      );

      coordinator.dispose();
      await Future.delayed(const Duration(milliseconds: 600));
      expect(persistCalled, isFalse);
    });

    test('isLoading 時不觸發持久化', () {
      var persistCalled = false;
      final coordinator = _makeCoordinator(
        onPersist: ({required chapterIndex, pageIndex, required reason}) {
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
        onPersist: ({required chapterIndex, pageIndex, required reason}) {
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
        updateVisible: (_, __, ___) {},
        updateCurrentChapterIndex: (_) {},
      );

      expect(persistCalled, isFalse);
      coordinator.dispose();
    });

    test('跨章節時立即持久化（不走 debounce）', () {
      var persistCalled = false;
      ReaderCommandReason? persistReason;
      final book = _makeBook()
        ..durChapterIndex = 0
        ..durChapterPos = 0;

      final coordinator = ReaderProgressCoordinator(
        book: () => book,
        chapters: () => [
          BookChapter(url: 'ch0', title: 'C0', index: 0),
          BookChapter(url: 'ch1', title: 'C1', index: 1),
        ],
        chapterAt: (_) => null,
        pagesForChapter: (_) => const [],
        store: ReaderProgressStore(),
        shouldPersistVisiblePosition: () => true,
        persistCurrentProgress: ({
          required chapterIndex,
          pageIndex,
          required reason,
        }) {
          persistCalled = true;
          persistReason = reason;
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
        updateVisible: (_, __, ___) {},
        updateCurrentChapterIndex: (_) {},
      );

      expect(persistCalled, isTrue);
      expect(persistReason, equals(ReaderCommandReason.userScroll));
      coordinator.dispose();
    });

    test('updateScrollPageIndex 正確設定 currentPageIndex 與 currentChapterIndex', () {
      final coordinator = _makeCoordinator(
        onPersist: ({required chapterIndex, pageIndex, required reason}) {},
      );

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
    });
  });
}
