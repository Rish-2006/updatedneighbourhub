// lib/models/help_request_model.dart
//
// Represents a help request from a neighbour.
// E.g. "Can someone lend me a ladder?"

class HelpRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String title;
  final String description;
  final DateTime createdAt;
  final int responseCount;
  final bool isResolved;     // Has the help been provided?

  const HelpRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.title,
    required this.description,
    required this.createdAt,
    this.responseCount = 0,
    this.isResolved = false,
  });

  factory HelpRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return HelpRequestModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhoto: map['userPhoto'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: (map['createdAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      responseCount: map['responseCount'] as int? ?? 0,
      isResolved: map['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'title': title,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'responseCount': responseCount,
      'isResolved': isResolved,
    };
  }
}
