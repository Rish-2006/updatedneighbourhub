import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/location_point.dart';

class LocationService {
  static Future<bool> requestLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      
      // Request background location permission if on mobile
      if (!kIsWeb) {
        await Permission.locationAlways.request();
      }

      return true;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return true;
    }
  }

  static Future<LocationPoint> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('GetCurrentLocation fallback triggered: $e');
      // Default to central fallback coordinates if GPS unavailable (e.g. emulator without GPS mock)
      return LocationPoint(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
      );
    }
  }

  static Stream<LocationPoint> getRealtimeLocationStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).map((pos) => LocationPoint(
            latitude: pos.latitude,
            longitude: pos.longitude,
            altitude: pos.altitude,
            speed: pos.speed,
            timestamp: DateTime.now(),
          ));
    } catch (e) {
      debugPrint('Realtime location stream fallback: $e');
      return Stream.value(LocationPoint(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
      ));
    }
  }
}
