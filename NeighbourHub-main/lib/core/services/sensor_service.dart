import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  static const double shakeThreshold = 27.0; // tuned firm shake threshold (m/s^2)
  static const int debounceMs = 1500;

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  DateTime _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);

  void startShakeDetection({required VoidCallback onPanicDetected}) {
    if (kIsWeb) return;

    _subscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      final double gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (gForce > shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inMilliseconds > debounceMs) {
          _lastShakeTime = now;
          debugPrint('FIRM SHAKE DETECTED! G-Force: $gForce m/s^2. Triggering panic alert.');
          onPanicDetected();
        }
      }
    });
  }

  void stopShakeDetection() {
    _subscription?.cancel();
    _subscription = null;
  }
}
