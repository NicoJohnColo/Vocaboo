import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/learner_model.dart';

class LearnerService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/learners';

  static Future<LearnerModel> createLearner(LearnerModel learner) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(learner.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return LearnerModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create learner: ${response.statusCode}');
  }

  static Future<LearnerModel?> verifyPin(String name, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-pin'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'pin': pin}),
    );
    if (response.statusCode == 200) {
      return LearnerModel.fromJson(json.decode(response.body));
    }
    return null;
  }

  static Future<LearnerModel?> getLearner(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return LearnerModel.fromJson(json.decode(response.body));
    }
    return null;
  }
}
