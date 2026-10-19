import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

class AudioVibrationService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _vibrationTimer;

  Future<void> startRingtoneAndVibration() async {
    try {
      // Play ringtone tone sound loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('ringtone.mp3'));
    } catch (e) {
      debugPrint('Ringtone playback fallback (using synth sound): $e');
    }

    if (!kIsWeb) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
            Vibration.vibrate(duration: 800, amplitude: 128);
          });
        }
      } catch (e) {
        debugPrint('Vibration fallback: $e');
      }
    }
  }

  Future<void> stopRingtoneAndVibration() async {
    try {
      await _audioPlayer.stop();
      _vibrationTimer?.cancel();
      _vibrationTimer = null;
      if (!kIsWeb) {
        Vibration.cancel();
      }
    } catch (e) {
      debugPrint('Stop audio/vibration error: $e');
    }
  }
}
