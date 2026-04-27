import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_host_base.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_viewport_mailbox.dart';

void main() {
  group('ReaderViewportMailbox', () {
    test('page jump 與 slide page index 會共用同一個 pending target', () {
      final mailbox = ReaderViewportMailbox<ReaderCommandReason>(
        systemReason: ReaderCommandReason.system,
      );

      mailbox.requestJumpToPage(5);

      expect(mailbox.consumePendingJump(), 5);
      expect(mailbox.consumePendingJump(), isNull);
      expect(mailbox.consumePendingSlidePageIndex(), 5);
      expect(mailbox.consumePendingSlidePageIndex(), isNull);
    });

    test('chapter jump 會保留 localOffset / alignment / reason', () {
      final mailbox = ReaderViewportMailbox<ReaderCommandReason>(
        systemReason: ReaderCommandReason.system,
      );

      mailbox.requestJumpToChapter(
        chapterIndex: 3,
        alignment: 0.2,
        localOffset: 48,
        reason: ReaderCommandReason.settingsRepaginate,
      );

      final jump = mailbox.consumePendingChapterJump();
      expect(jump, isNotNull);
      expect(jump!.chapterIndex, 3);
      expect(jump.alignment, 0.2);
      expect(jump.localOffset, 48);
      expect(jump.reason, ReaderCommandReason.settingsRepaginate);
      expect(mailbox.consumePendingChapterJump(), isNull);
    });

    test('clearPendingChapterJump 會清掉尚未消費的 chapter jump', () {
      final mailbox = ReaderViewportMailbox<ReaderCommandReason>(
        systemReason: ReaderCommandReason.system,
      );

      mailbox.requestJumpToChapter(
        chapterIndex: 3,
        alignment: 0.2,
        localOffset: 48,
        reason: ReaderCommandReason.settingsRepaginate,
      );
      mailbox.clearPendingChapterJump();

      expect(mailbox.consumePendingChapterJump(), isNull);
    });

    test('controller reset target 只會被消費一次', () {
      final mailbox = ReaderViewportMailbox<ReaderCommandReason>(
        systemReason: ReaderCommandReason.system,
      );

      mailbox.requestControllerReset(7);

      expect(mailbox.consumeControllerReset(), 7);
      expect(mailbox.consumeControllerReset(), isNull);
    });
  });
}
