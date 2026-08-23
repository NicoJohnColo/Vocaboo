import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ActivityFormat {
  multipleChoice,
  matching,
  fillInTheBlank,
  rearrangement,
  imageMatching,
  listeningTyping,
  translationMatching,
  flashcardRecall,
  wordScramble,
  imageLabeling,
  trueOrFalse,
}

enum ReinforcementStatus {
  pending,
  reinforcedComplete,
  reinforcedIncomplete,
}

class PracticeItemModel {
  final String wordId;
  final String englishWord;
  final String? displayWord;
  final String cebuanoMeaning;
  final String exampleSentenceEnglish;
  final String? hintText;
  final String? exampleSentenceCebuano;
  ActivityFormat activityFormat;
  final List<String> distractors;
  final String? mcDistractor1;
  final String? mcDistractor2;
  final String? mcDistractor3;
  final String? fitbSentence;
  final String? fitbAnswer;
  final List<Map<String, dynamic>>? matchingSet;
  final List<String>? sentenceArrangementTokens;
  final String? tileSentence;
  final String? sentenceCompletionSentence;
  final String? sentenceCompletionAnswer;
  final String? sentenceCompletionOption1;
  final String? sentenceCompletionOption2;
  final String? sentenceCompletionOption3;
  final String? imageAssetPath;
  final int? timeLimitSeconds;
  final String? difficultyLevel;
  /// Whether hints/cebuano meaning are shown (LEARNING tier only).
  final bool showHint;
  /// For SENTENCE_ARRANGEMENT at LEARNING tier: the pre-placed word token.
  final String? anchoredWord;
  final String? eligibleActivityTypes;

