import 'dart:async';

import 'package:inkpage_reader/features/reader/runtime/reader_tts_engine.dart';

class SwitchableReaderTtsEngine implements ReaderTtsEngine {
  ReaderTtsEngine _delegate;
  final StreamController<ReaderTtsEngineEvent> _events =
      StreamController<ReaderTtsEngineEvent>.broadcast();
  StreamSubscription<ReaderTtsEngineEvent>? _delegateSub;
  bool _isDisposed = false;

  SwitchableReaderTtsEngine({required ReaderTtsEngine delegate})
    : _delegate = delegate {
    _bindDelegate(delegate);
  }

  ReaderTtsEngine get delegate => _delegate;

  @override
  Stream<ReaderTtsEngineEvent> get events => _events.stream;

  @override
  bool get isPlaying => _delegate.isPlaying;

  Future<void> setDelegate(
    ReaderTtsEngine next, {
    bool stopPrevious = true,
    bool disposePrevious = true,
  }) async {
    if (_isDisposed) {
      await next.dispose();
      return;
    }
    if (identical(_delegate, next)) return;

    final previous = _delegate;
    if (stopPrevious) {
      await previous.stop();
    }
    await _delegateSub?.cancel();
    _delegate = next;
    _bindDelegate(next);

    if (disposePrevious) {
      await previous.dispose();
    }
  }

  void _bindDelegate(ReaderTtsEngine delegate) {
    _delegateSub = delegate.events.listen((event) {
      if (_isDisposed) return;
      _events.add(event);
    });
  }

  @override
  Future<void> speak(String text) => _delegate.speak(text);

  @override
  Future<void> pause() => _delegate.pause();

  @override
  Future<void> stop() => _delegate.stop();

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _delegateSub?.cancel();
    await _delegate.dispose();
    await _events.close();
  }
}
