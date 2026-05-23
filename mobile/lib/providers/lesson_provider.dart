import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  // Expose auth provider for UI components that need learner preferences.
  AuthProvider? get authProvider => _auth;

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

    // Try local V3 asset as a fallback when backend is unavailable or returned nothing
    try {
      final local = await loadLocalV3Activity(lessonId);
      if (local.isNotEmpty) {
        _words = local;
        _isLoading = false;
        notifyListeners();
        debugPrint('LessonProvider: loaded ${local.length} words from local V3 asset');
        return _words;
      }
    } catch (_) {
      // ignore and fall through to return empty
    }

    _isLoading = false;
    notifyListeners();
    return [];
  }

  Future<List<VocabularyWordModel>> loadLocalV3Activity(String lessonId) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/json/v3_activity_words.json');
      final List<dynamic> data = json.decode(jsonStr);
      final filtered = data.where((item) => (item['lessonId'] ?? '').toString() == lessonId || (item['lessonId'] ?? '').toString() == 'lesson_$lessonId').toList();
      if (filtered.isEmpty) {
        // Try matching numeric suffixes if lessonId is like 'lesson_1' vs '1'
        final alt = data.where((item) => (item['lessonId'] ?? '').toString() == 'lesson_$lessonId').toList();
        return alt.map((w) => VocabularyWordModel.fromJson(Map<String, dynamic>.from(w))).toList();
      }
      return filtered.map((w) => VocabularyWordModel.fromJson(Map<String, dynamic>.from(w))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadLessonActivity(String lessonId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lessons/$lessonId/activity'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      // Ignore and fall back to local data already loaded in the flow.
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> loadCategoryActivity(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId/activity'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      // Ignore and fall through.
    }

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
    String status, {
    int moduleNumber = 1,
  }) async {
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
          'moduleNumber': moduleNumber,
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

  Future<List<Map<String, dynamic>>> loadConfusablePairs(String lessonId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lessons/$lessonId/confusable-pairs'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      // Fail silently or log
    }
    return [];
  }

  /// Returns the review items for a cumulative mixed review screen.
  ///
  /// The current backend does not expose a dedicated list endpoint for this
  /// screen, so the app falls back to an empty list instead of failing.
  Future<List<Map<String, dynamic>>> getCumulativeMixedReview(String sessionId) async {
    try {
      // Try backend sandbox session endpoint which returns session info including words
      final response = await http.get(
        Uri.parse('$baseUrl/sandbox/sessions/$sessionId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final words = (data['words'] as List<dynamic>?) ?? [];
        // Build simple mixed review items: one item per word with basic fields
        final items = words
            .whereType<Map>()
            .map((w) => <String, dynamic>{
                  'wordId': w['wordId'] ?? w['id'] ?? w['vocabularyId'],
                  'word': w['englishWord'] ?? w['word'] ?? '',
                  'definition': w['cebuanoMeaning'] ?? w['cebuanoDefinition'] ?? w['definition'] ?? '',
                  'example': w['exampleSentence'] ?? w['englishSentence'] ?? '',
                })
            .toList();

        return items;
      }
    } catch (e) {
      // ignore network errors and fall through to local empty list
    }

    // Fallback: try local V3 asset to assemble mixed review items
    try {
      final jsonStr = await rootBundle.loadString('assets/json/v3_activity_words.json');
      final List<dynamic> data = json.decode(jsonStr);
      if (data.isNotEmpty) {
        final items = data
            .whereType<Map>()
            .map((w) => <String, dynamic>{
                  'wordId': w['wordId'] ?? '',
                  'word': w['englishWord'] ?? w['word'] ?? '',
                  'definition': w['cebuanoMeaning'] ?? '',
                  'example': w['exampleSentenceEnglish'] ?? w['example'] ?? '',
                })
            .toList();
        debugPrint('LessonProvider: returning ${items.length} mixed review items from local V3 asset');
        return items;
      }
    } catch (_) {
      // ignore
    }

    // Final fallback: return empty list
    return [];
  }

  /// Starts a cumulative mixed review session.
  Future<String?> startReview(String lessonId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lessons/$lessonId/review/start'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sessionId'] as String?;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    // Catch any errors silently; can log if needed
    } catch (e) {
      debugPrint('LessonProvider.startReview error: $e');
    }

    return null;
  }

  /// Submits a single review item (word) result.
  Future<void> submitReviewItem({
    required String sessionId,
    required String wordId,
    required bool isCorrect,
    required int confidence,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/review-items'),
        headers: _headers,
        body: json.encode({
          'sessionId': sessionId,
          'wordId': wordId,
          'isCorrect': isCorrect,
          'confidence': confidence,
        }),
      );
      if (response.statusCode == 401) {
        _auth?.logout();
      }
    // Catch any errors silently; can log if needed
    } catch (e) {
      debugPrint('LessonProvider.submitReviewItem error: $e');
    }

  }

  /// Completes the review session and returns score & pass status.
  Future<Map<String, dynamic>?> completeReview(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/lesson-completion'),
        headers: _headers,
        body: json.encode({'sessionId': sessionId}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    // Catch any errors silently; can log if needed
    } catch (e) {
      debugPrint('LessonProvider.completeReview error: $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> completeCategoryReview({
    required String sessionId,
    required String categoryId,
    required double score,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/category-completion'),
        headers: _headers,
        body: json.encode({
          'sessionId': sessionId,
          'categoryId': categoryId,
          'score': score,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.completeCategoryReview error: $e');
    }

    return null;
  }

  /// Placeholder sandbox prompt generator.
  /// In a full implementation this would call the backend to generate a prompt based on a seed word.
  Future<String?> getSandboxPrompt() async {
    // TODO: Replace with actual API call to fetch a sandbox prompt.
    return 'Sample sandbox prompt generated for practice.';
  }

  Future<Map<String, dynamic>?> generateSandbox({String? topic, String? customWord}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sandbox/generate'),
        headers: _headers,
        body: json.encode({
          'topic': topic,
          'customWord': customWord,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      // Handle network errors silently
    }
    return null;
  }

  /// Updates sandbox progress for a word.
  Future<void> updateSandboxProgress({
    required String sessionId,
    required String wordId,
    required String pathway,
    required int stepCompleted,
    required String status,
    int moduleNumber = 1,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/sandbox/sessions/$sessionId/progress'),
        headers: _headers,
        body: json.encode({
          'wordId': wordId,
          'pathway': pathway,
          'stepCompleted': stepCompleted,
          'status': status,
          'moduleNumber': moduleNumber,
        }),
      );
    // Catch any errors silently; can log if needed
    } catch (e) {
      debugPrint('LessonProvider.updateSandboxProgress error: $e');
    }

  }

  /// Completes sandbox session and returns result.
  Future<Map<String, dynamic>?> completeSandbox(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sandbox/sessions/$sessionId/complete'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    // Catch any errors silently; can log if needed
    } catch (e) {
      debugPrint('LessonProvider.completeSandbox error: $e');
    }

    return null;
  }

  /// Fetches dashboard progress summary.
  Future<Map<String, dynamic>?> fetchDashboardProgress() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/progress'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    // Catch any errors silently; can log if needed
    } catch (e) {
      debugPrint('LessonProvider.fetchDashboardProgress error: $e');
    }

    return null;
  }

  /// Updates learner preferences.
  Future<void> updatePreferences(Map<String, dynamic> prefs) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/learners/preferences'),
        headers: _headers,
        body: json.encode(prefs),
      );
      if (response.statusCode == 401) {
        _auth?.logout();
      }
    // Catch any errors silently; can log if needed
    } catch (e) {
      debugPrint('LessonProvider.updatePreferences error: $e');
    }

  }

  /// Resets learner progress.
  Future<void> resetProgress() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/learners/reset-progress'),
        headers: _headers,
      );
      if (response.statusCode == 401) {
        _auth?.logout();
      }
    // Catch any errors silently; can log if needed
    } catch (e) {
      debugPrint('LessonProvider.resetProgress error: $e');
    }

  }

}
