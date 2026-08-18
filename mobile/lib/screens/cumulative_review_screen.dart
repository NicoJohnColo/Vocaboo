// cumulative_mixed_review_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
 
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../services/tts_service.dart';
import '../services/local_storage_service.dart';
import '../services/scoring_service.dart';
import '../widgets/mascot_visual.dart';
import '../widgets/mascot_bubble.dart';
import '../widgets/custom_image_viewer.dart';
import '../widgets/cebuano_text_highlighter.dart';
import '../providers/cumulative_review_provider.dart';

class CumulativeReviewScreen extends StatefulWidget {
  final String sessionId;
  final String? lessonId;
  final List<Map<String, dynamic>> allWords;
  final String categoryId;
  final bool isSandbox;
  final List<String>? lessonIds;
  final List<String>? priorityWordIds;
  const CumulativeReviewScreen({super.key, required this.sessionId, this.lessonId, this.allWords = const [], required this.categoryId, this.isSandbox = false, this.lessonIds, this.priorityWordIds});

  @override
  State<CumulativeReviewScreen> createState() => _CumulativeReviewScreenState();
}

class _CumulativeReviewScreenState extends State<CumulativeReviewScreen> with WidgetsBindingObserver {
  List<dynamic> _reviewItems = [];
  bool _loading = true;
  final Map<String, bool> _results = {};
  final Map<String, int> _attemptCounts = {}; // kept for compat
  final Map<String, int> _wordWrongAttempts = {}; // unified penalty tracker
  final Map<String, bool> _itemResults = {}; // key: wordId_activityFormat -> correctness
  final Set<String> _attemptedWordIds = <String>{};
  Map<String, dynamic>? _pendingSavedState;
  bool _hasError = false;
  bool _showResumePrompt = false;
  bool _showFailurePrompt = false;
  Map<String, String> _wordDifficulties = {};
  final List<Map<String, dynamic>> _retryQueue = [];
  int _firstPassCorrectCount = 0;
  double? _failedFinalScore;
  double _maxProgress = 0.0;
  double? _progressOverride;
  int _reviewAttemptCount = 0;
  bool _isPerfectFirstAttempt = false;
  List<String> _allWordIds = []; // ordered list of word IDs
  List<dynamic> _crossLessonSentences = []; // newly added for Module 4
  bool _inReinforcementPass = false;

  // Active Time Tracking
  DateTime? _moduleStartTime;
  Duration _totalPausedDuration = Duration.zero;
  DateTime? _pauseStartTime;

  // Feedback State
  bool _checked = false;
  bool _isAnswerCorrect = false;
  bool _showFeedback = false;
  String _lastCorrectAnswer = '';
  int? _selectedOptionIndex;
  List<String> _currentMcOptions = [];

  // Fixed activity order per word
  static const List<String> _module4Formats = [
    'MULTIPLE_CHOICE',
    'FILL_IN_THE_BLANK',
    'MATCHING',
    'SENTENCE_RECONSTRUCTION',
    'WORD_SORTING',
    'ODD_ONE_OUT',
    'SENTENCE_PUZZLE',
  ];

  // Working queue with activityFormat assigned
  final List<Map<String, dynamic>> _queue = [];
  int _currentIndex = 0;
  double? _weightedScore;
  String? _selectedMatchingWord;
  List<String> _matchingOptions = [];
  bool _flashcardFlipped = false;
  List<Map<String, dynamic>> _currentOddOneOutOptions = [];
  final TextEditingController _typingController = TextEditingController();
  final List<String> _scrambledWords = [];
  final List<String> _assembledWords = [];

  Map<String, dynamic>? get _currentItem => _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  List<Map<String, dynamic>> get _normalizedReviewItems =>
      _reviewItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();

  String _itemKeyFor(Map<String, dynamic>? item) {
    if (item == null) return '';
    final wid = (item['wordId'] ?? '').toString();
    final fmt = (item['activityFormat'] ?? '').toString();
    return '${wid}_$fmt';
  }

  String _getMascotName() {
    if (_currentItem == null) return 'Bibo';
    final format = (_currentItem?['activityFormat'] ?? '').toString();
    final mascotType = _mascotForFormat(format);
    switch (mascotType) {
      case MascotType.bibo:
        return 'Bibo';
      case MascotType.toti:
        return 'Toti';
      case MascotType.sippy:
        return 'Sippy';
      case MascotType.starry:
        return 'Starry';
      default:
        return 'Bibo';
    }
  }

  String _getInstructionText() {
    if (_currentItem == null) return 'Preparing your review...';
    final format = (_currentItem?['activityFormat'] ?? '').toString();
    switch (format) {
      case 'MULTIPLE_CHOICE':
        return 'Choose the correct word for the image.';
      case 'FILL_IN_THE_BLANK':
        return 'Select the missing word to complete the sentence.';
      case 'MATCHING':
        return 'Connect the matching words together.';
      case 'WORD_SORTING':
        return 'Sort the words into the correct categories.';
      case 'ODD_ONE_OUT':
        return 'Find the word that doesn\'t belong.';
      case 'SENTENCE_PUZZLE':
        return 'Drag the words to build the sentence.';
      case 'SENTENCE_RECONSTRUCTION':
        return 'Drag the words to build the sentence.';
      default:
        return 'Choose the correct answer.';
    }
  }

