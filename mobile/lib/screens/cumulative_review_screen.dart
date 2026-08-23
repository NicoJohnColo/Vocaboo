// cumulative_review_screen.dart  –  Module 4 Final Evaluation (v1 design spec)
// Scoring engine (ScoringService formulas, penalty scale, thresholds) is untouched.
// CumulativeReviewProvider / cross-lesson sentence fetch removed: not needed for
// the fixed 3-activity sequence.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../services/tts_service.dart';
import '../services/local_storage_service.dart';
import '../services/scoring_service.dart';
import '../widgets/mascot_visual.dart';
import '../widgets/custom_image_viewer.dart';
import '../widgets/cebuano_text_highlighter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class CumulativeReviewScreen extends StatefulWidget {
  final String sessionId;
  final String? lessonId;
  final List<Map<String, dynamic>> allWords;
  final String categoryId;
  final bool isSandbox;
  final List<String>? lessonIds;
  final List<String>? priorityWordIds;

  const CumulativeReviewScreen({
    super.key,
    required this.sessionId,
    this.lessonId,
    this.allWords = const [],
    required this.categoryId,
    this.isSandbox = false,
    this.lessonIds,
    this.priorityWordIds,
  });

  @override
  State<CumulativeReviewScreen> createState() => _CumulativeReviewScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _CumulativeReviewScreenState extends State<CumulativeReviewScreen>
    with TickerProviderStateMixin {

  // ── data ──────────────────────────────────────────────────────────────────
  List<dynamic> _reviewItems = [];
  bool _loading = true;
  bool _hasError = false;
  bool _showFailurePrompt = false;
  double? _failedFinalScore;
  Map<String, String> _wordDifficulties = {};
  List<String> _allWordIds = [];

  // ── scoring / tracking ────────────────────────────────────────────────────
  final Map<String, bool> _results = {};
  final Map<String, int> _attemptCounts = {}; // kept for compat
  final Map<String, int> _wordWrongAttempts = {};
  final Map<String, bool> _itemResults = {};
  final Set<String> _attemptedWordIds = <String>{};

  int _reviewAttemptCount = 0;
  bool _isPerfectFirstAttempt = false;
  double _maxProgress = 0.0;
  double? _progressOverride;
  double? _weightedScore;

  // ── queue ─────────────────────────────────────────────────────────────────
  // Fixed activity order per word: Image → FITB → Sentence Reconstruction
  static const List<String> _fixedActivityOrder = [
    'IMAGE_MATCHING',
    'FILL_IN_THE_BLANK',
    'SENTENCE_RECONSTRUCTION',
  ];

  final List<Map<String, dynamic>> _queue = [];
  int _currentIndex = 0;

  Map<String, dynamic>? get _currentItem =>
      _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  List<Map<String, dynamic>> get _normalizedReviewItems =>
      _reviewItems.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  // ── per-question UI state ─────────────────────────────────────────────────
  bool _checked = false;
  bool _isAnswerCorrect = false;
  bool _showFeedback = false;
  String _lastCorrectAnswer = '';
  int? _selectedOptionIndex;
  List<String> _currentMcOptions = [];
  String? _selectedMatchingWord;
  List<String> _matchingOptions = [];
  final TextEditingController _typingController = TextEditingController();
  final List<String> _scrambledWords = [];
  final List<String> _assembledWords = [];
  List<String> _arrangementPrefix = [];
  List<String> _arrangementTargetTokens = [];
  List<String> _arrangementSuffix = [];

  // ── countdown entry screen ────────────────────────────────────────────────
  bool _showingCountdown = true;
  int _countdown = 10;
  Timer? _countdownTimer;
  late AnimationController _countdownRingController;
  late AnimationController _entryFadeController;

  // ── active time ───────────────────────────────────────────────────────────
  DateTime? _moduleStartTime;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _countdownRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _entryFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fetchReviewItems();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownRingController.dispose();
    _entryFadeController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Countdown helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _startCountdown() {
    _countdownRingController.forward();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          t.cancel();
          _dismissCountdown();
        }
      });
    });
  }

  void _dismissCountdown() {
    _countdownTimer?.cancel();
    _entryFadeController.forward().then((_) {
      if (mounted) setState(() => _showingCountdown = false);
    });
    _moduleStartTime = DateTime.now();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data loading
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<String>> _resolveLessonIds(LessonProvider lessons) async {
    if (widget.lessonIds != null && widget.lessonIds!.isNotEmpty) {
      return List<String>.from(widget.lessonIds!);
    }
    if (widget.lessonId != null && widget.lessonId!.isNotEmpty) {
      return [widget.lessonId!];
    }
    if (widget.categoryId.isNotEmpty) {
      await lessons.loadLessons(widget.categoryId);
      final selected = lessons.lessons
          .take(2)
          .map((l) => l.lessonId)
          .where((id) => id.isNotEmpty)
          .toList();
      if (selected.isNotEmpty) return selected;
    }
    return const [];
  }

  Future<void> _fetchReviewItems() async {
    if (!mounted) return;
    final lessons = Provider.of<LessonProvider>(context, listen: false);
    List<Map<String, dynamic>> items = [];

    if (widget.allWords.isNotEmpty) {
      items = widget.allWords.toList();
    } else {
      final lessonIds = await _resolveLessonIds(lessons);
      final targetIds = lessonIds.isNotEmpty
          ? lessonIds
          : ((widget.lessonId != null && widget.lessonId!.isNotEmpty)
              ? [widget.lessonId!]
              : (widget.lessonIds ?? []));

      for (final lId in targetIds) {
        final batch = await lessons.loadVocabulary(lId);
        for (final word in batch) {
          items.add(word.toJson());
        }
      }

      if (items.isEmpty && widget.categoryId.isNotEmpty) {
        final catItems = await lessons.loadCategoryActivity(widget.categoryId);
        items = catItems.toList();
      }
    }

    if (items.isEmpty) {
      setState(() { _loading = false; _hasError = true; });
      return;
    }

    String firstNonEmpty(Map<dynamic, dynamic> map, List<String> keys) {
      for (final k in keys) {
        final v = map[k]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return '';
    }

    // Normalize
    final list = items.map((e) {
      final item = Map<String, dynamic>.from(e);
      final word = firstNonEmpty(item, ['word', 'englishWord', 'targetWord']);
      final cebuano = firstNonEmpty(item, ['cebuanoMeaning', 'definition', 'cebuanoDefinition']);
      final engSentence = firstNonEmpty(item, ['exampleSentenceEnglish', 'example', 'englishSentence', 'englishExampleSentence']);
      final cebSentence = firstNonEmpty(item, [
        'exampleSentenceCebuano',
        'example_sentence_cebuano',
        'cebuanoSentence',
        'cebuano_sentence',
        'sentenceCebuano',
        'sentence_cebuano',
        'sentenceArrangementCebuano',
        'audioTextCebuano',
        'audio_text_cebuano',
        'cebuanoTranslation',
        'cebuano_translation',
        'cebuanoExample',
        'cebuanoExampleSentence',
      ]);
      final fitbSent = firstNonEmpty(item, ['sentenceCompletionSentence', 'fitbSentence', 'fillInTheBlankSentence', 'tileSentence']);
      final fitbAns = firstNonEmpty(item, ['sentenceCompletionAnswer', 'fitbAnswer', 'word', 'englishWord']);

      return <String, dynamic>{
        'wordId': firstNonEmpty(item, ['wordId', 'id', 'vocabularyId']),
        'word': word,
        'definition': cebuano,
        'cebuanoMeaning': cebuano,
        'example': engSentence.isNotEmpty ? engSentence : fitbSent,
        'exampleSentenceEnglish': engSentence.isNotEmpty ? engSentence : fitbSent,
        'exampleCebuano': cebSentence.isNotEmpty ? cebSentence : cebuano,
        'exampleSentenceCebuano': cebSentence.isNotEmpty ? cebSentence : cebuano,
        'mcDistractor1': item['mcDistractor1'],
        'mcDistractor2': item['mcDistractor2'],
        'mcDistractor3': item['mcDistractor3'],
        'fitbSentence': fitbSent.isNotEmpty ? fitbSent : engSentence,
        'fitbAnswer': fitbAns.isNotEmpty ? fitbAns : word,
        'matchingSet': item['matchingSet'],
        'sentenceArrangementTokens': item['sentenceArrangementTokens'],
        'imageAssetPath': item['imageAssetPath'],
        'partOfSpeech': item['partOfSpeech'] ?? '',
      };
    }).where((it) => (it['wordId'] ?? '').toString().isNotEmpty).toList();

    // Fetch difficulty levels in parallel
    final Map<String, String> diffMap = {};
    await Future.wait(list.map((item) {
      final wid = item['wordId'].toString();
      return lessons.getWordDifficulty(wid).then((level) => diffMap[wid] = level);
    }));

    // Build queue: fixed 3-activity order per word
    _queue.clear();
    _allWordIds = list.map((it) => (it['wordId'] ?? '').toString()).toList();
    for (final item in list) {
      if (widget.isSandbox) {
        _queue.add({...item, 'activityFormat': 'FILL_IN_THE_BLANK'});
      } else {
        final perWordSet = <String>{};
        for (final fmt in _fixedActivityOrder) {
          String resolved = fmt;

          // IMAGE_MATCHING → MULTIPLE_CHOICE if no image asset
          if (resolved == 'IMAGE_MATCHING') {
            final hasImage = (item['imageAssetPath'] ?? '').toString().isNotEmpty;
            if (!hasImage) resolved = 'MULTIPLE_CHOICE';
          }

          // SENTENCE_RECONSTRUCTION → MULTIPLE_CHOICE if not enough tokens
          if (resolved == 'SENTENCE_RECONSTRUCTION' &&
              _sentenceTokens(item).length < 2) {
            resolved = 'MULTIPLE_CHOICE';
          }

          // Dedup within this word: fall back to FILL_IN_THE_BLANK then MATCHING
          if (perWordSet.contains(resolved)) {
            if (!perWordSet.contains('FILL_IN_THE_BLANK')) {
              resolved = 'FILL_IN_THE_BLANK';
            } else if (!perWordSet.contains('MATCHING')) {
              resolved = 'MATCHING';
            }
          }

          perWordSet.add(resolved);
          _queue.add({...item, 'activityFormat': resolved});
        }
      }
    }

    setState(() {
      _reviewItems = list;
      _wordDifficulties = diffMap;
      _loading = false;
      _currentIndex = 0;
      _weightedScore = null;
      _results.clear();
      _wordWrongAttempts.clear();
      _itemResults.clear();
      _attemptedWordIds.clear();
      _maxProgress = 0.0;
      _progressOverride = null;
      _prepareCurrentActivityState();
    });

    // Start countdown only after data is ready
    _startCountdown();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Per-question state setup
  // ─────────────────────────────────────────────────────────────────────────

  List<String> _sentenceTokens(Map<String, dynamic> item) {
    final explicit = (item['sentenceArrangementTokens'] as List<dynamic>?)
        ?.map((t) => t.toString())
        .where((t) => t.trim().isNotEmpty)
        .toList();
    if (explicit != null && explicit.length >= 2) return explicit;

    final raw = (item['exampleSentenceEnglish'] ?? item['example'] ?? '').toString().trim();
    if (raw.isEmpty ||
        raw.startsWith('Match the English') ||
        raw.startsWith('What is the Cebuano')) {
      return const [];
    }
    return raw
        .replaceAll(RegExp(r'[.,\/#!$%\^\&\*;:{}=\-_`~(?)]'), '')
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .toList();
  }

  List<String> _buildMatchingOptions(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString().trim();
    if (correct.isEmpty) return const [];

    final matchingSet = (item['matchingSet'] as List<dynamic>?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const [];

    final candidates = <String>{};
    if (matchingSet.isNotEmpty) {
      for (final entry in matchingSet) {
        final w = (entry['englishWord'] ?? '').toString().trim();
        if (w.isNotEmpty && w != correct) candidates.add(w);
      }
    } else {
      for (final entry in _reviewItems) {
        final w = (entry['word'] ?? '').toString().trim();
        if (w.isNotEmpty && w != correct) candidates.add(w);
      }
    }

    final distractors = candidates.toList()
      ..shuffle(Random('${item['wordId'] ?? correct}'.hashCode));
    final options = <String>[correct, ...distractors.take(2)];
    options.shuffle(Random('${item['wordId'] ?? correct}_bank'.hashCode));
    return options;
  }

  void _prepareCurrentActivityState() {
    _selectedMatchingWord = null;
    _matchingOptions = [];
    _typingController.clear();
    _scrambledWords.clear();
    _assembledWords.clear();
    _selectedOptionIndex = null;
    _checked = false;
    _showFeedback = false;
    _isAnswerCorrect = false;

    final item = _currentItem;
    if (item == null) return;

    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();
    if (fmt == 'MATCHING' || fmt == 'TRANSLATION_MATCHING') {
      _matchingOptions = _buildMatchingOptions(item);
    } else if (fmt == 'SENTENCE_RECONSTRUCTION') {
      final allTokens = _sentenceTokens(item);
      final targetWord = (item['word'] ?? '').toString().toLowerCase().trim();
      int targetIdx = -1;
      for (int i = 0; i < allTokens.length; i++) {
        if (allTokens[i].toLowerCase().replaceAll(RegExp(r'[^\w]'), '') == targetWord) {
          targetIdx = i;
          break;
        }
      }
      if (targetIdx == -1) targetIdx = 0;

      int startIndex = 0;
      int endIndex = allTokens.length - 1;

      // Pick exactly 3 missing words (window of 3 centered on targetIdx)
      if (allTokens.length > 3) {
        if (targetIdx == 0) {
          startIndex = 0;
          endIndex = 2;
        } else if (targetIdx >= allTokens.length - 1) {
          startIndex = (allTokens.length - 3).clamp(0, allTokens.length - 1);
          endIndex = allTokens.length - 1;
        } else {
          startIndex = (targetIdx - 1).clamp(0, allTokens.length - 3);
          endIndex = startIndex + 2;
        }
      }

      _arrangementPrefix = allTokens.sublist(0, startIndex);
      _arrangementTargetTokens = allTokens.sublist(startIndex, endIndex + 1);
      _arrangementSuffix = allTokens.sublist(endIndex + 1);

      _scrambledWords.addAll(_arrangementTargetTokens);
      _scrambledWords.shuffle(Random('${item['wordId'] ?? ''}_scramble'.hashCode));
      _assembledWords.clear();
    } else if (fmt == 'MULTIPLE_CHOICE' || fmt == 'IMAGE_MATCHING') {
      final correct = (item['word'] ?? '').toString();
      final level = _wordDifficulties[(item['wordId'] ?? '').toString()] ?? 'LEARNING';
      final distractorCount = level == 'LEARNING' ? 2 : level == 'MASTERED' ? 4 : 3;

      final provided = [
        item['mcDistractor1'],
        item['mcDistractor2'],
        item['mcDistractor3'],
      ].whereType<String>().where((v) => v.isNotEmpty && v != correct).toList();

      final distractors = <String>[...provided];
      if (distractors.length < distractorCount) {
        final other = _normalizedReviewItems
            .map((e) => e['word']?.toString() ?? '')
            .where((w) => w.isNotEmpty && w != correct && !distractors.contains(w))
            .toList()..shuffle();
        distractors.addAll(other);
      }
      if (distractors.length < distractorCount) {
        const fallback = ['apple', 'house', 'water', 'friend', 'school',
            'book', 'tree', 'happy', 'run', 'big', 'cat', 'dog'];
        distractors.addAll(
            fallback.where((w) => w != correct && !distractors.contains(w)));
      }

      final options = <String>[correct, ...distractors.take(distractorCount)];
      options.shuffle(Random('${item['wordId'] ?? ''}_mc'.hashCode));
      _currentMcOptions = options;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Answer checking
  // ─────────────────────────────────────────────────────────────────────────



  void _recordAnswer(String wordId, bool correct) {
    _attemptedWordIds.add(wordId);
    final cur = _currentItem;
    final fmt = cur != null ? (cur['activityFormat'] ?? '').toString() : '';
    _itemResults['${wordId}_$fmt'] = correct;

    if (!correct) {
      _wordWrongAttempts[wordId] = (_wordWrongAttempts[wordId] ?? 0) + 1;
    }
    if (!_results.containsKey(wordId)) {
      _results[wordId] = correct;
    }
  }

  void _checkAnswer() {
    if (_currentIndex >= _queue.length) return;
    final item = _queue[_currentIndex];
    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();
    final wordId = (item['wordId'] ?? '').toString();

    bool correct = false;
    String correctAns = '';

    if (fmt == 'MULTIPLE_CHOICE' || fmt == 'IMAGE_MATCHING') {
      final correctWord = (item['word'] ?? '').toString();
      if (_selectedOptionIndex != null &&
          _selectedOptionIndex! >= 0 &&
          _selectedOptionIndex! < _currentMcOptions.length) {
        correct = _currentMcOptions[_selectedOptionIndex!] == correctWord;
      }
      correctAns = correctWord;
    } else if (fmt == 'FILL_IN_THE_BLANK') {
      final correctWord = (item['word'] ?? '').toString();
      correct = _typingController.text.trim().toLowerCase() == correctWord.toLowerCase();
      correctAns = correctWord;
    } else if (fmt == 'SENTENCE_RECONSTRUCTION') {
      correct = _assembledWords.join(' ').toLowerCase().trim() ==
          _arrangementTargetTokens.join(' ').toLowerCase().trim();
      correctAns = _arrangementTargetTokens.join(' ');
    } else if (fmt == 'MATCHING' || fmt == 'TRANSLATION_MATCHING') {
      final correctWord = (item['word'] ?? '').toString();
      correct = _selectedMatchingWord == correctWord;
      correctAns = correctWord;
    }

    setState(() {
      _checked = true;
      _isAnswerCorrect = correct;
      _showFeedback = true;
      _lastCorrectAnswer = correctAns;
      _recordAnswer(wordId, correct);
    });
  }

  void _handleContinue() {
    setState(() {
      _currentIndex++;
      _prepareCurrentActivityState();
    });
    if (_currentIndex >= _queue.length) {
      _finishReview();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Finish / scoring
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _finishReview() async {
    setState(() { _progressOverride = 1.0; });
    await Future.delayed(const Duration(milliseconds: 450));

    final wordIds = _allWordIds.isNotEmpty
        ? _allWordIds
        : _reviewItems.map((it) => (it['wordId'] ?? '').toString()).where((s) => s.isNotEmpty).toList();

    final score = ScoringService.calculateCumulativeScore(_wordWrongAttempts, wordIds);
    _weightedScore = score;
    final passed = ScoringService.isPassing(score);

    final int mastered = wordIds.where((id) => (_wordWrongAttempts[id] ?? 0) == 0).length;
    final List<String> missed = wordIds.where((id) => (_wordWrongAttempts[id] ?? 0) > 0).toList();

    final wordBreakdown = <Map<String, dynamic>>[];
    for (final wordId in wordIds) {
      final wrong = _wordWrongAttempts[wordId] ?? 0;
      final wordData = _reviewItems.firstWhere(
        (it) => (it['wordId'] ?? '').toString() == wordId,
        orElse: () => <String, dynamic>{'word': wordId},
      );
      wordBreakdown.add({
        'wordId': wordId,
        'word': (wordData['word'] ?? wordId).toString(),
        'wrongAttempts': wrong,
        'points': ScoringService.calculateWordScore(wrong),
      });
    }

    await LocalStorageService.saveCumulativeReviewScoreDetails(widget.sessionId, {
      'wordIds': wordIds,
      'wordWrongAttempts': Map<String, dynamic>.from(_wordWrongAttempts),
      'wordBreakdown': wordBreakdown,
      'finalScore': score,
      'passed': passed,
      'totalWords': wordIds.length,
      'masteredCount': mastered,
    });

    if (!mounted) return;
    final lessons = Provider.of<LessonProvider>(context, listen: false);
    final lessonIds = await _resolveLessonIds(lessons);

    final int activeSeconds = _moduleStartTime == null
        ? 0
        : DateTime.now().difference(_moduleStartTime!).inSeconds.clamp(0, 86400);

    final targetLessonId = widget.lessonId ?? (lessonIds.isNotEmpty ? lessonIds.first : null);
    if (!widget.isSandbox && targetLessonId != null) {
      try {
        await lessons.persistModuleScore(
          targetLessonId,
          4,
          mastered,
          wordIds.length,
          isSandbox: false,
          sessionId: widget.sessionId,
          timeSeconds: activeSeconds,
        );
      } catch (e) {
        debugPrint('Module 4 score sync failed: $e');
      }
    }

    if (!widget.isSandbox) {
      final List<Map<String, dynamic>> wordsToSave = widget.allWords.isNotEmpty
          ? widget.allWords
          : List<Map<String, dynamic>>.from(_reviewItems);
      await LocalStorageService.saveCumulativeReviewCompleted(
        widget.categoryId,
        score,
        mastered,
        wordIds.length,
        widget.sessionId,
        missed,
        wordsToSave,
      );

      if (passed) {
        try {
          String badge = 'BRONZE';
          if (score >= 100.0) {
            badge = 'PERFECT_GOLD';
          } else if (score >= 90.0) {
            badge = 'GOLD';
          } else if (score >= 80.0) {
            badge = 'SILVER';
          }
          final pairId = lessonIds.isNotEmpty ? lessonIds.join('_') : (widget.lessonId ?? widget.categoryId);
          await lessons.completeCumulativeReview(
            widget.sessionId,
            accuracyScore: score,
            totalAttempts: wordIds.length,
            correctCount: mastered,
            badgeAwarded: badge,
            pointsEarned: (score * 1.5).round(),
            timeSpentSeconds: activeSeconds,
            categoryId: widget.categoryId,
            lessonPairId: pairId,
          );
        } catch (e) {
          debugPrint('completeCumulativeReview failed (non-fatal): $e');
        }
        await LocalStorageService.clearCumulativeReviewState(widget.sessionId);
        await LocalStorageService.clearReviewCompletionState(widget.sessionId);
      } else {
        await LocalStorageService.saveReviewCompletionState(widget.sessionId, {
          'cumulativeReviewScore': score,
          'finalScore': score,
          'passed': false,
        });
      }
    } else {
      try {
        await lessons.completeSandbox(widget.sessionId, finalScore: score);
      } catch (e) {
        debugPrint('completeSandbox failed (non-fatal): $e');
      }
    }

    _isPerfectFirstAttempt = (score >= 100.0 && _reviewAttemptCount == 0);

    if (!mounted) return;

    if (!passed) {
      setState(() {
        _showFailurePrompt = true;
        _failedFinalScore = score;
      });
      return;
    }

    context.go(
      '/session/${widget.sessionId}/lesson-score',
      extra: {
        'sessionId': widget.sessionId,
        'lessonId': widget.lessonId ?? '',
        'categoryId': widget.categoryId,
        'lessonTitle': 'Lesson Complete',
        'allWords': _normalizedReviewItems,
        'overallScore': score,
        'isPerfectFirstAttempt': _isPerfectFirstAttempt,
        'reviewAttemptCount': _reviewAttemptCount,
        'isSandbox': widget.isSandbox,
      },
    );
  }

  void _restartModule4() {
    setState(() {
      _reviewAttemptCount++;
      _showFailurePrompt = false;
      _failedFinalScore = null;
      _wordWrongAttempts.clear();
      _results.clear();
      _itemResults.clear();
      _attemptCounts.clear();
      _currentIndex = 0;
      _progressOverride = null;
      _checked = false;
      _showFeedback = false;
      _loading = true;
      // Reset countdown for retry
      _showingCountdown = true;
      _countdown = 10;
      _countdownRingController.reset();
      _entryFadeController.reset();
    });
    _fetchReviewItems();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _playAudio(String text) => TTSService.speak(text);

  MascotType _mascotForFormat(String fmt) {
    switch (fmt) {
      case 'FILL_IN_THE_BLANK':
        return MascotType.sippy;
      case 'MATCHING':
      case 'TRANSLATION_MATCHING':
        return MascotType.toti;
      case 'SENTENCE_RECONSTRUCTION':
        return MascotType.starry;
      default:
        return MascotType.bibo;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ── COUNTDOWN / ENTRY SCREEN ─────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCountdownScreen() {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(_entryFadeController),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top: close / skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => context.go('/home'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _dismissCountdown,
                        child: const Text(
                          'Start Now',
                          style: TextStyle(
                            color: Color(0xFF4338CA),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Mascot
                const MascotVisual(type: MascotType.starry, size: 120),
                const SizedBox(height: 24),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Text(
                    'MODULE 4 · FINAL EVALUATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4338CA),
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  "Let's see what you've learned!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'You will be tested across all three activity types. Take your time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                  ),
                ),

                const SizedBox(height: 36),

                // Countdown ring
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _countdownRingController,
                        builder: (_, _) => CircularProgressIndicator(
                          value: 1.0 - _countdownRingController.value,
                          strokeWidth: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4338CA)),
                        ),
                      ),
                      Text(
                        '$_countdown',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Starting in…',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),

                const Spacer(),

                // Activity indicators
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _activityPill(Icons.image_outlined, 'Image'),
                      const SizedBox(width: 10),
                      _activityPill(Icons.edit_outlined, 'Fill-in'),
                      const SizedBox(width: 10),
                      _activityPill(Icons.sort_rounded, 'Build'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activityPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF4338CA), size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ── FAILURE SCREEN ───────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFailureScreen() {
    final score = (_failedFinalScore ?? _weightedScore ?? 0.0);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MascotVisual(type: MascotType.bibo, size: 110, isSad: true),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'NOT QUITE YET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB91C1C),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                "Let's review again",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You scored ${score.toStringAsFixed(1)}%.\nYou need at least 70% to pass.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 32),

              // Score bar
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  minHeight: 14,
                  backgroundColor: const Color(0xFFFEE2E2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${score.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
                  const Text('70% needed', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _restartModule4,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ── BOTTOM PANEL (Check / Feedback) ─────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────

  bool _isActionEnabled() {
    if (_currentIndex >= _queue.length) return false;
    final fmt = (_queue[_currentIndex]['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();
    switch (fmt) {
      case 'MULTIPLE_CHOICE':
      case 'IMAGE_MATCHING':
        return _selectedOptionIndex != null;
      case 'FILL_IN_THE_BLANK':
        return _typingController.text.trim().isNotEmpty;
      case 'SENTENCE_RECONSTRUCTION':
        return _assembledWords.isNotEmpty;
      case 'MATCHING':
      case 'TRANSLATION_MATCHING':
        return _selectedMatchingWord != null;
      default:
        return false;
    }
  }

  Widget _buildBottomPanel() {
    if (_currentIndex >= _queue.length) return const SizedBox.shrink();
    final item = _queue[_currentIndex];
    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();

    String? getLearnerStatement() {
      if (fmt == 'SENTENCE_RECONSTRUCTION') return _assembledWords.join(' ');
      if (fmt == 'FILL_IN_THE_BLANK') {
        final s = (item['fitbSentence'] ?? item['sentenceCompletionSentence'] ?? '').toString();
        final ans = _typingController.text.trim();
        if (s.isNotEmpty) {
          final rx = RegExp(r'_{2,}|-{2,}|\[_\]');
          return s.contains(rx) ? s.replaceFirst(rx, ans.isEmpty ? '___' : ans) : '$s (Answer: $ans)';
        }
      }
      return null;
    }

    String? getCorrectStatement() {
      if (fmt == 'SENTENCE_RECONSTRUCTION') return _sentenceTokens(item).join(' ');
      if (fmt == 'FILL_IN_THE_BLANK') {
        final s = (item['fitbSentence'] ?? item['sentenceCompletionSentence'] ?? '').toString();
        final a = (item['fitbAnswer'] ?? item['word'] ?? '').toString();
        if (s.isNotEmpty) {
          final rx = RegExp(r'_{2,}|-{2,}|\[_\]');
          return s.contains(rx) ? s.replaceFirst(rx, a) : '$s (Answer: $a)';
        }
      }
      return null;
    }

    if (!_showFeedback) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: ElevatedButton(
          onPressed: _isActionEnabled() ? _checkAnswer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4338CA),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            disabledForegroundColor: const Color(0xFF94A3B8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text('CHECK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ),
      );
    }

    final Color panelBg = _isAnswerCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final Color textColor = _isAnswerCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final Color btnBg = _isAnswerCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final learnerStatement = getLearnerStatement();
    final correctStatement = getCorrectStatement();

    return Container(
      color: panelBg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _isAnswerCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: textColor,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAnswerCorrect
                          ? (((_wordWrongAttempts[item['wordId']] ?? 0) > 0)
                              ? 'Correct (+5 pts)'
                              : (fmt == 'SENTENCE_RECONSTRUCTION'
                                  ? 'Correct (+15 pts)'
                                  : 'Correct (+10 pts)'))
                          : 'Incorrect (0 pts)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    if (learnerStatement != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Your answer: "$learnerStatement"',
                        style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.85)),
                      ),
                    ],
                    if (!_isAnswerCorrect) ...[
                      const SizedBox(height: 3),
                      Text(
                        correctStatement != null
                            ? 'Correct: "$correctStatement"'
                            : 'Correct answer: $_lastCorrectAnswer',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('CONTINUE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ── ACTIVITY WIDGETS ─────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────

  Widget _wordChip(String word, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEDE9FE) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF4338CA) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        boxShadow: selected
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        word,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFF4338CA) : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required int index,
    required String option,
    required String correct,
    required VoidCallback? onTap,
  }) {
    final isSelected = _selectedOptionIndex == index;
    Color cardBg = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF334155);

    if (_checked) {
      if (option == correct) {
        cardBg = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFF22C55E);
        textColor = const Color(0xFF15803D);
      } else if (isSelected) {
        cardBg = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFFB91C1C);
      }
    } else if (isSelected) {
      cardBg = const Color(0xFFEDE9FE);
      borderColor = const Color(0xFF4338CA);
      textColor = const Color(0xFF4338CA);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected && !_checked ? const Color(0xFF4338CA) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                  color: isSelected && !_checked ? const Color(0xFF4338CA) : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected && !_checked ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCebuanoGuideBox({
    required String text,
    String? highlightWord,
    bool showFlag = true,
  }) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFlag) ...[
            const Text('🇵🇭', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bisaya Translation:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                CebuanoTextHighlighter(
                  text: text.replaceAll('**', ''),
                  highlightWord: highlightWord?.replaceAll('**', ''),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.4,
                  ),
                  highlightStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0369A1),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF0284C7),
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMatching(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final definition = (item['cebuanoMeaning'] ?? item['definition'] ?? '').toString();
    final imagePath = (item['imageAssetPath'] ?? '').toString();
    if (imagePath.isEmpty) return _buildMultipleChoice(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'IMAGE TO WORD',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        const Text(
          'What is the English word for this image?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomImageViewer(
                imagePath: imagePath,
                width: 220,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  width: 220,
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18)),
                  child: const Text('Image not available', style: TextStyle(color: Color(0xFF64748B))),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildCebuanoGuideBox(text: definition, highlightWord: definition),
        const SizedBox(height: 20),
        ..._currentMcOptions.asMap().entries.map((e) => _buildOptionRow(
          index: e.key,
          option: e.value,
          correct: correct,
          onTap: _checked ? null : () => setState(() => _selectedOptionIndex = e.key),
        )),
      ],
    );
  }

  Widget _buildFillInBlank(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final sentence = (item['fitbSentence'] ?? item['example'] ?? '').toString();
    final definition = (item['cebuanoMeaning'] ?? item['definition'] ?? '').toString();
    final cebSentence = (item['exampleSentenceCebuano'] ?? item['exampleCebuano'] ?? definition).toString();

    String displaySentence = sentence;
    if (displaySentence.contains(RegExp(r'\{blank\}|\[blank\]|<blank>', caseSensitive: false))) {
      displaySentence = displaySentence.replaceAll(RegExp(r'\{blank\}|\[blank\]|<blank>', caseSensitive: false), '_____');
    } else if (correct.isNotEmpty) {
      displaySentence = displaySentence.replaceAll(RegExp(r'\b' + RegExp.escape(correct) + r'\b', caseSensitive: false), '_____');
      if (!displaySentence.contains('_____')) {
        displaySentence = displaySentence.replaceAll(RegExp(RegExp.escape(correct), caseSensitive: false), '_____');
      }
    }
    if (displaySentence.trim().isEmpty) {
      displaySentence = 'Type the word: _____';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'FILL IN THE BLANK',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displaySentence,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCebuanoGuideBox(
          text: cebSentence.isNotEmpty ? cebSentence : definition,
          highlightWord: definition,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _typingController,
          enabled: !_checked,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            hintText: 'Type your answer here…',
            hintStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2.5)),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => _playAudio(correct),
          icon: const Icon(Icons.volume_up_rounded, size: 20),
          label: const Text('Hear word', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4338CA),
            side: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildSentenceReconstruction(Map<String, dynamic> item) {
    final answerTokens = _sentenceTokens(item);
    if (_scrambledWords.isEmpty && _assembledWords.isEmpty && _arrangementTargetTokens.isEmpty) {
      final allTokens = answerTokens;
      final targetWord = (item['word'] ?? '').toString().toLowerCase().trim();
      int targetIdx = -1;
      for (int i = 0; i < allTokens.length; i++) {
        if (allTokens[i].toLowerCase().replaceAll(RegExp(r'[^\w]'), '') == targetWord) {
          targetIdx = i;
          break;
        }
      }
      if (targetIdx == -1) targetIdx = 0;
      int startIndex = 0;
      int endIndex = allTokens.length - 1;
      if (allTokens.length > 3) {
        if (targetIdx == 0) {
          startIndex = 0;
          endIndex = 2;
        } else if (targetIdx >= allTokens.length - 1) {
          startIndex = (allTokens.length - 3).clamp(0, allTokens.length - 1);
          endIndex = allTokens.length - 1;
        } else {
          startIndex = (targetIdx - 1).clamp(0, allTokens.length - 3);
          endIndex = startIndex + 2;
        }
      }
      _arrangementPrefix = allTokens.sublist(0, startIndex);
      _arrangementTargetTokens = allTokens.sublist(startIndex, endIndex + 1);
      _arrangementSuffix = allTokens.sublist(endIndex + 1);
      _scrambledWords.addAll(_arrangementTargetTokens);
      _scrambledWords.shuffle(Random('${item['wordId'] ?? ''}_recon'.hashCode));
    }

    final cebSentence = (item['exampleSentenceCebuano'] ?? item['exampleCebuano'] ?? item['cebuanoMeaning'] ?? item['definition'] ?? '').toString();
    final definition = (item['cebuanoMeaning'] ?? item['definition'] ?? '').toString();

    Widget buildLockedChip(String text) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF0369A1),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'BUILD THE SENTENCE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        _buildCebuanoGuideBox(
          text: cebSentence,
          highlightWord: definition,
          showFlag: true,
        ),
        const SizedBox(height: 20),
        // Assembled Sentence Area
        const Text(
          'Your Sentence:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _assembledWords.isNotEmpty ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
              width: 2,
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              ..._arrangementPrefix.map((w) => buildLockedChip(w)),
              if (_assembledWords.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Text(
                    'Tap words from the bank below to build your sentence…',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                  ),
                )
              else
                ..._assembledWords.map((word) => GestureDetector(
                  onTap: _checked ? null : () => setState(() {
                    _assembledWords.remove(word);
                    _scrambledWords.add(word);
                  }),
                  child: _wordChip(word, selected: true),
                )),
              ..._arrangementSuffix.map((w) => buildLockedChip(w)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Word Bank Area
        const Text(
          'WORD BANK',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: _scrambledWords.map((word) => GestureDetector(
            onTap: _checked ? null : () => setState(() {
              _scrambledWords.remove(word);
              _assembledWords.add(word);
            }),
            child: _wordChip(word),
          )).toList(),
        ),
        const SizedBox(height: 16),
        if (_assembledWords.isNotEmpty || _arrangementPrefix.isNotEmpty)
          Row(
            children: [
              IconButton(
                onPressed: () => _playAudio(answerTokens.join(' ')),
                icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF4338CA)),
                tooltip: 'Listen to sentence',
              ),
              Expanded(
                child: Text(
                  'Preview: ${[..._arrangementPrefix, ..._assembledWords, ..._arrangementSuffix].join(' ')}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMultipleChoice(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final definition = (item['cebuanoMeaning'] ?? item['definition'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'CHOOSE THE CORRECT WORD',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        _buildCebuanoGuideBox(text: definition, highlightWord: definition),
        const SizedBox(height: 20),
        const Text(
          'Select the matching English word:',
          style: TextStyle(fontSize: 15, color: Color(0xFF334155), fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        ..._currentMcOptions.asMap().entries.map((e) => _buildOptionRow(
          index: e.key,
          option: e.value,
          correct: correct,
          onTap: _checked ? null : () => setState(() => _selectedOptionIndex = e.key),
        )),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _playAudio(correct),
          icon: const Icon(Icons.volume_up_rounded, size: 20),
          label: const Text('Hear word', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4338CA),
            side: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildMatching(Map<String, dynamic> item) {
    final prompt = (item['cebuanoMeaning'] ?? item['definition'] ?? '').toString();
    final choices = _matchingOptions.isNotEmpty ? _matchingOptions : _buildMatchingOptions(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'MATCH THE WORD',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.0),
        ),
        const SizedBox(height: 12),
        _buildCebuanoGuideBox(text: prompt, highlightWord: prompt),
        const SizedBox(height: 20),
        const Text(
          'Select the matching English word:',
          style: TextStyle(fontSize: 15, color: Color(0xFF334155), fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        // Drop target
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _selectedMatchingWord != null ? const Color(0xFF4338CA) : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          child: Text(
            _selectedMatchingWord ?? 'Tap a word below to select',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _selectedMatchingWord == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: choices.map((choice) {
            final isSelected = choice == _selectedMatchingWord;
            return GestureDetector(
              onTap: _checked ? null : () => setState(() => _selectedMatchingWord = choice),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEDE9FE) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  choice,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF334155),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCurrentActivity() {
    if (_currentIndex >= _queue.length) return const SizedBox.shrink();
    final item = _queue[_currentIndex];
    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();
    switch (fmt) {
      case 'IMAGE_MATCHING':
        return _buildImageMatching(item);
      case 'FILL_IN_THE_BLANK':
        return _buildFillInBlank(item);
      case 'SENTENCE_RECONSTRUCTION':
        return _buildSentenceReconstruction(item);
      case 'MATCHING':
      case 'TRANSLATION_MATCHING':
        return _buildMatching(item);
      default:
        return _buildMultipleChoice(item);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ── MAIN REVIEW SCAFFOLD ─────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildReviewBody() {
    final totalWords = _allWordIds.isNotEmpty ? _allWordIds.length : _reviewItems.length;
    final attemptedCount = _allWordIds.isNotEmpty
        ? _allWordIds.where((id) => _attemptedWordIds.contains(id)).length
        : _attemptedWordIds.length;
    final progress = totalWords > 0 ? attemptedCount / totalWords : 0.0;
    if (progress > _maxProgress) _maxProgress = progress;
    final progressVal = _progressOverride ?? _maxProgress;

    final fmt = _currentItem != null
        ? (_currentItem!['activityFormat'] ?? 'MULTIPLE_CHOICE').toString()
        : 'MULTIPLE_CHOICE';
    final activityNum = _currentIndex + 1;
    final activityTotal = _queue.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── compact top header ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => context.go('/home'),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: progressVal),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (_, val, _) => LinearProgressIndicator(
                              value: val,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4338CA)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$activityNum / $activityTotal',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Enriched & Bigger Mascot
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MascotVisual(
                            type: _mascotForFormat(fmt),
                            size: 72,
                            isCelebrating: _checked && _isAnswerCorrect,
                            isSad: _checked && !_isAnswerCorrect,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4338CA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _mascotNameForFormat(fmt).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Dynamic Mascot Speech Bubble
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE9FE),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'MODULE 4 · FINAL EVALUATION',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF4338CA),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _activityLabel(fmt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _encouragingMessage(_currentIndex, fmt),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _checked
                                      ? (_isAnswerCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C))
                                      : const Color(0xFF0F172A),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── activity card area ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: _buildCurrentActivity(),
              ),
            ),

            // ── bottom panel ────────────────────────────────────────────────
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }



  String _mascotNameForFormat(String fmt) {
    switch (fmt) {
      case 'MULTIPLE_CHOICE':
      case 'IMAGE_MATCHING':
        return 'Bibo';
      case 'FILL_IN_BLANK':
      case 'FILL_IN_THE_BLANK':
        return 'Sippy';
      case 'MATCHING':
      case 'TRANSLATION_MATCHING':
        return 'Toti';
      case 'SENTENCE_RECONSTRUCTION':
      default:
        return 'Starry';
    }
  }

  String _encouragingMessage(int index, String fmt) {
    if (_checked) {
      if (_isAnswerCorrect) {
        final praises = [
          "Awesome job! That's correct! 🎉",
          "Brilliant! Keep the streak going! 🌟",
          "Spot on! You're doing amazing! ✨",
          "Fantastic work! Super smart! 🚀",
          "You nailed it! Keep it up! 💯",
        ];
        return praises[index % praises.length];
      } else {
        final encouragements = [
          "Don't worry! You'll get it next time! 💪",
          "Good effort! Keep trying, you can do it! 🌟",
          "Stay positive! Every try helps us learn! ✨",
          "Keep your head up! Let's get the next one! 🎯",
        ];
        return encouragements[index % encouragements.length];
      }
    }

    final prompts = [
      "Keep it up! You are doing great! 🌟",
      "You've got this! Stay focused! 💪",
      "Look at you go! Keep pushing forward! 🚀",
      "Awesome work! You are super close! ✨",
      "Believe in yourself! You can do it! 🎯",
      "Fantastic focus! Show what you've learned! 🌈",
      "Stay sharp! You're on fire today! 🔥",
      "Keep the energy high! You're doing great! ⭐",
    ];
    return prompts[index % prompts.length];
  }

  String _activityLabel(String fmt) {
    switch (fmt) {
      case 'IMAGE_MATCHING': return 'Image to Word';
      case 'FILL_IN_THE_BLANK': return 'Fill in the Blank';
      case 'SENTENCE_RECONSTRUCTION': return 'Build the Sentence';
      case 'MATCHING': return 'Match the Word';
      default: return 'Choose the Correct Word';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ── build ─────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_hasError || (!_loading && _queue.isEmpty && !_showingCountdown)) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FBF7),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                const Text('No Review Words', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Unable to load words for this session. Please return home and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Return to Home', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Failure screen
    if (_showFailurePrompt) return _buildFailureScreen();

    // Loading spinner (before countdown)
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4338CA))),
      );
    }

    // Countdown entry screen
    if (_showingCountdown) return _buildCountdownScreen();

    // Main review
    return _buildReviewBody();
  }
}
