import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/journey_model.dart';
import 'pulse_indicator.dart';
import 'custom_button.dart';

class JourneyStatusCard extends StatelessWidget {
  final JourneyModel? activeJourney;
  final VoidCallback onStartJourney;
  final VoidCallback onEndJourney;
  final VoidCallback onShareLink;
  final String elapsedTimeString;

  const JourneyStatusCard({
    super.key,
    required this.activeJourney,
    required this.onStartJourney,
    required this.onEndJourney,
    required this.onShareLink,
    required this.elapsedTimeString,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeJourney != null && activeJourney!.isActive;

    return Card(
      color: isActive ? AppColors.surfaceAlt : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      elevation: isActive ? 8 : 2,
      shadowColor: isActive ? AppColors.primary.withValues(alpha: 0.3) : Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PulseIndicator(
                  color: isActive ? AppColors.success : AppColors.textMuted,
                  size: 14,
                ),
                const SizedBox(width: 10),
                Text(
                  isActive ? 'ACTIVE JOURNEY' : 'DISPOSABLE SAFETY MODE',
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: AppColors.accent),
                    onPressed: onShareLink,
                    tooltip: 'Share Web Tracking Link',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? (activeJourney?.destinationName ?? 'Journey in Progress')
                  : 'Ready to start a protected trip?',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isActive
                  ? 'Sharing live location with trusted contacts until you confirm arrival.'
                  : 'Location shared silently with selected contacts only for the duration of this single journey.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ELAPSED TIME',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        elapsedTimeString,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'BATTERY GUARD',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Active (<15% alert)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            isActive
                ? CustomButton(
                    text: 'I\'m Safe (End Journey)',
                    onPressed: onEndJourney,
                    variant: ButtonVariant.coral,
                    icon: Icons.check_circle_outline,
                  )
                : CustomButton(
                    text: 'Start Journey Now',
                    onPressed: onStartJourney,
                    variant: ButtonVariant.primary,
                    icon: Icons.navigation_outlined,
                  ),
          ],
        ),
      ),
    );
  }
}
