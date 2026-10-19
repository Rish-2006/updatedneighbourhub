// lib/services/firestore_service.dart
//
// This service handles all reads and writes to our database.
// For this prototype, we are using in-memory mock data so it works
// perfectly across accounts without needing to set up Firebase!

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import '../models/help_request_model.dart';
import '../models/connection_request_model.dart';
import '../models/connection_model.dart';
import '../models/comment_model.dart';
import '../models/lost_found_model.dart';
import '../models/announcement_model.dart';
import '../data/mock_data.dart';

class FirestoreService {
  // In-memory global data (non-user features still use mock data)
  static final List<CommentModel> _comments = [];
  static final List<EventModel> _events = List.from(MockData.events);
  static final List<NotificationModel> _notifications = List.from(MockData.notifications);
  static final List<HelpRequestModel> _helpRequests = List.from(MockData.helpRequests);
  
  static final List<LostFoundModel> _lostFound = [];
  static final List<AnnouncementModel> _announcements = [];

  static final StreamController<List<CommentModel>> _commentsController = StreamController.broadcast();
  static final StreamController<List<LostFoundModel>> _lostFoundController = StreamController.broadcast();
  static final StreamController<List<AnnouncementModel>> _announcementController = StreamController.broadcast();

  FirestoreService() {
    // Populate lost and found if empty
    if (_lostFound.isEmpty && MockData.lostFoundItems.isNotEmpty) {
      for (var item in MockData.lostFoundItems) {
        try {
          _lostFound.add(LostFoundModel.fromMap(item, item['id'] ?? ''));
        } catch (_) {}
      }
    }
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  void _notifyComments() {
    _commentsController.add(List.from(_comments));
  }

  // ─── User Operations ──────────────────────────────────────────────────────

  /// Saves (upserts) a user document into Firestore.
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }


