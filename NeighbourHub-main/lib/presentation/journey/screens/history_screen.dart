import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/journey_model.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../providers/journey_provider.dart';
import '../../auth/providers/auth_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return 'Incomplete';
    final diff = end.difference(start);
    final mins = diff.inMinutes;
    if (mins < 1) return '< 1 min';
    if (mins < 60) return '$mins mins';
    final hrs = (mins / 60).toStringAsFixed(1);
    return '$hrs hours';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(journeyRepositoryProvider);
    final user = ref.watch(authStateProvider).value;
    final userId = user?.uid ?? 'demo_user_123';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navHistory),
      ),
      body: FutureBuilder<List<JourneyModel>>(
        future: repository.getJourneyHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final histories = snapshot.data ?? [];

          if (histories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history_toggle_off, color: AppColors.textMuted, size: 56),
                  SizedBox(height: 12),
                  Text(
                    'No Journey History Yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Completed journeys will be logged here privately.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final journey = histories[index];
              final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(journey.startTime);
              final durationStr = _formatDuration(journey.startTime, journey.endTime);

              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: journey.isPanicTriggered
                              ? AppColors.danger.withValues(alpha: 0.2)
                              : AppColors.surfaceAlt,
                        ),
                        child: Icon(
                          journey.isPanicTriggered
                              ? Icons.warning_amber_rounded
                              : Icons.navigation_outlined,
                          color: journey.isPanicTriggered
                              ? AppColors.danger
                              : AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              journey.destinationName ?? 'Completed Journey',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'Arrived Safe',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            durationStr,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) context.go('/');
          if (index == 1) context.go('/contacts');
        },
      ),
    );
  }
}
