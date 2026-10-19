// lib/services/storage_service.dart
//
// Handles uploading images to Firebase Storage.
// Used when users attach an image to a post.

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ─── Pick Image from Gallery ──────────────────────────────────────────────
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  // ─── Upload Post Image ────────────────────────────────────────────────────
  Future<String?> uploadPostImage(String postId, XFile imageFile) async {
    try {
      final ref = _storage.ref().child('post_images/$postId.jpg');

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        await ref.putFile(File(imageFile.path));
      }

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading post image: $e');
      return null;
    }
  }
}
