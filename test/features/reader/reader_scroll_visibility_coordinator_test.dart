import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_visibility_coordinator.dart';

void main() {
  group('ReaderScrollVisibilityCoordinator', () {
    test('會為鄰近 current chapter 的可見章節產生 ensure 請求', () {
      final coordinator = ReaderScrollVisibilityCoordinator();

      final update = coordinator.evaluate(
        visibleChapterIndexes: const [2, 3],
        focusChapterIndex: 2,
        hasRuntimeChapter: (_) => false,
        isLoadingChapter: (_) => false,
      );

      expect(update.chaptersToEnsure, [2, 3]);
      expect(update.preloadCenterChapter, 2);
    });

    test('已載入或已請求的章節不會重複要求 ensure', () {
      final coordinator = ReaderScrollVisibilityCoordinator();

      coordinator.evaluate(
        visibleChapterIndexes: const [2, 3],
        focusChapterIndex: 2,
        hasRuntimeChapter: (_) => false,
        isLoadingChapter: (_) => false,
      );

      final second = coordinator.evaluate(
        visibleChapterIndexes: const [2, 3],
        focusChapterIndex: 2,
        hasRuntimeChapter: (chapterIndex) => chapterIndex == 2,
        isLoadingChapter: (_) => false,
      );

      expect(second.chaptersToEnsure, isEmpty);
      expect(second.preloadCenterChapter, isNull);
    });

    test('reconcile 後已完成的章節可從請求集合移除', () {
      final coordinator = ReaderScrollVisibilityCoordinator();

      coordinator.evaluate(
        visibleChapterIndexes: const [1],
        focusChapterIndex: 1,
        hasRuntimeChapter: (_) => false,
        isLoadingChapter: (_) => false,
      );
      coordinator.reconcile((chapterIndex) => chapterIndex == 1);

      final update = coordinator.evaluate(
        visibleChapterIndexes: const [1, 2],
        focusChapterIndex: 1,
        hasRuntimeChapter: (chapterIndex) => chapterIndex == 1,
        isLoadingChapter: (_) => false,
      );

      expect(update.chaptersToEnsure, [2]);
      expect(update.preloadCenterChapter, 1);
    });

    test('preload center 會跟 focus chapter 走，不跟 visible 第一個 sliver 走', () {
      final coordinator = ReaderScrollVisibilityCoordinator();

      final update = coordinator.evaluate(
        visibleChapterIndexes: const [1, 2],
        focusChapterIndex: 2,
        hasRuntimeChapter: (_) => false,
        isLoadingChapter: (_) => false,
      );

      expect(update.preloadCenterChapter, 2);
      expect(update.chaptersToEnsure, [1, 2]);
    });
  });
}
