// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart'; // chứa AppConfig.apiBase
import '../models/user_profile.dart';

class AuthService {
  UserProfile? _current;
  UserProfile? get currentUser => _current;

  /// Đăng nhập bằng API backend (API thật)
  Future<UserProfile> signIn({
    required String identifier,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBase}/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': identifier, 'password': password}),
    );
    // Debug (có thể tắt khi release)
    // print('LOGIN RESPONSE: ${res.statusCode} - ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      _current = UserProfile(
        id: data['id'].toString(),
        name: data['name'] ?? '',
        role: data['role'] ?? 'patient',
        email: data['email'] ?? '',
        avatar: data['avatar'],
      );
      return _current!;
    } else {
      throw Exception(_safeMessage(res.body) ?? 'Đăng nhập thất bại');
    }
  }

  /// Đăng ký tài khoản mới qua API backend
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    String role = 'patient',
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBase}/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return UserProfile(
        id: data['id'].toString(),
        name: data['name'] ?? '',
        role: data['role'] ?? 'patient',
        email: data['email'] ?? '',
        avatar: data['avatar'],
      );
    } else {
      throw Exception(_safeMessage(res.body) ?? 'Đăng ký thất bại');
    }
  }

  /// Đổi mật khẩu (khi đang đăng nhập, cần oldPassword)
  Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    final res = await http.patch(
      Uri.parse('${AppConfig.apiBase}/users/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(_safeMessage(res.body) ?? 'Đổi mật khẩu thất bại');
    }
  }

  /// B1 (Quên MK): yêu cầu gửi mã 4–6 số về email
  Future<void> requestPasswordReset(String email) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBase}/users/request-password-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 200) {
      throw Exception(_safeMessage(res.body) ?? 'Gửi mã thất bại');
    }
  }

  /// B2 (Quên MK): nhập mã và đặt mật khẩu mới
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBase}/users/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
    );
    if (res.statusCode != 200) {
      throw Exception(_safeMessage(res.body) ?? 'Đổi mật khẩu thất bại');
    }
  }

  /// Đăng xuất (FE)
  void signOut() => _current = null;

  /// Parse message lỗi an toàn
  String? _safeMessage(String body) {
    try {
      final m = jsonDecode(body);
      if (m is Map && m['message'] != null) {
        return m['message'].toString();
      }
    } catch (_) {}
    return null;
  }
}
