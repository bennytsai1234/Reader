import 'dart:async';

import 'reader_content_facade_mixin.dart';
import 'reader_provider_base.dart';

mixin ReaderChapterNavigationMixin
    on ReaderProviderBase, ReaderContentFacadeMixin {
  int? _pendingChapterNavigationIndex;
  bool isScrubbing = false;
  int scrubIndex = 0;

  int resolveScrubChapterIndexForNavigation(dynamic value);
  Future<void> performChapterNavigation({
    required int targetIndex,
    required ReaderCommandReason reason,
    bool fromEnd = false,
  });

  int? get pendingChapterNavigationIndex => _pendingChapterNavigationIndex;
  bool get hasPendingChapterNavigation =>
      _pendingChapterNavigationIndex != null;
  bool get canNavigateToPrevChapter =>
      currentChapterIndex > 0 && !hasPendingChapterNavigation;
  bool get canNavigateToNextChapter =>
      currentChapterIndex < chapters.length - 1 && !hasPendingChapterNavigation;

  void onScrubStart() {
    if (hasPendingChapterNavigation) return;
    isScrubbing = true;
    scrubIndex = currentChapterIndex;
    notifyListeners();
  }

  void onScrubbing(dynamic value) {
    if (hasPendingChapterNavigation) return;
    final targetIndex = resolveScrubChapterIndexForNavigation(value);
    if (scrubIndex != targetIndex) {
      scrubIndex = targetIndex;
      notifyListeners();
    }
  }

  void onScrubEnd(dynamic value) {
    isScrubbing = false;
    final targetIndex = resolveScrubChapterIndexForNavigation(value);
    unawaited(jumpToChapter(targetIndex));
    notifyListeners();
  }

  void _setPendingChapterNavigation(int targetIndex) {
    if (_pendingChapterNavigationIndex == targetIndex) return;
    _pendingChapterNavigationIndex = targetIndex;
    notifyListeners();
  }

  void _clearPendingChapterNavigation({int? targetIndex}) {
    if (targetIndex != null && _pendingChapterNavigationIndex != targetIndex) {
      return;
    }
    if (_pendingChapterNavigationIndex == null) return;
    _pendingChapterNavigationIndex = null;
    if (!isDisposed) {
      notifyListeners();
    }
  }

  Future<void> _navigateToChapter({
    required int targetIndex,
    required ReaderCommandReason reason,
    bool fromEnd = false,
  }) async {
    if (targetIndex < 0 || targetIndex >= chapters.length) return;
    if (_pendingChapterNavigationIndex == targetIndex ||
        loadingChapters.contains(targetIndex)) {
      return;
    }
    if (targetIndex == currentChapterIndex && !fromEnd) return;

    isScrubbing = false;
    _setPendingChapterNavigation(targetIndex);
    try {
      await performChapterNavigation(
        targetIndex: targetIndex,
        reason: reason,
        fromEnd: fromEnd,
      );
    } finally {
      _clearPendingChapterNavigation(targetIndex: targetIndex);
    }
  }

  Future<void> jumpToChapter(
    int index, {
    ReaderCommandReason reason = ReaderCommandReason.user,
  }) async {
    await _navigateToChapter(targetIndex: index, reason: reason);
  }

  @override
  Future<void> nextChapter({
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    await _navigateToChapter(
      targetIndex: currentChapterIndex + 1,
      reason: reason,
    );
  }

  @override
  Future<void> prevChapter({
    bool fromEnd = true,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    await _navigateToChapter(
      targetIndex: currentChapterIndex - 1,
      fromEnd: fromEnd,
      reason: reason,
    );
  }
}
