import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';

enum ReaderScrollViewportSettlePhase {
  settled,
  pendingRestore,
  awaitingVisibleConfirmation,
  pendingNavigation,
  pendingPlaceholderReanchor,
}

class ReaderScrollViewportSettleState {
  final ReaderScrollViewportSettlePhase phase;
  final ReaderCommandReason? commandReason;

  const ReaderScrollViewportSettleState._(this.phase, [this.commandReason]);

  static const settled = ReaderScrollViewportSettleState._(
    ReaderScrollViewportSettlePhase.settled,
  );
  static const pendingRestore = ReaderScrollViewportSettleState._(
    ReaderScrollViewportSettlePhase.pendingRestore,
    ReaderCommandReason.restore,
  );
  static const awaitingVisibleConfirmation = ReaderScrollViewportSettleState._(
    ReaderScrollViewportSettlePhase.awaitingVisibleConfirmation,
    ReaderCommandReason.restore,
  );
  static ReaderScrollViewportSettleState pendingNavigation(
    ReaderCommandReason? reason,
  ) => ReaderScrollViewportSettleState._(
    ReaderScrollViewportSettlePhase.pendingNavigation,
    reason ?? ReaderCommandReason.system,
  );
  static const pendingPlaceholderReanchor = ReaderScrollViewportSettleState._(
    ReaderScrollViewportSettlePhase.pendingPlaceholderReanchor,
    ReaderCommandReason.system,
  );

  bool get isSettled => phase == ReaderScrollViewportSettlePhase.settled;

  bool get isNavigationDriven =>
      phase == ReaderScrollViewportSettlePhase.pendingNavigation;

  bool get isRestoreDriven =>
      phase == ReaderScrollViewportSettlePhase.pendingRestore ||
      phase == ReaderScrollViewportSettlePhase.awaitingVisibleConfirmation;

  bool get shouldHoldContent => isRestoreDriven;

  bool get shouldShowRestoreOverlay => false;

  bool get shouldSuppressTtsFollow =>
      phase != ReaderScrollViewportSettlePhase.settled;

  bool get shouldReplaySuppressedTtsFollow {
    switch (phase) {
      case ReaderScrollViewportSettlePhase.settled:
        return false;
      case ReaderScrollViewportSettlePhase.pendingRestore:
      case ReaderScrollViewportSettlePhase.awaitingVisibleConfirmation:
      case ReaderScrollViewportSettlePhase.pendingPlaceholderReanchor:
        return true;
      case ReaderScrollViewportSettlePhase.pendingNavigation:
        switch (commandReason) {
          case ReaderCommandReason.settingsRepaginate:
          case ReaderCommandReason.system:
          case ReaderCommandReason.restore:
            return true;
          case ReaderCommandReason.user:
          case ReaderCommandReason.userScroll:
          case ReaderCommandReason.tts:
          case ReaderCommandReason.autoPage:
          case ReaderCommandReason.chapterChange:
          case null:
            return false;
        }
    }
  }

  bool get shouldConsumeSuppressedTtsFollow =>
      shouldSuppressTtsFollow && !shouldReplaySuppressedTtsFollow;
}
