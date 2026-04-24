import 'package:flutter/widgets.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/view/scroll_execution_adapter.dart';
import 'package:inkpage_reader/features/reader/view/scroll_restore_runner.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ScrollRuntimeExecutor {
  ScrollRuntimeExecutor({
    required this.provider,
    required this.itemScrollController,
    required this.pageKeys,
    required this.scrollExecution,
    required this.scrollRestoreRunner,
    required this.isMounted,
    required this.viewportHeight,
  });

  final ReaderProvider provider;
  final ItemScrollController itemScrollController;
  final Map<String, GlobalKey> pageKeys;
  final ScrollExecutionAdapter scrollExecution;
  final ScrollRestoreRunner scrollRestoreRunner;
  final bool Function() isMounted;
  final double Function() viewportHeight;
  int _jumpGeneration = 0;

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
    VoidCallback? onCompleted,
    int retries = 20,
  }) {
    final generation = ++_jumpGeneration;
    _runScrollJump(
      generation: generation,
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      retries: retries,
      onCompleted: onCompleted,
    );
  }

  void restoreScrollPosition({
    required int chapterIndex,
    required double localOffset,
    required int token,
    required int navigationToken,
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
        itemScrollController.jumpTo(index: chapterIndex, alignment: 0);
      },
      deferRestore: () => provider.deferPendingScrollRestore(token),
      cancelRestore:
          () => provider.abortNavigation(
            navigationToken,
            ReaderCommandReason.restore,
          ),
      onCompleted: () {},
      scrollToChapterLocalOffset: ({
        required int chapterIndex,
        required double localOffset,
        required bool animate,
      }) {
        scrollToChapterLocalOffset(
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          animate: animate,
          topPadding: provider.scrollRestoreAnchorPadding,
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
        final pageIndex =
            runtimeChapter != null
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

  void _runScrollJump({
    required int generation,
    required int chapterIndex,
    required double localOffset,
    required int retries,
    VoidCallback? onCompleted,
  }) {
    if (!isMounted() || generation != _jumpGeneration) return;
    if (!itemScrollController.isAttached) {
      if (retries <= 0) {
        onCompleted?.call();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runScrollJump(
          generation: generation,
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          retries: retries - 1,
          onCompleted: onCompleted,
        );
      });
      return;
    }

    final runtimeChapter = provider.chapterAt(chapterIndex);
    final pages = provider.pagesForChapter(chapterIndex);
    if ((runtimeChapter == null && pages.isEmpty) ||
        (runtimeChapter != null && runtimeChapter.isEmpty)) {
      if (retries <= 0) {
        onCompleted?.call();
        return;
      }
      provider.ensureChapterCached(
        chapterIndex,
        silent: false,
        prioritize: true,
        preloadRadius: 1,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runScrollJump(
          generation: generation,
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          retries: retries - 1,
          onCompleted: onCompleted,
        );
      });
      return;
    }

    itemScrollController.jumpTo(index: chapterIndex, alignment: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted() || generation != _jumpGeneration) return;
      if (!_hasTargetPageContext(chapterIndex, localOffset)) {
        if (retries <= 0) {
          onCompleted?.call();
          return;
        }
        _runScrollJump(
          generation: generation,
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          retries: retries - 1,
          onCompleted: onCompleted,
        );
        return;
      }
      scrollToChapterLocalOffset(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        animate: false,
        topPadding: 0.0,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isMounted() || generation != _jumpGeneration) return;
        onCompleted?.call();
      });
    });
  }

  bool _hasTargetPageContext(int chapterIndex, double localOffset) {
    final runtimeChapter = provider.chapterAt(chapterIndex);
    final pages = provider.pagesForChapter(chapterIndex);
    final pageIndex =
        runtimeChapter != null
            ? runtimeChapter.pageIndexAtLocalOffset(localOffset)
            : ChapterPositionResolver.pageIndexAtLocalOffset(
              pages,
              localOffset,
            );
    return pageKeys['$chapterIndex:$pageIndex']?.currentContext != null;
  }

  void scrollToTtsHighlight() {
    final target = provider.evaluateTtsFollowTarget(
      viewportHeight: viewportHeight(),
    );
    if (target == null) return;
    final command = provider.buildScrollViewportCommand(
      chapterIndex: target.chapterIndex,
      localOffset: target.localOffset,
      reason: ReaderCommandReason.tts,
    );
    itemScrollController.scrollTo(
      index: command.target.chapterIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToChapterLocalOffset(
        chapterIndex: command.target.chapterIndex,
        localOffset: command.target.localOffset,
        animate: true,
        duration: const Duration(milliseconds: 160),
        topPadding: target.topPadding,
      );
    });
  }
}
