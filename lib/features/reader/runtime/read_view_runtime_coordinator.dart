import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';

typedef PendingScrollAction =
    ({
      int chapterIndex,
      double localOffset,
      int token,
      bool isRestore,
    });

class ReadViewRuntimeCoordinator {
  const ReadViewRuntimeCoordinator();

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
        token: -1,
        isRestore: false,
      );
    }

    final pendingRestore = provider.consumePendingScrollRestore();
    if (pendingRestore == null) return null;
    return (
      chapterIndex: pendingRestore.chapterIndex,
      localOffset: pendingRestore.localOffset,
      token: provider.pendingScrollRestoreToken,
      isRestore: true,
    );
  }

  bool shouldFollowTts(
    ReaderProvider provider, {
    required int lastTtsScrolledStart,
    required bool isUserScrolling,
  }) {
    return provider.pageTurnMode == PageAnim.scroll &&
        provider.ttsStart >= 0 &&
        provider.ttsStart != lastTtsScrolledStart &&
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
}
