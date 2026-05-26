import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/config/app_config.dart';

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
