import 'location_point.dart';

class JourneyModel {
  final String id;
  final String userId;
  final bool isActive;
  final DateTime startTime;
  final DateTime? endTime;
  final String? destinationName;
  final LocationPoint? lastKnownLocation;
  final List<String> contactIds;
  final bool isPanicTriggered;
  final bool isBatteryAlerted;
  final bool isInactivityAlerted;
  final DateTime expiresAt;

  const JourneyModel({
    required this.id,
    required this.userId,
    required this.isActive,
    required this.startTime,
    this.endTime,
    this.destinationName,
    this.lastKnownLocation,
    required this.contactIds,
    this.isPanicTriggered = false,
    this.isBatteryAlerted = false,
    this.isInactivityAlerted = false,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'isActive': isActive,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'destinationName': destinationName,
      'lastKnownLocation': lastKnownLocation?.toMap(),
      'contactIds': contactIds,
      'isPanicTriggered': isPanicTriggered,
      'isBatteryAlerted': isBatteryAlerted,
      'isInactivityAlerted': isInactivityAlerted,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory JourneyModel.fromMap(Map<String, dynamic> map, String docId) {
    return JourneyModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? false,
      startTime: map['startTime'] != null
          ? DateTime.tryParse(map['startTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      endTime: map['endTime'] != null
          ? DateTime.tryParse(map['endTime'] as String)
          : null,
      destinationName: map['destinationName'] as String?,
      lastKnownLocation: map['lastKnownLocation'] != null
          ? LocationPoint.fromMap(Map<String, dynamic>.from(map['lastKnownLocation']))
          : null,
      contactIds: List<String>.from(map['contactIds'] ?? []),
      isPanicTriggered: map['isPanicTriggered'] as bool? ?? false,
      isBatteryAlerted: map['isBatteryAlerted'] as bool? ?? false,
      isInactivityAlerted: map['isInactivityAlerted'] as bool? ?? false,
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'] as String) ?? DateTime.now().add(const Duration(hours: 12))
          : DateTime.now().add(const Duration(hours: 12)),
    );
  }

  JourneyModel copyWith({
    String? id,
    String? userId,
    bool? isActive,
    DateTime? startTime,
    DateTime? endTime,
    String? destinationName,
    LocationPoint? lastKnownLocation,
    List<String>? contactIds,
    bool? isPanicTriggered,
    bool? isBatteryAlerted,
    bool? isInactivityAlerted,
    DateTime? expiresAt,
  }) {
    return JourneyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      destinationName: destinationName ?? this.destinationName,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      contactIds: contactIds ?? this.contactIds,
      isPanicTriggered: isPanicTriggered ?? this.isPanicTriggered,
      isBatteryAlerted: isBatteryAlerted ?? this.isBatteryAlerted,
      isInactivityAlerted: isInactivityAlerted ?? this.isInactivityAlerted,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
