// lib/models/announcement_model.dart

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String postedBy;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.postedBy,
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String docId) {
    return AnnouncementModel(
      id: docId,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      postedBy: map['postedBy'] as String? ?? 'Association Committee',
      createdAt: (map['createdAt'] != null)
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'postedBy': postedBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
