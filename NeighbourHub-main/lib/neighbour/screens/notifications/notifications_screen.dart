// lib/screens/notifications/notifications_screen.dart
//
// Shows a list of all user notifications with mark-as-read functionality.
// Emergency notifications open a detail bottom sheet on tap.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_card.dart';
import '../safety/emergency_alert_detail_sheet.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _markAllAsRead() async {
    final userId = context.read<AuthService>().currentUser?.uid ?? '';
    await context.read<FirestoreService>().markAllNotificationsRead(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  Future<void> _onNotificationTap(NotificationModel notif) async {
    // Mark as read first
    if (!notif.isRead) {
      await context.read<FirestoreService>().markNotificationRead(notif.id);
    }

    if (!mounted) return;

    // For emergency notifications, open the detail bottom sheet
    if (notif.type == NotificationType.emergency) {
      EmergencyAlertDetailSheet.show(context, notif);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: context.read<FirestoreService>().getNotificationsStream(userId),
            builder: (context, snapshot) {
              final unreadCount = (snapshot.data ?? []).where((n) => !n.isRead).length;
              if (unreadCount > 0) {
                return TextButton(
                  onPressed: _markAllAsRead,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: context.read<FirestoreService>().getNotificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          return notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) {
                    // Emergency cards have their own container margin — skip divider between them
                    final isEmergency =
                        notifications[index].type == NotificationType.emergency;
                    return isEmergency
                        ? const SizedBox.shrink()
                        : const Divider(height: 1);
                  },
                  itemBuilder: (context, index) {
                    return NotificationCard(
                      notification: notifications[index],
                      onTap: () => _onNotificationTap(notifications[index]),
                    ).animate().fadeIn(delay: (index * 50).ms);
                  },
                );
        },
      ),
    );
  }
}
