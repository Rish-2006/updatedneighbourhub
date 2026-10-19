import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'location_service.dart';
import '../../data/repositories/journey_repository.dart';

class BackgroundTrackingService {
  static const String notificationChannelId = 'neighbourhub_tracking_channel';
  static const int notificationId = 888;

  static Future<void> initializeService() async {
    if (kIsWeb) return;

    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'NeighbourHub Active Tracking',
      description: 'Persistent notification while journey safety tracking is active',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'NeighbourHub Live Protection',
        initialNotificationContent: 'Sharing location silently with trusted contacts',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> startTracking(String journeyId) async {
    if (kIsWeb) return;
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
    service.invoke('setJourneyId', {'journeyId': journeyId});
  }

  static Future<void> stopTracking() async {
    if (kIsWeb) return;
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke('stopService');
    }
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    String activeJourneyId = '';

    service.on('setJourneyId').listen((event) {
      if (event != null && event.containsKey('journeyId')) {
        activeJourneyId = event['journeyId'] as String;
      }
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    final repository = JourneyRepository();

    Timer.periodic(const Duration(seconds: 20), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: 'NeighbourHub Active Protection',
            content: 'Live location updated at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          );
        }
      }

      if (activeJourneyId.isNotEmpty) {
        try {
          final loc = await LocationService.getCurrentLocation();
          await repository.updateLocation(
            journeyId: activeJourneyId,
            location: loc,
          );
        } catch (e) {
          debugPrint('Background location tick error: $e');
        }
      }
    });
  }
}
