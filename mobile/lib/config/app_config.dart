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
      // 10.0.2.2 is the special alias to your host loopback interface (127.0.0.1) for Android Emulators.
      // If you are testing on a PHYSICAL Android device over Wi-Fi, change this back to your computer's current IPv4 address (e.g. 192.168.x.x)
      return 'http://192.168.1.16:8081/api/v1';
    }
    return 'http://127.0.0.1:8081/api/v1';
  }
  

  static String get baseHost {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  static String sanitizeAssetPath(String path) {
    String trimmed = path.trim();
    if (trimmed.startsWith('http://localhost:') || trimmed.startsWith('http://10.0.2.2:') || trimmed.contains(RegExp(r'http://192\.168\.\d+\.\d+:'))) {
      return trimmed.replaceFirst(RegExp(r'http://(localhost|10\.0\.2\.2|192\.168\.\d+\.\d+):\d+'), baseHost);
    } else if (trimmed.startsWith('/')) {
      return '$baseHost$trimmed';
    }
    return trimmed;
  }
}
