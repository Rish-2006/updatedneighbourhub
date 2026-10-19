import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

class BatteryService {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _stateSubscription;
  bool _alertTriggered = false;

  void startBatteryMonitoring({
    required Function(int level) onCriticalBattery,
  }) {
    if (kIsWeb) return;

    _stateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) async {
      final level = await _battery.batteryLevel;
      if (level <= 15 && !_alertTriggered) {
        _alertTriggered = true;
        onCriticalBattery(level);
      } else if (level > 15) {
        _alertTriggered = false;
      }
    });
  }

  void stopMonitoring() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
  }
}
