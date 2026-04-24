import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
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
      expect(
        coordinator.pendingScrollRestoreAnchor,
        const ReaderAnchor(
          location: ReaderLocation(chapterIndex: 3, charOffset: 0),
          localOffsetSnapshot: 256,
        ),
      );
    });

    test('register 可直接保留完整 anchor metadata', () {
      final coordinator = ReaderRestoreCoordinator();

      coordinator.registerPendingScrollRestore(
        anchor: const ReaderAnchor(
          location: ReaderLocation(chapterIndex: 2, charOffset: 88),
          pageIndexSnapshot: 4,
          localOffsetSnapshot: 128,
          layoutSignature: 'scroll:320x640',
        ),
      );

      expect(
        coordinator.pendingScrollRestoreAnchor,
        const ReaderAnchor(
          location: ReaderLocation(chapterIndex: 2, charOffset: 88),
          pageIndexSnapshot: 4,
          localOffsetSnapshot: 128,
          layoutSignature: 'scroll:320x640',
        ),
      );
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
      expect(
        first.anchor,
        const ReaderAnchor(
          location: ReaderLocation(chapterIndex: 1, charOffset: 0),
          localOffsetSnapshot: 64,
        ),
      );
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

    test('missing local offset 不會預設成 0，會等待 resolver', () {
      final coordinator = ReaderRestoreCoordinator();

      final token = coordinator.registerPendingScrollRestore(
        chapterIndex: 1,
        charOffset: 88,
      );

      expect(coordinator.pendingScrollRestoreLocalOffset, isNull);
      expect(coordinator.dispatchPendingScrollRestore(), isNull);

      final resolved = coordinator.dispatchPendingScrollRestore(
        resolveLocalOffset: (anchor) {
          expect(
            anchor.location,
            const ReaderLocation(chapterIndex: 1, charOffset: 88),
          );
          return 144;
        },
      );

      expect(resolved, isNotNull);
      expect(resolved!.token, token);
      expect(resolved.localOffset, 144);
      expect(resolved.anchor.localOffsetSnapshot, 144);
      expect(coordinator.pendingScrollRestoreLocalOffset, 144);
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
