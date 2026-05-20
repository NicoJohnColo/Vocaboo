import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<http.Response> register(String displayName, int age, String pin, String languagePreference) async {
    return await http.post(
      Uri.parse('${ApiService.baseUrl}/learners/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'displayName': displayName,
        'age': age,
        'pin': pin,
        'languagePreference': languagePreference,
      }),
    );
  }

  Future<http.Response> login(String learnerId, String pin) async {
    return await http.post(
      Uri.parse('${ApiService.baseUrl}/learners/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'learnerId': learnerId,
        'pin': pin,
      }),
    );
  }

  Future<http.Response> getProfile() async {
    final headers = await _apiService.getHeaders();
    return await http.get(
      Uri.parse('${ApiService.baseUrl}/learners/me'),
      headers: headers,
    );
  }
}
