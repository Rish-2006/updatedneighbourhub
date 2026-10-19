// lib/models/lost_found_model.dart

class LostFoundModel {
  final String id;
  final String type; // 'lost' or 'found'
  final String title;
  final String category;
  final String description;
  final String location;
  final String date;        // e.g. "3 Oct 2026"
  final String postedBy;
  final String postedById;
  final DateTime createdAt;
  final String status;      // 'Active', 'ClaimPending', 'Matched', 'Returned', 'Closed'

  // Convenience
  bool get isResolved => status == 'Returned' || status == 'Closed';

  const LostFoundModel({
    required this.id,
    required this.type,
    required this.title,
    this.category = '',
    required this.description,
    required this.location,
    this.date = '',
    required this.postedBy,
    required this.postedById,
    required this.createdAt,
    this.status = 'Active',
  });

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    try { return (v as dynamic).toDate() as DateTime; } catch (_) { return DateTime.now(); }
  }

  factory LostFoundModel.fromMap(Map<String, dynamic> map, String docId) {
    return LostFoundModel(
      id: docId,
      type: map['type'] as String? ?? 'lost',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      date: map['date'] as String? ?? '',
      postedBy: map['postedBy'] as String? ?? 'Unknown',
      postedById: map['postedById'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      status: map['status'] as String? ?? (map['isResolved'] == true ? 'Returned' : 'Active'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'category': category,
      'description': description,
      'location': location,
      'date': date,
      'postedBy': postedBy,
      'postedById': postedById,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status,
      // Keep backward compat
      'isResolved': isResolved,
    };
  }

  LostFoundModel copyWith({String? status}) => LostFoundModel(
    id: id, type: type, title: title, category: category,
    description: description, location: location, date: date,
    postedBy: postedBy, postedById: postedById, createdAt: createdAt,
    status: status ?? this.status,
  );
}
