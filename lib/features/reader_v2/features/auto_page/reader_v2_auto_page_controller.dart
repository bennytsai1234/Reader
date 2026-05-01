import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_viewport_controller.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_runtime.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_state.dart';

typedef ReaderV2AutoPageTimerFactory =
    Timer Function(Duration interval, void Function(Timer timer) onTick);

class ReaderV2AutoPageController extends ChangeNotifier {
  ReaderV2AutoPageController({
    required this.runtime,
    ReaderV2ViewportController? viewportController,
    double Function()? viewportExtent,
    Duration interval = const Duration(seconds: 8),
    ReaderV2AutoPageTimerFactory? timerFactory,
  }) : _viewportController = viewportController,
       _viewportExtent = viewportExtent,
       _interval = interval,
       _timerFactory = timerFactory ?? Timer.periodic;

  final ReaderV2Runtime runtime;
  final ReaderV2ViewportController? _viewportController;
  final double Function()? _viewportExtent;
  final Duration _interval;
  final ReaderV2AutoPageTimerFactory _timerFactory;
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

  Future<bool> _step() async {
    if (runtime.state.mode == ReaderV2Mode.scroll) {
      final delta = _scrollStepDelta();
      if (delta > 0) {
        final animateBy = _viewportController?.animateBy;
        if (animateBy != null && await animateBy(delta)) return true;
        final scrollBy = _viewportController?.scrollBy;
        if (scrollBy != null && await scrollBy(delta)) return true;
      }
      final moveToNextPage = _viewportController?.moveToNextPage;
      if (moveToNextPage != null && await moveToNextPage()) return true;
      final moved = runtime.moveToNextPage();
      return Future<bool>.value(moved);
    }
    final moveToNextPage = _viewportController?.moveToNextPage;
    if (moveToNextPage != null && await moveToNextPage()) return true;
    final moved = runtime.moveSlidePageAndSettle(forward: true);
    return Future<bool>.value(moved);
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
