class ReaderPendingChapterJump<TReason> {
  final int chapterIndex;
  final double alignment;
  final double localOffset;
  final TReason reason;

  const ReaderPendingChapterJump({
    required this.chapterIndex,
    required this.alignment,
    required this.localOffset,
    required this.reason,
  });
}

class ReaderViewportMailbox<TReason> {
  final TReason _systemReason;
  int? _pendingJumpTarget;
  int? _pendingJumpChapterIndex;
  double? _pendingJumpAlignment;
  double? _pendingJumpLocalOffset;
  int? _pendingSlidePageIndex;
  int? _pendingControllerReset;
  late TReason _pendingChapterJumpReason = _systemReason;

  ReaderViewportMailbox({required TReason systemReason})
    : _systemReason = systemReason;

  void requestJumpToPage(int pageIndex) {
    _pendingJumpTarget = pageIndex;
    _pendingSlidePageIndex = pageIndex;
  }

  int? consumePendingJump() {
    final value = _pendingJumpTarget;
    _pendingJumpTarget = null;
    return value;
  }

  void requestJumpToChapter({
    required int chapterIndex,
    required double alignment,
    required double localOffset,
    required TReason reason,
  }) {
    _pendingJumpChapterIndex = chapterIndex;
    _pendingJumpAlignment = alignment;
    _pendingJumpLocalOffset = localOffset;
    _pendingChapterJumpReason = reason;
  }

  ReaderPendingChapterJump<TReason>? consumePendingChapterJump() {
    final chapterIndex = _pendingJumpChapterIndex;
    if (chapterIndex == null) return null;
    final jump = ReaderPendingChapterJump<TReason>(
      chapterIndex: chapterIndex,
      alignment: _pendingJumpAlignment ?? 0.0,
      localOffset: _pendingJumpLocalOffset ?? 0.0,
      reason: _pendingChapterJumpReason,
    );
    _pendingJumpChapterIndex = null;
    _pendingJumpAlignment = null;
    _pendingJumpLocalOffset = null;
    _pendingChapterJumpReason = _systemReason;
    return jump;
  }

  int? consumePendingSlidePageIndex() {
    final value = _pendingSlidePageIndex;
    _pendingSlidePageIndex = null;
    return value;
  }

  void requestControllerReset(int pageIndex) {
    _pendingControllerReset = pageIndex;
  }

  int? consumeControllerReset() {
    final value = _pendingControllerReset;
    _pendingControllerReset = null;
    return value;
  }
}
