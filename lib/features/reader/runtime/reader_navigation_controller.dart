import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_command_guard.dart';

enum ReaderNavigationCompletionPolicy { explicit, visibleLocationMatch }

enum ReaderNavigationCommandType { slideJump, chapterJump, charJump }

class ReaderNavigationCommand {
  final ReaderNavigationCommandType type;
  final ReaderCommandReason reason;
  final ReaderLocation? targetLocation;
  final double? targetScrollLocalOffset;
  final ReaderNavigationCompletionPolicy completionPolicy;

  const ReaderNavigationCommand.slide({
    required this.reason,
    this.targetLocation,
    this.targetScrollLocalOffset,
    this.completionPolicy = ReaderNavigationCompletionPolicy.explicit,
  }) : type = ReaderNavigationCommandType.slideJump;

  const ReaderNavigationCommand.chapter({
    required this.reason,
    this.targetLocation,
    this.targetScrollLocalOffset,
    this.completionPolicy = ReaderNavigationCompletionPolicy.explicit,
  }) : type = ReaderNavigationCommandType.chapterJump;

  const ReaderNavigationCommand.char({
    required this.reason,
    this.targetLocation,
    this.targetScrollLocalOffset,
    this.completionPolicy = ReaderNavigationCompletionPolicy.explicit,
  }) : type = ReaderNavigationCommandType.charJump;
}

class ReaderNavigationTransaction {
  final int token;
  final ReaderCommandReason reason;
  final ReaderLocation? targetLocation;
  final double? targetScrollLocalOffset;
  final ReaderNavigationCompletionPolicy completionPolicy;
  final int? restoreToken;

  const ReaderNavigationTransaction({
    required this.token,
    required this.reason,
    this.targetLocation,
    this.targetScrollLocalOffset,
    this.completionPolicy = ReaderNavigationCompletionPolicy.explicit,
    this.restoreToken,
  });

  ReaderNavigationTransaction copyWith({
    ReaderLocation? targetLocation,
    double? targetScrollLocalOffset,
    ReaderNavigationCompletionPolicy? completionPolicy,
    int? restoreToken,
  }) {
    return ReaderNavigationTransaction(
      token: token,
      reason: reason,
      targetLocation: targetLocation ?? this.targetLocation,
      targetScrollLocalOffset:
          targetScrollLocalOffset ?? this.targetScrollLocalOffset,
      completionPolicy: completionPolicy ?? this.completionPolicy,
      restoreToken: restoreToken ?? this.restoreToken,
    );
  }

  bool matchesVisibleLocation(
    ReaderLocation visibleLocation, {
    int charTolerance = 4,
  }) {
    final target = targetLocation;
    if (target == null) return false;
    if (visibleLocation.chapterIndex != target.chapterIndex) return false;
    return (visibleLocation.charOffset - target.charOffset).abs() <=
        charTolerance;
  }

  bool matchesVisibleScrollAnchor({
    required int chapterIndex,
    required double localOffset,
    required double anchorPadding,
    required double chapterContentHeight,
    double localOffsetTolerance = 24.0,
  }) {
    final target = targetLocation;
    final targetLocalOffset = targetScrollLocalOffset;
    if (target == null || targetLocalOffset == null) return false;
    if (chapterIndex != target.chapterIndex) return false;
    final expectedLocalOffset = (targetLocalOffset + anchorPadding).clamp(
      0.0,
      chapterContentHeight <= 0 ? double.infinity : chapterContentHeight,
    );
    return (localOffset - expectedLocalOffset).abs() <= localOffsetTolerance;
  }
}

class ReaderNavigationController {
  final ReaderCommandGuard _commandGuard = ReaderCommandGuard();
  ReaderNavigationTransaction? _activeNavigation;
  int _nextNavigationToken = 0;
  ReaderCommandReason _lastPendingSlideJumpReason = ReaderCommandReason.system;
  int? _lastPendingSlideJumpToken;
  ReaderCommandReason _nextPageChangeReason = ReaderCommandReason.user;
  int? _nextPageChangeToken;

  ReaderCommandReason? get activeCommandReason => _commandGuard.activeReason;
  int? get activeNavigationToken => _activeNavigation?.token;
  ReaderLocation? get activeNavigationTargetLocation =>
      _activeNavigation?.targetLocation;
  bool get hasActiveNavigation => _activeNavigation != null;

  ReaderNavigationTransaction? dispatch(ReaderNavigationCommand command) {
    final transaction = _beginNavigation(
      command.reason,
      targetLocation: command.targetLocation,
      targetScrollLocalOffset: command.targetScrollLocalOffset,
      completionPolicy: command.completionPolicy,
    );
    if (transaction == null) return null;
    if (command.type == ReaderNavigationCommandType.slideJump) {
      _lastPendingSlideJumpReason = command.reason;
      _lastPendingSlideJumpToken = transaction.token;
    }
    return transaction;
  }

