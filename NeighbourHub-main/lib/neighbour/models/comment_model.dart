// lib/models/comment_model.dart

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    required this.createdAt,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String docId) {
    return CommentModel(
      id: docId,
      postId: map['postId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Unknown',
      authorPhoto: map['authorPhoto'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
