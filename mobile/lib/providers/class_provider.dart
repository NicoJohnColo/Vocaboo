import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/app_config.dart';
import '../models/class_model.dart';
import '../models/class_performance_model.dart';
import '../models/lesson_model.dart';

class ClassProvider with ChangeNotifier {
  static String get baseUrl => AppConfig.baseUrl;

  List<ClassModel> _enrolledClasses = [];
  List<ClassInvitationModel> _invitations = [];
  List<ClassPerformanceModel> _allClassPerformances = [];
  bool _isLoading = false;
  String? _error;

  List<ClassModel> get enrolledClasses => _enrolledClasses;
  List<ClassInvitationModel> get invitations => _invitations;
  List<ClassPerformanceModel> get allClassPerformances => _allClassPerformances;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingInvitationCount =>
      _invitations.where((i) => i.status == 'PENDING').length;

  ClassPerformanceModel? getPerformanceForClass(String classId) {
    try {
      return _allClassPerformances.firstWhere((p) => p.classId == classId);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchEnrolledClasses(String? token) async {
    if (token == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/learner/classes'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        _enrolledClasses = data
            .map((json) => ClassModel.fromJson(json))
            .toList();
        await fetchAllClassPerformances(token);
      } else {
        _error = 'Failed to load classes';
      }
    } catch (e) {
      _error = 'Network error loading classes';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvitations(String? token) async {
    if (token == null) return;
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/learner/classes/invitations'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        _invitations = data
            .map((json) => ClassInvitationModel.fromJson(json))
            .toList();
        notifyListeners();
      } else {
        debugPrint('fetchInvitations failed (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      debugPrint('fetchInvitations exception: $e');
    }
  }

  Future<String?> joinClassByCode(String code, String? token) async {
    if (token == null) return 'Not authenticated';
    _isLoading = true;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/learner/classes/join'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'classCode': code.trim().toUpperCase()}),
          )
          .timeout(const Duration(seconds: 10));

      _isLoading = false;
      notifyListeners();

      if (res.statusCode == 201 || res.statusCode == 200) {
        return null; // success
      } else {
        try {
          final body = json.decode(res.body);
          return body['message'] ?? body['error'] ?? 'Failed to join class';
        } catch (_) {
          return 'Failed to join class (HTTP ${res.statusCode})';
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Connection error. Please try again.';
    }
  }

  Future<bool> respondToInvitation(
    String invitationId,
    String decision,
    String? token,
  ) async {
    if (token == null) return false;
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/learner/classes/invitations/$invitationId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'status': decision}),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        await fetchInvitations(token);
        if (decision == 'ACCEPTED') {
          await fetchEnrolledClasses(token);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<Map<String, dynamic>>> fetchClassCategories(
    String classId,
    String? token,
  ) async {
    if (token == null) return [];
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/learner/classes/$classId/categories'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('fetchClassCategories error: $e');
    }
    return [];
  }

  Future<List<LessonModel>> fetchClassLessons(
    String classId,
    String? token, {
    String? categoryId,
  }) async {
    if (token == null) return [];
    try {
      final uri = Uri.parse('$baseUrl/learner/classes/$classId/lessons')
          .replace(
            queryParameters: categoryId == null
                ? null
                : {'categoryId': categoryId},
          );
      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((json) => LessonModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetches the class-scoped leaderboard for a specific classroom.
  /// This is independent from the global leaderboard — only classmates appear.
  ///
  /// [classId] – the UUID of the classroom
  /// [token]   – learner auth token
  /// [range]   – "weekly" or "all" (default: "weekly")
  Future<List<Map<String, dynamic>>> fetchClassLeaderboard(
    String classId,
    String? token, {
    String range = 'weekly',
  }) async {
    if (token == null) return [];
    try {
      final res = await http
          .get(
            Uri.parse(
              '$baseUrl/learner/classes/$classId/leaderboard?range=$range',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('fetchClassLeaderboard error: \$e');
    }
    return [];
  }

  /// Fetches this learner's class-scoped performance for a specific classroom.
  /// Used to show the dual score card: Global Score vs Class Score.
  Future<ClassPerformanceModel?> fetchClassPerformance(
    String classId,
    String? token,
  ) async {
    if (token == null) return null;
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/learner/classes/$classId/performance'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);
        return ClassPerformanceModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('fetchClassPerformance error: \$e');
    }
    return null;
  }

  /// Fetches class performance summaries across ALL enrolled classes.
  /// Populates the learner profile's multi-class score view.
  Future<List<ClassPerformanceModel>> fetchAllClassPerformances(
    String? token,
  ) async {
    if (token == null) return [];
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/learner/classes/performance/all'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        _allClassPerformances = data
            .map((e) => ClassPerformanceModel.fromJson(e))
            .toList();
        notifyListeners();
        return _allClassPerformances;
      }
    } catch (e) {
      debugPrint('fetchAllClassPerformances error: $e');
    }
    return [];
  }
}
