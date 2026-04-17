import 'dart:async';
import 'package:flutter/foundation.dart';

/// 處理閱讀器內部的虛擬電池電量模擬
mixin ReaderBatteryMixin {
  final ValueNotifier<int> batteryLevelNotifier = ValueNotifier<int>(100);
  Timer? _heartbeatTimer;

  int get batteryLevel => batteryLevelNotifier.value;

  void startBatteryHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      batteryLevelNotifier.value = (batteryLevelNotifier.value - 1).clamp(0, 100);
    });
  }

  void stopBatteryHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}
