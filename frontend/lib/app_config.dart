
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static String get apiBase {
    // Nếu chạy trên web thì dùng localhost
    if (kIsWeb) return 'http://localhost:3000';
    // Nếu là máy ảo Android thì dùng 10.0.2.2, máy thật thì dùng IP LAN
    if (Platform.isAndroid) {
      // Có thể kiểm tra thêm bằng môi trường hoặc device info nếu cần
      // Mặc định: máy ảo dùng 10.0.2.2, máy thật dùng IP LAN
      // Nếu cần phân biệt máy ảo, có thể dùng device_info_plus
      return 'http://10.0.2.2:3000';
    }
    // Máy thật (điện thoại thật, iOS, desktop) dùng IP LAN
    return 'http://192.168.1.44:3000';
  }
}
