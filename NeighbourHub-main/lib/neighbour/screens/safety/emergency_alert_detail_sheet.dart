// lib/screens/safety/emergency_alert_detail_sheet.dart
//
// Bottom sheet shown when a user taps an emergency notification.
// Displays the alert details in a prominent emergency style.

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';

class EmergencyAlertDetailSheet extends StatelessWidget {
  final NotificationModel notification;

  const EmergencyAlertDetailSheet({super.key, required this.notification});

  /// Convenience helper — show this sheet from any [BuildContext].
  static void show(BuildContext context, NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmergencyAlertDetailSheet(notification: notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final senderName = notification.senderName ?? notification.title;
    final apartment = notification.senderApartment;
    final hasApartment = apartment != null && apartment.isNotEmpty;
    final timeStr = timeago.format(notification.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: AppTheme.errorColor, width: 2),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // ── Siren banner ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🚨', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Text(
                  'Community Emergency',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Main message ──────────────────────────────────────────────
          Text(
            '$senderName needs help.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Please check on your neighbour and provide assistance if possible.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkSubtext,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // ── Details card ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.darkBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Reported', value: timeStr),
                const Divider(height: 20),
                _DetailRow(label: 'Neighbour', value: senderName),
                if (hasApartment) ...[
                  const Divider(height: 20),
                  _DetailRow(label: 'Flat', value: apartment),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Dismiss ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: AppTheme.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Got it — I\'ll check on them',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helper ──────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.darkSubtext,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
