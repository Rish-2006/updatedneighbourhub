// lib/widgets/notification_card.dart
//
// Card widget for a single notification item.
// Emergency notifications get a distinct red visual treatment.
// All other notifications use the standard style.

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification_model.dart';
import '../theme/app_theme.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
  });

  bool get _isEmergency => notification.type == NotificationType.emergency;

  @override
  Widget build(BuildContext context) {
    return _isEmergency
        ? _EmergencyNotificationCard(notification: notification, onTap: onTap)
        : _StandardNotificationCard(notification: notification, onTap: onTap);
  }
}

// ─── Standard notification (existing style, unchanged) ────────────────────────
class _StandardNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const _StandardNotificationCard({
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        // Unread notifications get a subtle tinted background
        color: isUnread
            ? AppTheme.primaryColor.withValues(alpha: 0.06)
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji icon in a circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  notification.type.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      // Blue dot for unread
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Emergency notification (distinct red card) ───────────────────────────────
class _EmergencyNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const _EmergencyNotificationCard({
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: isUnread ? 0.10 : 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.errorColor.withValues(alpha: isUnread ? 0.5 : 0.25),
            width: isUnread ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────────
            Row(
              children: [
                const Text('🚨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'EMERGENCY',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Main message ─────────────────────────────────────────
            Text(
              notification.message,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              'Please check on your neighbour and provide assistance if possible.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.white.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),

            // ── Timestamp + tap hint ─────────────────────────────────
            Row(
              children: [
                Text(
                  timeago.format(notification.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap for details →',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
