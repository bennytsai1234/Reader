class ReaderRestoreCoordinator {
  int _pendingScrollRestoreToken = 0;
  int? _pendingScrollRestoreChapterIndex;
  double? _pendingScrollRestoreLocalOffset;
  bool _pendingScrollRestoreDispatched = false;

  int registerPendingScrollRestore({
    required int chapterIndex,
    required double localOffset,
  }) {
    _pendingScrollRestoreToken++;
    _pendingScrollRestoreChapterIndex = chapterIndex;
    _pendingScrollRestoreLocalOffset = localOffset;
    _pendingScrollRestoreDispatched = false;
    return _pendingScrollRestoreToken;
  }

  int get pendingScrollRestoreToken => _pendingScrollRestoreToken;
  int? get pendingScrollRestoreChapterIndex =>
      _pendingScrollRestoreChapterIndex;
  double? get pendingScrollRestoreLocalOffset =>
      _pendingScrollRestoreLocalOffset;
  bool get hasPendingScrollRestore =>
      _pendingScrollRestoreChapterIndex != null &&
      _pendingScrollRestoreLocalOffset != null;
  bool get hasQueuedScrollRestore =>
      hasPendingScrollRestore && !_pendingScrollRestoreDispatched;

  bool matchesPendingScrollRestore(int token) =>
      hasPendingScrollRestore && token == _pendingScrollRestoreToken;

  ({int token, int chapterIndex, double localOffset})?
  dispatchPendingScrollRestore() {
    final chapterIndex = _pendingScrollRestoreChapterIndex;
    final localOffset = _pendingScrollRestoreLocalOffset;
    if (chapterIndex == null ||
        localOffset == null ||
        _pendingScrollRestoreDispatched) {
      return null;
    }
    _pendingScrollRestoreDispatched = true;
    return (
      token: _pendingScrollRestoreToken,
      chapterIndex: chapterIndex,
      localOffset: localOffset,
    );
  }

  void deferPendingScrollRestore(int token) {
    if (!matchesPendingScrollRestore(token)) return;
    _pendingScrollRestoreDispatched = false;
  }

  bool completePendingScrollRestore(int token) {
    if (!matchesPendingScrollRestore(token)) return false;
    clear();
    return true;
  }

  void clear() {
    _pendingScrollRestoreChapterIndex = null;
    _pendingScrollRestoreLocalOffset = null;
    _pendingScrollRestoreDispatched = false;
  }
}
