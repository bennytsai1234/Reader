import 'dart:async';
import 'package:flutter/foundation.dart';

class ReaderPerfTrace {
  static void mark(String label) {
    if (kReleaseMode) return;
    debugPrint('ReaderPerf: $label');
  }

  static T measureSync<T>(String label, T Function() action) {
    if (kReleaseMode) {
      return action();
    }

    final stopwatch = Stopwatch()..start();
    final result = action();
    stopwatch.stop();
    debugPrint('ReaderPerf: $label took ${stopwatch.elapsedMilliseconds}ms');
    return result;
  }

  static Future<T> measureAsync<T>(
    String label,
    Future<T> Function() action,
  ) async {
    if (kReleaseMode) {
      return action();
    }

    final stopwatch = Stopwatch()..start();
    final result = await action();
    stopwatch.stop();
    debugPrint('ReaderPerf: $label took ${stopwatch.elapsedMilliseconds}ms');
    return result;
  }
}
