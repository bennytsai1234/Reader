import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_restore_coordinator.dart';

void main() {
  group('ReaderRestoreCoordinator', () {
    test('register 會遞增 token 並保存 restore target', () {
      final coordinator = ReaderRestoreCoordinator();

      final first = coordinator.registerPendingScrollRestore(
        chapterIndex: 2,
        localOffset: 128,
      );
      final second = coordinator.registerPendingScrollRestore(
        chapterIndex: 3,
        localOffset: 256,
      );

      expect(first, 1);
      expect(second, 2);
      expect(coordinator.matchesPendingScrollRestore(2), isTrue);
      expect(coordinator.pendingScrollRestoreChapterIndex, 3);
      expect(coordinator.pendingScrollRestoreLocalOffset, 256);
    });

    test('dispatch 只會派發一次，直到 defer 或 complete', () {
      final coordinator = ReaderRestoreCoordinator();

      final token = coordinator.registerPendingScrollRestore(
        chapterIndex: 1,
        localOffset: 64,
      );

      final first = coordinator.dispatchPendingScrollRestore();
      final second = coordinator.dispatchPendingScrollRestore();

      expect(first, isNotNull);
      expect(first!.token, token);
      expect(first.chapterIndex, 1);
      expect(first.localOffset, 64);
      expect(second, isNull);
      expect(coordinator.pendingScrollRestoreChapterIndex, 1);
      expect(coordinator.pendingScrollRestoreLocalOffset, 64);

      coordinator.deferPendingScrollRestore(token);
      expect(coordinator.dispatchPendingScrollRestore(), isNotNull);

      expect(coordinator.completePendingScrollRestore(token), isTrue);
      expect(coordinator.pendingScrollRestoreChapterIndex, isNull);
      expect(coordinator.pendingScrollRestoreLocalOffset, isNull);
    });

    test('clear 會清空 target 但保留 token 序列', () {
      final coordinator = ReaderRestoreCoordinator();

      coordinator.registerPendingScrollRestore(
        chapterIndex: 1,
        localOffset: 64,
      );
      coordinator.clear();

      expect(coordinator.dispatchPendingScrollRestore(), isNull);
      expect(coordinator.pendingScrollRestoreToken, 1);
    });
  });
}
