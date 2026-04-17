import 'package:flutter/scheduler.dart';

class ReaderAutoPageCoordinator {
  bool isActive = false;
  bool isPaused = false;
  double speed = 30.0;

  Ticker? _ticker;
  Duration _lastTickTime = Duration.zero;

  void attachTicker(
    Ticker Function(TickerCallback) createTicker, {
    required bool Function() shouldTick,
    required void Function(double dtSeconds) onTick,
  }) {
    _ticker?.stop();
    _ticker?.dispose();
    _lastTickTime = Duration.zero;
    _ticker = createTicker((elapsed) {
      if (!isActive || isPaused || !shouldTick()) {
        _lastTickTime = Duration.zero;
        return;
      }
      if (_lastTickTime == Duration.zero) {
        _lastTickTime = elapsed;
        return;
      }
      final dtSeconds =
          (elapsed.inMicroseconds - _lastTickTime.inMicroseconds) / 1000000.0;
      _lastTickTime = elapsed;
      onTick(dtSeconds);
    });
    syncTickerState();
  }

  void syncTickerState() {
    final ticker = _ticker;
    if (ticker == null) return;
    if (isActive && !isPaused) {
      if (!ticker.isActive) {
        ticker.start();
      }
      return;
    }
    if (ticker.isActive) {
      ticker.stop();
    }
    _lastTickTime = Duration.zero;
  }

  void detachTicker() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _lastTickTime = Duration.zero;
  }

  void stop() {
    isActive = false;
    isPaused = false;
    syncTickerState();
  }

  void dispose() {
    detachTicker();
  }
}
