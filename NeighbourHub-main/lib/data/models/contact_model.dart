class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? relationship;
  final DateTime addedAt;

  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.relationship,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map, String id) {
    return ContactModel(
      id: id,
      name: map['name'] as String? ?? 'Contact',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      relationship: map['relationship'] as String?,
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