  bool beginSlideJump(
    ReaderCommandReason reason, {
    ReaderLocation? targetLocation,
    double? targetScrollLocalOffset,
    ReaderNavigationCompletionPolicy completionPolicy =
        ReaderNavigationCompletionPolicy.explicit,
  }) {
    final transaction = dispatch(
      ReaderNavigationCommand.slide(
        reason: reason,
        targetLocation: targetLocation,
        targetScrollLocalOffset: targetScrollLocalOffset,
        completionPolicy: completionPolicy,
      ),
    );
    if (transaction == null) return false;
    return true;
  }

  bool beginChapterJump(
    ReaderCommandReason reason, {
    ReaderLocation? targetLocation,
    double? targetScrollLocalOffset,
    ReaderNavigationCompletionPolicy completionPolicy =
        ReaderNavigationCompletionPolicy.explicit,
  }) {
    return dispatch(
          ReaderNavigationCommand.chapter(
            reason: reason,
            targetLocation: targetLocation,
            targetScrollLocalOffset: targetScrollLocalOffset,
            completionPolicy: completionPolicy,
          ),
        ) !=
        null;
  }

  bool beginCharJump(
    ReaderCommandReason reason, {
    ReaderLocation? targetLocation,
    double? targetScrollLocalOffset,
    ReaderNavigationCompletionPolicy completionPolicy =
        ReaderNavigationCompletionPolicy.explicit,
  }) {
    return dispatch(
          ReaderNavigationCommand.char(
            reason: reason,
            targetLocation: targetLocation,
            targetScrollLocalOffset: targetScrollLocalOffset,
            completionPolicy: completionPolicy,
          ),
        ) !=
        null;
  }

  void retargetActiveNavigation({
    required ReaderCommandReason reason,
    required ReaderLocation targetLocation,
    double? targetScrollLocalOffset,
    ReaderNavigationCompletionPolicy? completionPolicy,
  }) {
    final active = _activeNavigation;
    if (active == null || active.reason != reason) return;
    _activeNavigation = active.copyWith(
      targetLocation: targetLocation,
      targetScrollLocalOffset: targetScrollLocalOffset,
      completionPolicy: completionPolicy,
    );
  }

  bool canPersistProgress(ReaderCommandReason reason) {
    return _commandGuard.canDispatch(reason);
  }

  bool shouldPersistVisiblePosition([DateTime? now]) {
    return _activeNavigation == null;
  }

  ReaderCommandReason consumePendingSlideJumpReason() {
    final reason = _lastPendingSlideJumpReason;
    _lastPendingSlideJumpReason = ReaderCommandReason.system;
    _nextPageChangeReason = reason;
    _nextPageChangeToken = _lastPendingSlideJumpToken;
    _lastPendingSlideJumpToken = null;
    return reason;
  }

  ReaderCommandReason consumePageChangeReason() {
    final reason = _nextPageChangeReason;
    final token = _nextPageChangeToken;
    _nextPageChangeReason = ReaderCommandReason.user;
    _nextPageChangeToken = null;
    if (token != null) {
      completeNavigation(token, reason: reason);
    } else {
      _commandGuard.clear(reason);
    }
    return reason;
  }

  bool shouldPersistForReason(ReaderCommandReason reason) {
    switch (reason) {
      case ReaderCommandReason.user:
      case ReaderCommandReason.userScroll:
      case ReaderCommandReason.chapterChange:
        return true;
      case ReaderCommandReason.restore:
      case ReaderCommandReason.tts:
      case ReaderCommandReason.autoPage:
      case ReaderCommandReason.settingsRepaginate:
      case ReaderCommandReason.system:
        return false;
    }
  }

  void clear(ReaderCommandReason reason) {
    if (_activeNavigation?.reason == reason) {
      _activeNavigation = null;
    }
    _commandGuard.clear(reason);
  }

  void attachRestoreTokenToActiveNavigation(
    int restoreToken, {
    required ReaderCommandReason reason,
  }) {
    final active = _activeNavigation;
    if (active == null || active.reason != reason) return;
    _activeNavigation = active.copyWith(restoreToken: restoreToken);
  }

  ReaderNavigationTransaction? abortNavigation(
    int token, {
    required ReaderCommandReason reason,
  }) {
    final active = _activeNavigation;
    if (active == null) return null;
    if (active.token != token || active.reason != reason) return null;
    return _completeActiveNavigation();
  }

  ReaderNavigationTransaction? completeNavigation(
    int token, {
    required ReaderCommandReason reason,
  }) {
    final active = _activeNavigation;
    if (active == null) return null;
    if (active.token != token || active.reason != reason) return null;
    if (active.completionPolicy ==
            ReaderNavigationCompletionPolicy.visibleLocationMatch &&
        reason != ReaderCommandReason.restore) {
      return null;
    }
    return _completeActiveNavigation();
  }

