// lib/models/connection_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;

  const ConnectionModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
  });

  factory ConnectionModel.fromMap(Map<String, dynamic> map, String docId) {
    return ConnectionModel(
      id: docId,
      user1Id: map['user1Id'] as String? ?? '',
      user2Id: map['user2Id'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int) : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
