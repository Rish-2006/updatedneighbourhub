// lib/services/mongodb_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// This exact class name must match line 132 in main.dart
class MongoDBService {
  final String _baseUrl = 'http://localhost:5000/api';

  Future<bool> syncUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/users');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'photoUrl': photoUrl,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    final url = Uri.parse('$_baseUrl/users/$uid');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
