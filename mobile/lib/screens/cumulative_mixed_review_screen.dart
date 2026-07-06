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
import '../widgets/custom_image_viewer.dart';
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
  final Map<String, int> _attemptCounts = {}; // kept for compat
  final Map<String, int> _wordWrongAttempts = {}; // unified penalty tracker
  final Map<String, bool> _itemResults = {}; // key: wordId_activityFormat -> correctness
  final Set<String> _attemptedWordIds = <String>{};
  Map<String, dynamic>? _pendingSavedState;
  bool _showResumePrompt = false;
  bool _showFailurePrompt = false;
  final List<Map<String, dynamic>> _retryQueue = [];
  int _firstPassCorrectCount = 0;
  double? _failedFinalScore;
  double _maxProgress = 0.0;
  double? _progressOverride;
  List<String> _allWordIds = []; // ordered list of 10 word IDs
  bool _inReinforcementPass = false;
  List<Map<String, dynamic>> _wordBreakdown = [];

  // Feedback State
  bool _checked = false;
  bool _isAnswerCorrect = false;
  bool _showFeedback = false;
  String _lastCorrectAnswer = '';
  int? _selectedOptionIndex;
  List<String> _currentMcOptions = [];

  // Fixed activity order per word
  static const List<String> _fixedActivityOrder = [
    'IMAGE_MATCHING',
    'FILL_IN_THE_BLANK',
    'SENTENCE_RECONSTRUCTION',
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

  List<Map<String, dynamic>> get _normalizedReviewItems =>
      _reviewItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();

  String _itemKeyFor(Map<String, dynamic>? item) {
    if (item == null) return '';
    final wid = (item['wordId'] ?? '').toString();
    final fmt = (item['activityFormat'] ?? '').toString();
    return '${wid}_$fmt';
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
    } else if (fmt == 'MULTIPLE_CHOICE' || fmt == 'IMAGE_MATCHING') {
      final correct = (item['word'] ?? '').toString();
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
      options.shuffle(Random('${item['wordId'] ?? ''}_mc'.hashCode));
      _currentMcOptions = options;
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
      setState(() {
        _pendingSavedState = Map<String, dynamic>.from(savedState);
        _showResumePrompt = true;
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    final lessons = Provider.of<LessonProvider>(context, listen: false);
    List<Map<String, dynamic>> items = [];

    if (widget.allWords.isNotEmpty) {
      // Words passed in directly (e.g. from retry)
      items = widget.allWords.take(10).toList();
    } else {
      // Sequential loading: fetch lesson 1 first, then lesson 2
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

    // Validate: we need exactly 10 words
    if (items.isEmpty) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No vocabulary words found for review.')),
        );
      }
      return;
    }

    // Normalise items
    final list = items.take(10).map((e) {
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
      };
    }).where((it) => (it['wordId'] ?? '').toString().isNotEmpty).toList();

    // Build queue: exactly 3 fixed activities per word (or 1 if sandbox), in order
    _queue.clear();
    _allWordIds = list.map((it) => (it['wordId'] ?? '').toString()).toList();
    for (final item in list) {
      if (widget.isSandbox) {
        _queue.add({...item, 'activityFormat': 'FILL_IN_THE_BLANK'});
      } else {
        final perWordSet = <String>{};
        for (final fmt in _fixedActivityOrder) {
          String resolvedFmt = fmt;
          // IMAGE_MATCHING falls back to MULTIPLE_CHOICE if no image
          if (resolvedFmt == 'IMAGE_MATCHING') {
            final hasImage = (item['imageAssetPath'] ?? '').toString().isNotEmpty;
            if (!hasImage) resolvedFmt = 'MULTIPLE_CHOICE';
          }
          // SENTENCE_RECONSTRUCTION falls back to MULTIPLE_CHOICE if not enough tokens
          if (resolvedFmt == 'SENTENCE_RECONSTRUCTION' && _sentenceTokens(item).length < 2) {
            resolvedFmt = 'MULTIPLE_CHOICE';
          }

          // Avoid duplicate activity types per word. If duplicate, prefer MULTIPLE_CHOICE as a substitute.
          if (perWordSet.contains(resolvedFmt)) {
            if (!perWordSet.contains('MULTIPLE_CHOICE')) {
              resolvedFmt = 'MULTIPLE_CHOICE';
            } else if (!perWordSet.contains('FLASHCARD_RECALL')) {
              resolvedFmt = 'FLASHCARD_RECALL';
            } else {
              // As a last resort, keep original but we won't duplicate in set
              // find a safe unique fallback
              resolvedFmt = 'FLASHCARD_RECALL';
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

    _wordBreakdown = wordBreakdown;

    if (!mounted) return;

    final lessons = Provider.of<LessonProvider>(context, listen: false);
    final lessonIds = await _resolveLessonIds(lessons);

    int total = wordIds.length;
    int mastered = wordIds.where((id) => (_wordWrongAttempts[id] ?? 0) == 0).length;
    List<String> missed = wordIds.where((id) => (_wordWrongAttempts[id] ?? 0) > 0).toList();

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

    if (!passed) {
      if (!mounted) return;
      setState(() {
        _showFailurePrompt = true;
        _failedFinalScore = cumulativeReviewScore;
      });
      return;
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
        allWords: _normalizedReviewItems,
        masteryScore: _weightedScore,
        wordBreakdown: _wordBreakdown,
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
                            allWords: _normalizedReviewItems,
                            masteryScore: score,
                            wordBreakdown: _wordBreakdown,
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
                      _isAnswerCorrect ? 'Nice!' : 'Incorrect',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (!_isAnswerCorrect) ...[
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
            const Text('Flashcard recall', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
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
                                      _currentItem == null ? 'Preparing your review...' : 'Now let\'s test all that you have learned!',
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
                        Builder(
                          builder: (context) {
                            // Word-based progress: count unique words that were attempted (correct or wrong)
                            final totalWords = _allWordIds.isNotEmpty ? _allWordIds.length : (_reviewItems.length);
                            final attemptedWordCount = _allWordIds.isNotEmpty
                                ? _allWordIds.where((id) => _attemptedWordIds.contains(id)).length
                                : _attemptedWordIds.length;
                            final calculatedProgress = totalWords > 0 ? attemptedWordCount / totalWords : 0.0;
                            if (calculatedProgress > _maxProgress) _maxProgress = calculatedProgress;
                            return Text(
                              '$attemptedWordCount / $totalWords words',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final totalWords = _allWordIds.isNotEmpty ? _allWordIds.length : (_reviewItems.length);
                        final attemptedWordCount = _allWordIds.isNotEmpty
                          ? _allWordIds.where((id) => _attemptedWordIds.contains(id)).length
                          : _attemptedWordIds.length;
                        final calculatedProgress = totalWords > 0 ? attemptedWordCount / totalWords : 0.0;
                        if (calculatedProgress > _maxProgress) _maxProgress = calculatedProgress;
                        final progressVal = _progressOverride ?? _maxProgress;
                        return Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFFAF1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: progressVal),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.linear,
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  minHeight: 12,
                                  backgroundColor: const Color(0x00FFFFFF),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                );
                              },
                            ),
                          ),
                        );
                      },
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
