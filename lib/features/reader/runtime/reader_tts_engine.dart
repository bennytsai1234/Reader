import 'dart:async';

abstract class ReaderTtsEngine {
  Stream<ReaderTtsEngineEvent> get events;
  bool get isPlaying;

  Future<void> speak(String text);
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}

abstract class ReaderTtsEngineEvent {
  const ReaderTtsEngineEvent();
}

class ReaderTtsEngineStarted extends ReaderTtsEngineEvent {
  const ReaderTtsEngineStarted();
}

class ReaderTtsEngineProgress extends ReaderTtsEngineEvent {
  final int wordStart;
  final int wordEnd;

  const ReaderTtsEngineProgress({
    required this.wordStart,
    required this.wordEnd,
  });
}

class ReaderTtsEngineCompleted extends ReaderTtsEngineEvent {
  const ReaderTtsEngineCompleted();
}

enum ReaderTtsEngineCommandAction {
  play,
  pause,
  stop,
  skipToNext,
  skipToPrevious,
}

class ReaderTtsEngineCommand extends ReaderTtsEngineEvent {
  final ReaderTtsEngineCommandAction action;

  const ReaderTtsEngineCommand(this.action);
}
