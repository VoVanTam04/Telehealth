import 'package:http/http.dart' as http;
import '../app_config.dart';
import 'dart:convert';

class UserApiService {
  static String get _baseUrl => '${AppConfig.apiBase}/users';

  // GET all users
  Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  // GET 1 user by id
  Future<Map<String, dynamic>?> getUser(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  // POST create user
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create user');
    }
  }

  // PATCH update user profile (dùng cho cả bệnh nhân và bác sĩ)
  Future<Map<String, dynamic>> updateUserProfile(int id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/profile'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user');
    }
  }

  // DELETE user
  Future<bool> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$id'));
    return response.statusCode == 200;
  }
}
