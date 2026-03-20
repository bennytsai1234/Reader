import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/features/reader/runtime/reader_tts_follow_coordinator.dart';

void main() {
  group('ReaderTtsFollowCoordinator', () {
    const coordinator = ReaderTtsFollowCoordinator();

    test('當目標已在安全可見區間內時不產生 follow target', () {
      final target = coordinator.evaluate(
        chapterIndex: 2,
        visibleChapterIndex: 2,
        targetLocalOffset: 120,
        visibleChapterLocalOffset: 100,
        viewportHeight: 400,
      );

      expect(target, isNull);
    });

    test('當目標落在安全區間外時會產生 follow target', () {
      final target = coordinator.evaluate(
        chapterIndex: 2,
        visibleChapterIndex: 2,
        targetLocalOffset: 320,
        visibleChapterLocalOffset: 100,
        viewportHeight: 400,
      );

      expect(target, isNotNull);
      expect(target!.chapterIndex, 2);
      expect(target.localOffset, 320);
      expect(target.topPadding, 48);
    });

    test('跨章時會直接要求 follow', () {
      final target = coordinator.evaluate(
        chapterIndex: 3,
        visibleChapterIndex: 2,
        targetLocalOffset: 40,
        visibleChapterLocalOffset: 100,
        viewportHeight: 400,
      );

      expect(target, isNotNull);
      expect(target!.chapterIndex, 3);
      expect(target.localOffset, 40);
      expect(target.topPadding, 0);
    });
  });
}
