import 'dart:io' show Platform;

class AppConfig {
  // Centralized configuration for the backend base URL.
  // Using local machine IP on the LAN to support physical device testing.
  static String get baseUrl {
    const overrideUrl = String.fromEnvironment('BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    if (Platform.isAndroid) {
      // 1. Android Emulator: 'http://10.0.2.2:8081/api/v1'
      // 2. USB Connection / ADB reverse: 'http://127.0.0.1:8081/api/v1' (Requires: adb reverse tcp:8081 tcp:8081)
      // 3. Physical device (same Wi-Fi): 'http://192.168.1.x:8081/api/v1' or use --dart-define=BASE_URL=...
      return 'http://192.168.0.155:8081/api/v1';
    }
    return 'http://192.168.0.155:8081/api/v1';
  }
  

  static String get baseHost {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  static String sanitizeAssetPath(String path) {
    String trimmed = path.trim();
    if (trimmed.startsWith('http://localhost:') || trimmed.startsWith('http://127.0.0.1:') || trimmed.startsWith('http://10.0.2.2:') || trimmed.contains(RegExp(r'http://(192\.168|10\.\d+)\.\d+\.\d+:'))) {
      return trimmed.replaceFirst(RegExp(r'http://(localhost|127\.0\.0\.1|10\.0\.2\.2|(192\.168|10\.\d+)\.\d+\.\d+):\d+'), baseHost);
    } else if (trimmed.startsWith('/')) {
      return '$baseHost$trimmed';
    }
    return trimmed;
  }
}
