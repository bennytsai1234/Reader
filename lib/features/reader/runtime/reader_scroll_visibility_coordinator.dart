class ReaderScrollVisibilityUpdate {
  final List<int> chaptersToEnsure;
  final int? preloadCenterChapter;

  const ReaderScrollVisibilityUpdate({
    this.chaptersToEnsure = const [],
    this.preloadCenterChapter,
  });
}

class ReaderScrollVisibilityCoordinator {
  final Set<int> _requestedVisibleChapterLoads = <int>{};
  int _lastPreloadChapterIndex = -1;

  void reconcile(bool Function(int chapterIndex) hasRuntimeChapter) {
    _requestedVisibleChapterLoads.removeWhere(hasRuntimeChapter);
  }

  ReaderScrollVisibilityUpdate evaluate({
    required List<int> visibleChapterIndexes,
    required int focusChapterIndex,
    required bool Function(int chapterIndex) hasRuntimeChapter,
    required bool Function(int chapterIndex) isLoadingChapter,
  }) {
    final chaptersToEnsure = <int>[];
    for (final visibleChapter in visibleChapterIndexes) {
      if (hasRuntimeChapter(visibleChapter) ||
          isLoadingChapter(visibleChapter) ||
          _requestedVisibleChapterLoads.contains(visibleChapter)) {
        continue;
      }
      if ((visibleChapter - focusChapterIndex).abs() > 1) continue;
      _requestedVisibleChapterLoads.add(visibleChapter);
      chaptersToEnsure.add(visibleChapter);
    }

    int? preloadCenterChapter;
    if (visibleChapterIndexes.isNotEmpty) {
      if (_lastPreloadChapterIndex != focusChapterIndex ||
          chaptersToEnsure.isNotEmpty) {
        _lastPreloadChapterIndex = focusChapterIndex;
        preloadCenterChapter = focusChapterIndex;
      }
    }

    return ReaderScrollVisibilityUpdate(
      chaptersToEnsure: chaptersToEnsure,
      preloadCenterChapter: preloadCenterChapter,
    );
  }
}
