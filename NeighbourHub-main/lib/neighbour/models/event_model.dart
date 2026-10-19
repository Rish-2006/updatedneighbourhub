// lib/models/event_model.dart
//
// Represents a community event stored in Firestore 'events' collection.
// Fields: title, description, date, startTime, endTime, place, additionalDetails, createdAt, createdBy.

import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;            // The date of the event
  final String startTime;         // e.g. "8:00 AM"
  final String endTime;           // e.g. "11:00 AM"
  final String place;             // Venue / location
  final String additionalDetails; // Optional extra info
  final String createdBy;         // User ID of creator
  final String createdByName;     // Creator's display name
  final DateTime createdAt;
  final String emoji;             // kept for legacy widget compat
  final List<String> participants;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.startTime = '',
    this.endTime = '',
    this.place = '',
    this.additionalDetails = '',
    required this.createdBy,
    this.createdByName = 'Admin',
    DateTime? createdAt,
    this.emoji = '📅',
    this.participants = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  // ── Legacy getters for backward compat ──────────────────────────────────────
  String get location => place;
  int get participantCount => participants.length;
  bool isUserJoined(String userId) => participants.contains(userId);

  // ── fromMap ─────────────────────────────────────────────────────────────────
  factory EventModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.now();
    }

    final place = map['place'] as String? ?? map['location'] as String? ?? '';
    return EventModel(
      id: docId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: parseDate(map['date']),
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      place: place,
      additionalDetails: map['additionalDetails'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? 'Admin',
      createdAt: parseDate(map['createdAt']),
      emoji: map['emoji'] as String? ?? '📅',
      participants: List<String>.from(map['participants'] as List? ?? []),
    );
  }

  // ── toMap ───────────────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'place': place,
      'location': place, // legacy field kept in sync
      'additionalDetails': additionalDetails,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'emoji': emoji,
      'participants': participants,
    };
  }

  // ── toMapForUpdate (no createdAt override) ──────────────────────────────────
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'place': place,
      'location': place,
      'additionalDetails': additionalDetails,
      'emoji': emoji,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? place,
    String? additionalDetails,
    String? createdBy,
    String? createdByName,
    String? emoji,
    List<String>? participants,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      place: place ?? this.place,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      emoji: emoji ?? this.emoji,
      participants: participants ?? this.participants,
      createdAt: createdAt,
    );
  }
}