  PracticeItemModel({
    required this.wordId,
    required this.englishWord,
    this.displayWord,
    required this.cebuanoMeaning,
    required this.exampleSentenceEnglish,
    this.exampleSentenceCebuano,
    required this.activityFormat,
    required this.distractors,
    this.eligibleActivityTypes,
    this.mcDistractor1,
    this.mcDistractor2,
    this.mcDistractor3,
    this.fitbSentence,
    this.fitbAnswer,
    this.matchingSet,
    this.sentenceArrangementTokens,
    this.tileSentence,
    this.sentenceCompletionSentence,
    this.sentenceCompletionAnswer,
    this.sentenceCompletionOption1,
    this.sentenceCompletionOption2,
    this.sentenceCompletionOption3,
    this.imageAssetPath,
    this.timeLimitSeconds,
    this.difficultyLevel,
    this.hintText,
    this.showHint = false,
    this.anchoredWord,
  });

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'englishWord': englishWord,
      'displayWord': displayWord,
      'cebuanoMeaning': cebuanoMeaning,
      'exampleSentenceEnglish': exampleSentenceEnglish,
      'exampleSentenceCebuano': exampleSentenceCebuano,
      'activityFormat': activityFormat.index,
      'distractors': distractors,
      'mcDistractor1': mcDistractor1,
      'mcDistractor2': mcDistractor2,
      'mcDistractor3': mcDistractor3,
      'fitbSentence': fitbSentence,
      'fitbAnswer': fitbAnswer,
      'matchingSet': matchingSet,
      'sentenceArrangementTokens': sentenceArrangementTokens,
      'tileSentence': tileSentence,
      'sentenceCompletionSentence': sentenceCompletionSentence,
      'sentenceCompletionAnswer': sentenceCompletionAnswer,
      'sentenceCompletionOption1': sentenceCompletionOption1,
      'sentenceCompletionOption2': sentenceCompletionOption2,
      'sentenceCompletionOption3': sentenceCompletionOption3,
      'imageAssetPath': imageAssetPath,
      'timeLimitSeconds': timeLimitSeconds,
      'difficultyLevel': difficultyLevel,
      'hintText': hintText,
      'showHint': showHint,
      'anchoredWord': anchoredWord,
    };
  }

  factory PracticeItemModel.fromJson(Map<String, dynamic> json) {
    final sentenceCompletionOptions = _readStringList(json, 'sentenceCompletionOptions');
    return PracticeItemModel(
      wordId: json['wordId'],
      englishWord: json['englishWord'],
      displayWord: json['displayWord'],
      cebuanoMeaning: json['cebuanoMeaning'],
      exampleSentenceEnglish: _readString(json, 'exampleSentenceEnglish', 'englishExampleSentence', 'example'),
      exampleSentenceCebuano: _readString(json, 'exampleSentenceCebuano', 'cebuanoExampleSentence', 'cebuanoExample'),
      activityFormat: ActivityFormat.values[json['activityFormat'] as int],
      distractors: List<String>.from((json['distractors'] as List<dynamic>? ?? const []).map((item) => item.toString())),
      mcDistractor1: json['mcDistractor1'],
      mcDistractor2: json['mcDistractor2'],
      mcDistractor3: json['mcDistractor3'],
      fitbSentence: _readString(json, 'fitbSentence', 'fillInTheBlankSentence'),
      fitbAnswer: _readString(json, 'fitbAnswer', 'sentenceCompletionAnswer', 'sentenceCompletionBlank'),
      matchingSet: (json['matchingSet'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      sentenceArrangementTokens: ((json['sentenceArrangementTokens'] ?? json['scrambledTokens']) as List<dynamic>?)?.map((item) => item.toString()).toList(),
      tileSentence: _readString(json, 'tileSentence', 'sentenceCompletionSentence'),
      sentenceCompletionSentence: _readString(json, 'sentenceCompletionSentence', 'sentenceCompletionBlank', 'fillInTheBlankSentence'),
      sentenceCompletionAnswer: _readString(json, 'sentenceCompletionAnswer', 'fitbAnswer', 'englishWord'),
      sentenceCompletionOption1: _readSentenceCompletionOption(json, sentenceCompletionOptions, 0),
      sentenceCompletionOption2: _readSentenceCompletionOption(json, sentenceCompletionOptions, 1),
      sentenceCompletionOption3: _readSentenceCompletionOption(json, sentenceCompletionOptions, 2),
      imageAssetPath: json['imageAssetPath'],
      timeLimitSeconds: json['timeLimitSeconds'] as int?,
      difficultyLevel: json['difficultyLevel'] as String?,
      hintText: json['hintText'] ?? json['explanationText'] ?? json['explanation'],
      showHint: json['showHint'] == true || json['showHints'] == true || json['showExplanation'] == true || json['showExplanations'] == true,
      anchoredWord: json['anchoredWord'] as String?,
    );
  }

  static String _readString(Map<String, dynamic> json, String primaryKey, String secondaryKey, [String? tertiaryKey]) {
    for (final key in [primaryKey, secondaryKey, tertiaryKey].whereType<String>()) {
      final value = json[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return '';
  }

  static List<String> _readStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is List) {
      return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
    }
    return const [];
  }

  static String? _readSentenceCompletionOption(Map<String, dynamic> json, List<String> options, int index) {
    if (options.length > index) {
      final value = options[index].trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    final legacyKey = 'sentenceCompletionOption${index + 1}';
    final fallback = json[legacyKey]?.toString().trim() ?? '';
    return fallback.isEmpty ? null : fallback;
  }
}

class PracticeEvaluationResult {
  final String wordId;
  final ActivityFormat activityFormat;
  final String learnerResponse;
  final String correctAnswer;
  final bool isCorrect;
  final DateTime evaluatedAt;
  final int isReinforcementAttempt; // 0 = initial, 1 = reinforcement

  PracticeEvaluationResult({
    required this.wordId,
    required this.activityFormat,
    required this.learnerResponse,
    required this.correctAnswer,
    required this.isCorrect,
    required this.evaluatedAt,
    required this.isReinforcementAttempt,
  });

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'activityFormat': activityFormat.index,
      'learnerResponse': learnerResponse,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'evaluatedAt': evaluatedAt.toIso8601String(),
      'isReinforcementAttempt': isReinforcementAttempt,
    };
  }

  factory PracticeEvaluationResult.fromJson(Map<String, dynamic> json) {
    return PracticeEvaluationResult(
      wordId: json['wordId'],
      activityFormat: ActivityFormat.values[json['activityFormat']],
      learnerResponse: json['learnerResponse'],
      correctAnswer: json['correctAnswer'],
      isCorrect: json['isCorrect'],
      evaluatedAt: DateTime.parse(json['evaluatedAt']),
      isReinforcementAttempt: json['isReinforcementAttempt'],
    );
  }
}

class ReinforcementQueueItem {
  final String wordId;
  ActivityFormat assignedFormat;
  ReinforcementStatus status;
  final DateTime createdAt;

