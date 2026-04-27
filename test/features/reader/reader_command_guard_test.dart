import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_host_base.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_command_guard.dart';

void main() {
  group('ReaderCommandGuard', () {
    test('restore 進行中時會擋下 autoPage 與 tts，但允許 user 覆蓋', () {
      final guard = ReaderCommandGuard();

      expect(guard.begin(ReaderCommandReason.restore), isTrue);
      expect(guard.activeReason, ReaderCommandReason.restore);

      expect(guard.canDispatch(ReaderCommandReason.autoPage), isFalse);
      expect(guard.canDispatch(ReaderCommandReason.tts), isFalse);
      expect(guard.canDispatch(ReaderCommandReason.user), isTrue);

      expect(guard.begin(ReaderCommandReason.user), isTrue);
      expect(guard.activeReason, ReaderCommandReason.user);
    });

    test('userScroll 可以覆蓋 tts，clear 後恢復空閒', () {
      final guard = ReaderCommandGuard();

      expect(guard.begin(ReaderCommandReason.tts), isTrue);
      expect(guard.canDispatch(ReaderCommandReason.userScroll), isTrue);
      expect(guard.begin(ReaderCommandReason.userScroll), isTrue);
      expect(guard.activeReason, ReaderCommandReason.userScroll);

      guard.clear(ReaderCommandReason.userScroll);
      expect(guard.activeReason, isNull);
      expect(guard.canDispatch(ReaderCommandReason.autoPage), isTrue);
    });

    test('較低優先級命令不能覆蓋較高優先級命令', () {
      final guard = ReaderCommandGuard();

      expect(guard.begin(ReaderCommandReason.settingsRepaginate), isTrue);
      expect(guard.canDispatch(ReaderCommandReason.autoPage), isFalse);
      expect(guard.begin(ReaderCommandReason.autoPage), isFalse);
      expect(guard.activeReason, ReaderCommandReason.settingsRepaginate);
    });
  });
}
