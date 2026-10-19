// lib/models/connection_request_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  const ConnectionRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.status,
    required this.createdAt,
  });

  factory ConnectionRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return ConnectionRequestModel(
      id: docId,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      receiverName: map['receiverName'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int) : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