  ReinforcementQueueItem({
    required this.wordId,
    required this.assignedFormat,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'assignedFormat': assignedFormat.index,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReinforcementQueueItem.fromJson(Map<String, dynamic> json) {
    return ReinforcementQueueItem(
      wordId: json['wordId'],
      assignedFormat: ActivityFormat.values[json['assignedFormat']],
      status: ReinforcementStatus.values[json['status']],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class SessionSummaryModel {
  final String sessionId;
  final String learnerId;
  final String lessonId;
  final int totalWordsPracticed;
  final int initialPassCorrectCount;
  final int reinforcementPassCorrectCount;
  final double overallMasteryPercentage;
  final DateTime summaryGeneratedAt;

  SessionSummaryModel({
    required this.sessionId,
    required this.learnerId,
    required this.lessonId,
    required this.totalWordsPracticed,
    required this.initialPassCorrectCount,
    required this.reinforcementPassCorrectCount,
    required this.overallMasteryPercentage,
    required this.summaryGeneratedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'learnerId': learnerId,
      'lessonId': lessonId,
      'totalWordsPracticed': totalWordsPracticed,
      'initialPassCorrectCount': initialPassCorrectCount,
      'reinforcementPassCorrectCount': reinforcementPassCorrectCount,
      'overallMasteryPercentage': overallMasteryPercentage,
      'summaryGeneratedAt': summaryGeneratedAt.toIso8601String(),
    };
  }

  factory SessionSummaryModel.fromJson(Map<String, dynamic> json) {
    return SessionSummaryModel(
      sessionId: json['sessionId'],
      learnerId: json['learnerId'],
      lessonId: json['lessonId'],
      totalWordsPracticed: json['totalWordsPracticed'],
      initialPassCorrectCount: json['initialPassCorrectCount'],
      reinforcementPassCorrectCount: json['reinforcementPassCorrectCount'],
      overallMasteryPercentage: json['overallMasteryPercentage'],
      summaryGeneratedAt: DateTime.parse(json['summaryGeneratedAt']),
    );
  }
}

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Practice Session State ---
  static Future<void> savePracticeSessionState(
    String sessionId,
    List<PracticeItemModel> queue,
    int currentIndex, {
    int? completedScreens,
    int? plannedScreens,
  }) async {
    await init();
    final data = {
      'queue': queue.map((item) => item.toJson()).toList(),
      'currentIndex': currentIndex,
      'completedScreens': completedScreens,
      'plannedScreens': plannedScreens,
    };
    await _prefs!.setString('practice_session_state_$sessionId', json.encode(data));
  }

  static Future<void> saveModuleProgressSnapshot(
    String sessionId,
    Map<String, dynamic> snapshot,
  ) async {
    await init();
    await _prefs!.setString('module_progress_snapshot_$sessionId', json.encode(snapshot));
  }

  static Future<Map<String, dynamic>?> getModuleProgressSnapshot(String sessionId) async {
    await init();
    final raw = _prefs!.getString('module_progress_snapshot_$sessionId');
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearModuleProgressSnapshot(String sessionId) async {
    await init();
    await _prefs!.remove('module_progress_snapshot_$sessionId');
  }

  static Future<Map<String, dynamic>?> getPracticeSessionState(String sessionId) async {
    await init();
    final raw = _prefs!.getString('practice_session_state_$sessionId');
    if (raw == null) return null;
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final queueRaw = decoded['queue'] as List<dynamic>;
    final queue = queueRaw.map((item) => PracticeItemModel.fromJson(item)).toList();
    return {
      'queue': queue,
      'currentIndex': decoded['currentIndex'] as int,
      'completedScreens': decoded['completedScreens'] as int?,
      'plannedScreens': decoded['plannedScreens'] as int?,
    };
  }

  static Future<void> clearPracticeSessionState(String sessionId) async {
    await init();
    await _prefs!.remove('practice_session_state_$sessionId');
  }

  // --- Practice Results ---
  static Future<void> saveEvaluationResult(String sessionId, PracticeEvaluationResult result) async {
    await init();
    final list = await getEvaluationResults(sessionId);
    list.add(result);
    final raw = list.map((res) => res.toJson()).toList();
    await _prefs!.setString('practice_results_$sessionId', json.encode(raw));
  }

  static Future<List<PracticeEvaluationResult>> getEvaluationResults(String sessionId) async {
    await init();
    final raw = _prefs!.getString('practice_results_$sessionId');
    if (raw == null) return [];
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded.map((res) => PracticeEvaluationResult.fromJson(res)).toList();
  }

  // --- Reinforcement Queue ---
  static Future<void> saveReinforcementQueue(String sessionId, List<ReinforcementQueueItem> queue) async {
    await init();
    final raw = queue.map((item) => item.toJson()).toList();
    await _prefs!.setString('reinforcement_queue_$sessionId', json.encode(raw));
  }

  static Future<List<ReinforcementQueueItem>> getReinforcementQueue(String sessionId) async {
    await init();
    final raw = _prefs!.getString('reinforcement_queue_$sessionId');
    if (raw == null) return [];
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded.map((item) => ReinforcementQueueItem.fromJson(item)).toList();
  }

  // --- Session Summaries ---
  static Future<void> saveSessionSummary(SessionSummaryModel summary) async {
    await init();
    await _prefs!.setString('session_summary_${summary.sessionId}', json.encode(summary.toJson()));
  }

  static Future<SessionSummaryModel?> getSessionSummary(String sessionId) async {
    await init();
    final raw = _prefs!.getString('session_summary_$sessionId');
    if (raw == null) return null;
    return SessionSummaryModel.fromJson(json.decode(raw));
  }
  
  // --- Cumulative Review State ---
  static Future<void> saveCumulativeReviewState(String sessionId, Map<String, dynamic> state) async {
    await init();
    await _prefs!.setString('cumulative_review_state_$sessionId', json.encode(state));
  }
  
  static Future<Map<String, dynamic>?> getCumulativeReviewState(String sessionId) async {
    await init();
    final raw = _prefs!.getString('cumulative_review_state_$sessionId');
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }
  
  static Future<void> clearCumulativeReviewState(String sessionId) async {
    await init();
    await _prefs!.remove('cumulative_review_state_$sessionId');
  }

  static Future<void> saveCumulativeReviewScoreDetails(String sessionId, Map<String, dynamic> details) async {
    await init();
    await _prefs!.setString('cumulative_review_score_details_$sessionId', json.encode(details));
  }

  static Future<Map<String, dynamic>?> getCumulativeReviewScoreDetails(String sessionId) async {
    await init();
    final raw = _prefs!.getString('cumulative_review_score_details_$sessionId');
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveReviewCompletionState(String sessionId, Map<String, dynamic> state) async {
    await init();
    await _prefs!.setString('review_completion_state_$sessionId', json.encode(state));
  }

  static Future<Map<String, dynamic>?> getReviewCompletionState(String sessionId) async {
    await init();
    final raw = _prefs!.getString('review_completion_state_$sessionId');
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearReviewCompletionState(String sessionId) async {
    await init();
    await _prefs!.remove('review_completion_state_$sessionId');
  }

  // --- Active Lesson Session Resuming ---
  static Future<void> saveActiveLessonSession(String lessonId, String sessionId, String redirectPath) async {
    await init();
    await _prefs!.setString('active_session_id_$lessonId', sessionId);
    await _prefs!.setString('active_session_route_$lessonId', redirectPath);
  }

  static Future<Map<String, String>?> getActiveLessonSession(String lessonId) async {
    await init();
    final sid = _prefs!.getString('active_session_id_$lessonId');
    final route = _prefs!.getString('active_session_route_$lessonId');
    if (sid != null && route != null) {
      return {'sessionId': sid, 'redirectPath': route};
    }
    return null;
  }

  static Future<void> clearActiveLessonSession(String lessonId) async {
    await init();
    await _prefs!.remove('active_session_id_$lessonId');
    await _prefs!.remove('active_session_route_$lessonId');
  }

  // --- Cumulative Review Completion ---
  static Future<void> saveCumulativeReviewCompleted(String categoryId, double masteryScore, int masteredCount, int totalItems, String sessionId, List<String> missedWordIds, List<Map<String, dynamic>> allWords) async {
    await init();
    await _prefs!.setBool('cumulative_review_completed_$categoryId', true);
    await _prefs!.setDouble('cumulative_review_score_$categoryId', masteryScore);
    await _prefs!.setInt('cumulative_review_mastered_$categoryId', masteredCount);
    await _prefs!.setInt('cumulative_review_total_$categoryId', totalItems);
    await _prefs!.setString('cumulative_review_session_id_$categoryId', sessionId);
    await _prefs!.setStringList('cumulative_review_missed_$categoryId', missedWordIds);
    await _prefs!.setString('cumulative_review_all_words_$categoryId', json.encode(allWords));
  }

  static Future<bool> getCumulativeReviewCompleted(String categoryId) async {
    await init();
    return _prefs!.getBool('cumulative_review_completed_$categoryId') ?? false;
  }

  static Future<double?> getCumulativeReviewScore(String categoryId) async {
    await init();
    return _prefs!.getDouble('cumulative_review_score_$categoryId');
  }

  static Future<int?> getCumulativeReviewMasteredCount(String categoryId) async {
    await init();
    return _prefs!.getInt('cumulative_review_mastered_$categoryId');
  }

  static Future<int?> getCumulativeReviewTotalItems(String categoryId) async {
    await init();
    return _prefs!.getInt('cumulative_review_total_$categoryId');
  }

  static Future<String?> getCumulativeReviewSessionId(String categoryId) async {
    await init();
    return _prefs!.getString('cumulative_review_session_id_$categoryId');
  }

  static Future<List<String>> getCumulativeReviewMissedWordIds(String categoryId) async {
    await init();
    return _prefs!.getStringList('cumulative_review_missed_$categoryId') ?? [];
  }

  static Future<List<Map<String, dynamic>>> getCumulativeReviewAllWords(String categoryId) async {
    await init();
    final raw = _prefs!.getString('cumulative_review_all_words_$categoryId');
    if (raw == null) return [];
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearCumulativeReviewCompletion(String categoryId) async {
    await init();
    await _prefs!.remove('cumulative_review_completed_$categoryId');
    await _prefs!.remove('cumulative_review_score_$categoryId');
    await _prefs!.remove('cumulative_review_mastered_$categoryId');
    await _prefs!.remove('cumulative_review_total_$categoryId');
    await _prefs!.remove('cumulative_review_session_id_$categoryId');
    await _prefs!.remove('cumulative_review_missed_$categoryId');
    await _prefs!.remove('cumulative_review_all_words_$categoryId');
  }

  // --- Module Scoring Persistence ---
  static Future<void> saveModuleScore(String lessonId, int moduleNumber, int correctCount, int totalCount) async {
    await init();
    final data = {
      'correct': correctCount,
      'total': totalCount,
    };
    await _prefs!.setString('lesson_${lessonId}_module_${moduleNumber}_score', json.encode(data));
  }

  static Future<Map<String, int>?> getModuleScore(String lessonId, int moduleNumber) async {
    await init();
    final raw = _prefs!.getString('lesson_${lessonId}_module_${moduleNumber}_score');
    if (raw == null) return null;
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return {
      'correct': decoded['correct'] as int? ?? 0,
      'total': decoded['total'] as int? ?? 0,
    };
  }

  static Future<void> saveLessonScore(String lessonId, double score) async {
    await init();
    final existing = _prefs!.getDouble('lesson_${lessonId}_score');
    if (existing == null || score >= existing || score == 0.0) {
      await _prefs!.setDouble('lesson_${lessonId}_score', score);
    }
  }

  static Future<double?> getLessonScore(String lessonId) async {
    await init();
    return _prefs!.getDouble('lesson_${lessonId}_score');
  }

  static Future<void> saveLessonScoreDetails(String lessonId, Map<String, dynamic> details) async {
    await init();
    await _prefs!.setString('lesson_${lessonId}_score_details', json.encode(details));
  }

  static Future<Map<String, dynamic>?> getLessonScoreDetails(String lessonId) async {
    await init();
    final raw = _prefs!.getString('lesson_${lessonId}_score_details');
    if (raw == null) return null;
    return json.decode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearLessonScoreDetails(String lessonId) async {
    await init();
    await _prefs!.remove('lesson_${lessonId}_score_details');
  }

  // --- Retry Queue Persistence ---
  static Future<void> saveModule4RetryQueue(String sessionId, List<String> wordIds) async {
    await init();
    await _prefs!.setStringList('module4_retry_queue_$sessionId', wordIds);
  }

  static Future<List<String>> getModule4RetryQueue(String sessionId) async {
    await init();
    return _prefs!.getStringList('module4_retry_queue_$sessionId') ?? [];
  }

  static Future<void> saveFailedWords(String sessionId, List<String> wordIds) async {
    await init();
    await _prefs!.setStringList('failed_words_$sessionId', wordIds);
  }

  static Future<List<String>> getFailedWords(String sessionId) async {
    await init();
    return _prefs!.getStringList('failed_words_$sessionId') ?? [];
  }

  // --- App Preferences ---

  static Future<void> saveThemeMode(String mode) async {
    await init();
    await _prefs!.setString('pref_theme_mode', mode);
  }

  static Future<String> getThemeMode() async {
    await init();
    return _prefs!.getString('pref_theme_mode') ?? 'light';
  }

  static Future<void> saveNotificationsEnabled(bool enabled) async {
    await init();
    await _prefs!.setBool('pref_notifications_enabled', enabled);
  }

  static Future<bool> getNotificationsEnabled() async {
    await init();
    return _prefs!.getBool('pref_notifications_enabled') ?? true;
  }

  /// Clears ALL lesson progress and score data from local storage.
  /// App-level preferences (theme, notifications) are preserved.
  /// Call this on logout so that a new user starts with a completely clean slate.
  static Future<void> clearAllLessonData() async {
    await init();
    const keysToPreserve = {'pref_theme_mode', 'pref_notifications_enabled'};
    final allKeys = Set<String>.from(_prefs!.getKeys());
    for (final key in allKeys) {
      if (!keysToPreserve.contains(key)) {
        await _prefs!.remove(key);
      }
    }
  }
}
