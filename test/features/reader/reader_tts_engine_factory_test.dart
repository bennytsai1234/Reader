import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/models/http_tts.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/runtime/http_tts_engine.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine_factory.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_source.dart';

class _FakeHttpTtsAudioPlayer implements ReaderHttpTtsAudioPlayer {
  @override
  bool get isPlaying => false;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> playBytes(bytes, {String? contentType}) async {}

  @override
  Future<void> stop() async {}
}

class _FakeSystemEngine implements ReaderTtsEngine {
  @override
  final events = const Stream<ReaderTtsEngineEvent>.empty();

  @override
  bool get isPlaying => false;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderTtsEngineFactory', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('當 source key 指向 httpTts 時會建立 HttpTtsEngine', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PreferKey.ttsSource: ReaderTtsSourcePreference.httpKeyForId(7),
        PreferKey.ttsSpeechRate: 0.8,
      });

      final factory = ReaderTtsEngineFactory(
        lookupHttpSource:
            (id) async => HttpTTS(
              id: id,
              name: 'Remote',
              url: 'https://example.com/tts?text={{speakText}}',
            ),
        httpAudioPlayerBuilder: () => _FakeHttpTtsAudioPlayer(),
        buildSystemEngine: (_) => _FakeSystemEngine(),
        ttsService: TTSService(),
      );

      final engine = await factory.create();

      expect(engine, isA<HttpTtsEngine>());
      final httpEngine = engine as HttpTtsEngine;
      expect(httpEngine.source.id, 7);
      expect(httpEngine.speakSpeed, 8);
    });

    test('找不到 http source 時會回退 system engine', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PreferKey.ttsSource: ReaderTtsSourcePreference.httpKeyForId(9),
      });

      final factory = ReaderTtsEngineFactory(
        lookupHttpSource: (_) async => null,
        httpAudioPlayerBuilder: () => _FakeHttpTtsAudioPlayer(),
        buildSystemEngine: (_) => _FakeSystemEngine(),
        ttsService: TTSService(),
      );

      final engine = await factory.create();

      expect(engine, isA<_FakeSystemEngine>());
    });

    test('book override source key 會優先於全域設定', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PreferKey.ttsSource: ReaderTtsSourcePreference.systemKey,
      });

      final factory = ReaderTtsEngineFactory(
        lookupHttpSource:
            (id) async => HttpTTS(
              id: id,
              name: 'Book Override',
              url: 'https://example.com/override',
            ),
        httpAudioPlayerBuilder: () => _FakeHttpTtsAudioPlayer(),
        buildSystemEngine: (_) => _FakeSystemEngine(),
        ttsService: TTSService(),
      );

      final engine = await factory.create(
        overrideSourceKey: ReaderTtsSourcePreference.httpKeyForId(3),
      );

      expect(engine, isA<HttpTtsEngine>());
      expect((engine as HttpTtsEngine).source.id, 3);
    });

    test('deriveHttpSpeakSpeed 會把 speechRate 映射到 1..10', () {
      expect(ReaderTtsEngineFactory.deriveHttpSpeakSpeed(0.1), 1);
      expect(ReaderTtsEngineFactory.deriveHttpSpeakSpeed(0.55), 6);
      expect(ReaderTtsEngineFactory.deriveHttpSpeakSpeed(1.0), 10);
    });
  });
}
