import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine.dart';
import 'package:inkpage_reader/features/reader/runtime/switchable_tts_engine.dart';

class _FakeEngine implements ReaderTtsEngine {
  final StreamController<ReaderTtsEngineEvent> controller =
      StreamController<ReaderTtsEngineEvent>.broadcast();
  bool disposed = false;
  bool stopped = false;
  bool paused = false;
  String? lastSpokenText;

  @override
  Stream<ReaderTtsEngineEvent> get events => controller.stream;

  @override
  bool get isPlaying => false;

  @override
  Future<void> dispose() async {
    disposed = true;
    await controller.close();
  }

  @override
  Future<void> pause() async {
    paused = true;
  }

  @override
  Future<void> speak(String text) async {
    lastSpokenText = text;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

void main() {
  group('SwitchableReaderTtsEngine', () {
    test('會轉發當前 delegate 的事件', () async {
      final first = _FakeEngine();
      final host = SwitchableReaderTtsEngine(delegate: first);
      final events = <Type>[];
      final sub = host.events.listen((event) => events.add(event.runtimeType));

      first.controller.add(const ReaderTtsEngineStarted());
      await Future<void>.delayed(Duration.zero);

      expect(events, [ReaderTtsEngineStarted]);

      await sub.cancel();
      await host.dispose();
    });

    test('setDelegate 會停止並處置前一個 engine，之後轉發新事件', () async {
      final first = _FakeEngine();
      final second = _FakeEngine();
      final host = SwitchableReaderTtsEngine(delegate: first);
      final events = <Type>[];
      final sub = host.events.listen((event) => events.add(event.runtimeType));

      await host.setDelegate(second);

      expect(first.stopped, isTrue);
      expect(first.disposed, isTrue);

      second.controller.add(
        const ReaderTtsEngineProgress(wordStart: 1, wordEnd: 2),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, [ReaderTtsEngineProgress]);

      await sub.cancel();
      await host.dispose();
    });

    test('會把 speak/pause/stop 代理到目前 engine', () async {
      final first = _FakeEngine();
      final second = _FakeEngine();
      final host = SwitchableReaderTtsEngine(delegate: first);

      await host.speak('alpha');
      expect(first.lastSpokenText, 'alpha');

      await host.setDelegate(second);
      await host.pause();
      await host.stop();
      await host.speak('beta');

      expect(second.paused, isTrue);
      expect(second.stopped, isTrue);
      expect(second.lastSpokenText, 'beta');

      await host.dispose();
    });
  });
}
