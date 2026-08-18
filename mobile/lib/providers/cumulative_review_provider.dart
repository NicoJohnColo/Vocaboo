import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/learner_model.dart';

class CumulativeReviewProvider with ChangeNotifier {
  LearnerModel? _learner;
  String? _token;

  void update(LearnerModel? learner, String? token) {
    _learner = learner;
    _token = token;
  }

  Map<String, String> get _headers {
    if (_token == null) return {'Content-Type': 'application/json'};
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> startSession(String lessonPairId) async {
    if (_learner == null) throw Exception('No learner authenticated');
    
    final url = Uri.parse('${AppConfig.baseUrl}/cumulative-review/start?learnerId=${_learner!.learnerId}&lessonPairId=$lessonPairId');
    final response = await http.post(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to start cumulative review session');
    }
  }

  Future<List<dynamic>> getSessionQuestions(String sessionId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/cumulative-review/$sessionId/questions');
    final response = await http.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load session questions');
    }
  }

  Future<List<dynamic>> getSessionSentences(String sessionId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/cumulative-review/$sessionId/sentences');
    final response = await http.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load session sentences');
    }
  }

  Future<void> recordAnswer({
    required String sessionId,
    required String wordId,
    required String activityType,
    required bool correct,
    String? crossLessonSentenceId,
    int attemptNumber = 1,
  }) async {
    var uriString = '${AppConfig.baseUrl}/cumulative-review/$sessionId/record'
        '?wordId=$wordId&activityType=$activityType&correct=$correct&attemptNumber=$attemptNumber';
    if (crossLessonSentenceId != null) {
      uriString += '&crossLessonSentenceId=$crossLessonSentenceId';
    }
    
    final url = Uri.parse(uriString);
    final response = await http.post(url, headers: _headers);
    
    if (response.statusCode != 200) {
      throw Exception('Failed to record answer');
    }
  }

  Future<Map<String, dynamic>> completeSession(String sessionId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/cumulative-review/$sessionId/complete');
    final response = await http.post(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to complete session');
    }
  }
}