  Widget _buildTimerBadge() {
    // For Cumulative Review, show a timer instead of tier badge
    // This is a placeholder - you can add actual timer logic if needed
    return const SizedBox.shrink();
  }

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
    WidgetsBinding.instance.addObserver(this);
    _moduleStartTime = DateTime.now();
    _fetchReviewItems();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _pauseStartTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pauseStartTime != null) {
        _totalPausedDuration += DateTime.now().difference(_pauseStartTime!);
        _pauseStartTime = null;
      }
    }
  }

  int _computeActiveSeconds() {
    if (_moduleStartTime == null) return 0;
    final elapsed = DateTime.now().difference(_moduleStartTime!) - _totalPausedDuration;
    return elapsed.inSeconds.clamp(0, 86400);
  }

  void _prepareCurrentActivityState() {
    _selectedMatchingWord = null;
    _matchingOptions = [];
    _flashcardFlipped = false;
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
      _scrambledWords.addAll(_sentenceTokens(item));
      _scrambledWords.shuffle(Random('${item['wordId'] ?? ''}_scramble'.hashCode));
    } else if (fmt == 'ODD_ONE_OUT') {
      final pos = (item['partOfSpeech'] ?? '').toString().toLowerCase();
      // Find 3 words with a DIFFERENT POS from the target item
      final samePos = _reviewItems
          .where((i) => (i['partOfSpeech'] ?? '').toString().toLowerCase() != pos && i['wordId'] != item['wordId'])
          .take(3)
          .map((i) => Map<String, dynamic>.from(i))
          .toList();
      
      final options = [item, ...samePos];
      options.shuffle(Random('${item['wordId'] ?? ''}_odd'.hashCode));
      _currentOddOneOutOptions = options;
    } else if (fmt == 'MULTIPLE_CHOICE' || fmt == 'IMAGE_MATCHING') {
      final correct = (item['word'] ?? '').toString();
      final level = _wordDifficulties[(item['wordId'] ?? '').toString()] ?? 'LEARNING';
      int distractorCount = 3;
      if (level == 'LEARNING') {
        distractorCount = 2;
      } else if (level == 'FAMILIAR' || level == 'PROFICIENT') {
        distractorCount = 3;
      } else if (level == 'MASTERED') {
        distractorCount = 4;
      }

      final provided = [
        item['mcDistractor1'],
        item['mcDistractor2'],
        item['mcDistractor3'],
      ].whereType<String>().where((value) => value.isNotEmpty && value != correct).toList();

      final distractors = <String>[...provided];
      if (distractors.length < distractorCount) {
        final other = _normalizedReviewItems
            .map((e) => e['word']?.toString() ?? '')
            .where((w) => w.isNotEmpty && w != correct && !distractors.contains(w))
            .toList();
        other.shuffle();
        distractors.addAll(other);
      }
      
      if (distractors.length < distractorCount) {
        final fallback = ['apple', 'house', 'water', 'friend', 'school', 'book', 'tree', 'happy', 'run', 'big', 'cat', 'dog', 'sun', 'moon', 'star'];
        final availableFallback = fallback
            .where((w) => w != correct && !distractors.contains(w))
            .toList()..shuffle();
        distractors.addAll(availableFallback);
      }

      final options = <String>[correct, ...distractors.take(distractorCount)];
      options.shuffle(Random('${item['wordId'] ?? ''}_mc'.hashCode));
      _currentMcOptions = options;
    }
  }

  List<String> _sentenceTokens(Map<String, dynamic> item) {
    final explicit = (item['sentenceArrangementTokens'] as List<dynamic>?)?.map((token) => token.toString()).where((token) => token.trim().isNotEmpty).toList();
    if (explicit != null && explicit.length >= 2) return explicit;

    final rawSentence = (item['exampleSentenceEnglish'] ?? item['example'] ?? '').toString().trim();
    if (rawSentence.isEmpty || rawSentence.startsWith('Match the English') || rawSentence.startsWith('What is the Cebuano')) {
      return const [];
    }

    return rawSentence
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~(?)]'), '')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();
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
      final savedQueue = savedState['queue'] as List<dynamic>?;
      final savedItems = savedState['reviewItems'] as List<dynamic>?;
      if ((savedQueue == null || savedQueue.isEmpty) && (savedItems == null || savedItems.isEmpty)) {
        await LocalStorageService.clearCumulativeReviewState(widget.sessionId);
      } else {
        setState(() {
          _pendingSavedState = Map<String, dynamic>.from(savedState);
          _showResumePrompt = true;
          _loading = false;
        });
        return;
      }
    }

    if (!mounted) return;
    final lessons = Provider.of<LessonProvider>(context, listen: false);
    final crProvider = Provider.of<CumulativeReviewProvider>(context, listen: false);
    List<Map<String, dynamic>> items = [];

    if (widget.allWords.isNotEmpty) {
      // Words passed in directly (e.g. from retry)
      items = widget.allWords.toList();
    } else {
      String? targetLessonId = widget.lessonId;
      if ((targetLessonId == null || targetLessonId.isEmpty) && widget.lessonIds != null && widget.lessonIds!.isNotEmpty) {
        targetLessonId = widget.lessonIds!.first;
      }

      if (targetLessonId != null && targetLessonId.isNotEmpty) {
        items = await lessons.loadModule4Review(targetLessonId);
      }

      if (items.isEmpty) {
        final lessonIds = await _resolveLessonIds(lessons);
        for (final lessonId in lessonIds) {
          if (items.length >= 10) break;
          final batch = await lessons.loadVocabulary(lessonId);
          final mapped = batch.map((w) => w.toJson()).toList();
          for (final word in mapped) {
            if (items.length >= 10) break;
            items.add(word);
          }
        }
        if (items.isEmpty && widget.categoryId.isNotEmpty) {
          final catItems = await lessons.loadCategoryActivity(widget.categoryId);
          items = catItems.take(10).toList();
        }
      }
    }

    // Validate: check non-empty
    if (items.isEmpty) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
      return;
    }

    // NEW: Fetch cross-lesson sentences if this is a Module 4 review (has session)
    if (widget.sessionId.startsWith('review_')) {
      try {
        final session = await crProvider.startSession(widget.lessonIds!.join('_'));
        final sentences = await crProvider.getSessionSentences(session['id']);
        _crossLessonSentences = sentences;
      } catch (e) {
        debugPrint('Failed to load cross lesson sentences: $e');
      }
    }

    // Normalise items
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
        'fitbSentence': item['sentenceCompletionSentence'] ?? item['fitbSentence'],
        'fitbAnswer': item['sentenceCompletionAnswer'] ?? item['fitbAnswer'],
        'matchingSet': item['matchingSet'],
        'sentenceArrangementTokens': item['sentenceArrangementTokens'],
        'imageAssetPath': item['imageAssetPath'],
        'isRefresher': item['isRefresher'] ?? false,
      };
    }).where((it) => (it['wordId'] ?? '').toString().isNotEmpty).toList();

    // Fetch difficulty levels in parallel
    final List<Future<void>> diffFutures = [];
    final Map<String, String> diffMap = {};
    for (final item in list) {
      final wid = item['wordId'].toString();
      diffFutures.add(lessons.getWordDifficulty(wid).then((level) {
        diffMap[wid] = level;
      }));
    }
    await Future.wait(diffFutures);
    setState(() {
      _wordDifficulties = diffMap;
    });

    // Build queue: exactly 3 fixed activities per word (or 1 if sandbox), in order
    _queue.clear();
    _allWordIds = list.map((it) => (it['wordId'] ?? '').toString()).toList();
    for (final item in list) {
      if (widget.isSandbox) {
        _queue.add({...item, 'activityFormat': 'FILL_IN_THE_BLANK'});
      } else {
        final perWordSet = <String>{};
        final formatsToUse = _module4Formats.toList()..shuffle();
        final selectedFormats = formatsToUse.take(3).toList();
        for (final fmt in selectedFormats) {
          String resolvedFmt = fmt;
          
          if (resolvedFmt == 'IMAGE_MATCHING') {
            final hasImage = (item['imageAssetPath'] ?? '').toString().isNotEmpty;
            if (!hasImage) resolvedFmt = 'MULTIPLE_CHOICE';
          }
          if (resolvedFmt == 'SENTENCE_RECONSTRUCTION' && _sentenceTokens(item).length < 2) {
            resolvedFmt = 'MULTIPLE_CHOICE';
          }
          if (resolvedFmt == 'SENTENCE_PUZZLE') {
            // Need a cross lesson sentence
            final wid = item['wordId'].toString();
            final hasCls = _crossLessonSentences.any((cls) => 
                (cls['wordA']?['wordId'] == wid || cls['wordB']?['wordId'] == wid));
            if (!hasCls) resolvedFmt = 'MULTIPLE_CHOICE';
          }

          if (perWordSet.contains(resolvedFmt)) {
            if (!perWordSet.contains('FILL_IN_THE_BLANK')) {
              resolvedFmt = 'FILL_IN_THE_BLANK';
            } else if (!perWordSet.contains('MATCHING')) {
              resolvedFmt = 'MATCHING';
            }
          }

          perWordSet.add(resolvedFmt);
          _queue.add({...item, 'activityFormat': resolvedFmt});
        }
      }
    }

    setState(() {
      _reviewItems = list;
      _loading = false;
      _currentIndex = 0;
      _weightedScore = null;
      _firstPassCorrectCount = 0;
      _retryQueue.clear();
      _results.clear();
      _wordWrongAttempts.clear();
      _attemptedWordIds.clear();
      _maxProgress = 0.0;
      _progressOverride = null;
      _prepareCurrentActivityState();
    });

    LocalStorageService.saveCumulativeReviewState(widget.sessionId, {
      'reviewItems': _reviewItems,
      'queue': _queue,
      'retryQueue': _retryQueue,
      'currentIndex': _currentIndex,
      'results': _results,
      'attemptCounts': _attemptCounts,
      'itemResults': _itemResults,
      'attemptedWordIds': _attemptedWordIds.toList(),
      'inReinforcementPass': _inReinforcementPass,
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
      _itemResults
        ..clear()
        ..addAll((saved['itemResults'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as bool)) ?? {});
      _attemptedWordIds
        ..clear()
        ..addAll((saved['attemptedWordIds'] as List<dynamic>? ?? const []).map((e) => e.toString()));
      if (_attemptedWordIds.isEmpty) {
        // Backward compatibility for sessions saved before attemptedWordIds existed.
        _attemptedWordIds.addAll(_wordWrongAttempts.keys);
      }
      _inReinforcementPass = saved['inReinforcementPass'] as bool? ?? false;
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
    _attemptedWordIds.add(wordId);

    // Record item-level result (derive format from current item if available)
    final cur = _currentItem;
    final fmt = cur != null ? (cur['activityFormat'] ?? '').toString() : '';
    final itemKey = '${wordId}_$fmt';

    if (!correct) {
      // Increment penalty at word level
      _wordWrongAttempts[wordId] = (_wordWrongAttempts[wordId] ?? 0) + 1;
    }

    // Record the item-level correctness
    _itemResults[itemKey] = correct;

    // Record word-level first-pass correctness only once on first recorded correct with no prior wrongs
    if (!_results.containsKey(wordId)) {
      _results[wordId] = correct;
      if (correct && (_wordWrongAttempts[wordId] ?? 0) == 0) {
        _firstPassCorrectCount++;
      }
    }
  }

  void _nextItem() {
    setState(() {
      _currentIndex++;
      _prepareCurrentActivityState();
    });

    // If we've completed the initial pass over the queue, either start reinforcement pass (sandbox only) or finish
    if (_currentIndex >= _queue.length) {
      if (!_inReinforcementPass && widget.isSandbox) {
        _onFirstPassComplete();
      } else {
        _finishReview();
      }
    }
  }

  void _onFirstPassComplete() {
    if (!widget.isSandbox) {
      _finishReview();
      return;
    }

    // Build reinforcement queue from items that were answered incorrectly on first pass
    _retryQueue.clear();
    for (final item in _queue) {
      final key = _itemKeyFor(item);
      final ok = _itemResults[key] ?? false;
      if (!ok) {
        _retryQueue.add(Map<String, dynamic>.from(item));
      }
    }

    if (_retryQueue.isEmpty) {
      // No reinforcement needed
      _finishReview();
      return;
    }

    // Prepare reinforcement pass: replace queue with retryQueue and reset indices
    setState(() {
      _inReinforcementPass = true;
      _queue
        ..clear()
        ..addAll(_retryQueue);
      _currentIndex = 0;
      _prepareCurrentActivityState();
      // reset per-item attempt counts for reinforcement pass
      _attemptCounts.clear();
    });
  }

  Future<void> _finishReview() async {
    // Animate progress to 100%
    setState(() { _progressOverride = 1.0; });
    await Future.delayed(const Duration(milliseconds: 450));

    // Compute final score using unified penalty system
    final wordIds = _allWordIds.isNotEmpty
        ? _allWordIds
        : _reviewItems.map((it) => (it['wordId'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    final cumulativeReviewScore = ScoringService.calculateCumulativeScore(_wordWrongAttempts, wordIds);
    _weightedScore = cumulativeReviewScore;
    // NOTE: 70% is the mixed review mastery pass gate (UC-4.2).
    // It is intentionally independent of the 80% gamification lesson-complete bonus threshold (UC-4.1).
    final passed = ScoringService.isPassing(cumulativeReviewScore);

    // Build per-word breakdown for storage
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

    // Persist breakdown details
    await LocalStorageService.saveCumulativeReviewScoreDetails(widget.sessionId, {
      'wordIds': wordIds,
      'wordWrongAttempts': Map<String, dynamic>.from(_wordWrongAttempts),
      'wordBreakdown': wordBreakdown,
      'finalScore': cumulativeReviewScore,
      'passed': passed,
      'totalWords': wordIds.length,
      'masteredCount': wordIds.where((id) => (_wordWrongAttempts[id] ?? 0) == 0).length,
    });

    if (!mounted) return;

    final lessons = Provider.of<LessonProvider>(context, listen: false);
    final lessonIds = await _resolveLessonIds(lessons);

    int total = wordIds.length;
    int mastered = wordIds.where((id) => (_wordWrongAttempts[id] ?? 0) == 0).length;
    List<String> missed = wordIds.where((id) => (_wordWrongAttempts[id] ?? 0) > 0).toList();

    final int activeSeconds = _computeActiveSeconds();
    if (!widget.isSandbox && widget.lessonId != null) {
      try {
        await lessons.persistModuleScore(
          widget.lessonId!,
          4,
          mastered,
          total,
          isSandbox: false,
          sessionId: widget.sessionId,
          timeSeconds: activeSeconds,
        );
      } catch (e) {
        debugPrint('Module 4 score sync failed: $e');
      }
    }

    if (!widget.isSandbox) {
      await LocalStorageService.saveCumulativeReviewCompleted(
        widget.categoryId,
        cumulativeReviewScore,
        mastered,
        total,
        widget.sessionId,
        missed,
        widget.allWords,
      );

      if (passed) {
        // Call backend mastery endpoint
        try {
          await lessons.submitMastery(
            categoryId: widget.categoryId,
            lessonIds: lessonIds,
            lessonScore: cumulativeReviewScore,
            cumulativeReviewScore: cumulativeReviewScore,
            finalScore: cumulativeReviewScore,
            passed: true,
            totalItems: total,
            masteredCount: mastered,
            missedWordIds: missed,
          );
        } catch (e) {
          debugPrint('submitMastery failed (non-fatal): $e');
        }
        await LocalStorageService.clearCumulativeReviewState(widget.sessionId);
        await LocalStorageService.clearReviewCompletionState(widget.sessionId);
      } else {
        await LocalStorageService.saveReviewCompletionState(widget.sessionId, {
          'cumulativeReviewScore': cumulativeReviewScore,
          'finalScore': cumulativeReviewScore,
          'passed': false,
        });
      }
    } else {
      // Sandbox completion
      try {
        await lessons.completeSandbox(widget.sessionId, finalScore: cumulativeReviewScore);
      } catch (e) {
        debugPrint('completeSandbox failed (non-fatal): $e');
      }
    }

    _isPerfectFirstAttempt = (cumulativeReviewScore >= 70.0 && cumulativeReviewScore >= 100.0 && _reviewAttemptCount == 0);

    if (!passed) {
      if (!mounted) return;
      setState(() {
        _showFailurePrompt = true;
        _failedFinalScore = cumulativeReviewScore;
      });
      return;
    }

    if (!mounted) return;
    context.go(
      '/session/${widget.sessionId}/lesson-score',
      extra: {
        'sessionId': widget.sessionId,
        'lessonId': widget.lessonId ?? '',
        'categoryId': widget.categoryId,
        'lessonTitle': 'Lesson Complete',
        'allWords': _normalizedReviewItems,
        'overallScore': cumulativeReviewScore,
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
      _inReinforcementPass = false;
      _checked = false;
      _showFeedback = false;
    });
    _fetchReviewItems();
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
                    const MascotVisual(type: MascotType.bibo, size: 90, isSad: true),
                    const SizedBox(height: 16),
                    const Text(
                      'Keep Trying!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score: ${(_failedFinalScore ?? _weightedScore ?? 0.0).toStringAsFixed(1)}%. You need at least 70% to pass — let\'s try again!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _restartModule4,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _checkAnswer() {
    if (_currentIndex >= _queue.length) return;
    final item = _queue[_currentIndex];
    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();
    final wordId = (item['wordId'] ?? '').toString();

    bool correct = false;
    String correctAns = '';

    if (fmt == 'MULTIPLE_CHOICE' || fmt == 'IMAGE_MATCHING') {
      final correctWord = (item['word'] ?? '').toString();
      final options = _currentMcOptions;
      if (_selectedOptionIndex != null && _selectedOptionIndex! >= 0 && _selectedOptionIndex! < options.length) {
        final selected = options[_selectedOptionIndex!];
        correct = selected == correctWord;
      }
      correctAns = correctWord;
    } else if (fmt == 'FILL_IN_THE_BLANK') {
      final correctWord = (item['word'] ?? '').toString();
      final userAns = _typingController.text.trim();
      correct = userAns.toLowerCase() == correctWord.toLowerCase();
      correctAns = correctWord;
    } else if (fmt == 'LISTENING_TYPING') {
      final answer = (item['fitbAnswer'] ?? item['word'] ?? '').toString().trim();
      final userAns = _typingController.text.trim();
      correct = userAns.toLowerCase() == answer.toLowerCase();
      correctAns = answer;
    } else if (fmt == 'SENTENCE_RECONSTRUCTION') {
      final answerTokens = _sentenceTokens(item);
      final expected = answerTokens.join(' ').toLowerCase().trim();
      final learner = _assembledWords.join(' ').toLowerCase().trim();
      correct = learner == expected;
      correctAns = answerTokens.join(' ');
    } else if (fmt == 'SENTENCE_PUZZLE') {
      final wid = item['wordId'].toString();
      final cls = _crossLessonSentences.firstWhere((c) => 
          (c['wordA']?['wordId'] == wid || c['wordB']?['wordId'] == wid), 
          orElse: () => null);
      if (cls != null) {
        final answerStr = (cls['sentenceText'] ?? '').toString().replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~(?)]'), '').replaceAll(RegExp(r'\s+'), '').toLowerCase();
        final assembledStr = _assembledWords.join('').toLowerCase();
        correct = answerStr == assembledStr;
        correctAns = cls['sentenceText'] ?? '';
      }
    } else if (fmt == 'WORD_SORTING') {
      final pos = (item['partOfSpeech'] ?? '').toString().toLowerCase();
      final options = ['noun', 'verb', 'adjective'];
      if (_selectedOptionIndex != null && _selectedOptionIndex! >= 0 && _selectedOptionIndex! < options.length) {
        correct = options[_selectedOptionIndex!] == pos;
      }
      correctAns = pos;
    } else if (fmt == 'ODD_ONE_OUT') {
      final correctWord = (item['word'] ?? '').toString();
      final options = _currentOddOneOutOptions;
      if (_selectedOptionIndex != null && _selectedOptionIndex! >= 0 && _selectedOptionIndex! < options.length) {
        final selectedWord = (options[_selectedOptionIndex!]['word'] ?? '').toString();
        correct = selectedWord == correctWord;
      }
      correctAns = correctWord;
    } else if (fmt == 'MATCHING' || fmt == 'TRANSLATION_MATCHING') {
      final correctWord = (item['word'] ?? '').toString();
      correct = _selectedMatchingWord == correctWord;
      correctAns = correctWord;
    } else if (fmt == 'FLASHCARD_RECALL') {
      correct = _flashcardFlipped;
      correctAns = (item['word'] ?? '').toString();
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
      _nextItem();
    });
  }

  Widget _buildBottomPanel(ThemeData theme) {
    if (_currentIndex >= _queue.length) return const SizedBox.shrink();
    final item = _queue[_currentIndex];
    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();

    String? getLearnerSentenceRestatement() {
      String learnerAns = '';
      if (fmt == 'MULTIPLE_CHOICE' || fmt == 'IMAGE_MATCHING') {
        if (_selectedOptionIndex != null && _selectedOptionIndex! >= 0 && _selectedOptionIndex! < _currentMcOptions.length) {
          learnerAns = _currentMcOptions[_selectedOptionIndex!];
        }
      } else if (fmt == 'FILL_IN_THE_BLANK' || fmt == 'LISTENING_TYPING') {
        learnerAns = _typingController.text.trim();
      } else if (fmt == 'SENTENCE_RECONSTRUCTION') {
        return _assembledWords.join(' ');
      }

      if (fmt == 'FILL_IN_THE_BLANK') {
        final sentence = (item['fitbSentence'] ?? item['sentenceCompletionSentence'] ?? '').toString();
        if (sentence.isNotEmpty) {
          final blankRegex = RegExp(r'_{2,}|-{2,}|\[_\]');
          if (sentence.contains(blankRegex)) {
            return sentence.replaceFirst(blankRegex, learnerAns.isEmpty ? '___' : learnerAns);
          }
          return '$sentence (Answer: $learnerAns)';
        }
      }
      return null;
    }

    String? getCorrectSentenceRestatement() {
      if (fmt == 'SENTENCE_RECONSTRUCTION') {
        final answerTokens = _sentenceTokens(item);
        return answerTokens.join(' ');
      }
      if (fmt == 'FILL_IN_THE_BLANK') {
        final sentence = (item['fitbSentence'] ?? item['sentenceCompletionSentence'] ?? '').toString();
        final correctAns = (item['fitbAnswer'] ?? item['word'] ?? '').toString();
        if (sentence.isNotEmpty) {
          final blankRegex = RegExp(r'_{2,}|-{2,}|\[_\]');
          if (sentence.contains(blankRegex)) {
            return sentence.replaceFirst(blankRegex, correctAns);
          }
          return '$sentence (Answer: $correctAns)';
        }
      }
      return null;
    }

    bool isActionEnabled = false;
    if (fmt == 'MULTIPLE_CHOICE' || fmt == 'IMAGE_MATCHING') {
      isActionEnabled = _selectedOptionIndex != null;
    } else if (fmt == 'FILL_IN_THE_BLANK') {
      isActionEnabled = _typingController.text.trim().isNotEmpty;
    } else if (fmt == 'LISTENING_TYPING') {
      isActionEnabled = _typingController.text.trim().isNotEmpty;
    } else if (fmt == 'SENTENCE_RECONSTRUCTION') {
      isActionEnabled = _assembledWords.isNotEmpty;
    } else if (fmt == 'MATCHING' || fmt == 'TRANSLATION_MATCHING') {
      isActionEnabled = _selectedMatchingWord != null;
    } else if (fmt == 'FLASHCARD_RECALL') {
      isActionEnabled = _flashcardFlipped;
    }

    if (!_showFeedback) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isActionEnabled ? _checkAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06A6FF), // Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'CHECK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Feedback State
    final Color panelBg = _isAnswerCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final Color textColor = _isAnswerCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final Color btnBg = _isAnswerCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Container(
      color: panelBg,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _isAnswerCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: textColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAnswerCorrect ? 'Correct (+10 pts)' : 'Incorrect',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    () {
                      final learnerSentence = getLearnerSentenceRestatement();
                      final correctSentence = getCorrectSentenceRestatement();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (learnerSentence != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Your sentence: "$learnerSentence"',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                          if (!_isAnswerCorrect && correctSentence != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Correct sentence: "$correctSentence"',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ] else if (!_isAnswerCorrect && correctSentence == null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Correct answer: $_lastCorrectAnswer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      );
                    }(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 50),
              elevation: 0,
            ),
            child: const Text(
              'CONTINUE',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ],
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
      case 'WORD_SORTING':
        return _buildWordSorting(item);
      case 'ODD_ONE_OUT':
        return _buildOddOneOut(item);
      case 'SENTENCE_PUZZLE':
        return _buildSentencePuzzle(item);
      default:
        return _buildMultipleChoice(item);
    }
  }

  Widget _buildFlashcardRecall(Map<String, dynamic> item) {
    final word = (item['word'] ?? '').toString();
    final definition = (item['definition'] ?? '').toString();
    final cebuanoMeaning = (item['cebuanoMeaning'] ?? '').toString();
    final example = (item['example'] ?? '').toString();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      Text('Cebuano: $cebuanoMeaning', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0369A1), height: 1.45)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildListeningTyping(Map<String, dynamic> item) {
    final answer = (item['fitbAnswer'] ?? item['word'] ?? '').toString().trim();
    final prompt = (item['fitbSentence'] ?? item['example'] ?? '').toString().trim();
    final cebuanoMeaning = (item['cebuanoMeaning'] ?? '').toString();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Listening and typing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
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
                      'Cebuano Translation:',
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
              enabled: !_checked,
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
              onPressed: () => _playAudio('Listen carefully, then type what you hear.'),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Hear it again'),
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

  Widget _buildSentenceReconstruction(Map<String, dynamic> item) {
    final answerTokens = _sentenceTokens(item);
    if (_scrambledWords.isEmpty && _assembledWords.isEmpty) {
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
            // FIXED: Show Cebuano sentence first (meaning/context), then ask to arrange English words
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
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _scrambledWords.remove(word);
                            _assembledWords.add(word);
                          });
                        },
                        child: _wordChip(word),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 14),
            Text('Sentence preview: ${sentencePreview.isEmpty ? '...' : sentencePreview}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMatching(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final imagePath = (item['imageAssetPath'] ?? '').toString();
    final options = _currentMcOptions;

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
              child: CustomImageViewer(
                imagePath: imagePath,
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
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final opt = entry.value;
              final isSelected = _selectedOptionIndex == index;
              Color cardBg = Colors.white;
              Color borderColor = const Color(0xFFE2E8F0);
              Color textColor = const Color(0xFF334155);

              if (_checked) {
                if (opt == correct) {
                  cardBg = const Color(0xFFF0FDF4);
                  borderColor = const Color(0xFF22C55E);
                  textColor = const Color(0xFF15803D);
                } else if (isSelected) {
                  cardBg = const Color(0xFFFEF2F2);
                  borderColor = const Color(0xFFEF4444);
                  textColor = const Color(0xFFB91C1C);
                }
              } else if (isSelected) {
                cardBg = const Color(0xFFEFF6FF);
                borderColor = const Color(0xFF3B82F6);
                textColor = const Color(0xFF1D4ED8);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: _checked
                      ? null
                      : () {
                          setState(() {
                            _selectedOptionIndex = index;
                          });
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
    final options = _currentMcOptions;

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
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final opt = entry.value;
              final isSelected = _selectedOptionIndex == index;
              Color cardBg = Colors.white;
              Color borderColor = const Color(0xFFE2E8F0);
              Color textColor = const Color(0xFF334155);

              if (_checked) {
                if (opt == correct) {
                  cardBg = const Color(0xFFF0FDF4);
                  borderColor = const Color(0xFF22C55E);
                  textColor = const Color(0xFF15803D);
                } else if (isSelected) {
                  cardBg = const Color(0xFFFEF2F2);
                  borderColor = const Color(0xFFEF4444);
                  textColor = const Color(0xFFB91C1C);
                }
              } else if (isSelected) {
                cardBg = const Color(0xFFEFF6FF);
                borderColor = const Color(0xFF3B82F6);
                textColor = const Color(0xFF1D4ED8);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: _checked
                      ? null
                      : () {
                          setState(() {
                            _selectedOptionIndex = index;
                          });
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
    final answer = correct;
    final definition = (item['definition'] ?? item['cebuanoMeaning'] ?? '').toString();

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
              'Fill in the missing word',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.7),
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
                      'Cebuano Translation:',
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
              controller: _typingController,
              enabled: !_checked,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Answer',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF06A6FF), width: 2)),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _playAudio(correct),
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

  Widget _buildSentencePuzzle(Map<String, dynamic> item) {
    final wid = item['wordId'].toString();
    final cls = _crossLessonSentences.firstWhere((c) => 
        (c['wordA']?['wordId'] == wid || c['wordB']?['wordId'] == wid), 
        orElse: () => null);

    if (cls == null) return _buildFailurePrompt(Theme.of(context));

    final sentenceText = (cls['sentenceText'] ?? '').toString();
    final sentenceTranslation = (cls['sentenceTranslation'] ?? '').toString();

    // Parse the tokens if not already done in _prepareCurrentActivityState
    if (_scrambledWords.isEmpty && _assembledWords.isEmpty) {
       final tokens = sentenceText.replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~(?)]'), '').split(' ').where((w) => w.trim().isNotEmpty).toList();
       _scrambledWords.addAll(tokens);
       _scrambledWords.shuffle(Random('${wid}_puzzle'.hashCode));
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
            const Text(
              'Sentence Puzzle',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.7),
            ),
            const SizedBox(height: 10),
            if (sentenceTranslation.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cebuano Translation:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1))),
                    const SizedBox(height: 6),
                    CebuanoTextHighlighter(
                      text: sentenceTranslation,
                      highlightWord: (item['cebuanoMeaning'] ?? item['definition'] ?? '').toString(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.45),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
              constraints: const BoxConstraints(minHeight: 100),
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _assembledWords.asMap().entries.map((e) {
                  return GestureDetector(
                    onTap: _checked ? null : () {
                      setState(() {
                        _scrambledWords.add(e.value);
                        _assembledWords.removeAt(e.key);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))]),
                      child: Text(e.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Tap words to build the sentence:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scrambledWords.asMap().entries.map((e) {
                return GestureDetector(
                  onTap: _checked ? null : () {
                    setState(() {
                      _assembledWords.add(e.value);
                      _scrambledWords.removeAt(e.key);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.5), blurRadius: 0, offset: const Offset(0, 3))]),
                    child: Text(e.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordSorting(Map<String, dynamic> item) {
    final word = (item['word'] ?? '').toString();
    final pos = (item['partOfSpeech'] ?? '').toString();
    final translation = (item['cebuanoMeaning'] ?? item['definition'] ?? '').toString();
    
    // If we haven't selected an option yet, _selectedOptionIndex can hold the index of the tapped button (0=Noun, 1=Verb, 2=Adjective)
    final options = ['Noun', 'Verb', 'Adjective'];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              word,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.normal, color: Color(0xFF0F172A)),
            ),
            if (translation.isNotEmpty) ...[
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
                    const Text('Cebuano Translation:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1))),
                    const SizedBox(height: 6),
                    Text(translation, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text('What part of speech is this word?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ...options.asMap().entries.map((e) {
              final idx = e.key;
              final text = e.value;
              final isSelected = _selectedOptionIndex == idx;
              
              Color bgColor = Colors.white;
              Color borderColor = const Color(0xFFE2E8F0);
              Color textColor = const Color(0xFF334155);
              
              if (isSelected) {
                bgColor = const Color(0xFFF0F9FF);
                borderColor = const Color(0xFF0EA5E9);
                textColor = const Color(0xFF0369A1);
              }

              if (_checked) {
                if (text.toLowerCase() == pos.toLowerCase()) {
                  bgColor = const Color(0xFFDCFCE7);
                  borderColor = const Color(0xFF22C55E);
                  textColor = const Color(0xFF15803D);
                } else if (isSelected && text.toLowerCase() != pos.toLowerCase()) {
                  bgColor = const Color(0xFFFEE2E2);
                  borderColor = const Color(0xFFEF4444);
                  textColor = const Color(0xFFB91C1C);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _checked ? null : () => setState(() => _selectedOptionIndex = idx),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: isSelected || (_checked && text.toLowerCase() == pos.toLowerCase()) ? 2 : 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor))),
                        if (_checked && text.toLowerCase() == pos.toLowerCase())
                          const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                        if (_checked && isSelected && text.toLowerCase() != pos.toLowerCase())
                          const Icon(Icons.cancel, color: Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOddOneOut(Map<String, dynamic> item) {
    final correctWord = (item['word'] ?? '').toString();
    
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._currentOddOneOutOptions.asMap().entries.map((e) {
              final idx = e.key;
              final opt = e.value;
              final word = (opt['word'] ?? '').toString();
              final translation = (opt['cebuanoMeaning'] ?? opt['definition'] ?? '').toString();
              
              final isSelected = _selectedOptionIndex == idx;
              
              Color bgColor = Colors.white;
              Color borderColor = const Color(0xFFE2E8F0);
              Color textColor = const Color(0xFF334155);
              Color translationColor = const Color(0xFF64748B);
              
              if (isSelected) {
                bgColor = const Color(0xFFF0F9FF);
                borderColor = const Color(0xFF0EA5E9);
                textColor = const Color(0xFF0369A1);
                translationColor = const Color(0xFF0284C7);
              }

              if (_checked) {
                if (word == correctWord) {
                  bgColor = const Color(0xFFDCFCE7);
                  borderColor = const Color(0xFF22C55E);
                  textColor = const Color(0xFF15803D);
                  translationColor = const Color(0xFF166534);
                } else if (isSelected && word != correctWord) {
                  bgColor = const Color(0xFFFEE2E2);
                  borderColor = const Color(0xFFEF4444);
                  textColor = const Color(0xFFB91C1C);
                  translationColor = const Color(0xFF991B1B);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _checked ? null : () => setState(() => _selectedOptionIndex = idx),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: isSelected || (_checked && word == correctWord) ? 2 : 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(word, style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: textColor)),
                              if (translation.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(translation, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: translationColor)),
                              ],
                            ],
                          ),
                        ),
                        if (_checked && word == correctWord)
                          const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                        if (_checked && isSelected && word != correctWord)
                          const Icon(Icons.cancel, color: Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                ),
              );
            }),
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
                    onPressed: _checked
                        ? null
                        : () {
                            setState(() {
                              _selectedMatchingWord = choice;
                            });
                          },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
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

    if (_hasError || (!_loading && _queue.isEmpty && !_showResumePrompt)) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FBF7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Cumulative Review'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                const Text('No Review Words Available', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                const Text('Unable to load review words for this session. Please select a lesson from Home to try again.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06A6FF),
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

    if (_showFailurePrompt) {
      return _buildFailurePrompt(Theme.of(context));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final provider = Provider.of<LessonProvider>(context, listen: false);
        provider.recordPartialModuleTime(widget.sessionId, 4, _computeActiveSeconds(), lessonId: widget.lessonId);
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () {
              final provider = Provider.of<LessonProvider>(context, listen: false);
              provider.recordPartialModuleTime(widget.sessionId, 4, _computeActiveSeconds(), lessonId: widget.lessonId);
              context.go('/home');
            },
          ),
          title: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: Builder(
                builder: (context) {
                  int getTierPoints(String tier) {
                    switch (tier.toUpperCase()) {
                      case 'LEARNING': return 0;
                      case 'FAMILIAR': return 1;
                      case 'PROFICIENT': return 2;
                      case 'MASTERED': return 3;
                      default: return 0;
                    }
                  }

                  int totalMaxPoints = _allWordIds.length * 3;
                  int currentPoints = 0;
                  for (final id in _allWordIds) {
                    final tier = _wordDifficulties[id] ?? 'LEARNING';
                    currentPoints += getTierPoints(tier);
                  }
                  
                  final calculatedProgress = totalMaxPoints == 0 ? 0.0 : (currentPoints / totalMaxPoints);
                  if (calculatedProgress > _maxProgress) _maxProgress = calculatedProgress;
                  final progressVal = _progressOverride ?? _maxProgress;
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progressVal),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.linear,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Builder(
                  builder: (context) {
                    final totalWords = _allWordIds.isNotEmpty ? _allWordIds.length : (_reviewItems.length);
                    final attemptedWordCount = _allWordIds.isNotEmpty
                      ? _allWordIds.where((id) => _attemptedWordIds.contains(id)).length
                      : _attemptedWordIds.length;
                    return Text(
                      '$attemptedWordCount/$totalWords',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF06A6FF)))
            : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Mascot Speech Bubble
                          MascotBubble(
                            mascotName: _getMascotName(),
                            speechText: _getInstructionText(),
                            ttsText: _getInstructionText(),
                            isSad: _checked && !_isAnswerCorrect,
                            isCelebrating: _checked && _isAnswerCorrect,
                          ),
                          const SizedBox(height: 16),
                          // Timer badge for Cumulative Review
                          _buildTimerBadge(),
                          const SizedBox(height: 16),
                          // Activity content
                          _buildCurrentActivity(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomPanel(Theme.of(context)),
                ],
              ),
            ),
      ),
    );
  }

  // Removed unused _goBackWithAnimation helper to satisfy analyzer.

  // _buildResumeRoute removed — navigation now uses direct pushes to MasteryResultScreen where needed.
}
