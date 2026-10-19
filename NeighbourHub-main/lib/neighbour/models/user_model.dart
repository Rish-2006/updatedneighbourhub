// lib/models/user_model.dart
//
// Represents a NeighbourHub user.
// This model matches what we store in Firestore's "users" collection.
// It also handles converting to/from Firestore's Map format.

class UserModel {
  final String id;           // Firebase Auth UID
  final String name;         // Full name
  final String email;        // Email address
  final String photoUrl;     // Profile photo URL (can be empty string)
  final String neighbourhood;// Which neighbourhood they live in
  final String apartment;    // Apartment / house name (optional)
  final String bio;          // Short bio shown on profile
  final DateTime createdAt;  // When they joined

  // Constructor - all fields required except apartment/bio which have defaults
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.neighbourhood,
    this.apartment = '',
    this.bio = '',
    required this.createdAt,
  });

  // Creates a UserModel from a Firestore document (Map of data)
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      neighbourhood: map['neighbourhood'] as String? ?? '',
      apartment: map['apartment'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      // Firestore stores timestamps - we convert them to Dart DateTime
      createdAt: (map['createdAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['createdAt'] as int),
            )
          : DateTime.now(),
    );
  }

  // Converts this model to a Map so we can save it to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'neighbourhood': neighbourhood,
      'apartment': apartment,
      'bio': bio,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Creates a copy of this model with some fields changed
  // Useful when editing the profile
  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? neighbourhood,
    String? apartment,
    String? bio,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      neighbourhood: neighbourhood ?? this.neighbourhood,
      apartment: apartment ?? this.apartment,
      bio: bio ?? this.bio,
      createdAt: createdAt,
    );
  }

  // Returns the user's first name only (e.g. "Srinivas" from "Srinivas Madhu")
  String get firstName {
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts.first : name;
  }
}
