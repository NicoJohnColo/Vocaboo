import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import '../models/category_model.dart';
import '../models/lesson_model.dart';
import '../models/vocabulary_word_model.dart';
import '../models/diagnostic_result_model.dart';
import '../models/learner_progress_model.dart';
import '../models/learner_lesson_progress_model.dart';
import '../models/learner_category_progress_model.dart';
import '../models/recent_word_progress_model.dart';
import '../models/learner_activity_stats_model.dart';
import '../services/scoring_service.dart';
import '../services/local_storage_service.dart';
import '../services/daily_goal_service.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile/config/app_config.dart';

const double lessonWeight = ScoringService.lessonWeight;
const double reviewWeight = ScoringService.reviewWeight;
const double passingThreshold = ScoringService.passingThreshold;

class LessonProvider with ChangeNotifier {
  AuthProvider? _auth;
  static String get baseUrl => AppConfig.baseUrl;

  List<CategoryModel> _categories = [];
  List<LessonModel> _lessons = [];
  List<VocabularyWordModel> _words = [];
  bool _isLoading = false;
  String? _error;
  String? _categoriesError;
  String? _lessonsError;

  List<CategoryModel> get categories => _categories;
  List<LessonModel> get lessons => _lessons;
  List<VocabularyWordModel> get words => _words;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get categoriesError => _categoriesError;
  String? get lessonsError => _lessonsError;

  String? _activeClassroomId;
  String? _activeClassName;
  String? get activeClassroomId => _activeClassroomId;
  String? get activeClassName => _activeClassName;

  void setActiveClassroom(String? id, String? name) {
    _activeClassroomId = id;
    _activeClassName = name;
    notifyListeners();
  }

  void clearActiveClassroom() {
    _activeClassroomId = null;
    _activeClassName = null;
    notifyListeners();
  }

