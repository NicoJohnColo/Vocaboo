import 'dart:io' show Platform;

class AppConfig {
  // Centralized configuration for the backend base URL.
  // Using local machine IP on the LAN to support physical device testing.
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1'; // Android emulator localhost
    }
    return 'http://127.0.0.1:8080/api/v1';
  }
  

  static String get baseHost {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  static String sanitizeAssetPath(String path) {
    String trimmed = path.trim();
    if (trimmed.startsWith('http://localhost:') || trimmed.startsWith('http://10.0.2.2:')) {
      return trimmed.replaceFirst(RegExp(r'http://(localhost|10\.0\.2\.2):\d+'), baseHost);
    } else if (trimmed.startsWith('/')) {
      return '$baseHost$trimmed';
    }
    return trimmed;
  }
}