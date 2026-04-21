import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_viewport_bridge.dart';

void main() {
  group('ReaderPageViewportBridge', () {
    test('build update 只會安排一次 recenter poll', () {
      final bridge = ReaderPageViewportBridge();

      final first = bridge.resolveBuildUpdate(
        controllerResetPage: 3,
        hasPendingSlideRecenter: true,
        pendingJumpPage: 7,
      );
      final second = bridge.resolveBuildUpdate(
        controllerResetPage: null,
        hasPendingSlideRecenter: true,
        pendingJumpPage: null,
      );

      expect(first.controllerResetPage, 3);
      expect(first.pendingJumpPage, 7);
      expect(first.shouldScheduleRecenterPoll, isTrue);
      expect(second.shouldScheduleRecenterPoll, isFalse);
      expect(bridge.isRecenterPollScheduled, isTrue);
    });

    test('poll action 會在動畫中要求 reschedule，停止後套用 recenter', () {
      final bridge = ReaderPageViewportBridge();
      bridge.resolveBuildUpdate(
        controllerResetPage: null,
        hasPendingSlideRecenter: true,
        pendingJumpPage: null,
      );

      final reschedule = bridge.handleRecenterPoll(
        isMounted: true,
        hasPendingSlideRecenter: true,
        isPageScrolling: true,
      );
      final apply = bridge.handleRecenterPoll(
        isMounted: true,
        hasPendingSlideRecenter: true,
        isPageScrolling: false,
      );

      expect(reschedule, ReaderPageRecenterAction.reschedule);
      expect(apply, ReaderPageRecenterAction.applyPendingRecenter);
      expect(bridge.isRecenterPollScheduled, isFalse);
    });

    test('沒有 pending recenter 時 poll action 為 none', () {
      final bridge = ReaderPageViewportBridge();

      final action = bridge.handleRecenterPoll(
        isMounted: true,
        hasPendingSlideRecenter: false,
        isPageScrolling: false,
      );

      expect(action, ReaderPageRecenterAction.none);
    });
  });
}
