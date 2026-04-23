import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_source.dart';

void main() {
  group('ReaderTtsSourcePreference', () {
    test('normalize 會把空值回退成 system', () {
      expect(
        ReaderTtsSourcePreference.normalize(null),
        ReaderTtsSourcePreference.systemKey,
      );
      expect(
        ReaderTtsSourcePreference.normalize(''),
        ReaderTtsSourcePreference.systemKey,
      );
    });

    test('http key 會正確解析與正規化', () {
      const key = 'httpTts:12';
      expect(ReaderTtsSourcePreference.typeOf(key), ReaderTtsSourceType.http);
      expect(ReaderTtsSourcePreference.httpIdFromKey(key), 12);
      expect(ReaderTtsSourcePreference.normalize(' httpTts:12 '), key);
      expect(ReaderTtsSourcePreference.httpKeyForId(12), key);
    });

    test('未知 key 會回退 system', () {
      expect(
        ReaderTtsSourcePreference.normalize('com.google.android.tts'),
        ReaderTtsSourcePreference.systemKey,
      );
    });
  });
}
