import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_viewport_controller.dart';

typedef ReaderAutoPageTimerFactory =
    Timer Function(Duration interval, void Function(Timer timer) onTick);

class ReaderAutoPageController extends ChangeNotifier {
  ReaderAutoPageController({
    required this.runtime,
    ReaderViewportController? viewportController,
    double Function()? viewportExtent,
    Duration interval = const Duration(seconds: 8),
    ReaderAutoPageTimerFactory? timerFactory,
  }) : _viewportController = viewportController,
       _viewportExtent = viewportExtent,
       _interval = interval,
       _timerFactory = timerFactory ?? Timer.periodic;

  final ReaderRuntime runtime;
  final ReaderViewportController? _viewportController;
  final double Function()? _viewportExtent;
  final Duration _interval;
  final ReaderAutoPageTimerFactory _timerFactory;
  Timer? _timer;
  bool _stepping = false;

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
    _timer = _timerFactory(_interval, (_) => unawaited(stepAsync()));
    notifyListeners();
  }

  Future<bool> stepAsync() async {
    if (_stepping) return false;
    _stepping = true;
    try {
      final moved = await _step();
      if (!moved) stop();
      return moved;
    } finally {
      _stepping = false;
    }
  }

  bool step() {
    final moved = runtime.moveToNextPage();
    if (!moved) stop();
    return moved;
  }

  Future<bool> _step() async {
    if (runtime.state.mode == ReaderMode.scroll) {
      final delta = _scrollStepDelta();
      if (delta > 0) {
        final animateBy = _viewportController?.animateBy;
        if (animateBy != null) return animateBy(delta);
        final scrollBy = _viewportController?.scrollBy;
        if (scrollBy != null) return scrollBy(delta);
      }
    }
    return step();
  }

  double _scrollStepDelta() {
    final explicit = _viewportExtent?.call();
    final viewportHeight =
        explicit != null && explicit.isFinite && explicit > 0
            ? explicit
            : runtime.state.layoutSpec.viewportSize.height;
    if (!viewportHeight.isFinite || viewportHeight <= 0) return 0;
    return viewportHeight * 0.9;
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