  /// Fetches a single user by their UID from Firestore.
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('getUser error: $e');
      return null;
    }
  }

  /// Checks whether a user document exists in Firestore.
  Future<bool> userExists(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists;
  }

  /// Gets all users in the same neighbourhood — used for the Members list.
  /// Falls back to all users if none match the neighbourhood (handles empty neighbourhood field).
  Future<List<UserModel>> getNeighbours(String neighbourhood) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snap;
      if (neighbourhood.isNotEmpty) {
        snap = await _db
            .collection('users')
            .where('neighbourhood', isEqualTo: neighbourhood)
            .get();
      } else {
        snap = await _db.collection('users').get();
      }
      return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('getNeighbours error: $e');
      return [];
    }
  }

  /// Gets ALL registered users — for the Members screen when neighbourhood is not set.
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snap = await _db.collection('users').get();
      return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      debugPrint('getAllUsers error: $e');
      return [];
    }
  }

  /// Real-time stream of ALL registered users
  Stream<List<UserModel>> getAllUsersStream() {
    return _db.collection('users').snapshots().map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  // ─── Post Operations ──────────────────────────────────────────────────────

  Stream<List<PostModel>> getPostsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Returns a real-time stream of posts created by a specific user.
  /// Results are sorted client-side to avoid requiring a Firestore composite index.
  Stream<List<PostModel>> getUserPostsStream(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort newest first in Dart — no composite index needed
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  Future<void> createPost(PostModel post) async {
    await _db.collection('posts').doc(post.id).set(post.toMap()).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Connection timeout. Please ensure Firestore Database is enabled in your Firebase Console!'),
    );
  }

  Future<void> toggleLike(String postId, String userId) async {
    final docRef = _db.collection('posts').doc(postId);
    final docSnap = await docRef.get();
    if (!docSnap.exists) return;
    
    final post = PostModel.fromMap(docSnap.data()!, docSnap.id);
    final likedBy = List<String>.from(post.likedBy);
    
    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }
    
    await docRef.update({
      'likedBy': likedBy,
      'likesCount': likedBy.length,
    });
  }

  // ─── Comment Operations ───────────────────────────────────────────────────

  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _db
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in Dart to avoid composite index requirement
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return comments;
    });
  }

  Future<void> addComment(CommentModel comment) async {
    // Write comment to Firestore
    final docRef = _db.collection('comments').doc(comment.id);
    await docRef.set(comment.toMap());
    
    // Update post comments count in Firestore
    final postRef = _db.collection('posts').doc(comment.postId);
    final postSnap = await postRef.get();
    if (postSnap.exists) {
      final post = PostModel.fromMap(postSnap.data()!, postSnap.id);
      await postRef.update({
        'commentsCount': post.commentsCount + 1,
      });
    }
  }

  // ─── Event Operations ─────────────────────────────────────────────────────

  /// All events sorted by date (admin use — shows all including past).
  Stream<List<EventModel>> getEventsStream() {
    return _db.collection('events').snapshots().map((snap) {
      final list = snap.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  /// Only upcoming events (today onwards) — for user-facing Community section.
  Stream<List<EventModel>> getUpcomingEventsStream() {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return _db
        .collection('events')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .where((e) => !e.date.isBefore(startOfToday))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  Future<void> joinEvent(EventModel event, UserModel user) async {
    final registrationId = '${event.id}_${user.id}';
    final registrationRef = _db.collection('event_registrations').doc(registrationId);
    final eventRef = _db.collection('events').doc(event.id);
    
    final batch = _db.batch();
    batch.set(registrationRef, {
      'eventId': event.id,
      'userId': user.id,
      'userName': user.name,
      'userEmail': user.email,
      'flatNumber': user.apartment,
      'registeredAt': FieldValue.serverTimestamp(),
    });
    
    batch.update(eventRef, {
      'participants': FieldValue.arrayUnion([user.id]),
    });
    
    await batch.commit();
  }

  Future<void> createEvent(EventModel event) async {
    final docRef = _db.collection('events').doc();
    final newEvent = event.copyWith(id: docRef.id);
    await docRef.set(newEvent.toMap());
  }

  Future<void> updateEvent(EventModel event) async {
    await _db.collection('events').doc(event.id).update(event.toUpdateMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
    final regs = await _db.collection('event_registrations').where('eventId', isEqualTo: eventId).get();
    if (regs.docs.isNotEmpty) {
      final batch = _db.batch();
      for (var doc in regs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Stream<List<Map<String, dynamic>>> getEventRegistrationsStream(String eventId) {
    return _db.collection('event_registrations').where('eventId', isEqualTo: eventId).snapshots().map((snap) {
      return snap.docs.map((doc) => doc.data()).toList();
    });
  }

  // ─── Notification Operations ──────────────────────────────────────────────

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final firestoreNotifs = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      final userNotifs = _notifications.where((n) => n.userId == userId).toList();
      final allNotifs = [...userNotifs, ...firestoreNotifs];
      allNotifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allNotifs;
    });
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final userNotifs = _notifications.where((n) => n.userId == userId).toList();
    
    try {
      final snap = await _db.collection('notifications').where('userId', isEqualTo: userId).get();
      final firestoreNotifs = snap.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList();
      userNotifs.addAll(firestoreNotifs);
    } catch (e) {
      debugPrint('Error getting Firestore notifications: $e');
    }

    userNotifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userNotifs;
  }

  Future<void> markNotificationRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      final n = _notifications[index];
      _notifications[index] = n.copyWith(isRead: true);
      return;
    }
    try {
      await _db.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('markNotificationRead error: $e');
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    try {
      final snap = await _db.collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _db.batch();
      for (var doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('markAllNotificationsRead error: $e');
    }
  }

  // ─── Help Request Operations ──────────────────────────────────────────────

  Future<List<HelpRequestModel>> getHelpRequests() async {
    final sorted = List<HelpRequestModel>.from(_helpRequests);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<void> createHelpRequest(HelpRequestModel request) async {
    _helpRequests.add(request);
  }

  // ─── Issue Reporting ──────────────────────────────────────────────────────

  Future<void> reportIssue(Map<String, dynamic> issueData) async {
    debugPrint('Issue reported: $issueData');
  }

  // ─── Emergency Community Alert ────────────────────────────────────────────

  /// Sends a community-wide emergency alert.
  ///
  /// 1. Writes an alert document to [community_alerts] collection.
  /// 2. Writes a notification document in [notifications] for every registered
  ///    user EXCEPT the sender — using a Firestore batch for atomicity.
  ///
  /// Returns the alert document ID on success, throws on failure.
  Future<String> sendEmergencyAlert({
    required String senderId,
    required String senderName,
    required String senderApartment,
  }) async {
    // Build message using actual sender name
    final message = '$senderName needs help.';

    // 1. Create the alert document
    final alertRef = _db.collection('community_alerts').doc();
    final alertData = {
      'senderId': senderId,
      'senderName': senderName,
      'senderApartment': senderApartment,
      'type': 'emergency',
      'message': message,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    };

    // 2. Fetch all users so we can notify each one
    final usersSnap = await _db.collection('users').get();
    final otherUsers = usersSnap.docs.where((d) => d.id != senderId).toList();

    // Firestore batch max is 500 writes — split if needed
    // For typical communities this is well within limits
    final batches = <WriteBatch>[];
    var currentBatch = _db.batch();
    int opCount = 0;

    // Write the alert itself
    currentBatch.set(alertRef, alertData);
    opCount++;

    for (final userDoc in otherUsers) {
      if (opCount >= 499) {
        batches.add(currentBatch);
        currentBatch = _db.batch();
        opCount = 0;
      }
      final notifRef = _db.collection('notifications').doc();
      currentBatch.set(notifRef, {
        'userId': userDoc.id,
        'title': '🚨 EMERGENCY COMMUNITY ALERT',
        'message': message,
        'type': 'emergency',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'senderId': senderId,
        'senderName': senderName,
        'senderApartment': senderApartment,
        'alertId': alertRef.id,
      });
      opCount++;
    }
    batches.add(currentBatch);

    // Commit all batches
    for (final batch in batches) {
      await batch.commit();
    }

    return alertRef.id;
  }

  // ─── Lost & Found Operations ──────────────────────────────────────────────

  Stream<List<LostFoundModel>> getLostFoundItemsStream() {
    return _db
        .collection('lost_found')
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((doc) => LostFoundModel.fromMap(doc.data(), doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> createLostFoundItem(LostFoundModel item) async {
    await _db.collection('lost_found').doc(item.id).set(item.toMap());
  }

  Future<void> updateLostFoundStatus(String itemId, String newStatus) async {
    await _db.collection('lost_found').doc(itemId).update({'status': newStatus, 'isResolved': newStatus == 'Returned' || newStatus == 'Closed'});
  }

  /// Submit a claim or "I Found This" response on a Lost & Found item.
  Future<void> submitClaim({
    required String itemId,
    required String itemTitle,
    required String itemOwnerId,
    required String claimantId,
    required String claimantName,
    required String claimLocation,
    required String claimDescription,
    required String claimType, // 'claim' for Found items, 'found_tip' for Lost items
  }) async {
    final batch = _db.batch();

    // Write the claim document
    final claimRef = _db.collection('lost_found_claims').doc();
    batch.set(claimRef, {
      'itemId': itemId,
      'itemTitle': itemTitle,
      'itemOwnerId': itemOwnerId,
      'claimantId': claimantId,
      'claimantName': claimantName,
      'claimLocation': claimLocation,
      'claimDescription': claimDescription,
      'claimType': claimType,
      'status': 'pending', // pending | accepted | rejected
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Mark the item as ClaimPending
    final itemRef = _db.collection('lost_found').doc(itemId);
    batch.update(itemRef, {'status': 'ClaimPending', 'isResolved': false});

    // Notify the item owner
    final notifRef = _db.collection('notifications').doc();
    final isFoundTip = claimType == 'found_tip';
    batch.set(notifRef, {
      'userId': itemOwnerId,
      'title': isFoundTip ? 'Someone May Have Found Your Item!' : 'New Claim on Your Found Item',
      'message': isFoundTip
          ? '$claimantName says they may have found your lost item: "$itemTitle". Tap to review.'
          : '$claimantName has submitted a claim for your found item: "$itemTitle". Tap to review.',
      'type': 'lostFoundClaim',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'claimId': claimRef.id,
      'itemId': itemId,
    });

    await batch.commit();
  }

  /// Owner accepts a claim — marks item Returned, notifies claimant.
  Future<void> acceptClaim({
    required String claimId,
    required String itemId,
    required String itemTitle,
    required String claimantId,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('lost_found_claims').doc(claimId), {'status': 'accepted'});
    batch.update(_db.collection('lost_found').doc(itemId), {'status': 'Returned', 'isResolved': true});
    final notifRef = _db.collection('notifications').doc();
    batch.set(notifRef, {
      'userId': claimantId,
      'title': 'Claim Accepted! 🎉',
      'message': 'Your claim for "$itemTitle" was accepted. Please coordinate with the owner.',
      'type': 'lostFoundClaim',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'itemId': itemId,
    });
    await batch.commit();
  }

  /// Owner rejects a claim — resets item to Active, notifies claimant.
  Future<void> rejectClaim({
    required String claimId,
    required String itemId,
    required String itemTitle,
    required String claimantId,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('lost_found_claims').doc(claimId), {'status': 'rejected'});
    batch.update(_db.collection('lost_found').doc(itemId), {'status': 'Active'});
    final notifRef = _db.collection('notifications').doc();
    batch.set(notifRef, {
      'userId': claimantId,
      'title': 'Claim Not Accepted',
      'message': 'Your claim for "$itemTitle" was not accepted. The item remains active.',
      'type': 'lostFoundClaim',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'itemId': itemId,
    });
    await batch.commit();
  }

  /// Get pending claims for a specific Lost & Found item (owner use only)
  Stream<List<Map<String, dynamic>>> getClaimsForItem(String itemId) {
    return _db
        .collection('lost_found_claims')
        .where('itemId', isEqualTo: itemId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ─── Announcement Operations ──────────────────────────────────────────────

  Stream<List<AnnouncementModel>> getAnnouncementsStream() async* {
    yield _announcements;
    yield* _announcementController.stream;
  }

  // ─── Connection Methods ──────────────────────────────────────────────────

  Future<void> sendConnectionRequest(UserModel sender, UserModel receiver) async {
    if (sender.id == receiver.id) return; // Prevent self request

    // Check if pending request exists
    final q1 = await _db.collection('connection_requests')
        .where('senderId', isEqualTo: sender.id)
        .where('receiverId', isEqualTo: receiver.id)
        .where('status', isEqualTo: 'pending')
        .get();
    
    final q2 = await _db.collection('connection_requests')
        .where('senderId', isEqualTo: receiver.id)
        .where('receiverId', isEqualTo: sender.id)
        .where('status', isEqualTo: 'pending')
        .get();

    if (q1.docs.isNotEmpty || q2.docs.isNotEmpty) return;

    // Check if connected
    final ids = [sender.id, receiver.id]..sort();
    final connectionId = '${ids[0]}_${ids[1]}';
    final connDoc = await _db.collection('connections').doc(connectionId).get();
    if (connDoc.exists) return;

    final requestId = '${sender.id}_${receiver.id}';
    final request = ConnectionRequestModel(
      id: requestId,
      senderId: sender.id,
      senderName: sender.name,
      receiverId: receiver.id,
      receiverName: receiver.name,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await _db.collection('connection_requests').doc(requestId).set(request.toMap());
  }

  Future<void> acceptConnectionRequest(ConnectionRequestModel request) async {
    // 1. Update the request status
    await _db.collection('connection_requests').doc(request.id).update({
      'status': 'accepted',
    });
    
    // 2. Create the connection document
    final ids = [request.senderId, request.receiverId]..sort();
    final connectionId = '${ids[0]}_${ids[1]}';
    
    final connection = ConnectionModel(
      id: connectionId,
      user1Id: ids[0],
      user2Id: ids[1],
      createdAt: DateTime.now(),
    );
    
    await _db.collection('connections').doc(connectionId).set(connection.toMap());
  }

  Future<void> rejectConnectionRequest(String requestId) async {
    await _db.collection('connection_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  Stream<List<ConnectionRequestModel>> getPendingRequestsStream(String currentUserId) {
    return _db
        .collection('connection_requests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConnectionRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  
  Stream<List<ConnectionRequestModel>> getSentRequestsStream(String currentUserId) {
    return _db
        .collection('connection_requests')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConnectionRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<String>> getConnectedUserIdsStream(String currentUserId) {
    return _db
        .collection('connections')
        .where(
          Filter.or(
            Filter('user1Id', isEqualTo: currentUserId),
            Filter('user2Id', isEqualTo: currentUserId),
          ),
        )
        .snapshots()
        .map((snapshot) {
      final List<String> connectedIds = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['user1Id'] == currentUserId) {
          connectedIds.add(data['user2Id'] as String);
        } else {
          connectedIds.add(data['user1Id'] as String);
        }
      }
      return connectedIds;
    });
  }

  /// Removes the connection between two users.
  /// Uses the same deterministic connection ID: '${sortedId1}_${sortedId2}'.
  /// Deleting this single document disconnects both sides simultaneously
  /// because getConnectedUserIdsStream queries by user1Id OR user2Id.
  Future<void> disconnectUser(String currentUserId, String otherUserId) async {
    final ids = [currentUserId, otherUserId]..sort();
    final connectionId = '${ids[0]}_${ids[1]}';
    await _db.collection('connections').doc(connectionId).delete();
  }
}


