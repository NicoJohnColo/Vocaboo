import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';
import '../models/vocabulary_word_model.dart';
import '../models/diagnostic_result_model.dart';
import '../services/scoring_service.dart';
import '../services/local_storage_service.dart';
import 'package:mobile/config/app_config.dart';

const double lessonWeight = ScoringService.lessonWeight;
const double reviewWeight = ScoringService.reviewWeight;
const double passingThreshold = ScoringService.passingThreshold;

class LessonProvider with ChangeNotifier {
  AuthProvider? _auth;
  static final String baseUrl = AppConfig.baseUrl;

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

  void updateAuth(AuthProvider? auth) {
    _auth = auth;
  }

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
        _lessons = data.map((les) => LessonModel.fromJson(les)).toList()
          ..sort((a, b) => a.lessonOrder.compareTo(b.lessonOrder));
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

  Future<List<VocabularyWordModel>> loadVocabulary(String lessonId, {String? partOfSpeech}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = (partOfSpeech != null && partOfSpeech.isNotEmpty)
          ? Uri.parse('$baseUrl/lessons/$lessonId/vocabulary?partOfSpeech=${Uri.encodeComponent(partOfSpeech)}')
          : Uri.parse('$baseUrl/lessons/$lessonId/vocabulary');

      final response = await http.get(
        uri,
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

  Future<String> getWordDifficulty(String wordId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/words/$wordId/difficulty'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['currentLevel'] ?? 'LEARNING';
      }
    } catch (e) {
      debugPrint('Error getting word difficulty: $e');
    }
    return 'LEARNING';
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

  Future<List<Map<String, dynamic>>> loadRetrievalQuestions(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/retrieval/session/$sessionId/questions'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('Error loading retrieval questions: $e');
    }
    return [];
  }

