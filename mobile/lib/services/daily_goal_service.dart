import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/daily_goal_model.dart';
import '../providers/auth_provider.dart';

class DailyGoalService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<DailyGoalModel?> getDailyGoal(AuthProvider auth) async {
    final learnerId = auth.learner?.learnerId;
    if (learnerId == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/learners/$learnerId/daily-goal'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return DailyGoalModel.fromJson(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching daily goal: $e');
    }
    return null;
  }

  static Future<DailyGoalModel?> incrementGoal(AuthProvider auth) async {
    final learnerId = auth.learner?.learnerId;
    if (learnerId == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/learners/$learnerId/daily-goal/increment'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return DailyGoalModel.fromJson(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error incrementing daily goal: $e');
    }
    return null;
  }
}