  LessonProvider([this._auth]);

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
    _categoriesError = null;
    _lessonsError = null;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _categoriesError = null;
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
        _categoriesError = 'Failed to load categories';
        _error = _categoriesError;
      }
    } catch (e) {
      _categoriesError = 'Network error. Please check your connection.';
      _error = _categoriesError;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLessons(String categoryId) async {
    _isLoading = true;
    _lessonsError = null;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId/lessons'),
        headers: _headers,
      );
      debugPrint('GET /categories/$categoryId/lessons STATUS: ${response.statusCode}, BODY: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _lessons = data.map((les) => LessonModel.fromJson(les)).toList()
          ..sort((a, b) => a.lessonOrder.compareTo(b.lessonOrder));
      } else if (response.statusCode == 401) {
        _auth?.logout();
      } else {
        _lessonsError = 'Failed to load lessons (Status: ${response.statusCode})';
        _error = _lessonsError;
      }
    } catch (e, st) {
      debugPrint('GET /categories/$categoryId/lessons EXCEPTION: $e\n$st');
      _lessonsError = 'Network error. Please check your connection.';
      _error = _lessonsError;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<LessonModel?> fetchLessonDetails(String lessonId) async {
    if (lessonId.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lessons/$lessonId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final lesson = LessonModel.fromJson(data);
        final index = _lessons.indexWhere((l) => l.lessonId == lessonId);
        if (index >= 0) {
          _lessons[index] = lesson;
        } else {
          _lessons.add(lesson);
        }
        notifyListeners();
        return lesson;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchLessonDetails error: $e');
    }
    return null;
  }

  Future<void> loadClassLessons(String classId, {String? categoryId}) async {
    _isLoading = true;
    _lessonsError = null;
    _error = null;
    notifyListeners();

    try {
      final uri = categoryId != null && categoryId.isNotEmpty
          ? Uri.parse('$baseUrl/learner/classes/$classId/lessons?categoryId=$categoryId')
          : Uri.parse('$baseUrl/learner/classes/$classId/lessons');

      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _lessons = data.map((les) => LessonModel.fromJson(les)).toList()
          ..sort((a, b) => a.lessonOrder.compareTo(b.lessonOrder));
      } else if (response.statusCode == 401) {
        _auth?.logout();
      } else {
        _lessonsError = 'Failed to load class lessons';
        _error = _lessonsError;
      }
    } catch (e) {
      _lessonsError = 'Network error. Please check your connection.';
      _error = _lessonsError;
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

  Future<List<Map<String, dynamic>>> loadLessonActivity(String lessonId, {String? partOfSpeech}) async {
    try {
      final uri = (partOfSpeech != null && partOfSpeech.isNotEmpty && partOfSpeech != 'ALL')
          ? Uri.parse('$baseUrl/lessons/$lessonId/activity?partOfSpeech=${Uri.encodeComponent(partOfSpeech)}')
          : Uri.parse('$baseUrl/lessons/$lessonId/activity');

      final response = await http.get(
        uri,
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

  /// Starts a practice session.
  ///
  /// Pass [classroomId] when launching from a class context (e.g. class detail
  /// screen lessons tab). The backend will tag all resulting point transactions
  /// and session summaries as CLASS context, enabling the separate class score.
  /// When [classroomId] is null, the active classroom context is reused when
  /// available; otherwise the session runs in global (GLOBAL) context.
  Future<String?> startPracticeSession(String lessonId,
      {int moduleNumber = 2, String? classroomId}) async {
    final effectiveClassroomId = classroomId ?? _activeClassroomId;
    if (effectiveClassroomId != null) {
      _activeClassroomId = effectiveClassroomId;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/practice-sessions'),
        headers: _headers,
        body: json.encode({
          'learnerId': _auth?.learner?.learnerId,
          'lessonId': lessonId,
          'moduleNumber': moduleNumber,
          'classroomContextId': ?effectiveClassroomId,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sessionId'] as String?;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('Error starting practice session: \$e');
    }
    return null;
  }

  Future<bool> endPracticeSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/practice-sessions/$sessionId/end'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('Error ending practice session: $e');
    }
    return false;
  }

  Future<void> updateWordProgress(
    String sessionId,
    String wordId,
    String pathway,
    int stepCompleted,
    String status, {
    int moduleNumber = 1,
  }) async {
    String validStatus = status;
    if (validStatus == 'LEARNING' || validStatus == 'FAMILIAR' || validStatus == 'PROFICIENT') {
      validStatus = 'PRACTICED';
    } else if (validStatus != 'MASTERED' && 
               validStatus != 'NEEDS_PRONUNCIATION_REVIEW' && 
               validStatus != 'INTRODUCED' && 
               validStatus != 'PRONUNCIATION_PENDING') {
      validStatus = 'PRACTICED';
    }

    try {
      // Fire and forget progress update as requested in UC-1.3 to avoid blocking UI latency
      http.patch(
        Uri.parse('$baseUrl/sessions/$sessionId/progress'),
        headers: _headers,
        body: json.encode({
          'wordId': wordId,
          'pathway': pathway,
          'stepCompleted': stepCompleted,
          'status': validStatus,
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


  Future<bool> submitPracticeResult(
    String sessionId,
    String wordId,
    bool isCorrect, {
    String? activityType,
    int? attemptNumber,
  }) async {
    bool goalJustCompleted = false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/practice-sessions/$sessionId/results'),
        headers: _headers,
        body: json.encode({
          'wordId': wordId,
          'correct': isCorrect,
          'isCorrect': isCorrect,
          if (activityType != null) 'activityType': activityType,
          if (attemptNumber != null) 'attemptNumber': attemptNumber,
        }),
      );
      if (response.statusCode == 401) {
        _auth?.logout();
      }

      // Check daily goal if correct
      if (isCorrect && _auth != null) {
        // Fetch current goal state first to see if it's already completed
        final currentGoal = await DailyGoalService.getDailyGoal(_auth!);
        if (currentGoal != null && !currentGoal.isCompleted) {
          final updatedGoal = await DailyGoalService.incrementGoal(_auth!);
          if (updatedGoal != null && updatedGoal.isCompleted) {
            goalJustCompleted = true; // Goal just completed in this step
          }
        }
      }
    } catch (e) {
      debugPrint('Error submitting practice result: $e');
    }
    return goalJustCompleted;
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
  Future<bool> submitReviewItem({
    required String sessionId,
    required String wordId,
    required bool isCorrect,
    required int confidence,
  }) async {
    bool goalJustCompleted = false;
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

      // Check daily goal if correct
      if (isCorrect && _auth != null) {
        final currentGoal = await DailyGoalService.getDailyGoal(_auth!);
        if (currentGoal != null && !currentGoal.isCompleted) {
          final updatedGoal = await DailyGoalService.incrementGoal(_auth!);
          if (updatedGoal != null && updatedGoal.isCompleted) {
            goalJustCompleted = true; // Goal just completed in this step
          }
        }
      }
    } catch (e) {
      debugPrint('LessonProvider.submitReviewItem error: $e');
    }
    return goalJustCompleted;
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

  Future<List<Map<String, dynamic>>> loadModule4Review(String lessonId) async {
    try {
      final learnerId = _auth?.learner?.learnerId;
      final uri = Uri.parse('$baseUrl/lessons/$lessonId/module4-review').replace(
        queryParameters: {
          if (learnerId != null && learnerId.isNotEmpty) 'learnerId': learnerId,
        },
      );

      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.loadModule4Review error: $e');
    }
    return [];
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
    double? customScore,
    bool isSandbox = false,
    String? sessionId,
    int? timeSeconds,
  }) async {
    final score = customScore ?? ScoringService.computeLessonScore(correctCount, totalCount);
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
              'timeSeconds': ?timeSeconds,
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
              'timeSeconds': ?timeSeconds,
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
    } catch (_) {
      // Don't let local storage failures block the app; just log silently.
      debugPrint('LessonProvider.persistModuleScore: failed to save locally');
    }
  }

  /// Records partial elapsed active time for a module when exiting/abandoning.
  Future<void> recordPartialModuleTime(
    String sessionId,
    int moduleNumber,
    int timeSeconds, {
    String? lessonId,
  }) async {
    try {
      http.post(
        Uri.parse('$baseUrl/progress/module-time'),
        headers: _headers,
        body: json.encode({
          'sessionId': sessionId,
          'lessonId': lessonId,
          'moduleNumber': moduleNumber,
          'timeSeconds': timeSeconds,
          'isPartial': true,
        }),
      );
    } catch (e) {
      debugPrint('LessonProvider.recordPartialModuleTime error: $e');
    }
  }

  /// Fetches retrieval practice questions generated for a session.
  Future<List<Map<String, dynamic>>> loadRetrievalQuestions(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/retrieval/session/$sessionId/questions'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.loadRetrievalQuestions error: $e');
    }
    return [];
  }

  /// Fetches a dynamic FAMILIAR-tier diagnostic question for a word.
  Future<Map<String, dynamic>?> loadDiagnosticQuestion(String sessionId, String wordId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/retrieval/session/$sessionId/diagnostic-question/$wordId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.loadDiagnosticQuestion error: $e');
    }
    return null;
  }

  /// Applies diagnostic boost promoting word from LEARNING -> PROFICIENT.
  Future<void> applyDiagnosticBoost(String wordId, {String? activityType}) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/words/$wordId/difficulty/adjust'),
        headers: _headers,
        body: json.encode({
          'action': 'DIAGNOSTIC_BOOST',
          'activityType': ?activityType,
        }),
      );
    } catch (e) {
      debugPrint('LessonProvider.applyDiagnosticBoost error: $e');
    }
  }

  /// Records diagnostic failure audit state.
  Future<void> recordDiagnosticFail(String wordId, {String? activityType}) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/words/$wordId/difficulty/adjust'),
        headers: _headers,
        body: json.encode({
          'action': 'DIAGNOSTIC_FAIL',
          'activityType': ?activityType,
        }),
      );
    } catch (e) {
      debugPrint('LessonProvider.recordDiagnosticFail error: $e');
    }
  }

  /// Submits an answer to the retrieval endpoint.
  Future<Map<String, dynamic>?> submitRetrievalAnswer(
    String sessionId,
    String wordId,
    bool isCorrect, {
    String? wrongAnswer,
    String? activityFormat,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/retrieval/session/$sessionId/submit'),
        headers: _headers,
        body: json.encode({
          'wordId': wordId,
          'correct': isCorrect,
          'wrongAnswer': wrongAnswer ?? '',
          'activityFormat': activityFormat ?? 'MULTIPLE_CHOICE',
        }),
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        
        // Check daily goal if correct
        if (isCorrect && _auth != null) {
          final currentGoal = await DailyGoalService.getDailyGoal(_auth!);
          if (currentGoal != null && !currentGoal.isCompleted) {
            final updatedGoal = await DailyGoalService.incrementGoal(_auth!);
            if (updatedGoal != null && updatedGoal.isCompleted) {
              result['goalJustCompleted'] = true;
            }
          }
        }
        
        return result;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.submitRetrievalAnswer error: $e');
    }
    return null;
  }

  /// Acknowledges reintroduction for a word.
  Future<void> acknowledgeReintroduction(String wordId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/words/$wordId/reintroduction/acknowledge'),
        headers: _headers,
      );
    } catch (e) {
      debugPrint('LessonProvider.acknowledgeReintroduction error: $e');
    }
  }

  /// Checks whether all words in a lesson are MASTERED.
  Future<Map<String, dynamic>?> checkLessonMasteryStatus(String lessonId, {int moduleNumber = 2}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lessons/$lessonId/mastery-status?moduleNumber=$moduleNumber'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.checkLessonMasteryStatus error: $e');
    }
    return null;
  }

  /// Submits difficulty result with activity type.
  Future<Map<String, dynamic>?> submitDifficultyResult(String wordId, bool isCorrect, {String? activityType, int moduleNumber = 2}) async {
    try {
      final uri = Uri.parse('$baseUrl/words/$wordId/difficulty/adjust').replace(
        queryParameters: {
          'moduleNumber': moduleNumber.toString(),
        },
      );
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({
          'correct': isCorrect,
          'activityType': ?activityType,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.submitDifficultyResult error: $e');
    }
    return null;
  }

  /// Loads a single retrieval question for a word.
  Future<Map<String, dynamic>?> loadSingleRetrievalQuestion(String sessionId, String wordId, {String? format}) async {
    try {
      final uri = Uri.parse('$baseUrl/retrieval/session/$sessionId/question/$wordId').replace(
        queryParameters: {
          if (format != null && format.isNotEmpty) 'format': format,
        },
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.loadSingleRetrievalQuestion error: $e');
    }
    return null;
  }

  /// Fetches leaderboard for a given time range.
  Future<List<Map<String, dynamic>>> fetchLeaderboard(String range) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard?range=$range'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchLeaderboard error: $e');
    }
    return [];
  }

  /// Loads word difficulty map for a lesson.
  Future<Map<String, String>> loadWordDifficulties(String lessonId, {int? moduleNumber}) async {
    try {
      final uri = Uri.parse('$baseUrl/lessons/$lessonId/word-difficulties').replace(
        queryParameters: {
          if (moduleNumber != null) 'moduleNumber': moduleNumber.toString(),
        },
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data.map((k, v) => MapEntry(k, v.toString()));
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.loadWordDifficulties error: $e');
    }
    return {};
  }

  /// Fetches word mastery summary for a lesson score screen.
  Future<List<Map<String, dynamic>>> fetchWordMasterySummary(String lessonId, {String? sessionId}) async {
    try {
      final uri = (sessionId != null && sessionId.isNotEmpty)
          ? Uri.parse('$baseUrl/lessons/$lessonId/word-mastery-summary?sessionId=${Uri.encodeComponent(sessionId)}')
          : Uri.parse('$baseUrl/lessons/$lessonId/word-mastery-summary');
      final response = await http.get(
        uri,
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchWordMasterySummary error: $e');
    }
    return [];
  }

  /// Resets difficulty and performance progress for words in a lesson (optionally for a specific POS).
  Future<bool> resetLessonProgress(String lessonId, {String? partOfSpeech}) async {
    try {
      final uri = (partOfSpeech != null && partOfSpeech.isNotEmpty && partOfSpeech != 'ALL')
          ? Uri.parse('$baseUrl/lessons/$lessonId/reset-progress?partOfSpeech=${Uri.encodeComponent(partOfSpeech)}')
          : Uri.parse('$baseUrl/lessons/$lessonId/reset-progress');

      final response = await http.post(uri, headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
    } catch (e) {
      debugPrint('LessonProvider.resetLessonProgress error: $e');
    }
    return false;
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

  /// Generates or builds a structured multi-word Sandbox Learning Path from topic or word input.
  Future<Map<String, dynamic>> generateSandboxPathCurriculum({
    required String customInput,
  }) async {
    final rawResult = await generateSandbox(customWord: customInput);
    final sessionMap = rawResult?['session'] is Map ? Map<String, dynamic>.from(rawResult!['session']) : <String, dynamic>{};
    final sessionId = sessionMap['sessionId']?.toString() ?? const Uuid().v4();
    final customWord = sessionMap['customWord']?.toString() ?? customInput;

    List<Map<String, dynamic>> wordsList = [];
    if (rawResult?['words'] is List) {
      wordsList = (rawResult!['words'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    final List<Map<String, dynamic>> processedWords = [];
    if (wordsList.isNotEmpty) {
      final w = Map<String, dynamic>.from(wordsList.first);
      w['wordId'] ??= const Uuid().v4();
      w['wordOrder'] = 1;
      processedWords.add(w);
    }

    if (processedWords.isEmpty) {
      processedWords.add({
        'wordId': const Uuid().v4(),
        'englishWord': customWord,
        'cebuanoMeaning': customWord,
        'exampleSentenceEnglish': 'I like $customWord.',
        'exampleSentenceCebuano': 'Ganahan ko sa $customWord.',
        'wordOrder': 1,
      });
    }

    final List<Map<String, dynamic>> pathNodes = [
      {
        'lessonId': 'sandbox_${sessionId}_n1',
        'lessonNumber': 1,
        'lessonTitle': '$customWord Vocabulary',
        'lessonDescription': 'Practice and master $customWord',
        'words': processedWords,
        'totalWordCount': processedWords.length,
        'status': 'UNLOCKED',
      }
    ];

    final fullSessionData = {
      'sessionId': sessionId,
      'customWord': customWord,
      'topic': customWord,
      'createdAt': DateTime.now().toIso8601String(),
      'words': processedWords,
      'pathNodes': pathNodes,
      'totalCount': processedWords.length,
      'masteredCount': 0,
      'nodeProgress': {},
    };

    await LocalStorageService.saveSandboxSession(fullSessionData);
    notifyListeners();
    return fullSessionData;
  }

  /// Loads sandbox history list.
  Future<List<Map<String, dynamic>>> getSandboxHistory() async {
    return await LocalStorageService.getSandboxSessions();
  }

  /// Deletes a sandbox session from history.
  Future<void> deleteSandboxSession(String sessionId) async {
    await LocalStorageService.deleteSandboxSession(sessionId);
    notifyListeners();
  }

  /// Completes a cumulative review session and records the history on backend.
  Future<Map<String, dynamic>?> completeCumulativeReview(
    String sessionId, {
    required double accuracyScore,
    int? totalAttempts,
    int? correctCount,
    String? badgeAwarded,
    int? pointsEarned,
    int? timeSpentSeconds,
    String? categoryId,
    String? lessonPairId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cumulative-review/sessions/$sessionId/complete'),
        headers: _headers,
        body: json.encode({
          'accuracyScore': accuracyScore,
          'totalAttempts': totalAttempts,
          'correctCount': correctCount,
          'badgeAwarded': badgeAwarded,
          'pointsEarned': pointsEarned,
          'timeSpentSeconds': timeSpentSeconds,
          'categoryId': categoryId,
          'lessonPairId': lessonPairId,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.completeCumulativeReview error: $e');
    }
    return null;
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

  /// Resets learner progress completely across backend and local storage.
  Future<void> resetProgress() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/learners/reset-progress'),
        headers: _headers,
      );
      
      debugPrint('Reset progress response status: ${response.statusCode}');
      debugPrint('Reset progress response body: ${response.body}');
      
      if (response.statusCode == 401) {
        _auth?.logout();
        return;
      } else if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to reset progress: ${response.statusCode}');
      }

      // 1. Wipe ALL local lesson progress, session states, scores, and module snapshots
      await LocalStorageService.clearAllLessonData();

      // 2. Refresh user profile (resets points, XP, streak, words mastered in UI)
      if (_auth != null) {
        await _auth!.fetchProfile();
      }

      // 3. Reload categories and lessons fresh from backend
      if (_categories.isNotEmpty) {
        await loadCategories();
        for (final cat in _categories) {
          await loadLessons(cat.categoryId);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('LessonProvider.resetProgress error: $e');
      rethrow;
    }
  }

  /// Resets a single lesson's progress across backend and local storage.
  Future<bool> resetLesson(String lessonId) async {
    try {
      // 1. Always wipe local storage data for this specific lesson
      await LocalStorageService.saveLessonScore(lessonId, 0.0);
      await LocalStorageService.clearLessonScoreDetails(lessonId);
      await LocalStorageService.clearModuleProgressSnapshot(lessonId);

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
        }
        notifyListeners();
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
  Future<Map<String, dynamic>?> completeMasterySession(
    String sessionId,
    String lessonId, {
    double? score,
    bool? isPerfectFirstAttempt,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mastery/session/$sessionId/complete').replace(
        queryParameters: {
          'lessonId': lessonId,
          if (score != null) 'score': score.toString(),
          if (isPerfectFirstAttempt != null) 'isPerfectFirstAttempt': isPerfectFirstAttempt.toString(),
        },
      );
      final response = await http.post(uri, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        _auth?.logout();
      } else {
        debugPrint('CRITICAL: LessonProvider.completeMasterySession failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('CRITICAL EXCEPTION: LessonProvider.completeMasterySession error: $e');
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

  /// Retrieves all earned badges for a learner from backend RewardData.
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

  /// Fetches consolidated badges across backend RewardData, Dashboard category breakdowns,
  /// live per-lesson progress, and local storage scores to ensure zero missed badges and live accuracy.
  Future<List<Map<String, dynamic>>> loadConsolidatedBadges(String? learnerId) async {
    final Map<String, Map<String, dynamic>> badgeByLessonId = {};

    // 1. Fetch live per-lesson progress (contains real-time, up-to-date accuracy from word performances)
    if (learnerId != null && learnerId.isNotEmpty) {
      try {
        final lessonProgressList = await fetchLearnerLessonProgress(learnerId);
        for (final lp in lessonProgressList) {
          final id = lp.lessonId;
          if (id.isNotEmpty && (lp.accuracyRate > 0 || lp.status == 'COMPLETED' || lp.totalAttempts > 0)) {
            final acc = lp.accuracyRate;
            final tier = acc >= 90.0 ? 'GOLD' : (acc >= 75.0 ? 'SILVER' : 'BRONZE');
            badgeByLessonId[id] = {
              'lessonId': id,
              'lessonTitle': lp.lessonTitle.isNotEmpty ? lp.lessonTitle : 'Lesson',
              'categoryName': lp.categoryName,
              'badgeType': tier,
              'score': acc,
              'hasLiveAccuracy': true,
            };
            // Keep local storage synchronized with the actual live lesson accuracy
            LocalStorageService.saveLessonScore(id, acc, force: true);
          }
        }
      } catch (e) {
        debugPrint('loadConsolidatedBadges fetchLearnerLessonProgress error: $e');
      }
    }

    // 2. Fetch backend RewardData badges
    if (learnerId != null && learnerId.isNotEmpty) {
      try {
        final backendBadges = await fetchLearnerBadges(learnerId);
        for (final b in backendBadges) {
          final id = (b['lessonId'] ?? '').toString();
          if (id.isNotEmpty) {
            if (!badgeByLessonId.containsKey(id)) {
              final rScore = (b['score'] as num?)?.toDouble();
              final bType = (b['badgeType'] ?? '').toString().toUpperCase();
              final tier = (rScore != null && rScore > 0)
                  ? (rScore >= 90.0 ? 'GOLD' : (rScore >= 75.0 ? 'SILVER' : 'BRONZE'))
                  : (bType.isNotEmpty ? bType : 'BRONZE');
              badgeByLessonId[id] = {
                ...Map<String, dynamic>.from(b),
                'badgeType': tier,
                'score': ?rScore,
              };
            } else {
              final existing = badgeByLessonId[id]!;
              if ((existing['categoryName'] == null || existing['categoryName'].toString().isEmpty) && b['categoryName'] != null) {
                existing['categoryName'] = b['categoryName'];
              }
              // Only apply backend score/tier if live progress did not already supply an accurate score
              if (existing['hasLiveAccuracy'] != true) {
                final rScore = (b['score'] as num?)?.toDouble();
                if (rScore != null && rScore > 0) {
                  existing['score'] = rScore;
                  existing['badgeType'] = rScore >= 90.0 ? 'GOLD' : (rScore >= 75.0 ? 'SILVER' : 'BRONZE');
                } else if (b['badgeType'] != null) {
                  existing['badgeType'] = b['badgeType'];
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('loadConsolidatedBadges fetchLearnerBadges error: $e');
      }
    }

    // 3. Augment with backend dashboard category breakdowns
    try {
      final dash = await fetchDashboardProgress();
      if (dash != null) {
        final breakdowns = List<Map<String, dynamic>>.from(dash['categoryBreakdowns'] ?? []);
        for (final cat in breakdowns) {
          final catName = (cat['categoryName'] ?? '').toString();
          final catLessons = List<Map<String, dynamic>>.from(cat['lessons'] ?? []);
          for (final l in catLessons) {
            final lessonId = (l['lessonId'] ?? '').toString();
            final lessonTitle = (l['lessonTitle'] ?? 'Lesson').toString();
            final acc = (l['lessonAccuracy'] as num?)?.toDouble();
            if (lessonId.isNotEmpty) {
              if (!badgeByLessonId.containsKey(lessonId)) {
                if (acc != null && acc > 0) {
                  final tier = acc >= 90.0 ? 'GOLD' : (acc >= 75.0 ? 'SILVER' : 'BRONZE');
                  badgeByLessonId[lessonId] = {
                    'lessonId': lessonId,
                    'lessonTitle': lessonTitle,
                    'categoryName': catName,
                    'badgeType': tier,
                    'score': acc,
                  };
                }
              } else {
                final existing = badgeByLessonId[lessonId]!;
                if ((existing['categoryName'] == null || existing['categoryName'].toString().isEmpty) && catName.isNotEmpty) {
                  existing['categoryName'] = catName;
                }
                // Do not override live progress accuracy with dashboard category breakdown
                if (existing['hasLiveAccuracy'] != true && acc != null && acc > 0) {
                  existing['score'] = acc;
                  existing['badgeType'] = acc >= 90.0 ? 'GOLD' : (acc >= 75.0 ? 'SILVER' : 'BRONZE');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('loadConsolidatedBadges dashboard error: $e');
    }

    // 4. Augment with local storage scores & lesson model masteryScores only for lessons not yet recorded
    for (final lesson in lessons) {
      try {
        if (!badgeByLessonId.containsKey(lesson.lessonId)) {
          final localScore = await LocalStorageService.getLessonScore(lesson.lessonId);
          final backendMasteryScore = lesson.masteryScore;
          final double? effectiveScore = (backendMasteryScore != null && backendMasteryScore > 0)
              ? (localScore != null && localScore > backendMasteryScore ? localScore : backendMasteryScore)
              : localScore;

          if (effectiveScore != null && effectiveScore > 0) {
            final tier = effectiveScore >= 90.0 ? 'GOLD' : (effectiveScore >= 75.0 ? 'SILVER' : 'BRONZE');
            badgeByLessonId[lesson.lessonId] = {
              'lessonId': lesson.lessonId,
              'lessonTitle': lesson.lessonTitle,
              'badgeType': tier,
              'score': effectiveScore,
            };
          }
        }
      } catch (_) {}
    }

    // 5. Strictly enforce score-based tiers so Gold is ONLY given for >= 90%
    for (final entry in badgeByLessonId.values) {
      final scoreVal = (entry['score'] as num?)?.toDouble();
      if (scoreVal != null && scoreVal > 0) {
        entry['badgeType'] = scoreVal >= 90.0
            ? 'GOLD'
            : (scoreVal >= 75.0 ? 'SILVER' : 'BRONZE');
      }
    }

    final sortedList = badgeByLessonId.values.toList();
    sortedList.sort((a, b) {
      final titleA = (a['lessonTitle'] ?? '').toString();
      final titleB = (b['lessonTitle'] ?? '').toString();
      return titleA.compareTo(titleB);
    });

    return sortedList;
  }

  /// Retrieves full progress details for a learner.
  Future<LearnerProgressModel?> fetchLearnerProgressDetails(String learnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learners/$learnerId/progress'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return LearnerProgressModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchLearnerProgressDetails error: $e');
    }
    return null;
  }

  /// Retrieves per-lesson progress breakdown for a learner.
  Future<List<LearnerLessonProgressModel>> fetchLearnerLessonProgress(String learnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learners/$learnerId/progress/lessons'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => LearnerLessonProgressModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchLearnerLessonProgress error: $e');
    }
    return [];
  }

  /// Retrieves per-category progress breakdown for a learner.
  Future<List<LearnerCategoryProgressModel>> fetchLearnerCategoryProgress(String learnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learners/$learnerId/progress/categories'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => LearnerCategoryProgressModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchLearnerCategoryProgress error: $e');
    }
    return [];
  }

  /// Retrieves recently practiced words for a learner.
  Future<List<RecentWordProgressModel>> fetchLearnerRecentWords(String learnerId, {int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learners/$learnerId/progress/recent-words?limit=$limit'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((e) => RecentWordProgressModel.fromJson(e as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchLearnerRecentWords error: $e');
    }
    return [];
  }

  /// Retrieves accurate user-specific active activity dates and streak statistics.
  Future<LearnerActivityStatsModel?> fetchLearnerActivityStats(String learnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learners/$learnerId/activity-dates'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LearnerActivityStatsModel.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        _auth?.logout();
      }
    } catch (e) {
      debugPrint('LessonProvider.fetchLearnerActivityStats error: $e');
    }
    return null;
  }
}
