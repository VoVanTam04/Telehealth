import 'dart:io';
import 'package:http/http.dart' as http;
import '../app_config.dart';

class AvatarUploadService {
  static String get _baseUrl => '${AppConfig.apiBase}/users';

  /// Upload avatar, trả về url hoặc path lưu trong database
  static Future<String?> uploadAvatar(int userId, File file) async {
    try {
      final uri = Uri.parse('$_baseUrl/$userId/avatar');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('avatar', file.path));
      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        return respStr;
      } else {
        final respStr = await response.stream.bytesToString();
        print('[AvatarUploadService] Upload failed: status=${response.statusCode}, body=$respStr');
        return null;
      }
    } catch (e) {
      print('[AvatarUploadService] Network or other error: $e');
      return null;
    }
  }
}
