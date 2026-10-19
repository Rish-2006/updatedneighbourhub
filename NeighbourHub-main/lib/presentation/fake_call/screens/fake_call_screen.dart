import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/audio_vibration_service.dart';

class FakeCallOverlay extends StatefulWidget {
  final String callerName;
  final VoidCallback onDismiss;

  const FakeCallOverlay({
    super.key,
    this.callerName = 'Mom',
    required this.onDismiss,
  });

  @override
  State<FakeCallOverlay> createState() => _FakeCallOverlayState();
}

class _FakeCallOverlayState extends State<FakeCallOverlay> {
  final AudioVibrationService _audioService = AudioVibrationService();
  bool _isCallConnected = false;
  int _callSeconds = 0;
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    _audioService.startRingtoneAndVibration();
  }

  @override
  void dispose() {
    _audioService.stopRingtoneAndVibration();
    _callTimer?.cancel();
    super.dispose();
  }

  void _acceptCall() {
    _audioService.stopRingtoneAndVibration();
    setState(() {
      _isCallConnected = true;
    });
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callSeconds++;
        });
      }
    });
  }

  void _declineOrEndCall() {
    _audioService.stopRingtoneAndVibration();
    _callTimer?.cancel();
    widget.onDismiss();
  }

  String _formatTimer(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0B18),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceAlt,
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.person, size: 56, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isCallConnected
                  ? _formatTimer(_callSeconds)
                  : 'Incoming Mobile Call...',
              style: TextStyle(
                color: _isCallConnected ? AppColors.success : AppColors.coral,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (!_isCallConnected) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decline Button
                    GestureDetector(
                      onTap: _declineOrEndCall,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.danger,
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Decline',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    // Accept Button
                    GestureDetector(
                      onTap: _acceptCall,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                            ),
                            child: const Icon(Icons.call, color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Accept',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Connected Call Action Button
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: GestureDetector(
                  onTap: _declineOrEndCall,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger,
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'End Call',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
