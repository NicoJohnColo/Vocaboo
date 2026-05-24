import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum ActivityFormat {
  multipleChoice,
  matching,
  fillInTheBlank,
  imageMatching,
  listeningTyping,
  translationMatching,
  flashcardRecall,
}

enum ReinforcementStatus {
  pending,
  reinforcedComplete,
  reinforcedIncomplete,
}

class PracticeItemModel {
  final String wordId;
  final String englishWord;
  final String cebuanoMeaning;
  final String exampleSentenceEnglish;
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
  final String? sentenceCompletionSentence;
  final String? sentenceCompletionAnswer;
  final String? sentenceCompletionOption1;
  final String? sentenceCompletionOption2;
  final String? sentenceCompletionOption3;
  final String? imageAssetPath;

  PracticeItemModel({
    required this.wordId,
    required this.englishWord,
    required this.cebuanoMeaning,
    required this.exampleSentenceEnglish,
    this.exampleSentenceCebuano,
    required this.activityFormat,
    required this.distractors,
    this.mcDistractor1,
    this.mcDistractor2,
    this.mcDistractor3,
    this.fitbSentence,
    this.fitbAnswer,
    this.matchingSet,
    this.sentenceArrangementTokens,
    this.sentenceCompletionSentence,
    this.sentenceCompletionAnswer,
    this.sentenceCompletionOption1,
    this.sentenceCompletionOption2,
    this.sentenceCompletionOption3,
    this.imageAssetPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'englishWord': englishWord,
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
      'sentenceCompletionSentence': sentenceCompletionSentence,
      'sentenceCompletionAnswer': sentenceCompletionAnswer,
      'sentenceCompletionOption1': sentenceCompletionOption1,
      'sentenceCompletionOption2': sentenceCompletionOption2,
      'sentenceCompletionOption3': sentenceCompletionOption3,
      'imageAssetPath': imageAssetPath,
    };
  }

  factory PracticeItemModel.fromJson(Map<String, dynamic> json) {
    return PracticeItemModel(
      wordId: json['wordId'],
      englishWord: json['englishWord'],
      cebuanoMeaning: json['cebuanoMeaning'],
      exampleSentenceEnglish: json['exampleSentenceEnglish'],
      exampleSentenceCebuano: json['exampleSentenceCebuano'],
      activityFormat: ActivityFormat.values[json['activityFormat']],
      distractors: List<String>.from(json['distractors']),
      mcDistractor1: json['mcDistractor1'],
      mcDistractor2: json['mcDistractor2'],
      mcDistractor3: json['mcDistractor3'],
      fitbSentence: json['fitbSentence'],
      fitbAnswer: json['fitbAnswer'],
      matchingSet: (json['matchingSet'] as List<dynamic>?)
          ?.whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      sentenceArrangementTokens: (json['sentenceArrangementTokens'] as List<dynamic>?)?.map((item) => item.toString()).toList(),
      sentenceCompletionSentence: json['sentenceCompletionSentence'],
      sentenceCompletionAnswer: json['sentenceCompletionAnswer'],
      sentenceCompletionOption1: json['sentenceCompletionOption1'],
      sentenceCompletionOption2: json['sentenceCompletionOption2'],
      sentenceCompletionOption3: json['sentenceCompletionOption3'],
      imageAssetPath: json['imageAssetPath'],
    );
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
  static Future<void> savePracticeSessionState(String sessionId, List<PracticeItemModel> queue, int currentIndex) async {
    await init();
    final data = {
      'queue': queue.map((item) => item.toJson()).toList(),
      'currentIndex': currentIndex,
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
    await _prefs!.setDouble('lesson_${lessonId}_score', score);
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
}
