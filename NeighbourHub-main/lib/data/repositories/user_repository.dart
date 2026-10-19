import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    try {
      return _firestore.collection('users').doc(uid).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return UserModel.fromMap(doc.data()!, doc.id);
      });
    } catch (e) {
      debugPrint('Error watching user profile: $e');
      return Stream.value(null);
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user profile (fallback active): $e');
    }
  }
}
