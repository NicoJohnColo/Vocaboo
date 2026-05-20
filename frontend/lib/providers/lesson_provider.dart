import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';
import '../models/vocabulary_word_model.dart';
import '../models/diagnostic_result_model.dart';

class LessonProvider with ChangeNotifier {
  final AuthProvider? _auth;
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  List<CategoryModel> _categories = [];
  List<LessonModel> _lessons = [];
  List<VocabularyWordModel> _words = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  List<LessonModel> get lessons => _lessons;
  List<VocabularyWordModel> get words => _words;
  bool get isLoading => _isLoading;
  String? get error => _error;

  LessonProvider(this._auth);

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${_auth?.token}',
        'Content-Type': 'application/json',
      };

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _categories = data.map((cat) => CategoryModel.fromJson(cat)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      } else {
        _error = 'Failed to load categories';
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLessons(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId/lessons'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _lessons = data.map((les) => LessonModel.fromJson(les)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      } else {
        _error = 'Failed to load lessons';
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<VocabularyWordModel>> loadVocabulary(String lessonId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lessons/$lessonId/vocabulary'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _words = data.map((w) => VocabularyWordModel.fromJson(w)).toList();
        _isLoading = false;
        notifyListeners();
        return _words;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      } else {
        _error = 'Failed to load vocabulary';
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
    return [];
  }

  Future<DiagnosticResultModel?> submitDiagnostic(String lessonId, Map<String, bool> responses) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Structure: { lessonId: UUID, responses: { wordId: boolean, ... } }
      final formattedResponses = responses.map((key, value) => MapEntry(key, value));
      final response = await http.post(
        Uri.parse('$baseUrl/diagnostic'),
        headers: _headers,
        body: json.encode({
          'lessonId': lessonId,
          'responses': formattedResponses,
        }),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return DiagnosticResultModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        _auth?.logout();
      } else {
        _error = 'Failed to submit diagnostic check';
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<void> updateWordProgress(
    String sessionId,
    String wordId,
    String pathway,
    int stepCompleted,
    String status,
  ) async {
    try {
      // Fire and forget progress update as requested in UC-1.3 to avoid blocking UI latency
      http.patch(
        Uri.parse('$baseUrl/sessions/$sessionId/progress'),
        headers: _headers,
        body: json.encode({
          'wordId': wordId,
          'pathway': pathway,
          'stepCompleted': stepCompleted,
          'status': status,
        }),
      ).then((response) {
        if (response.statusCode == 401) {
          _auth?.logout();
        }
      });
    } catch (e) {
      // Fail silently for fire-and-forget background sync
    }
  }
}
