import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_display_coordinator.dart';

void main() {
  group('ReaderDisplayCoordinator', () {
    const coordinator = ReaderDisplayCoordinator();

    test('全書百分比使用 chapterIndex 加章內 charOffset 比例', () {
      expect(
        coordinator.formatReadProgress(
          chapterIndex: 1,
          totalChapters: 4,
          charOffset: 50,
          chapterEndCharOffset: 100,
        ),
        '37.5%',
      );
      expect(
        coordinator.formatReadProgress(
          chapterIndex: 3,
          totalChapters: 4,
          charOffset: 99,
          chapterEndCharOffset: 100,
        ),
        '99.8%',
      );
      expect(
        coordinator.formatReadProgress(
          chapterIndex: 3,
          totalChapters: 4,
          charOffset: 100,
          chapterEndCharOffset: 100,
        ),
        '100.0%',
      );
    });

    test('章內百分比只使用目前章節 charOffset 比例', () {
      expect(
        coordinator.formatChapterProgress(
          charOffset: 50,
          chapterEndCharOffset: 100,
        ),
        '50.0%',
      );
      expect(
        coordinator.formatChapterProgress(
          charOffset: 150,
          chapterEndCharOffset: 100,
        ),
        '100.0%',
      );
      expect(
        coordinator.formatChapterProgress(
          charOffset: -10,
          chapterEndCharOffset: 100,
        ),
        '0.0%',
      );
    });

    test('scroll 章節標籤使用 chapterIndex 與總章節數', () {
      expect(
        coordinator.formatChapterLabel(chapterIndex: 0, totalChapters: 12),
        '1/12',
      );
      expect(
        coordinator.formatChapterLabel(chapterIndex: 4, totalChapters: 12),
        '5/12',
      );
      expect(
        coordinator.formatChapterLabel(chapterIndex: 99, totalChapters: 12),
        '12/12',
      );
    });

    test('page label 會 clamp 在有效頁數內', () {
      expect(coordinator.formatPageLabel(0, 10), '1/10');
      expect(coordinator.formatPageLabel(99, 10), '10/10');
      expect(coordinator.formatPageLabel(0, 0), '0/0');
    });

    test('scrub chapter index 會支援 slider double 和 int', () {
      expect(
        coordinator.resolveScrubChapterIndex(value: 0.5, totalChapters: 11),
        5,
      );
      expect(
        coordinator.resolveScrubChapterIndex(value: 99, totalChapters: 11),
        10,
      );
      expect(
        coordinator.resolveScrubChapterIndex(value: 0, totalChapters: 0),
        0,
      );
    });
  });
}
