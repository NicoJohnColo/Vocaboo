// cumulative_mixed_review_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
 
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import '../services/local_storage_service.dart';
import '../services/scoring_service.dart';
import '../widgets/mascot_visual.dart';
import 'mastery_result_screen.dart';

class CumulativeMixedReviewScreen extends StatefulWidget {
  final String sessionId;
  final List<Map<String, dynamic>> allWords;
  final String categoryId;
  final bool isSandbox;
  final List<String>? lessonIds;
  final List<String>? priorityWordIds;
  const CumulativeMixedReviewScreen({super.key, required this.sessionId, this.allWords = const [], required this.categoryId, this.isSandbox = false, this.lessonIds, this.priorityWordIds});

  @override
  State<CumulativeMixedReviewScreen> createState() => _CumulativeMixedReviewScreenState();
}

class _CumulativeMixedReviewScreenState extends State<CumulativeMixedReviewScreen> {
  List<dynamic> _reviewItems = [];
  bool _loading = true;
  final Map<String, bool> _results = {};
  final Map<String, int> _attemptCounts = {};
  Map<String, dynamic>? _pendingSavedState;
  bool _showResumePrompt = false;
  bool _showFailurePrompt = false;
  final List<Map<String, dynamic>> _retryQueue = [];
  int _firstPassCorrectCount = 0;
  double? _failedFinalScore;
  static const List<String> _mainFormats = [
    'FLASHCARD_RECALL',
    'MULTIPLE_CHOICE',
    'LISTENING_TYPING',
    'SENTENCE_RECONSTRUCTION',
    'FILL_IN_THE_BLANK',
    'IMAGE_MATCHING',
    'TRANSLATION_MATCHING',
    'MATCHING',
  ];

  // Working queue with activityFormat assigned
  final List<Map<String, dynamic>> _queue = [];
  int _currentIndex = 0;
  double? _weightedScore;
  String? _selectedMatchingWord;
  List<String> _matchingOptions = [];
  bool _flashcardFlipped = false;
  final TextEditingController _typingController = TextEditingController();
  final List<String> _scrambledWords = [];
  final List<String> _assembledWords = [];

