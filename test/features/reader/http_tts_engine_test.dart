import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/http_tts.dart';
import 'package:inkpage_reader/features/reader/runtime/http_tts_engine.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine.dart';

class _FakeHttpTtsAudioPlayer implements ReaderHttpTtsAudioPlayer {
  bool _isPlaying = false;
  bool disposed = false;
  int pauseCount = 0;
  int stopCount = 0;
  final List<({Uint8List bytes, String? contentType})> playRequests = [];
  Completer<void>? _playCompleter;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> playBytes(Uint8List bytes, {String? contentType}) async {
    _isPlaying = true;
    playRequests.add((bytes: bytes, contentType: contentType));
    final completer = _playCompleter ??= Completer<void>();
    await completer.future;
    _isPlaying = false;
  }

  void completePlayback() {
    final completer = _playCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  @override
  Future<void> pause() async {
    pauseCount += 1;
    _isPlaying = false;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  group('HttpTtsEngine', () {
    test('speak 會抓取音訊並轉成 started/completed 事件', () async {
      final source = HttpTTS(
        id: 1,
        name: 'HTTP',
        url: 'https://example.com/tts?text={{speakText}}&speed={{speakSpeed}}',
        contentType: 'audio/mpeg',
      );
      final player = _FakeHttpTtsAudioPlayer();
      final fetched = <({HttpTTS source, String text, int? speakSpeed})>[];
      final events = <Type>[];

      final engine = HttpTtsEngine(
        source: source,
        player: player,
        speakSpeed: 2,
        fetchBytes: (source, text, {int? speakSpeed}) async {
          fetched.add((source: source, text: text, speakSpeed: speakSpeed));
          return Uint8List.fromList([1, 2, 3]);
        },
      );

      final sub = engine.events.listen((event) => events.add(event.runtimeType));
      final speakFuture = engine.speak('hello world');
      await Future<void>.delayed(Duration.zero);

      expect(fetched, hasLength(1));
      expect(fetched.single.source, same(source));
      expect(fetched.single.text, 'hello world');
      expect(fetched.single.speakSpeed, 2);
      expect(player.playRequests, hasLength(1));
      expect(player.playRequests.single.bytes, Uint8List.fromList([1, 2, 3]));
      expect(player.playRequests.single.contentType, 'audio/mpeg');
      expect(events, [ReaderTtsEngineStarted]);

      player.completePlayback();
      await speakFuture;
      await Future<void>.delayed(Duration.zero);

      expect(events, [ReaderTtsEngineStarted, ReaderTtsEngineCompleted]);

      await sub.cancel();
      await engine.dispose();
    });

    test('stop 之後不會再送出 completed 事件', () async {
      final player = _FakeHttpTtsAudioPlayer();
      final events = <Type>[];
      final engine = HttpTtsEngine(
        source: HttpTTS(id: 1, url: 'https://example.com'),
        player: player,
        fetchBytes:
            (_, __, {int? speakSpeed}) async => Uint8List.fromList([9, 9, 9]),
      );

      final sub = engine.events.listen((event) => events.add(event.runtimeType));
      final speakFuture = engine.speak('hello');
      await Future<void>.delayed(Duration.zero);

      expect(events, [ReaderTtsEngineStarted]);
      await engine.stop();
      player.completePlayback();
      await speakFuture;

      expect(player.stopCount, 1);
      expect(events, [ReaderTtsEngineStarted]);

      await sub.cancel();
      await engine.dispose();
    });
  });
}
