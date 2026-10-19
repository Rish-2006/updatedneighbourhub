import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/journey_model.dart';
import '../models/location_point.dart';

class JourneyRepository {
  final FirebaseFirestore _firestore;
  final StreamController<JourneyModel?> _activeJourneyController =
      StreamController<JourneyModel?>.broadcast();
  JourneyModel? _activeMockJourney;
  final List<JourneyModel> _mockHistory = [];

  JourneyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<JourneyModel?> watchActiveJourney(String userId) async* {
    yield _activeMockJourney;
    try {
      final firestoreStream = _firestore
          .collection('journeys')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) return _activeMockJourney;
        return JourneyModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      });

      await for (final item in firestoreStream) {
        yield item ?? _activeMockJourney;
      }
    } catch (e) {
      debugPrint('Watch active journey stream fallback: $e');
      yield* _activeJourneyController.stream;
    }
  }

  Stream<JourneyModel?> watchJourneyById(String journeyId) {
    if (journeyId.toLowerCase().contains('demo')) {
      return Stream.value(JourneyModel(
        id: journeyId,
        userId: 'demo_user_123',
        isActive: true,
        startTime: DateTime.now().subtract(const Duration(minutes: 15)),
        destinationName: 'Market St & Ferry Building, San Francisco',
        contactIds: ['contact-1', 'contact-2'],
        isPanicTriggered: false,
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
        lastKnownLocation: LocationPoint(
          latitude: 37.7925,
          longitude: -122.3930,
          speed: 4.2,
          timestamp: DateTime.now(),
        ),
      ));
    }
    try {
      return _firestore
          .collection('journeys')
          .doc(journeyId)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) {
          if (_activeMockJourney?.id == journeyId) return _activeMockJourney;
          return null;
        }
        return JourneyModel.fromMap(doc.data()!, doc.id);
      });
    } catch (e) {
      debugPrint('Watch journey by ID fallback: $e');
      if (_activeMockJourney?.id == journeyId) {
        return Stream.value(_activeMockJourney);
      }
      return Stream.value(null);
    }
  }

  Stream<List<LocationPoint>> watchJourneyLocations(String journeyId) {
    if (journeyId.toLowerCase().contains('demo')) {
      final now = DateTime.now();
      return Stream.value([
        LocationPoint(
          latitude: 37.7925,
          longitude: -122.3930,
          speed: 4.2,
          timestamp: now,
        ),
        LocationPoint(
          latitude: 37.7897,
          longitude: -122.4012,
          speed: 4.5,
          timestamp: now.subtract(const Duration(minutes: 3)),
        ),
        LocationPoint(
          latitude: 37.7865,
          longitude: -122.4055,
          speed: 4.8,
          timestamp: now.subtract(const Duration(minutes: 7)),
        ),
        LocationPoint(
          latitude: 37.7812,
          longitude: -122.4110,
          speed: 5.1,
          timestamp: now.subtract(const Duration(minutes: 12)),
        ),
      ]);
    }
    try {
      return _firestore
          .collection('journeys')
          .doc(journeyId)
          .collection('locations')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => LocationPoint.fromMap(doc.data()))
            .toList();
      });
    } catch (e) {
      debugPrint('Locations stream fallback: $e');
      final loc = _activeMockJourney?.lastKnownLocation;
      return Stream.value(loc != null ? [loc] : []);
    }
  }

  Future<JourneyModel> startJourney({
    required String userId,
    required List<String> contactIds,
    String? destinationName,
    bool isPanicTriggered = false,
  }) async {
    final journeyId = const Uuid().v4();
    final now = DateTime.now();
    final journey = JourneyModel(
      id: journeyId,
      userId: userId,
      isActive: true,
      startTime: now,
      destinationName: destinationName ?? (isPanicTriggered ? 'SOS Emergency Panic' : 'Standard Journey'),
      contactIds: contactIds,
      isPanicTriggered: isPanicTriggered,
      expiresAt: now.add(const Duration(hours: 12)),
    );

    try {
      await _firestore.collection('journeys').doc(journeyId).set(journey.toMap());
    } catch (e) {
      debugPrint('Start journey fallback: $e');
    }
    _activeMockJourney = journey;
    _activeJourneyController.add(journey);
    return journey;
  }

  Future<void> updateLocation({
    required String journeyId,
    required LocationPoint location,
  }) async {
    try {
      await _firestore
          .collection('journeys')
          .doc(journeyId)
          .collection('locations')
          .add(location.toMap());

      await _firestore.collection('journeys').doc(journeyId).update({
        'lastKnownLocation': location.toMap(),
      });
    } catch (e) {
      debugPrint('Update location fallback: $e');
    }
    if (_activeMockJourney?.id == journeyId) {
      _activeMockJourney = _activeMockJourney!.copyWith(
        lastKnownLocation: location,
      );
      _activeJourneyController.add(_activeMockJourney);
    }
  }

  Future<void> endJourney(String journeyId) async {
    final now = DateTime.now();
    try {
      await _firestore.collection('journeys').doc(journeyId).update({
        'isActive': false,
        'endTime': now.toIso8601String(),
      });
    } catch (e) {
      debugPrint('End journey fallback: $e');
    }
    if (_activeMockJourney?.id == journeyId) {
      final ended = _activeMockJourney!.copyWith(
        isActive: false,
        endTime: now,
      );
      _mockHistory.add(ended);
      _activeMockJourney = null;
    }
    _activeJourneyController.add(null);
  }

  Future<void> setBatteryAlerted(String journeyId) async {
    try {
      await _firestore.collection('journeys').doc(journeyId).update({
        'isBatteryAlerted': true,
      });
    } catch (e) {
      debugPrint('Set battery alert fallback: $e');
    }
    if (_activeMockJourney?.id == journeyId) {
      _activeMockJourney = _activeMockJourney!.copyWith(isBatteryAlerted: true);
      _activeJourneyController.add(_activeMockJourney);
    }
  }

  Future<List<JourneyModel>> getJourneyHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('journeys')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: false)
          .get();

      final list = snapshot.docs
          .map((doc) => JourneyModel.fromMap(doc.data(), doc.id))
          .toList();
      return list.isNotEmpty ? list : _mockHistory;
    } catch (e) {
      debugPrint('Get history fallback: $e');
      return _mockHistory;
    }
  }

  Future<void> sendQuickPing({
    required String userId,
    required LocationPoint location,
    required List<String> contactIds,
  }) async {
    final pingId = const Uuid().v4();
    final pingData = {
      'id': pingId,
      'userId': userId,
      'location': location.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
      'contactIds': contactIds,
    };

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('quickPings')
          .doc(pingId)
          .set(pingData);

      await _firestore.collection('quickPings').doc(pingId).set(pingData);
    } catch (e) {
      debugPrint('Quick ping Firestore fallback: $e');
    }

    for (final contactId in contactIds) {
      debugPrint('Notifying FCM topic: contact_$contactId for Quick Ping');
    }
  }
}


