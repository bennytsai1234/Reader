import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_state.dart';

typedef PendingScrollAction =
    ({
      int chapterIndex,
      double localOffset,
      int navigationToken,
      int restoreToken,
      bool isRestore,
      ReaderCommandReason reason,
    });

class ReadViewRuntimeCoordinator {
  const ReadViewRuntimeCoordinator();

  ReaderViewportState? resolveBlockingViewportState(ReaderProvider provider) {
    return provider.transientViewportState;
  }

  bool shouldRunScrollAutoPage(ReaderProvider provider) {
    return provider.pageTurnMode == PageAnim.scroll &&
        provider.isAutoPaging &&
        !provider.isAutoPagePaused;
  }

  PendingScrollAction? consumePendingScrollAction(ReaderProvider provider) {
    if (provider.pageTurnMode != PageAnim.scroll) return null;

    final pendingChapterJump = provider.consumePendingChapterJump();
    if (pendingChapterJump != null) {
      return (
        chapterIndex: pendingChapterJump.chapterIndex,
        localOffset: pendingChapterJump.localOffset,
        navigationToken: provider.activeNavigationToken ?? -1,
        restoreToken: -1,
        isRestore: false,
        reason: pendingChapterJump.reason,
      );
    }

    final pendingRestore = provider.dispatchPendingScrollRestore();
    if (pendingRestore == null) return null;
    return (
      chapterIndex: pendingRestore.chapterIndex,
      localOffset: pendingRestore.localOffset,
      navigationToken: provider.activeNavigationToken ?? -1,
      restoreToken: pendingRestore.token,
      isRestore: true,
      reason: ReaderCommandReason.restore,
    );
  }

  bool shouldFollowTts(
    ReaderProvider provider, {
    required int lastTtsFollowOffset,
    required bool isUserScrolling,
  }) {
    final followOffset =
        provider.ttsWordStart >= 0 ? provider.ttsWordStart : provider.ttsStart;
    return provider.pageTurnMode == PageAnim.scroll &&
        followOffset >= 0 &&
        followOffset != lastTtsFollowOffset &&
        !isUserScrolling;
  }

  bool shouldWaitForFirstContent(
    ReaderProvider provider, {
    required bool hasVisibleData,
  }) {
    return !hasVisibleData &&
        (provider.lifecycle == ReaderLifecycle.loading ||
            provider.viewSize == null ||
            provider.chapters.isNotEmpty);
  }

  bool shouldHoldScrollUntilRestored(
    ReaderProvider provider, {
    required bool hasVisibleData,
  }) {
    return false;
  }

  bool shouldRestoreSlidePage(ReaderProvider provider) {
    return false;
  }

  ReaderViewportState resolveViewportState(
    ReaderProvider provider, {
    required bool hasVisibleData,
  }) {
    final blockingState = resolveBlockingViewportState(provider);
    if (blockingState != null) {
      return blockingState;
    }
    if (hasVisibleData) {
      return ReaderViewportState.ready;
    }

    if (provider.lifecycle == ReaderLifecycle.loading ||
        provider.viewSize == null ||
        provider.isLoading) {
      return const ReaderViewportState.loading();
    }

    if (provider.chapters.isEmpty) {
      return const ReaderViewportState.message('暫無章節');
    }

    final targetChapterIndex =
        provider.transientViewportChapterIndex ??
        (provider.pageTurnMode == PageAnim.scroll
            ? provider.visibleChapterIndex
            : provider.currentChapterIndex);
    final failureMessage = provider.chapterFailureMessage(targetChapterIndex);
    if (failureMessage != null && failureMessage.trim().isNotEmpty) {
      return ReaderViewportState.message(failureMessage);
    }
    if (provider.isKnownEmptyChapter(targetChapterIndex)) {
      return const ReaderViewportState.message('本章暫無內容');
    }

    return const ReaderViewportState.message('暫無可顯示頁面');
  }
}