  ReaderNavigationTransaction? reconcileVisibleLocation(
    ReaderLocation visibleLocation, {
    int charTolerance = 4,
  }) {
    final active = _activeNavigation;
    if (active == null) return null;
    if (active.completionPolicy !=
        ReaderNavigationCompletionPolicy.visibleLocationMatch) {
      return null;
    }
    if (!active.matchesVisibleLocation(
      visibleLocation,
      charTolerance: charTolerance,
    )) {
      return null;
    }
    return _completeActiveNavigation();
  }

  ReaderNavigationTransaction? reconcileVisibleScrollTarget({
    required int chapterIndex,
    required double localOffset,
    required double anchorPadding,
    required double chapterContentHeight,
    required ReaderLocation visibleLocation,
    double localOffsetTolerance = 24.0,
    int charTolerance = 4,
  }) {
    final active = _activeNavigation;
    if (active == null) return null;
    if (active.completionPolicy !=
        ReaderNavigationCompletionPolicy.visibleLocationMatch) {
      return null;
    }
    if (active.matchesVisibleScrollAnchor(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      anchorPadding: anchorPadding,
      chapterContentHeight: chapterContentHeight,
      localOffsetTolerance: localOffsetTolerance,
    )) {
      return _completeActiveNavigation();
    }
    if (active.targetScrollLocalOffset != null) {
      return null;
    }
    return reconcileVisibleLocation(
      visibleLocation,
      charTolerance: charTolerance,
    );
  }

  ({int chapterIndex, double localOffset})? nextAutoScrollTarget({
    required bool isAutoPaging,
    required Object pageTurnMode,
    required Size? viewSize,
    required int visibleChapterIndex,
    required double visibleChapterLocalOffset,
    required double Function(Size viewSize, double dtSeconds)
    scrollDeltaPerFrame,
    required ReaderChapter? Function(int) chapterAt,
    required List<TextPage> Function(int) pagesForChapter,
    required double dtSeconds,
  }) {
    if (!isAutoPaging || pageTurnMode != PageAnim.scroll) return null;
    final size = viewSize;
    if (size == null) return null;
    final chapterIndex = visibleChapterIndex;
    final runtimeChapter = chapterAt(chapterIndex);
    final chapterHeight =
        runtimeChapter?.chapterHeight ??
        ChapterPositionResolver.chapterHeight(pagesForChapter(chapterIndex));
    if (chapterHeight <= 0) return null;
    final delta = scrollDeltaPerFrame(size, dtSeconds);
    final nextLocalOffset = visibleChapterLocalOffset + delta;
    if (nextLocalOffset >= chapterHeight) return null;
    return (chapterIndex: chapterIndex, localOffset: nextLocalOffset);
  }

  ({int? chapterIndex, double? localOffset, bool advanceChapter})?
  evaluateScrollAutoPageStep({
    required bool isAutoPaging,
    required bool isAutoPagePaused,
    required bool isLoading,
    required Object pageTurnMode,
    required Size? viewSize,
    required int visibleChapterIndex,
    required double visibleChapterLocalOffset,
    required double Function(Size viewSize, double dtSeconds)
    scrollDeltaPerFrame,
    required ReaderChapter? Function(int) chapterAt,
    required List<TextPage> Function(int) pagesForChapter,
    required double dtSeconds,
  }) {
    if (!isAutoPaging || isAutoPagePaused || pageTurnMode != PageAnim.scroll) {
      return null;
    }
    final target = nextAutoScrollTarget(
      isAutoPaging: isAutoPaging,
      pageTurnMode: pageTurnMode,
      viewSize: viewSize,
      visibleChapterIndex: visibleChapterIndex,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
      scrollDeltaPerFrame: scrollDeltaPerFrame,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      dtSeconds: dtSeconds,
    );
    if (target != null) {
      return (
        chapterIndex: target.chapterIndex,
        localOffset: target.localOffset,
        advanceChapter: false,
      );
    }
    if (!isLoading) {
      return (chapterIndex: null, localOffset: null, advanceChapter: true);
    }
    return null;
  }

  ReaderNavigationTransaction? _beginNavigation(
    ReaderCommandReason reason, {
    ReaderLocation? targetLocation,
    double? targetScrollLocalOffset,
    ReaderNavigationCompletionPolicy completionPolicy =
        ReaderNavigationCompletionPolicy.explicit,
  }) {
    if (!_commandGuard.begin(reason)) return null;
    final transaction = ReaderNavigationTransaction(
      token: ++_nextNavigationToken,
      reason: reason,
      targetLocation: targetLocation,
      targetScrollLocalOffset: targetScrollLocalOffset,
      completionPolicy: completionPolicy,
    );
    _activeNavigation = transaction;
    return transaction;
  }

  ReaderNavigationTransaction? _completeActiveNavigation() {
    final active = _activeNavigation;
    if (active == null) return null;
    _activeNavigation = null;
    _commandGuard.clear(active.reason);
    return active;
  }
}
