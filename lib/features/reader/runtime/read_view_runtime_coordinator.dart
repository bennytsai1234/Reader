import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_scroll_viewport_settle_state.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_session_state.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_command.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_viewport_state.dart';

typedef PendingScrollAction =
    ({
      ReaderScrollViewportCommand command,
      int navigationToken,
      int restoreToken,
      bool isRestore,
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
        command: provider.buildScrollViewportCommand(
          chapterIndex: pendingChapterJump.chapterIndex,
          localOffset: pendingChapterJump.localOffset,
          alignment: pendingChapterJump.alignment,
          reason: pendingChapterJump.reason,
        ),
        navigationToken: provider.activeNavigationToken ?? -1,
        restoreToken: -1,
        isRestore: false,
      );
    }

    final pendingRestore = provider.dispatchPendingScrollRestore();
    if (pendingRestore == null) return null;
    return (
      command: provider.buildScrollViewportCommand(
        chapterIndex: pendingRestore.chapterIndex,
        localOffset: pendingRestore.localOffset,
        reason: ReaderCommandReason.restore,
        anchor: pendingRestore.anchor,
      ),
      navigationToken: provider.activeNavigationToken ?? -1,
      restoreToken: pendingRestore.token,
      isRestore: true,
    );
  }

  bool shouldFollowTts(
    ReaderProvider provider, {
    required int lastTtsFollowKey,
    required bool isUserScrolling,
    required bool hasVisibleData,
  }) {
    final followKey = provider.currentTtsPosition?.followKey ?? -1;
    final settleState = resolveScrollViewportSettleState(
      provider,
      hasVisibleData: hasVisibleData,
    );
    return provider.pageTurnMode == PageAnim.scroll &&
        followKey >= 0 &&
        followKey != lastTtsFollowKey &&
        !isUserScrolling &&
        !settleState.shouldSuppressTtsFollow;
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
  }) =>
      resolveScrollViewportSettleState(
        provider,
        hasVisibleData: hasVisibleData,
      ).shouldHoldContent;

  bool shouldSuppressScrollFollow(
    ReaderProvider provider, {
    required bool hasVisibleData,
  }) =>
      resolveScrollViewportSettleState(
        provider,
        hasVisibleData: hasVisibleData,
      ).shouldSuppressTtsFollow;

  ReaderScrollViewportSettleState resolveScrollViewportSettleState(
    ReaderProvider provider, {
    required bool hasVisibleData,
  }) {
    if (provider.pageTurnMode != PageAnim.scroll) {
      return ReaderScrollViewportSettleState.settled;
    }
    if (provider.hasPendingScrollRestore) {
      return ReaderScrollViewportSettleState.pendingRestore;
    }
    if (provider.sessionPhase == ReaderSessionPhase.restoring &&
        (!provider.visibleConfirmed || !hasVisibleData)) {
      return ReaderScrollViewportSettleState.awaitingVisibleConfirmation;
    }
    if (provider.hasActiveNavigation) {
      return ReaderScrollViewportSettleState.pendingNavigation(
        provider.activeCommandReason,
      );
    }
    if (provider.hasPendingVisiblePlaceholderReanchor) {
      return ReaderScrollViewportSettleState.pendingPlaceholderReanchor;
    }
    return ReaderScrollViewportSettleState.settled;
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
