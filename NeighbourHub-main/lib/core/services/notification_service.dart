import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('User notification permission status: ${settings.authorizationStatus}');

      // Retrieve FCM Token
      if (!kIsWeb) {
        final token = await _messaging.getToken();
        debugPrint('FCM Token: $token');
      }

      // Foreground notification handling
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground FCM message: ${message.notification?.title}');
        final notification = message.notification;
        if (notification != null) {
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title ?? 'NeighbourHub Alert',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (notification.body != null)
                          Text(
                            notification.body!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });

      // Background notification tap handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification opened app: ${message.data}');
      });
    } catch (e) {
      debugPrint('NotificationService initialization note: $e');
    }
  }

  Future<void> subscribeToContactTopic(String contactId) async {
    if (kIsWeb) {
      debugPrint('FCM topic subscription skipped on web platform');
      return;
    }
    try {
      final topic = 'contact_$contactId';
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to FCM topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to FCM topic contact_$contactId: $e');
    }
  }

  Future<void> unsubscribeFromContactTopic(String contactId) async {
    if (kIsWeb) {
      debugPrint('FCM topic unsubscription skipped on web platform');
      return;
    }
    try {
      final topic = 'contact_$contactId';
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from FCM topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from FCM topic contact_$contactId: $e');
    }
  }

  Future<void> syncContactSubscriptions(String userId, List<String> contactIds) async {
    if (kIsWeb) return;
    await subscribeToContactTopic(userId);
    for (final cId in contactIds) {
      await subscribeToContactTopic(cId);
    }
  }
}
