class ReaderPageViewportBuildUpdate {
  final int? controllerResetPage;
  final bool shouldScheduleRecenterPoll;
  final int? pendingJumpPage;

  const ReaderPageViewportBuildUpdate({
    this.controllerResetPage,
    this.shouldScheduleRecenterPoll = false,
    this.pendingJumpPage,
  });
}

enum ReaderPageRecenterAction { none, reschedule, applyPendingRecenter }

class ReaderPageViewportBridge {
  bool _recenterPollScheduled = false;

  bool get isRecenterPollScheduled => _recenterPollScheduled;

  ReaderPageViewportBuildUpdate resolveBuildUpdate({
    required int? controllerResetPage,
    required bool hasPendingSlideRecenter,
    required int? pendingJumpPage,
  }) {
    final shouldScheduleRecenterPoll =
        hasPendingSlideRecenter && !_recenterPollScheduled;
    if (shouldScheduleRecenterPoll) {
      _recenterPollScheduled = true;
    }
    return ReaderPageViewportBuildUpdate(
      controllerResetPage: controllerResetPage,
      shouldScheduleRecenterPoll: shouldScheduleRecenterPoll,
      pendingJumpPage: pendingJumpPage,
    );
  }

  ReaderPageRecenterAction handleRecenterPoll({
    required bool isMounted,
    required bool hasPendingSlideRecenter,
    required bool isPageScrolling,
  }) {
    _recenterPollScheduled = false;
    if (!isMounted || !hasPendingSlideRecenter) {
      return ReaderPageRecenterAction.none;
    }
    if (isPageScrolling) {
      _recenterPollScheduled = true;
      return ReaderPageRecenterAction.reschedule;
    }
    return ReaderPageRecenterAction.applyPendingRecenter;
  }
}
