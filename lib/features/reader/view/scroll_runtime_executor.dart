import 'package:flutter/widgets.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'package:legado_reader/features/reader/view/scroll_execution_adapter.dart';
import 'package:legado_reader/features/reader/view/scroll_restore_runner.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ScrollRuntimeExecutor {
  ScrollRuntimeExecutor({
    required this.provider,
    required this.itemScrollController,
    required this.pageKeys,
    required this.scrollExecution,
    required this.scrollRestoreRunner,
    required this.isMounted,
    required this.onRestoreCompleted,
    required this.viewportHeight,
  });

  final ReaderProvider provider;
  final ItemScrollController itemScrollController;
  final Map<String, GlobalKey> pageKeys;
  final ScrollExecutionAdapter scrollExecution;
  final ScrollRestoreRunner scrollRestoreRunner;
  final bool Function() isMounted;
  final VoidCallback onRestoreCompleted;
  final double Function() viewportHeight;

  void scrollToChapterLocalOffset({
    required int chapterIndex,
    required double localOffset,
    bool animate = false,
    Duration duration = Duration.zero,
    double topPadding = 0.0,
  }) {
    scrollExecution.scrollToChapterLocalOffset(
      provider: provider,
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      animate: animate,
      duration: duration,
      topPadding: topPadding,
    );
  }

  void jumpScrollPosition({
    required int chapterIndex,
    required double localOffset,
  }) {
    if (!itemScrollController.isAttached) return;
    itemScrollController.jumpTo(
      index: chapterIndex,
      alignment: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted()) return;
      scrollToChapterLocalOffset(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        animate: false,
      );
    });
  }

  void restoreScrollPosition({
    required int chapterIndex,
    required double localOffset,
    required int token,
    int retries = 20,
  }) {
    scrollRestoreRunner.run(
      provider: provider,
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      token: token,
      retries: retries,
      isMounted: isMounted,
      isScrollControllerAttached: () => itemScrollController.isAttached,
      ensureChapterVisible: () {
        itemScrollController.jumpTo(
          index: chapterIndex,
          alignment: 0,
        );
      },
      completeRestore: () => completeScrollRestore(token),
      scrollToChapterLocalOffset: ({
        required int chapterIndex,
        required double localOffset,
        required bool animate,
      }) {
        scrollToChapterLocalOffset(
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          animate: animate,
        );
      },
      ensureChapterCached: (targetChapterIndex) {
        return provider.ensureChapterCached(
          targetChapterIndex,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        );
      },
      hasTargetPageContext: (targetChapterIndex) {
        final runtimeChapter = provider.chapterAt(targetChapterIndex);
        final pages = provider.pagesForChapter(targetChapterIndex);
        final pageIndex = runtimeChapter != null
            ? runtimeChapter.pageIndexAtLocalOffset(localOffset)
            : ChapterPositionResolver.pageIndexAtLocalOffset(
                pages,
                localOffset,
              );
        return pageKeys['$targetChapterIndex:$pageIndex']?.currentContext !=
            null;
      },
    );
  }

  void completeScrollRestore(int token) {
    if (!isMounted() || !provider.matchesPendingScrollRestore(token)) return;
    onRestoreCompleted();
  }

  void scrollToTtsHighlight() {
    final target = provider.evaluateTtsFollowTarget(
      viewportHeight: viewportHeight(),
    );
    if (target == null) return;
    itemScrollController.scrollTo(
      index: target.chapterIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToChapterLocalOffset(
        chapterIndex: target.chapterIndex,
        localOffset: target.localOffset,
        animate: true,
        duration: const Duration(milliseconds: 160),
        topPadding: target.topPadding,
      );
    });
  }
}
