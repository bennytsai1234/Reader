import 'dart:async';

import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine.dart';

class SystemTtsEngine implements ReaderTtsEngine {
  final TTSService _tts;
  final StreamController<ReaderTtsEngineEvent> _events =
      StreamController<ReaderTtsEngineEvent>.broadcast();

  StreamSubscription<String>? _audioEventSub;
  bool _isDisposed = false;
  bool _lastIsPlaying = false;
  int _lastWordStart = -1;
  int _lastWordEnd = -1;

  SystemTtsEngine({TTSService? tts}) : _tts = tts ?? TTSService() {
    _lastIsPlaying = _tts.isPlaying;
    _lastWordStart = _tts.currentWordStart;
    _lastWordEnd = _tts.currentWordEnd;
    _tts.addListener(_handleTtsChanged);
    _audioEventSub = _tts.audioEvents.listen(_handleAudioEvent);
  }

  @override
  Stream<ReaderTtsEngineEvent> get events => _events.stream;

  @override
  bool get isPlaying => _tts.isPlaying;

  @override
  Future<void> speak(String text) => _tts.speak(text);

  @override
  Future<void> pause() => _tts.pause();

  @override
  Future<void> stop() => _tts.stop();

  void _handleTtsChanged() {
    if (_isDisposed) return;

    final isPlaying = _tts.isPlaying;
    final wordStart = _tts.currentWordStart;
    final wordEnd = _tts.currentWordEnd;

    if (isPlaying && !_lastIsPlaying) {
      _events.add(const ReaderTtsEngineStarted());
    }
    if (wordStart >= 0 &&
        (wordStart != _lastWordStart || wordEnd != _lastWordEnd)) {
      _events.add(
        ReaderTtsEngineProgress(wordStart: wordStart, wordEnd: wordEnd),
      );
    }

    _lastIsPlaying = isPlaying;
    _lastWordStart = wordStart;
    _lastWordEnd = wordEnd;
  }

  void _handleAudioEvent(String event) {
    if (_isDisposed) return;

    switch (event) {
      case 'onComplete':
        _events.add(const ReaderTtsEngineCompleted());
        return;
      case 'onPlay':
        _events.add(
          const ReaderTtsEngineCommand(ReaderTtsEngineCommandAction.play),
        );
        return;
      case 'onPause':
        _events.add(
          const ReaderTtsEngineCommand(ReaderTtsEngineCommandAction.pause),
        );
        return;
      case 'onStop':
        _events.add(
          const ReaderTtsEngineCommand(ReaderTtsEngineCommandAction.stop),
        );
        return;
      case 'onSkipToNext':
        _events.add(
          const ReaderTtsEngineCommand(ReaderTtsEngineCommandAction.skipToNext),
        );
        return;
      case 'onSkipToPrevious':
        _events.add(
          const ReaderTtsEngineCommand(
            ReaderTtsEngineCommandAction.skipToPrevious,
          ),
        );
        return;
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _tts.removeListener(_handleTtsChanged);
    await _audioEventSub?.cancel();
    await _events.close();
  }
}
