class LocationPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;
  final int? batteryLevel;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    required this.timestamp,
    this.batteryLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'batteryLevel': batteryLevel,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      batteryLevel: map['batteryLevel'] as int?,
    );
  }
}
