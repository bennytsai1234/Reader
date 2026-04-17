import 'dart:async';

import 'reader_provider_base.dart';

/// 處理閱讀器內部的虛擬電池電量模擬
mixin ReaderBatteryMixin on ReaderProviderBase {
  Timer? _heartbeatTimer;

  int get batteryLevel => batteryLevelNotifier.value;

  void startBatteryHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      batteryLevelNotifier.value = (batteryLevelNotifier.value - 1).clamp(
        0,
        100,
      );
    });
  }

  void stopBatteryHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}
