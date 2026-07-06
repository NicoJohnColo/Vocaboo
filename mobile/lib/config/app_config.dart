import 'dart:io' show Platform;

class AppConfig {
  // Use the host machine's loopback address for Android emulator (10.0.2.2).
  // For a physical device, set this to your machine IP on the LAN.
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://192.168.1.2:8080/api/v1';
  }
}