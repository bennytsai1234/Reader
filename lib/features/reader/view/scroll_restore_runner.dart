import 'package:flutter/widgets.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';

class ScrollRestoreRunner {
  const ScrollRestoreRunner();

  void run({
    required ReaderProvider provider,
    required int chapterIndex,
    required double localOffset,
    required int token,
    required bool Function() isMounted,
    required bool Function() isScrollControllerAttached,
    required void Function() ensureChapterVisible,
    required void Function() deferRestore,
    required VoidCallback cancelRestore,
    required VoidCallback onCompleted,
    required void Function({
      required int chapterIndex,
      required double localOffset,
      required bool animate,
    })
    scrollToChapterLocalOffset,
    required Future<void> Function(int chapterIndex) ensureChapterCached,
    required bool Function(int chapterIndex) hasTargetPageContext,
    int retries = 20,
  }) {
    if (!isMounted() || !provider.matchesPendingScrollRestore(token)) return;
    if (!isScrollControllerAttached()) {
      if (retries <= 0) {
        cancelRestore();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        run(
          provider: provider,
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          token: token,
          isMounted: isMounted,
          isScrollControllerAttached: isScrollControllerAttached,
          ensureChapterVisible: ensureChapterVisible,
          deferRestore: deferRestore,
          cancelRestore: cancelRestore,
          onCompleted: onCompleted,
          scrollToChapterLocalOffset: scrollToChapterLocalOffset,
          ensureChapterCached: ensureChapterCached,
          hasTargetPageContext: hasTargetPageContext,
          retries: retries - 1,
        );
      });
      return;
    }

    final runtimeChapter = provider.chapterAt(chapterIndex);
    final pages = provider.pagesForChapter(chapterIndex);
    if ((runtimeChapter == null && pages.isEmpty) ||
        (runtimeChapter != null && runtimeChapter.isEmpty)) {
      if (provider.loadingChapters.contains(chapterIndex) && retries > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          run(
            provider: provider,
            chapterIndex: chapterIndex,
            localOffset: localOffset,
            token: token,
            isMounted: isMounted,
            isScrollControllerAttached: isScrollControllerAttached,
            ensureChapterVisible: ensureChapterVisible,
            deferRestore: deferRestore,
            cancelRestore: cancelRestore,
            onCompleted: onCompleted,
            scrollToChapterLocalOffset: scrollToChapterLocalOffset,
            ensureChapterCached: ensureChapterCached,
            hasTargetPageContext: hasTargetPageContext,
            retries: retries - 1,
          );
        });
        return;
      }
      if (retries <= 0) {
        if (provider.loadingChapters.contains(chapterIndex)) {
          deferRestore();
        } else {
          cancelRestore();
        }
        return;
      }
      ensureChapterCached(chapterIndex);
      if (retries > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          run(
            provider: provider,
            chapterIndex: chapterIndex,
            localOffset: localOffset,
            token: token,
            isMounted: isMounted,
            isScrollControllerAttached: isScrollControllerAttached,
            ensureChapterVisible: ensureChapterVisible,
            deferRestore: deferRestore,
            cancelRestore: cancelRestore,
            onCompleted: onCompleted,
            scrollToChapterLocalOffset: scrollToChapterLocalOffset,
            ensureChapterCached: ensureChapterCached,
            hasTargetPageContext: hasTargetPageContext,
            retries: retries - 1,
          );
        });
      }
      return;
    }

    ensureChapterVisible();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted() || !provider.matchesPendingScrollRestore(token)) return;
      if (!hasTargetPageContext(chapterIndex)) {
        if (retries > 0) {
          run(
            provider: provider,
            chapterIndex: chapterIndex,
            localOffset: localOffset,
            token: token,
            isMounted: isMounted,
            isScrollControllerAttached: isScrollControllerAttached,
            ensureChapterVisible: ensureChapterVisible,
            deferRestore: deferRestore,
            cancelRestore: cancelRestore,
            onCompleted: onCompleted,
            scrollToChapterLocalOffset: scrollToChapterLocalOffset,
            ensureChapterCached: ensureChapterCached,
            hasTargetPageContext: hasTargetPageContext,
            retries: retries - 1,
          );
        } else if (provider.loadingChapters.contains(chapterIndex)) {
          deferRestore();
        } else {
          cancelRestore();
        }
        return;
      }
      scrollToChapterLocalOffset(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        animate: false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isMounted() || !provider.matchesPendingScrollRestore(token)) {
          return;
        }
        onCompleted();
      });
    });
  }
}
