import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';

typedef ReaderAutoPageTimerFactory =
    Timer Function(Duration interval, void Function(Timer timer) onTick);

class ReaderAutoPageController extends ChangeNotifier {
  ReaderAutoPageController({
    required this.runtime,
    Duration interval = const Duration(seconds: 8),
    ReaderAutoPageTimerFactory? timerFactory,
  }) : _interval = interval,
       _timerFactory = timerFactory ?? Timer.periodic;

  final ReaderRuntime runtime;
  final Duration _interval;
  final ReaderAutoPageTimerFactory _timerFactory;
  Timer? _timer;

  bool get isRunning => _timer != null;

  void toggle() {
    if (isRunning) {
      stop();
      return;
    }
    start();
  }

  void start() {
    if (isRunning) return;
    _timer = _timerFactory(_interval, (_) => step());
    notifyListeners();
  }

  bool step() {
    final moved = runtime.moveToNextPage();
    if (!moved) stop();
    return moved;
  }

  void stop() {
    final timer = _timer;
    if (timer == null) return;
    timer.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
