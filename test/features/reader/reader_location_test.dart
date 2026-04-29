import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/engine/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_anchor.dart';

void main() {
  group('ReaderLocation', () {
    test('normalized clamps visualOffsetPx to reader anchor range', () {
      expect(
        const ReaderLocation(
          chapterIndex: 1,
          charOffset: 20,
          visualOffsetPx: -120,
        ).normalized().visualOffsetPx,
        -80,
      );
      expect(
        const ReaderLocation(
          chapterIndex: 1,
          charOffset: 20,
          visualOffsetPx: 160,
        ).normalized().visualOffsetPx,
        120,
      );
    });

    test('normalized resets NaN and infinite visualOffsetPx', () {
      expect(
        const ReaderLocation(
          chapterIndex: 1,
          charOffset: 20,
          visualOffsetPx: double.nan,
        ).normalized().visualOffsetPx,
        0,
      );
      expect(
        const ReaderLocation(
          chapterIndex: 1,
          charOffset: 20,
          visualOffsetPx: double.infinity,
        ).normalized().visualOffsetPx,
        0,
      );
    });

    test('copyWith equality hashCode and json include visualOffsetPx', () {
      const location = ReaderLocation(
        chapterIndex: 2,
        charOffset: 88,
        visualOffsetPx: 16.5,
      );
      final copied = location.copyWith(visualOffsetPx: -12);

      expect(
        copied,
        const ReaderLocation(
          chapterIndex: 2,
          charOffset: 88,
          visualOffsetPx: -12,
        ),
      );
      expect(location, isNot(copied));
      expect(location.hashCode, isNot(copied.hashCode));
      expect(location.toJson(), {
        'chapterIndex': 2,
        'charOffset': 88,
        'visualOffsetPx': 16.5,
      });
      expect(ReaderLocation.fromJson(location.toJson()), location);
    });

    test('ReaderAnchor serialization preserves visualOffsetPx', () {
      const anchor = ReaderAnchor(
        location: ReaderLocation(
          chapterIndex: 3,
          charOffset: 128,
          visualOffsetPx: 24,
        ),
      );

      expect(ReaderAnchor.fromJson(anchor.toJson()), anchor);
    });
  });
}
