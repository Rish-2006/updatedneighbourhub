import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/contact_model.dart';

class ContactRepository {
  final FirebaseFirestore _firestore;
  final StreamController<List<ContactModel>> _contactsStreamController =
      StreamController<List<ContactModel>>.broadcast();

  final List<ContactModel> _mockContacts = [
    ContactModel(
      id: 'c1',
      name: 'Sarah Connor',
      phone: '+1 555-0192',
      email: 'sarah@example.com',
      relationship: 'Sister',
      addedAt: DateTime.now(),
    ),
    ContactModel(
      id: 'c2',
      name: 'Alex Rivera',
      phone: '+1 555-0144',
      email: 'alex@example.com',
      relationship: 'Friend',
      addedAt: DateTime.now(),
    ),
  ];

  ContactRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ContactModel>> getContactsStream(String userId) async* {
    yield await getContacts(userId);
    yield* _contactsStreamController.stream;
  }

  Future<List<ContactModel>> getContacts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();
      if (snapshot.docs.isEmpty) {
        return _mockContacts;
      }
      final list = snapshot.docs
          .map((doc) => ContactModel.fromMap(doc.data(), doc.id))
          .toList();
      return list.isNotEmpty ? list : _mockContacts;
    } catch (e) {
      debugPrint('Contacts get fallback: $e');
      return _mockContacts;
    }
  }

  Future<void> addContact(String userId, ContactModel contact) async {
    final contacts = await getContacts(userId);
    if (contacts.length >= 5) {
      throw Exception('Maximum 5 trusted contacts reached.');
    }

    try {
      final docId = contact.id.isEmpty ? const Uuid().v4() : contact.id;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(docId)
          .set(contact.toMap());
    } catch (e) {
      debugPrint('Adding contact in offline/mock mode: $e');
    }
    _mockContacts.add(contact);
    _contactsStreamController.add(List.from(_mockContacts));
  }

  Future<void> deleteContact(String userId, String contactId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .delete();
    } catch (e) {
      debugPrint('Deleting contact in offline/mock mode: $e');
    }
    _mockContacts.removeWhere((c) => c.id == contactId);
    _contactsStreamController.add(List.from(_mockContacts));
  }
}