  Future<void> submitRetrievalAnswer(String sessionId, String wordId, bool isCorrect) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/retrieval/session/$sessionId/submit'),
        headers: _headers,
        body: json.encode({
          'wordId': wordId,
          'correct': isCorrect,
        }),
      );
      if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('Error submitting retrieval answer: $e');
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
  Future<List<Map<String, dynamic>>> getCumulativeMixedReview(String sessionId, {bool isSandbox = false}) async {
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
                  'exampleSentenceEn': w['exampleSentenceEn'] ?? w['exampleSentence'] ?? w['englishSentence'] ?? '',
                  'exampleSentenceBiosatya': w['exampleSentenceBiosatya'] ?? w['cebuanoSentence'] ?? '',
                  'sentenceArrangementTokens': w['sentenceArrangementTokens'] ?? w['arrangementTokens'] ?? [],
                  'sentenceCompletionSentence': w['sentenceCompletionSentence'] ?? '',
                  'sentenceCompletionAnswer': w['sentenceCompletionAnswer'] ?? '',
                })
            .toList();

        return items;
      }
    } catch (e) {
      if (isSandbox) {
        debugPrint('LessonProvider.getCumulativeMixedReview sandbox error: $e');
        rethrow;
      }
      // ignore network errors and fall through to local empty list for non-sandbox
    }

    if (isSandbox) {
      // For sandbox requests we must not fall back to local assets — fail loudly.
      throw Exception('Failed to fetch sandbox session or it contained no words.');
    }

    // Fallback: try local V3 asset to assemble mixed review items (only for non-sandbox)
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

    // Final fallback: return empty list for non-sandbox
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

  double computeFinalScore({
    required double lesson1Score,
    required double lesson2Score,
    required double cumulativeReviewScore,
  }) {
    return ScoringService.computeFinalScoreFromLessons(lesson1Score, lesson2Score, cumulativeReviewScore);
  }

  bool didPass(double finalScore) {
    return finalScore >= passingThreshold;
  }

  Future<void> persistModuleScore(
    String lessonId,
    int? moduleNumber,
    int correctCount,
    int totalCount, {
    bool isSandbox = false,
    String? sessionId,
  }) async {
    final score = ScoringService.computeLessonScore(correctCount, totalCount);
    try {
      Future<http.Response> doPost() {
        if (isSandbox) {
          final sandboxSessionId = sessionId ?? lessonId;
          return http.post(
            Uri.parse('$baseUrl/sandbox/sessions/$sandboxSessionId/module-score'),
            headers: _headers,
            body: json.encode({
              'moduleNumber': moduleNumber,
              'correctCount': correctCount,
              'totalCount': totalCount,
              'score': score,
            }),
          );
        } else {
          return http.post(
            Uri.parse('$baseUrl/progress/module-score'),
            headers: _headers,
            body: json.encode({
              'lessonId': lessonId,
              'moduleNumber': moduleNumber,
              'correctCount': correctCount,
              'totalCount': totalCount,
              'score': score,
            }),
          );
        }
      }

      http.Response response = await doPost();
      // Retry once on server error (5xx)
      if (response.statusCode >= 500 && response.statusCode < 600) {
        await Future.delayed(const Duration(milliseconds: 200));
        response = await doPost();
      }

      if (response.statusCode == 401) {
        _auth?.logout();
        if (isSandbox) throw Exception('Failed to persist sandbox module score: unauthorized.');
      } else if (response.statusCode < 200 || response.statusCode >= 300) {
        final msg = _extractErrorMessage(response.body, 'Failed to persist module score');
        debugPrint('LessonProvider.persistModuleScore backend sync error: $msg (status=${response.statusCode})');
      }
    } catch (e) {
      debugPrint('LessonProvider.persistModuleScore backend sync error: ${e.runtimeType}: ${e.toString()}');
    }

    // Persist locally for both sandbox and normal lessons. For sandbox flows
    // moduleNumber may be null — treat as unified module 1 for local storage.
    final localModuleNumber = moduleNumber ?? 1;
    try {
      await LocalStorageService.saveModuleScore(lessonId, localModuleNumber, correctCount, totalCount);
      await LocalStorageService.saveLessonScore(lessonId, score);
    } catch (_) {
      // Don't let local storage failures block the app; just log silently.
      debugPrint('LessonProvider.persistModuleScore: failed to save locally');
    }
  }

  Future<Map<String, dynamic>?> generateSandbox({required String customWord}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sandbox/generate'),
        headers: _headers,
        body: json.encode({
          'customWord': customWord,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Ensure distractors exist - add fallback if missing
        if (data['words'] != null && data['words'] is List) {
          final words = data['words'] as List;
          for (var word in words) {
            if (word is Map) {
              final distractors = [
                word['mcDistractor1'],
                word['mcDistractor2'],
                word['mcDistractor3'],
              ].whereType<String>().where((d) => d.trim().isNotEmpty).toList();
              
              // If less than 3 distractors, add fallback words
              if (distractors.length < 3) {
                final fallbacks = ['apple', 'house', 'water', 'friend', 'school', 'book', 'tree', 'happy', 'run', 'big', 'cat', 'dog', 'sun', 'moon', 'star'];
                final targetWord = (word['englishWord'] ?? '').toString().toLowerCase();
                final needed = 3 - distractors.length;
                final available = fallbacks.where((f) => f.toLowerCase() != targetWord).toList()..shuffle();
                
                for (int i = 0; i < needed && i < available.length; i++) {
                  final key = 'mcDistractor${distractors.length + i + 1}';
                  word[key] = available[i];
                }
                debugPrint('Added $needed fallback distractors for word: $targetWord');
              }
            }
          }
        }
        
        return data;
      } else if (response.statusCode == 401) {
        _auth?.logout();
        throw Exception('Sandbox generation failed: unauthorized.');
      } else if (response.statusCode == 429 || response.statusCode == 502) {
        // Check if it's a rate limit error
        final errorMsg = _extractErrorMessage(response.body, '');
        if (errorMsg.contains('429') || errorMsg.toLowerCase().contains('rate limit')) {
          debugPrint('LessonProvider.generateSandbox: Rate limit error detected');
          throw Exception('Rate limit reached. Please wait a moment and try again.');
        }
        throw Exception(_extractErrorMessage(response.body, 'Sandbox generation failed.'));
      } else {
        debugPrint('LessonProvider.generateSandbox failed with status ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception(_extractErrorMessage(response.body, 'Sandbox generation failed.'));
      }
    } catch (e) {
      debugPrint('LessonProvider.generateSandbox error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Check if the error message contains rate limit info
      if (e.toString().contains('429') || e.toString().toLowerCase().contains('rate limit')) {
        throw Exception('Rate limit reached. Please wait a moment and try again.');
      }
      rethrow;
    }
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
    } catch (e) {
      debugPrint('LessonProvider.updateSandboxProgress error: $e');
      rethrow;
    }

  }

  /// Completes sandbox session and returns result.
  Future<Map<String, dynamic>?> completeSandbox(String sessionId, {required double finalScore}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sandbox/sessions/$sessionId/complete'),
        headers: _headers,
        body: json.encode({'score': finalScore}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
        throw Exception('Sandbox completion failed: unauthorized.');
      } else {
        throw Exception(_extractErrorMessage(response.body, 'Sandbox completion failed.'));
      }
    } catch (e) {
      debugPrint('LessonProvider.completeSandbox error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSandboxModuleScores(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sandbox/sessions/$sessionId/module-scores'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        }
      } else if (response.statusCode == 401) {
        _auth?.logout();
        throw Exception('Failed to fetch sandbox module scores: unauthorized.');
      } else {
        throw Exception(_extractErrorMessage(response.body, 'Failed to fetch sandbox module scores.'));
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchSandboxModuleScores error: $e');
      rethrow;
    }
    return [];
  }

  String _extractErrorMessage(String body, String fallbackMessage) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // ignore parse failure and fall back below
    }
    return fallbackMessage;
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

  /// Resets a single lesson's progress.
  Future<bool> resetLesson(String lessonId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lessons/$lessonId/reset'),
        headers: _headers,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Update local state to reflect reset
        final index = _lessons.indexWhere((l) => l.lessonId == lessonId);
        if (index >= 0) {
          _lessons[index] = LessonModel(
            lessonId: _lessons[index].lessonId,
            categoryId: _lessons[index].categoryId,
            lessonTitle: _lessons[index].lessonTitle,
            lessonDescription: _lessons[index].lessonDescription,
            gradeLevel: _lessons[index].gradeLevel,
            lessonOrder: _lessons[index].lessonOrder,
            totalWordCount: _lessons[index].totalWordCount,
            status: 'UNLOCKED',
            masteryScore: null,
          );
          notifyListeners();
        }
        return true;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.resetLesson error: $e');
    }
    return false;
  }

  /// Submits mastery data to the backend for server-side validation.
  Future<Map<String, dynamic>?> submitMastery({
    required String categoryId,
    required List<String> lessonIds,
    required double lessonScore,
    required double cumulativeReviewScore,
    required double finalScore,
    required bool passed,
    required int totalItems,
    required int masteredCount,
    required List<String> missedWordIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mastery'),
        headers: _headers,
        body: json.encode({
          'categoryId': categoryId,
          'lessonIds': lessonIds,
          'lessonScore': lessonScore,
          'cumulativeReviewScore': cumulativeReviewScore,
          'finalScore': finalScore,
          'passed': passed,
          'totalItems': totalItems,
          'masteredCount': masteredCount,
          'missedWordIds': missedWordIds,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.submitMastery error: $e');
    }

    return null;
  }

  /// Completes a mastery session on the backend, generating the summary and reward badge.
  Future<Map<String, dynamic>?> completeMasterySession(String sessionId, String lessonId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mastery/session/$sessionId/complete?lessonId=$lessonId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.completeMasterySession error: $e');
    }
    return null;
  }

  /// Retrieves the session summary for a completed practice session.
  Future<Map<String, dynamic>?> fetchSessionSummary(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mastery/session/$sessionId/summary'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchSessionSummary error: $e');
    }
    return null;
  }

  /// Retrieves all earned badges for a learner.
  Future<List<Map<String, dynamic>>> fetchLearnerBadges(String learnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mastery/learners/$learnerId/badges'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchLearnerBadges error: $e');
    }
    return [];
  }
}