  Map<String, dynamic>? get _currentItem => _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  MascotType _mascotForFormat(String fmt) {
    switch (fmt) {
      case 'FILL_IN_THE_BLANK':
        return MascotType.sippy;
      case 'MATCHING':
      case 'TRANSLATION_MATCHING':
        return MascotType.toti;
      default:
        return MascotType.bibo;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReviewItems();
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  void _prepareCurrentActivityState() {
    _selectedMatchingWord = null;
    _matchingOptions = [];
    _flashcardFlipped = false;
    _typingController.clear();
    _scrambledWords.clear();
    _assembledWords.clear();

    final item = _currentItem;
    if (item == null) return;

    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();
    if (fmt == 'MATCHING' || fmt == 'TRANSLATION_MATCHING') {
      _matchingOptions = _buildMatchingOptions(item);
    } else if (fmt == 'SENTENCE_RECONSTRUCTION') {
      _scrambledWords.addAll(_sentenceTokens(item));
      _scrambledWords.shuffle(Random('${item['wordId'] ?? ''}_scramble'.hashCode));
    }
  }

  List<String> _sentenceTokens(Map<String, dynamic> item) {
    final explicit = (item['sentenceArrangementTokens'] as List<dynamic>?)?.map((token) => token.toString()).where((token) => token.trim().isNotEmpty).toList();
    if (explicit != null && explicit.length >= 2) return explicit;

    final sentence = (item['sentenceCompletionSentence'] ?? item['example'] ?? '').toString().trim();
    if (sentence.isEmpty) {
      final word = (item['word'] ?? '').toString().trim();
      return word.isEmpty ? const [] : [word];
    }

    return sentence
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~(?)]'), '')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();
  }

  List<String> _buildQueueFormats(int count) {
    final rnd = Random();
    final planned = <String>[];
    for (var index = 0; index < count; index++) {
      var choice = _mainFormats[rnd.nextInt(_mainFormats.length)];
      if (planned.length >= 2 && planned[planned.length - 1] == choice && planned[planned.length - 2] == choice) {
        final alternatives = _mainFormats.where((fmt) => fmt != choice).toList();
        choice = alternatives[rnd.nextInt(alternatives.length)];
      }
      planned.add(choice);
    }
    return planned;
  }

  List<String> _buildMatchingOptions(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString().trim();
    if (correct.isEmpty) return const [];

    final matchingSet = (item['matchingSet'] as List<dynamic>?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const [];

    final candidateWords = <String>{};
    if (matchingSet.isNotEmpty) {
      for (final entry in matchingSet) {
        final word = (entry['englishWord'] ?? '').toString().trim();
        if (word.isNotEmpty && word != correct) {
          candidateWords.add(word);
        }
      }
    } else {
      for (final entry in _reviewItems) {
        final word = (entry['word'] ?? '').toString().trim();
        if (word.isNotEmpty && word != correct) {
          candidateWords.add(word);
        }
      }
    }

    final distractors = candidateWords.toList();
    distractors.shuffle(Random('${item['wordId'] ?? correct}'.hashCode));

    final options = <String>[correct, ...distractors.take(3)];
    options.shuffle(Random('${item['wordId'] ?? correct}_bank'.hashCode));
    return options;
  }

  Future<List<String>> _resolveLessonIds(LessonProvider lessons) async {
    if (widget.lessonIds != null && widget.lessonIds!.isNotEmpty) {
      return List<String>.from(widget.lessonIds!);
    }

    if (widget.categoryId.isNotEmpty) {
      await lessons.loadLessons(widget.categoryId);
      final selected = lessons.lessons.take(2).map((lesson) => lesson.lessonId).where((id) => id.isNotEmpty).toList();
      if (selected.isNotEmpty) {
        return selected;
      }
    }

    return const [];
  }

  Future<void> _fetchReviewItems() async {
    final savedState = await LocalStorageService.getCumulativeReviewState(widget.sessionId);
    if (savedState != null) {
      // Prompt user to resume or start fresh instead of auto-restoring
      setState(() {
        _pendingSavedState = Map<String, dynamic>.from(savedState);
        _showResumePrompt = true;
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    final lessons = Provider.of<LessonProvider>(context, listen: false);
    final lessonIds = await _resolveLessonIds(lessons);
    List<Map<String, dynamic>> items;

    if (widget.allWords.isNotEmpty) {
      items = widget.allWords;
    } else if (lessonIds.isNotEmpty) {
      final lessonBatches = await Future.wait(lessonIds.map((lessonId) => lessons.loadVocabulary(lessonId)));
      items = lessonBatches.expand((batch) => batch).map((word) => word.toJson()).toList();
    } else if (widget.categoryId.isNotEmpty) {
      items = await lessons.loadCategoryActivity(widget.categoryId);
    } else {
      items = const [];
    }

    final list = items.map((e) {
      final item = Map<String, dynamic>.from(e);
      return <String, dynamic>{
        'wordId': item['wordId'] ?? item['id'] ?? item['vocabularyId'] ?? '',
        'word': item['word'] ?? item['englishWord'] ?? '',
        'definition': item['definition'] ?? item['cebuanoMeaning'] ?? item['cebuanoDefinition'] ?? '',
        'cebuanoMeaning': item['cebuanoMeaning'] ?? item['definition'] ?? item['cebuanoDefinition'] ?? '',
        'example': item['example'] ?? item['exampleSentenceEnglish'] ?? item['englishSentence'] ?? '',
        'exampleCebuano': item['cebuanoTranslation'] ?? item['exampleSentenceCebuano'] ?? item['cebuanoExample'] ?? '',
        'mcDistractor1': item['mcDistractor1'],
        'mcDistractor2': item['mcDistractor2'],
        'mcDistractor3': item['mcDistractor3'],
        'fitbSentence': item['fitbSentence'],
        'fitbAnswer': item['fitbAnswer'],
        'matchingSet': item['matchingSet'],
      };
    }).toList();

    // Ensure every item has a wordId and englishWord
    list.removeWhere((it) => ((it['wordId'] ?? it['vocabularyId'] ?? '')).toString().isEmpty);

    // Build queue ensuring each word is tackled at least twice with different formats.
    final rnd = Random();
    _queue.clear();

    // First pass: vary across all formats
    final firstPassFormats = _buildQueueFormats(list.length);
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      var fmt = firstPassFormats[i];
      // Ensure image matching actually uses an image if available
      final hasImage = (item['imageAssetPath'] ?? '').toString().isNotEmpty;
      if (fmt == 'MULTIPLE_CHOICE' && hasImage && rnd.nextBool()) {
        fmt = 'IMAGE_MATCHING';
      }
      if (fmt == 'SENTENCE_RECONSTRUCTION' && _sentenceTokens(item).length < 2) {
        fmt = 'FILL_IN_THE_BLANK';
      }
      _queue.add({...item, 'activityFormat': fmt});
    }

    // Second pass: focus on different formats to ensure thorough tackling
    final secondPassFormats = _buildQueueFormats(list.length);
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      var fmt = secondPassFormats[i];
      
      // Ensure different format from first pass if possible
      final firstFmt = _queue[i]['activityFormat'];
      if (fmt == firstFmt) {
        final alternatives = _mainFormats.where((f) => f != firstFmt).toList();
        fmt = alternatives[rnd.nextInt(alternatives.length)];
      }

      final hasImage = (item['imageAssetPath'] ?? '').toString().isNotEmpty;
      if (hasImage && rnd.nextBool()) {
        fmt = 'IMAGE_MATCHING';
      }

      if (fmt == 'SENTENCE_RECONSTRUCTION' && _sentenceTokens(item).length < 2) {
        fmt = 'FILL_IN_THE_BLANK';
      }
      _queue.add({...item, 'activityFormat': fmt});
    }

    // Shuffle the entire combined queue
    _queue.shuffle(rnd);

    setState(() {
      _reviewItems = list;
      _loading = false;
      _currentIndex = 0;
      // Do not compute final weighted score yet; will compute on finish using prior-module data.
      _weightedScore = null;
      _firstPassCorrectCount = 0;
      _retryQueue.clear();
      _results.clear();
      _prepareCurrentActivityState();
    });

    // Save initial state
    LocalStorageService.saveCumulativeReviewState(widget.sessionId, {
      'reviewItems': _reviewItems,
      'queue': _queue,
      'retryQueue': _retryQueue,
      'currentIndex': _currentIndex,
      'results': _results,
      'attemptCounts': _attemptCounts,
      'firstPassCorrectCount': _firstPassCorrectCount,
      'weightedScore': _weightedScore,
    });
  }

  void _resumeSavedState() {
    if (_pendingSavedState == null) return;
    setState(() {
      final saved = _pendingSavedState!;
      _reviewItems = List<dynamic>.from(saved['reviewItems'] as List<dynamic>? ?? const []);
      _queue
        ..clear()
        ..addAll((saved['queue'] as List<dynamic>? ?? const []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)));
      _retryQueue
        ..clear()
        ..addAll((saved['retryQueue'] as List<dynamic>? ?? const []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)));
      _currentIndex = saved['currentIndex'] as int? ?? 0;
      _results
        ..clear()
        ..addAll((saved['results'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as bool)) ?? {});
      _attemptCounts
        ..clear()
        ..addAll((saved['attemptCounts'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {});
      _firstPassCorrectCount = saved['firstPassCorrectCount'] as int? ?? _results.values.where((value) => value).length;
      _weightedScore = (saved['weightedScore'] as num?)?.toDouble();
      _pendingSavedState = null;
      _showResumePrompt = false;
      _prepareCurrentActivityState();
    });
  }

  Future<void> _startFresh() async {
    // Clear saved state and rebuild queue from source
    await LocalStorageService.clearCumulativeReviewState(widget.sessionId);
    setState(() {
      _pendingSavedState = null;
      _showResumePrompt = false;
      _showFailurePrompt = false;
      _failedFinalScore = null;
      _loading = true;
    });
    // Re-run fetch to build a fresh queue
    await _fetchReviewItems();
  }

  void _playAudio(String text) {
    TTSService.speak(text);
  }

  void _recordAnswer(String wordId, bool correct) {
    if (!_results.containsKey(wordId)) {
      _results[wordId] = correct;
      if (correct) {
        _firstPassCorrectCount++;
      }
    }
  }

  void _nextItem() {
    setState(() {
      _currentIndex++;
      _prepareCurrentActivityState();
    });
    if (_currentIndex >= _queue.length) {
      _finishReview();
    }
  }

  Future<void> _finishReview() async {
    final lessons = Provider.of<LessonProvider>(context, listen: false);
    final lessonIds = await _resolveLessonIds(lessons);
    final lessonScores = <double>[];

    for (final lessonId in lessonIds) {
      final storedLessonScore = await LocalStorageService.getLessonScore(lessonId);
      if (storedLessonScore != null) {
        lessonScores.add(storedLessonScore);
        continue;
      }

      final module2 = await LocalStorageService.getModuleScore(lessonId, 2);
      final module3 = await LocalStorageService.getModuleScore(lessonId, 3);
      final scores = <double>[];
      final module2Total = module2?['total'] ?? 0;
      final module2Correct = module2?['correct'] ?? 0;
      final module3Total = module3?['total'] ?? 0;
      final module3Correct = module3?['correct'] ?? 0;
      if (module2Total > 0) {
        scores.add(ScoringService.computeLessonScore(module2Correct, module2Total));
      }
      if (module3Total > 0) {
        scores.add(ScoringService.computeLessonScore(module3Correct, module3Total));
      }
      lessonScores.add(scores.isEmpty ? 0.0 : ScoringService.computeCombinedLessonScore(scores.first, scores.length > 1 ? scores[1] : scores.first));
    }

    final lessonScore = lessonScores.isEmpty ? 0.0 : lessonScores.reduce((a, b) => a + b) / lessonScores.length;
    final uniqueWordCount = _reviewItems.map((it) => (it['wordId'] ?? '').toString()).toSet().length;
    final cumulativeReviewScore = uniqueWordCount == 0 ? 0.0 : (_firstPassCorrectCount / uniqueWordCount) * 100.0;
    _weightedScore = ScoringService.computeFinalScore(lessonScore, cumulativeReviewScore);
    bool passed = ScoringService.isPassing(_weightedScore ?? 0.0);

    // Call backend mastery endpoint for server-side validation
    final masteryResult = passed && !widget.isSandbox
        ? await lessons.submitMastery(
            categoryId: widget.categoryId,
            lessonIds: lessonIds,
            lessonScore: lessonScore,
            cumulativeReviewScore: cumulativeReviewScore,
            finalScore: _weightedScore ?? 0.0,
            passed: passed,
            totalItems: _reviewItems.length,
            masteredCount: _firstPassCorrectCount,
            missedWordIds: _reviewItems
                .where((it) => _results[(it['wordId'] ?? '').toString()] == false)
                .map((it) => (it['wordId'] ?? '').toString())
                .where((id) => id.isNotEmpty)
                .toList(),
          )
        : null;

    // Use server-validated score if available
    if (masteryResult != null) {
      _weightedScore = (masteryResult['finalScore'] as num?)?.toDouble() ?? _weightedScore;
      final serverPassed = masteryResult['passed'] as bool? ?? passed;
      if (serverPassed != passed) {
        passed = serverPassed;
      }
    }

    final result = passed
      ? widget.isSandbox
        ? await lessons.completeSandbox(widget.sessionId)
        : await lessons.completeCategoryReview(
          sessionId: widget.sessionId,
          categoryId: widget.categoryId,
          score: _weightedScore ?? cumulativeReviewScore,
          )
      : null;

    int total = _reviewItems.length;
    int mastered = _firstPassCorrectCount;
    List<String> missed = _reviewItems
        .where((it) => _results[(it['wordId'] ?? '').toString()] == false)
        .map((it) => (it['wordId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();

    if (result != null) {
      total = result['totalItems'] as int? ?? total;
      mastered = result['masteredCount'] as int? ?? (result['correctCount'] as int? ?? mastered);
      _weightedScore = (result['score'] as num?)?.toDouble() ?? _weightedScore;
      final backendMissed = result['missedWordIds'] ?? result['wordsToReview'] ?? result['missedWords'];
      if (backendMissed is List) {
        missed = backendMissed.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
    }

    // Save cumulative review completion data for later retrieval (pass and fail)
    await LocalStorageService.saveCumulativeReviewCompleted(
      widget.categoryId,
      _weightedScore ?? cumulativeReviewScore,
      mastered,
      total,
      widget.sessionId,
      missed,
      widget.allWords,
    );

    if (passed) {
      await LocalStorageService.clearCumulativeReviewState(widget.sessionId);
      await LocalStorageService.clearReviewCompletionState(widget.sessionId);
    } else {
      await LocalStorageService.saveReviewCompletionState(widget.sessionId, {
        'lessonScore': lessonScore,
        'cumulativeReviewScore': cumulativeReviewScore,
        'finalScore': _weightedScore,
        'passed': false,
        'retryQueue': _retryQueue,
      });
    }

    if (!passed) {
      if (!mounted) return;
      setState(() {
        _showFailurePrompt = true;
        _failedFinalScore = _weightedScore;
      });
      return;
    }

    // Automatically speak score if it is 100%
    final finalPercent = (_weightedScore ?? cumulativeReviewScore).round();
    if (finalPercent == 100) {
      TTSService.speak('Excellent! You got a perfect score of 100 percent.');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => MasteryResultScreen(
        sessionId: widget.sessionId,
        categoryId: widget.categoryId,
        isSandbox: widget.isSandbox,
        totalItems: total,
        masteredCount: mastered,
        missedWordIds: missed,
        allWords: widget.allWords,
        masteryScore: _weightedScore,
      ),
    ));
  }

  Widget _buildFailurePrompt(ThemeData theme) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Review not passed'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.replay_circle_filled_rounded, size: 72, color: Color(0xFFF59E0B)),
                    const SizedBox(height: 16),
                    const Text(
                      'You are close, but not yet at mastery.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Final score: ${(_failedFinalScore ?? _weightedScore ?? 0.0).toStringAsFixed(1)}%. Pass at 70.0%.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Retrying will rebuild the review queue and give you another full pass through the lesson content.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        final score = _failedFinalScore ?? _weightedScore;
                        final missedIds = _reviewItems
                            .where((it) => _results[(it['wordId'] ?? '').toString()] == false)
                            .map((it) => (it['wordId'] ?? '').toString())
                            .where((id) => id.isNotEmpty)
                            .toList();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => MasteryResultScreen(
                            sessionId: widget.sessionId,
                            categoryId: widget.categoryId,
                            isSandbox: widget.isSandbox,
                            totalItems: _reviewItems.length,
                            masteredCount: _firstPassCorrectCount,
                            missedWordIds: missedIds,
                            allWords: widget.allWords,
                            masteryScore: score,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('View Score'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06A6FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('Exit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await LocalStorageService.clearCumulativeReviewCompletion(widget.categoryId);
                              await _startFresh();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06A6FF),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry Review'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentActivity() {
    if (_currentIndex >= _queue.length) return const SizedBox.shrink();
    final item = _queue[_currentIndex];
    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();
    switch (fmt) {
      case 'FLASHCARD_RECALL':
        return _buildFlashcardRecall(item);
      case 'LISTENING_TYPING':
        return _buildListeningTyping(item);
      case 'SENTENCE_RECONSTRUCTION':
        return _buildSentenceReconstruction(item);
      case 'IMAGE_MATCHING':
        return _buildImageMatching(item);
      case 'TRANSLATION_MATCHING':
      case 'MATCHING':
        return _buildMatching(item);
      case 'FILL_IN_THE_BLANK':
        return _buildFillInBlank(item);
      default:
        return _buildMultipleChoice(item);
    }
  }

  Widget _buildFlashcardRecall(Map<String, dynamic> item) {
    final word = (item['word'] ?? '').toString();
    final definition = (item['definition'] ?? '').toString();
    final cebuanoMeaning = (item['cebuanoMeaning'] ?? '').toString();
    final example = (item['example'] ?? '').toString();
    final wordId = (item['wordId'] ?? '').toString();
    final currentAttempt = _attemptCounts[wordId] ?? 0;
    final maxAttempts = 3;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Flashcard recall', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                Text(
                  'Attempt $currentAttempt/$maxAttempts',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: currentAttempt >= maxAttempts ? const Color(0xFFDC2626) : const Color(0xFF0F9488)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _flashcardFlipped ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _flashcardFlipped ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  if (_flashcardFlipped) ...[
                    if (cebuanoMeaning.isNotEmpty) ...[
                      Text('Bisaya: $cebuanoMeaning', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0369A1), height: 1.45)),
                      const SizedBox(height: 8),
                    ],
                    Text(definition, style: const TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.45)),
                    const SizedBox(height: 8),
                    Text(example, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                  ] else ...[
                    const Text('Think first, then flip to confirm.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _flashcardFlipped = !_flashcardFlipped;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF06A6FF),
                side: const BorderSide(color: Color(0xFF06A6FF), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_flashcardFlipped ? 'HIDE ANSWER' : 'REVEAL ANSWER', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: currentAttempt >= maxAttempts
                  ? null
                  : () {
                      setState(() {
                        _attemptCounts[wordId] = ((_attemptCounts[wordId] ?? 0) + 1);
                      });
                      _recordAnswer(wordId, true);
                      _nextItem();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                currentAttempt >= maxAttempts ? 'No more attempts' : 'GOT IT',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningTyping(Map<String, dynamic> item) {
    final answer = (item['fitbAnswer'] ?? item['word'] ?? '').toString().trim();
    final prompt = (item['fitbSentence'] ?? item['example'] ?? '').toString().trim();
    final cebuanoMeaning = (item['cebuanoMeaning'] ?? '').toString();
    final wordId = (item['wordId'] ?? '').toString();
    final currentAttempt = _attemptCounts[wordId] ?? 0;
    final maxAttempts = 3;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Listening and typing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                Text(
                  'Attempt $currentAttempt/$maxAttempts',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: currentAttempt >= maxAttempts ? const Color(0xFFDC2626) : const Color(0xFF0F9488)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              prompt.isEmpty ? 'Type what you hear:' : prompt.replaceAll(RegExp(RegExp.escape(answer), caseSensitive: false), '_____'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.45),
            ),
            if (cebuanoMeaning.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bisaya Translation:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cebuanoMeaning,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _typingController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Type what you heard',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF06A6FF), width: 2)),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _playAudio(answer),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Hear it again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF06A6FF),
                side: const BorderSide(color: Color(0xFF06A6FF), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _typingController.text.trim().isEmpty || currentAttempt >= maxAttempts
                  ? null
                  : () {
                      final learner = _typingController.text.trim();
                      final isCorrect = learner.toLowerCase() == answer.toLowerCase();
                      setState(() {
                        _attemptCounts[wordId] = ((_attemptCounts[wordId] ?? 0) + 1);
                      });
                      if (isCorrect) {
                        _recordAnswer(wordId, true);
                        _nextItem();
                      } else if (_attemptCounts[wordId]! >= maxAttempts) {
                        _recordAnswer(wordId, false);
                        _nextItem();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Incorrect. You have ${maxAttempts - _attemptCounts[wordId]!} attempt(s) left.')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06A6FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                currentAttempt >= maxAttempts ? 'No more attempts' : 'CHECK',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentenceReconstruction(Map<String, dynamic> item) {
    final answerTokens = _sentenceTokens(item);
    if (_scrambledWords.isEmpty) {
      _scrambledWords.addAll(answerTokens);
      _scrambledWords.shuffle(Random('${item['wordId'] ?? ''}_recon'.hashCode));
    }
    final sentencePreview = _assembledWords.join(' ').trim();
    final bisayaPrompt = (item['exampleCebuano'] ?? item['definition'] ?? '').toString();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sentence reconstruction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            // FIXED: Show Bisaya sentence first (meaning/context), then ask to arrange English words
            if (bisayaPrompt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(bisayaPrompt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.45)),
              ),
            const Text('Arrange these English words:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _assembledWords.isEmpty
                    ? [const Text('Drop words here', style: TextStyle(color: Color(0xFF94A3B8)))]
                    : _assembledWords.map((word) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _assembledWords.remove(word);
                              _scrambledWords.add(word);
                            });
                          },
                          child: _wordChip(word, selected: true),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            DragTarget<String>(
              onAcceptWithDetails: (details) {
                setState(() {
                  _scrambledWords.remove(details.data);
                  _assembledWords.add(details.data);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _scrambledWords.map((word) {
                    return Draggable<String>(
                      data: word,
                      feedback: Material(color: Colors.transparent, child: _wordChip(word, selected: true)),
                      childWhenDragging: Opacity(opacity: 0.35, child: _wordChip(word)),
                      child: _wordChip(word),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 14),
            Text('Sentence preview: ${sentencePreview.isEmpty ? '...' : sentencePreview}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _assembledWords.length < answerTokens.length
                  ? null
                  : () {
                      final expected = answerTokens.join(' ').toLowerCase().trim();
                      final learner = _assembledWords.join(' ').toLowerCase().trim();
                      final isCorrect = learner == expected;
                      _recordAnswer((item['wordId'] ?? '').toString(), isCorrect);
                      _nextItem();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06A6FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('CHECK SENTENCE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMatching(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final imagePath = (item['imageAssetPath'] ?? '').toString();
    final provided = [item['mcDistractor1'], item['mcDistractor2'], item['mcDistractor3']].whereType<String>().where((value) => value.isNotEmpty).toList();
    final options = <String>[correct];
    if (provided.isNotEmpty) {
      options.addAll(provided.take(3));
    } else {
      final other = _reviewItems.map((e) => e['word']?.toString() ?? '').where((word) => word.isNotEmpty && word != correct).toList()..shuffle();
      options.addAll(other.take(3));
    }
    options.shuffle(Random('${item['wordId'] ?? correct}_image'.hashCode));

    if (imagePath.isEmpty) {
      return _buildMultipleChoice(item);
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Image-to-word matching', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            Center(
              child: Image.asset(
                imagePath,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 180,
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: const Text('Image not available', style: TextStyle(color: Color(0xFF64748B))),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  onPressed: () {
                    final isCorrect = opt == correct;
                    _recordAnswer((item['wordId'] ?? '').toString(), isCorrect);
                    _nextItem();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(opt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _wordChip(String word, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF06A6FF).withValues(alpha: 0.10) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? const Color(0xFF06A6FF) : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        word,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFF0369A1) : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildMultipleChoice(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    // FIXED: Use Cebuano meaning as prompt instead of English
    final definition = (item['cebuanoMeaning'] ?? item['definition'] ?? '').toString();
    final provided = [
      item['mcDistractor1'],
      item['mcDistractor2'],
      item['mcDistractor3'],
    ].whereType<String>().where((value) => value.isNotEmpty).toList();

    final options = <String>[correct];
    if (provided.isNotEmpty) {
      options.addAll(provided.take(3));
    } else {
      final other = _reviewItems.map((e) => e['word']?.toString() ?? '').where((w) => w.isNotEmpty && w != correct).toList();
      other.shuffle();
      for (var i = 0; i < min(3, other.length); i++) {
        options.add(other[i]);
      }
    }
    options.shuffle();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose the correct English word',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.7),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        definition,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (definition.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'What is the English word for this meaning?',
                  style: TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.45),
                ),
              ),
            const SizedBox(height: 18),
            ...options.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final isCorrect = opt == correct;
                      _recordAnswer((item['wordId'] ?? '').toString(), isCorrect);
                      _nextItem();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(const Color(0xFFEFF6FF)),
                    ),
                    child: Text(
                      opt,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                )),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _playAudio(correct),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Hear word'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF06A6FF),
                side: const BorderSide(color: Color(0xFF06A6FF), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillInBlank(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final sentence = (item['fitbSentence'] ?? item['example'] ?? '').toString();
    final answer = (item['fitbAnswer'] ?? correct).toString();
    final definition = (item['definition'] ?? item['cebuanoMeaning'] ?? '').toString();
    final wordId = (item['wordId'] ?? '').toString();
    final currentAttempt = _attemptCounts[wordId] ?? 0;
    final maxAttempts = 3;
    final controller = TextEditingController();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fill in the missing word',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.7),
                ),
                Text(
                  'Attempt $currentAttempt/$maxAttempts',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: currentAttempt >= maxAttempts ? const Color(0xFFDC2626) : const Color(0xFF0F9488)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              sentence.isEmpty ? 'Type the word:' : sentence.replaceAll(RegExp(RegExp.escape(answer), caseSensitive: false), '_____'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.45),
            ),
            if (definition.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bisaya Translation:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      definition,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              enabled: currentAttempt < maxAttempts,
              decoration: InputDecoration(
                labelText: 'Answer',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF06A6FF), width: 2)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: currentAttempt >= maxAttempts
                  ? null
                  : () {
                      final wordId = (item['wordId'] ?? '').toString();
                      final userAnswer = controller.text.trim();
                      final isCorrect = userAnswer.toLowerCase() == (item['fitbAnswer'] ?? correct).toString().toLowerCase();
                      
                      setState(() {
                        _attemptCounts[wordId] = ((_attemptCounts[wordId] ?? 0) + 1);
                      });
                      
                      if (isCorrect) {
                        _recordAnswer(wordId, true);
                        _nextItem();
                      } else if (_attemptCounts[wordId]! >= maxAttempts) {
                        // Max attempts reached - mark as incorrect and move on
                        _recordAnswer(wordId, false);
                        _nextItem();
                      } else {
                        // Show error but allow retry
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Incorrect. You have ${maxAttempts - _attemptCounts[wordId]!} attempt(s) left.')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: currentAttempt >= maxAttempts ? const Color(0xFFCBD5E1) : const Color(0xFF06A6FF),
                disabledBackgroundColor: const Color(0xFFCBD5E1),
              ),
              child: Text(
                currentAttempt >= maxAttempts ? 'No more attempts' : 'Submit',
                style: TextStyle(
                  color: currentAttempt >= maxAttempts ? const Color(0xFF64748B) : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _playAudio(definition),
              icon: const Icon(Icons.volume_up),
              label: const Text('Hear word'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF06A6FF),
                side: const BorderSide(color: Color(0xFF06A6FF), width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatching(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final prompt = (item['definition'] ?? '').toString();
    final choices = _matchingOptions.isNotEmpty ? _matchingOptions : _buildMatchingOptions(item);
    final selectedWord = _selectedMatchingWord;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Drag or tap the matching word',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              prompt.isEmpty ? 'Choose the English word that matches the Cebuano meaning' : prompt,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.45),
            ),
            const SizedBox(height: 18),
            DragTarget<String>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) {
                setState(() {
                  _selectedMatchingWord = details.data;
                });
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isHovering ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHovering ? const Color(0xFF06A6FF) : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'DROP HERE',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        selectedWord ?? 'Drop or tap a word',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: selectedWord == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'WORD BANK',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 12,
              children: choices.map((choice) {
                final isSelected = choice == selectedWord;
                return Draggable<String>(
                  data: choice,
                  feedback: Material(
                    color: Colors.transparent,
                    child: ActionChip(
                      label: Text(
                        choice,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF334155)),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF06A6FF), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: ActionChip(
                      label: Text(
                        choice,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF334155)),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  child: ActionChip(
                    label: Text(
                      choice,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF334155)),
                    ),
                    backgroundColor: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    side: BorderSide(color: isSelected ? const Color(0xFF06A6FF) : const Color(0xFFCBD5E1), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.black.withValues(alpha: 0.04),
                    elevation: 2,
                    onPressed: () {
                      setState(() {
                        _selectedMatchingWord = choice;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: selectedWord == null
                  ? null
                  : () {
                      final isCorrect = selectedWord == correct;
                      _recordAnswer((item['wordId'] ?? '').toString(), isCorrect);
                      _nextItem();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06A6FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('CHECK', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _playAudio(correct),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Hear word'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF06A6FF),
                side: const BorderSide(color: Color(0xFF06A6FF), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pref = Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;

    // If there is a saved session waiting to be resumed, show prompt UI
    if (_showResumePrompt && _pendingSavedState != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Cumulative Review'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Resume your previous Module 4 review?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      const Text('You have an in-progress review. Resume where you left off or start a fresh review.'),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: _startFresh,
                            child: const Text('Start Fresh'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _resumeSavedState,
                            child: const Text('Resume'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_showFailurePrompt) {
      return _buildFailurePrompt(Theme.of(context));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          LocalizationService.translate(pref, 'cumulative_review'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/home'),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06A6FF)))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0xFFB7E4C7), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              MascotVisual(
                                type: _currentItem == null ? MascotType.starry : _mascotForFormat((_currentItem?['activityFormat'] ?? '').toString()),
                                size: 100,
                                isCelebrating: _currentIndex > 0 && _currentIndex == _queue.length - 1,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: const Color(0xFFBBF7D0)),
                                      ),
                                      child: const Text(
                                        'MODULE 4',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: 1.0),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Mastery Review',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _currentItem == null ? 'Preparing your review...' : 'Keep going. Missed words return later in the same session.',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569), height: 1.45),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.autorenew_rounded, size: 16, color: Color(0xFF059669)),
                              const SizedBox(width: 6),
                              Text(
                                _showResumePrompt ? 'Resume available' : 'Persistent session state',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Review progress',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF059669).withValues(alpha: 0.9)),
                        ),
                        Text(
                          _queue.isEmpty ? '0%' : '${((_currentIndex + 1) / _queue.length * 100).round()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _queue.isEmpty ? 0 : (_currentIndex + 1) / _queue.length,
                          minHeight: 12,
                          backgroundColor: const Color(0x00FFFFFF),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0, bottom: 24.0),
                          child: _buildCurrentActivity(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Removed unused _goBackWithAnimation helper to satisfy analyzer.

  // _buildResumeRoute removed — navigation now uses direct pushes to MasteryResultScreen where needed.
}
