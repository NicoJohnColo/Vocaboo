import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import 'cumulative_mixed_review_screen.dart';
import '../models/vocabulary_word_model.dart';
import '../models/pronunciation_attempt_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/streaming_stt_service.dart';
import '../services/pronunciation_matcher.dart';
import '../services/local_storage_service.dart';

enum Phase {
  sentenceActivity,
  pronunciationFeedback,
  confusableDistinction,
  summary,
}

enum ActivityFormat {
  completion,
  rearrangement,
}

class SentenceBuildingScreen extends StatefulWidget {
  final String sessionId;
  final String lessonId;
  final String categoryId;
  final String? lessonTitle;
  final int moduleNumber;
  final List<Map<String, dynamic>> allWords;
  final bool isSandbox;

  const SentenceBuildingScreen({
    super.key,
    required this.sessionId,
    required this.lessonId,
    required this.categoryId,
    this.lessonTitle,
    required this.allWords,
    this.moduleNumber = 3,
    this.isSandbox = false,
  });

  @override
  State<SentenceBuildingScreen> createState() => _SentenceBuildingScreenState();
}

class _SentenceBuildingScreenState extends State<SentenceBuildingScreen> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final SttService _sttService = SttService();
  final TtsService _ttsService = TtsService();
  final StreamingSttService _streamingSttService = StreamingSttService();
  final ValueNotifier<String> _liveTranscriptNotifier = ValueNotifier<String>('');
  StreamSubscription<double>? _amplitudeSubscription;
  Timer? _silenceTimer;
  DateTime? _lastSpeechAt;
  DateTime? _recordingStartedAt;
  bool _recordingSessionActive = false;
  bool _disposed = false;

  // Lesson data
  List<VocabularyWordModel> _words = [];
  bool _isLoading = true;
  String? _error;

  // Queues and Progression State
  List<VocabularyWordModel> _queue = [];
  final Set<String> _seenWordIds = {};
  final List<VocabularyWordModel> _failedSentenceWords = [];
  bool _isReinforcementPass = false;
  Phase _currentPhase = Phase.sentenceActivity;
  int _totalUniqueWords = 0;
  int _phaseWordCount = 0;
  int _initialPassCompletedCount = 0;
  int _reinforcementCompletedCount = 0;
  bool _confusableScreenShown = false;

  // Stats for Summary Screen
  int _initialPassCorrectCount = 0;
  int _reinforcementPassCorrectCount = 0;
  int _totalPronunciationAttempts = 0;
  final int _totalPronunciationWords = 0;
  List<Map<String, dynamic>> _confusablePairs = [];
  final Map<String, bool> _confusableMastery = {};

  // Inline confusable distinction state
  Map<String, dynamic>? _activeConfusablePair;
  String? _confusableSelectedForA;
  String? _confusableSelectedForB;
  bool _confusableChecked = false;
  bool _confusableCorrect = false;

  // Per-word pronunciation tracking for score screen
  final Map<String, bool> _wordPronunciationCorrect = {}; // wordId -> isCorrect
  final Map<String, int> _wordPronunciationAttempts = {}; // wordId -> attemptCount

  // Current item state
  late VocabularyWordModel _currentWord;
  ActivityFormat _currentFormat = ActivityFormat.completion;
  bool _isChecked = false;
  bool _isCorrect = false;

  // Format 1: Completion Options
  List<String> _completionOptions = [];
  String? _selectedCompletionWord;

  // Format 2: Rearrangement Chips
  List<String> _assembledWords = [];
  List<String> _scrambledWords = [];

  // Pronunciation feedback state
  bool _isRecording = false;
  bool _isEvaluating = false;
  int _pronunciationAttempt = 1;
  PronunciationAttemptModel? _attemptResult;
  late int _maxAttempts;

  int _attemptLimitForModule() {
    return 3; // Always 3 attempts for pronunciation
  }

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadLessonData();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initialize();
    await _streamingSttService.initialize();
  }

  @override
  void dispose() {
    _disposed = true;
    _recordingSessionActive = false;
    _amplitudeSubscription?.cancel();
    _silenceTimer?.cancel();
    _ttsService.stop();
    _sttService.dispose();
    _streamingSttService.dispose();
    _liveTranscriptNotifier.dispose();
    _recorderService.dispose();
    super.dispose();
  }

  Future<void> _loadLessonData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      List<VocabularyWordModel> fetchedWords = [];
      List<Map<String, dynamic>> fetchedConfusables = [];

      // Prefer words passed via navigation (fast path)
      if (widget.allWords.isNotEmpty) {
        fetchedWords = widget.allWords.map((w) => VocabularyWordModel.fromJson(w)).toList();
      } else if (widget.isSandbox) {
        // Sandbox: fetch the sandbox session words only; do NOT fall back to local assets or other endpoints.
        try {
          final mixed = await lessonProvider.getCumulativeMixedReview(widget.sessionId, isSandbox: true);
          if (mixed.isNotEmpty) {
            fetchedWords = mixed.map((m) => VocabularyWordModel.fromJson({
                  'wordId': m['wordId'] ?? m['word'] ?? '',
                  'lessonId': widget.lessonId,
                  'englishWord': m['word'] ?? m['englishWord'] ?? '',
                  'cebuanoMeaning': m['definition'] ?? m['cebuanoMeaning'] ?? '',
                  'exampleSentenceEnglish': m['example'] ?? m['exampleSentenceEnglish'] ?? '',
                })).toList();
          }
        } catch (e) {
          setState(() {
            _error = 'Failed to load sandbox lesson: ${e.toString()}';
            _isLoading = false;
          });
          return;
        }
      } else {
        // Primary backend fetch for non-sandbox
        fetchedWords = await lessonProvider.loadVocabulary(widget.lessonId);

        // Fallback 1: try lesson activity endpoint which sometimes contains word-like items
        if (fetchedWords.isEmpty) {
          final activity = await lessonProvider.loadLessonActivity(widget.lessonId);
          if (activity.isNotEmpty) {
            fetchedWords = activity.map((m) => VocabularyWordModel.fromJson({
                  'wordId': m['wordId'] ?? m['id'] ?? '',
                  'lessonId': widget.lessonId,
                  'englishWord': m['word'] ?? m['englishWord'] ?? '',
                  'cebuanoMeaning': m['definition'] ?? m['cebuanoMeaning'] ?? '',
                  'exampleSentenceEnglish': m['example'] ?? m['exampleSentenceEnglish'] ?? '',
                })).toList();
          }
        }
      }

        fetchedConfusables = (!widget.isSandbox && widget.moduleNumber == 3)
          ? await lessonProvider.loadConfusablePairs(widget.lessonId)
          : <Map<String, dynamic>>[];

        if (fetchedConfusables.isEmpty && !widget.isSandbox && widget.moduleNumber == 3) {
          fetchedConfusables = _buildFallbackConfusablePairs(fetchedWords);
        }

      debugPrint('SentenceBuilding: allWords=${widget.allWords.length}, fetchedWords=${fetchedWords.length}, confusables=${fetchedConfusables.length}');

      if (!mounted) return;

      if (fetchedWords.isEmpty) {
        setState(() {
          _error = "Failed to load vocabulary words.";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _words = fetchedWords;
        _totalUniqueWords = fetchedWords.length;
        _phaseWordCount = _totalUniqueWords;
        _confusablePairs = fetchedConfusables;

        // Build a queue that is sequential per-word: for each word add Completion then Rearrangement
        final List<VocabularyWordModel> builtQueue = [];
        final shuffled = List<VocabularyWordModel>.from(fetchedWords)..shuffle();
        for (var word in shuffled) {
          builtQueue.add(word); // completion for this word
          builtQueue.add(word); // rearrangement for this word
        }

        _queue = builtQueue;
        
        _startNextItem();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "An error occurred while loading lesson data.";
          _isLoading = false;
        });
      }
    }
  }

  String _activitySentence(VocabularyWordModel word) {
    return (word.sentenceCompletionSentence?.trim().isNotEmpty ?? false)
        ? word.sentenceCompletionSentence!.trim()
        : word.exampleSentenceEnglish;
  }

  String _activityAnswer(VocabularyWordModel word) {
    return (word.sentenceCompletionAnswer?.trim().isNotEmpty ?? false)
        ? word.sentenceCompletionAnswer!.trim()
        : word.englishWord;
  }

  void _speakFullSentence() {
    final sentence = _activitySentence(_currentWord);
    String textToSpeak = sentence;
    if (sentence.contains('___')) {
      final answer = _activityAnswer(_currentWord);
      textToSpeak = sentence.replaceAll('___', answer);
    }
    _ttsService.speak(textToSpeak);
  }

  List<Map<String, dynamic>> _buildFallbackConfusablePairs(List<VocabularyWordModel> words) {
    final confusableWords = words.where((word) => word.isConfusablePairMember).toList()
      ..sort((a, b) => a.wordOrder.compareTo(b.wordOrder));

    if (confusableWords.length < 2) {
      return const [];
    }

    final wordA = confusableWords[0];
    final wordB = confusableWords[1];

    String buildSentence(VocabularyWordModel word) {
      final sourceSentence = (word.sentenceCompletionSentence?.trim().isNotEmpty ?? false)
          ? word.sentenceCompletionSentence!.trim()
          : word.exampleSentenceEnglish.trim();
      final replacement = word.englishWord.trim();
      if (sourceSentence.isEmpty || replacement.isEmpty) {
        return replacement;
      }
      final blanked = sourceSentence.replaceAll(
        RegExp('\\b${RegExp.escape(replacement)}\\b', caseSensitive: false),
        replacement,
      );
      return blanked.isNotEmpty ? blanked : sourceSentence;
    }

    return [
      {
        'pairId': '${widget.lessonId}_confusable_fallback',
        'lessonId': widget.lessonId,
        'wordA': wordA.toJson(),
        'wordB': wordB.toJson(),
        'contrastiveSentenceA': buildSentence(wordA),
        'contrastiveSentenceB': buildSentence(wordB),
      },
    ];
  }

  List<String> _activityOptions(VocabularyWordModel word) {
    final options = <String>{_activityAnswer(word)};
    for (final value in [
      word.sentenceCompletionOption1,
      word.sentenceCompletionOption2,
      word.sentenceCompletionOption3,
    ]) {
      if (value != null && value.trim().isNotEmpty) {
        options.add(value.trim());
      }
    }
    return options.toList();
  }

  List<String> _activityArrangementTokens(VocabularyWordModel word) {
    final sentence = word.exampleSentenceEnglish.trim().isEmpty
        ? word.englishWord
        : word.exampleSentenceEnglish;
    final sentenceTokens = _tokensFromSentence(sentence);

    if (word.sentenceArrangementTokens != null &&
        word.sentenceArrangementTokens!.isNotEmpty) {
      final provided = word.sentenceArrangementTokens!
          .map((token) => token.trim())
          .where((token) => token.isNotEmpty)
          .toList();

      if (provided.length >= 2) {
        // Only accept DB tokens if they contain exactly the same words as
        // the sentence (same multiset, case-insensitive). This prevents
        // distractor words from other sentences polluting the word bank.
        final lowerProvided = provided.map((t) => t.toLowerCase()).toList()
          ..sort();
        final lowerSentence = sentenceTokens.map((t) => t.toLowerCase()).toList()
          ..sort();

        if (lowerProvided.join(' ') == lowerSentence.join(' ')) {
          // Exact same words as the sentence — use DB tokens (may have
          // different capitalisation that the author intended).
          return provided;
        }

        debugPrint(
            'SentenceBuilding: DB tokens differ from sentence words; '
            'using sentence tokens only. '
            'DB: $provided | Sentence: $sentenceTokens');
      }
    }

    return sentenceTokens;
  }

  List<String> _tokensFromSentence(String sentence) {
    return sentence
        .replaceAll(RegExp(r"[^\p{L}\p{N}' ]", unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
  }

  String _normalizeSentenceText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\p{L}\p{N}' ]", unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _startNextItem() {
    if (_queue.isEmpty) {
      // End of current queue pass!
      debugPrint('Module 3 complete, navigating to results...');
      _handleQueueEmpty();
      return;
    }

    _currentWord = _queue.removeAt(0);

    final wordId = _currentWord.wordId ?? '';
    if (wordId.isNotEmpty && _seenWordIds.contains(wordId)) {
      _currentFormat = ActivityFormat.rearrangement;
    } else {
      _currentFormat = ActivityFormat.completion;
      if (wordId.isNotEmpty) _seenWordIds.add(wordId);
    }

    setState(() {
      _resetItemState();
    });
  }

  void _resetItemState() {
    _isChecked = false;
    _isCorrect = false;
    _selectedCompletionWord = null;
    _assembledWords = []; // clear previous sentence's answer
    final wordId = _currentWord.wordId;
    final priorAttempts = _wordPronunciationAttempts[wordId] ?? 0;
    _pronunciationAttempt = (priorAttempts + 1).clamp(1, 3);
    _attemptResult = null;

    // Modules 2-4 use 3 pronunciation attempts per sentence word.
    _maxAttempts = _attemptLimitForModule();

    if (_currentFormat == ActivityFormat.completion) {
      _generateCompletionOptions();
    } else {
      _generateRearrangementChips();
    }
  }

  void _generateCompletionOptions() {
    final correct = _activityAnswer(_currentWord);
    final provided = _activityOptions(_currentWord)
        .where((option) => option.toLowerCase() != correct.toLowerCase())
        .toList();

    if (provided.length >= 3) {
      _completionOptions = [correct, ...provided.take(3)];
    } else {
      // Generate distractors from other words in session
      final others = _words
          .where((word) => word.wordId != _currentWord.wordId)
          .map((word) => word.englishWord)
          .toList();
      
      // Add fallback distractors if we don't have enough
      final fallbackDistractors = ['apple', 'house', 'water', 'friend', 'school', 'book', 'tree', 'happy', 'run', 'big'];
      if (others.length < 3) {
        others.addAll(fallbackDistractors);
      }
      
      others.shuffle();
      // Always take 3 distractors to ensure 4 total options (1 correct + 3 distractors)
      _completionOptions = [correct, ...others.take(3)];
    }
    _completionOptions.shuffle();
  }

  void _generateRearrangementChips() {
    final List<String> wordsInSentence = _activityArrangementTokens(_currentWord);

    _scrambledWords = List.from(wordsInSentence);
    _scrambledWords.shuffle();

    if (_scrambledWords.length < 2) {
      _currentFormat = ActivityFormat.completion;
      _generateCompletionOptions();
    }
  }

  Future<void> _handleQueueEmpty() async {
    debugPrint('Queue empty! isReinforcementPass: $_isReinforcementPass, failedWords: ${_failedSentenceWords.length}');
    // 1. If we finished the initial pass
    if (!_isReinforcementPass) {
      // Transition to reinforcement pass if we failed any words
      if (_failedSentenceWords.isNotEmpty) {
        debugPrint('Starting reinforcement pass with ${_failedSentenceWords.length} failed words');
        final reinforcementWords = _failedSentenceWords.length;
        setState(() {
          _isReinforcementPass = true;
          _queue = List.from(_failedSentenceWords);
          _phaseWordCount = reinforcementWords;
          _failedSentenceWords.clear();
          _startNextItem();
        });
      } else {
        debugPrint('No failed words, completing module...');
        await _completeModuleAndAdvance();
      }
    } else {
      debugPrint('Reinforcement pass complete, completing module...');
      await _completeModuleAndAdvance();
    }
  }

  void _checkConfusableAnswers() {
    final pair = _activeConfusablePair!;
    final wordA = pair['wordA']['englishWord'] as String;
    final wordB = pair['wordB']['englishWord'] as String;
    final isCorrectA = _confusableSelectedForA?.toLowerCase() == wordA.toLowerCase();
    final isCorrectB = _confusableSelectedForB?.toLowerCase() == wordB.toLowerCase();
    final allCorrect = isCorrectA && isCorrectB;
    if (allCorrect) {
      _initialPassCorrectCount++;
      _confusableMastery[pair['pairId'] as String] = true;
    } else {
      _confusableMastery[pair['pairId'] as String] = false;
    }
    setState(() {
      _confusableChecked = true;
      _confusableCorrect = allCorrect;
    });
  }

  Future<void> _handleConfusableContinue() async {
    if (_confusableCorrect) {
      // Advance past confusable phase
      setState(() {
        _currentPhase = Phase.sentenceActivity;
      });
      // Now check if reinforcement pass is needed
      if (_failedSentenceWords.isNotEmpty) {
        final reinforcementWords = _failedSentenceWords.length;
        setState(() {
          _isReinforcementPass = true;
          _queue = List.from(_failedSentenceWords);
          _phaseWordCount = reinforcementWords;
          _failedSentenceWords.clear();
          _startNextItem();
        });
      } else {
        await _completeModuleAndAdvance();
      }
    } else {
      // Reset and retry
      setState(() {
        _confusableSelectedForA = null;
        _confusableSelectedForB = null;
        _confusableChecked = false;
        _confusableCorrect = false;
      });
    }
  }

  Future<void> _completeModuleAndAdvance() async {
    final navContext = context;

    final totalActivities = _totalUniqueWords * 2;
    try {
      await Provider.of<LessonProvider>(context, listen: false).persistModuleScore(
        widget.lessonId,
        widget.isSandbox ? null : 3,
        _initialPassCompletedCount,
        totalActivities > 0 ? totalActivities : _totalUniqueWords,
        isSandbox: widget.isSandbox,
        sessionId: widget.sessionId,
      );
    } catch (e) {
      debugPrint('Module 3 score sync failed, continuing anyway: $e');
    }

    if (!mounted) return;

    await _showConfusableDistinctionIfNeeded();

    if (!mounted) return;

    // Calculate overall score using completed activities count against total activities
    // Each word has 2 activities (tile arrangement + voice validation)
    final overallScore = (totalActivities > 0 
        ? (_initialPassCompletedCount / totalActivities) * 100 
        : 0.0).clamp(0.0, 100.0);
    
    debugPrint('Module 3 score: completedCount=$_initialPassCompletedCount, totalActivities=$totalActivities, totalWords=$_totalUniqueWords, score=$overallScore%');

    // Get failed sentence word IDs
    final failedSentenceWordIds = _failedSentenceWords.map((w) => w.wordId).toSet();

    // Use provided lessonTitle or fall back to formatted string
    final displayTitle = widget.isSandbox
        ? 'Sandbox Lesson Complete'
        : (widget.lessonTitle?.isNotEmpty == true 
            ? widget.lessonTitle! 
            : 'Lesson Complete');
    final confusableMasteredCount = _confusableMastery.values.where((v) => v).length;

    if (!widget.isSandbox) {
      // Persist full score details so the map screen can retrieve them later
      await LocalStorageService.saveLessonScoreDetails(widget.lessonId, {
        'wordPronunciationCorrect': _wordPronunciationCorrect,
        'wordPronunciationAttempts': _wordPronunciationAttempts,
        'failedSentenceWordIds': failedSentenceWordIds.toList(),
        'overallScore': overallScore,
        'confusablePairsTotal': _confusablePairs.length,
        'confusablePairsMastered': confusableMasteredCount,
        'confusableMastery': _confusableMastery,
      });
    }

    // Navigate to lesson score screen
    debugPrint('Navigating to next screen...');
    // ignore: use_build_context_synchronously
    navContext.go(
      '/session/${widget.sessionId}/lesson-score',
      extra: {
        'sessionId': widget.sessionId,
        'lessonId': widget.lessonId,
        'categoryId': widget.categoryId,
        'lessonTitle': displayTitle,
        'allWords': _words.map((w) => w.toJson()).toList(),
        'wordPronunciationCorrect': _wordPronunciationCorrect,
        'wordPronunciationAttempts': _wordPronunciationAttempts,
        'failedSentenceWordIds': failedSentenceWordIds,
        'overallScore': overallScore,
        'isSandbox': widget.isSandbox,
      },
    );
  }

  Future<void> _showConfusableDistinctionIfNeeded() async {
    if (widget.isSandbox ||
      widget.moduleNumber != 3 ||
      widget.lessonId != 'b1000000-0000-0000-0000-000000000001' ||
      widget.categoryId != 'a1000000-0000-0000-0000-000000000001') {
      return;
    }

    if (_confusableScreenShown) {
      return;
    }

    _confusableScreenShown = true;

    final forcedPair = {
      'pairId': 'd9000000-0000-0000-0000-000000000001',
      'lessonId': widget.lessonId,
      'wordA': {
        'wordId': 'c1000000-0000-0000-0000-000000000005',
        'englishWord': 'Ruler',
        'cebuanoMeaning': 'Ruler',
        'exampleSentenceEnglish': 'She used a ruler to draw a straight line.',
        'exampleSentenceCebuano': 'Gigamit niya ang ruler sa pagdrowing og tul-id nga linya.',
        'sentenceCompletionSentence': 'She used a ___ to draw a straight line.',
        'sentenceCompletionAnswer': 'Ruler',
      },
      'wordB': {
        'wordId': 'c9000000-0000-0000-0000-000000000001',
        'englishWord': 'ruler',
        'cebuanoMeaning': 'Magmamando',
        'exampleSentenceEnglish': 'The ruler governed the kingdom with wisdom.',
        'exampleSentenceCebuano': 'Ang magmamando nagdumala sa gingharian nga may kaalam.',
        'sentenceCompletionSentence': 'The ___ governed the kingdom with wisdom.',
        'sentenceCompletionAnswer': 'ruler',
      },
      'contrastiveSentenceA': 'She used a ruler to draw a straight line.',
      'contrastiveSentenceB': 'The ruler governed the kingdom with wisdom.',
    };

    await context.push(
      '/session/${widget.sessionId}/confusable-distinction',
      extra: {
        'lessonId': widget.lessonId,
        'confusablePairs': [forcedPair],
      },
    );
  }

  void _checkAnswer() {
    if (_currentFormat == ActivityFormat.completion) {
      if (_selectedCompletionWord == null) return;
      _isCorrect = _selectedCompletionWord!.toLowerCase() == _activityAnswer(_currentWord).toLowerCase();
    } else {
      final expected = _activityArrangementTokens(_currentWord).join(' ').toLowerCase().trim();
      final learner = _assembledWords.join(' ').toLowerCase().trim();
      _isCorrect = learner == expected;
    }

    // Keep statistics
    if (_isCorrect) {
      if (!_isReinforcementPass) {
        _initialPassCorrectCount++;
      } else {
        _reinforcementPassCorrectCount++;
      }
    } else {
      // Move to reinforcement queue later
      if (!_failedSentenceWords.any((w) => w.wordId == _currentWord.wordId)) {
        _failedSentenceWords.add(_currentWord);
      }
    }

    if (!widget.isSandbox) {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      provider.submitReviewItem(
        sessionId: widget.sessionId,
        wordId: _currentWord.wordId,
        isCorrect: _isCorrect,
        confidence: 3,
      );
    }

    setState(() {
      _isChecked = true;
    });
  }

  Future<void> _handleContinueFromSentence() async {
    debugPrint('Continue button tapped in Module 3');
    if (_isCorrect) {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      if (widget.isSandbox) {
        // Sandbox mode: skip pronunciation phase entirely
        await provider.updateSandboxProgress(
          sessionId: widget.sessionId,
          wordId: _currentWord.wordId,
          pathway: 'FULL',
          stepCompleted: 4,
          status: 'MASTERED',
          moduleNumber: widget.moduleNumber,
        );

        if (_isReinforcementPass) {
          _reinforcementCompletedCount++;
        } else {
          _initialPassCompletedCount++;
        }

        debugPrint('Calling _startNextItem, queue length: ${_queue.length}');
        _startNextItem();
      } else {
        // Non-sandbox: Advance to Pronunciation Mode for the current word
        // Notify backend that Module 3 (pronunciation) has started for this word.
        provider.updateWordProgress(
          widget.sessionId,
          _currentWord.wordId,
          'FULL',
          0,
          'PRONUNCIATION_PENDING',
          moduleNumber: widget.moduleNumber,
        );

        setState(() {
          _currentPhase = Phase.pronunciationFeedback;
        });
      }
    } else {
      // Swap format and go to next item in the queue (or place it back at the end)
      _currentFormat = (_currentFormat == ActivityFormat.completion)
          ? ActivityFormat.rearrangement
          : ActivityFormat.completion;
      _resetItemState();
      
      // Place it at the end of the active queue to review it later in the same pass
      _queue.add(_currentWord);
      _startNextItem();
    }
  }

  Widget _buildModule3Header(ThemeData theme) {
    return const SizedBox.shrink();
  }

  // Pronunciation flow
  Future<void> _startRecording() async {
    if (_isRecording || _isEvaluating || _attemptResult != null || _disposed) return;

    if (await _recorderService.hasPermission()) {
      if (_disposed || !mounted) return;
      _recordingSessionActive = true;
      _liveTranscriptNotifier.value = '';
      setState(() {
        _isRecording = true;
        _attemptResult = null;
      });
      await _recorderService.startRecording();
      // NOTE: Streaming STT is intentionally disabled here.
      // Starting local speech_to_text concurrently with AudioRecorder causes
      // an Android microphone resource conflict: the OS terminates the
      // recorder session early, producing a near-empty .m4a file (< 6 KB)
      // that Deepgram cannot transcribe (returns empty transcript → 400).
      // Audio is instead captured fully by AudioRecorder and evaluated via
      // the Deepgram backend once recording completes.
      // await _startStreamingRecognition(_currentWord.englishWord);
      _startAutoEvaluationMonitoring();

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildRecordingModal(context),
      );

      if (_disposed || !mounted) return;

      if (_attemptResult != null) {
        return;
      }

      if (!_recordingSessionActive) {
        return;
      }

      _stopAutoEvaluationMonitoring();
      setState(() {
        _isRecording = false;
        _isEvaluating = true;
      });

      final path = await _recorderService.stopRecording();
      if (_disposed || !mounted) return;

      if (path != null) {
        _totalPronunciationAttempts++;
        final result = await _sttService.evaluatePronunciation(
          audioFilePath: path,
          sessionId: widget.sessionId,
          wordId: _currentWord.wordId,
          lessonId: widget.lessonId,
          moduleNumber: widget.moduleNumber,
          targetWord: _currentWord.englishWord,
          attemptNumber: _pronunciationAttempt,
        );

        if (_disposed || !mounted) return;
        setState(() {
          _attemptResult = result;
          _isEvaluating = false;
        });
      } else {
        if (_disposed || !mounted) return;
        setState(() {
          _isEvaluating = false;
        });
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required.')),
      );
    }
  }

  void _stopAutoEvaluationMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _lastSpeechAt = null;
    _recordingStartedAt = null;
  }

  Future<void> _cancelRecordingSession() async {
    final wasActiveAttempt = _recordingSessionActive && _isRecording && _attemptResult == null;
    final shouldMarkFailure = wasActiveAttempt && _pronunciationAttempt >= _maxAttempts;

    _recordingSessionActive = false;
    // Stop monitoring and listening immediately
    _stopAutoEvaluationMonitoring();
    await _streamingSttService.stopListening();
    await _recorderService.stopRecording();

    if (_disposed || !mounted) return;

    setState(() {
      _isRecording = false;
      _isEvaluating = false;
      _liveTranscriptNotifier.value = '';

      if (wasActiveAttempt) {
        _totalPronunciationAttempts++;

        if (shouldMarkFailure) {
          _attemptResult = PronunciationAttemptModel(
            attemptId: '',
            isCorrect: false,
            transcribedText: null,
            phoneticTarget: null,
            phonologicalTip: null,
            attemptNumber: _pronunciationAttempt,
            isInconclusive: true,
          );
        } else {
          _pronunciationAttempt = _pronunciationAttempt < _maxAttempts ? _pronunciationAttempt + 1 : _maxAttempts;
          _attemptResult = null;
        }
      } else {
        _attemptResult = null;
      }
    });
    
    _wordPronunciationAttempts[_currentWord.wordId] = _pronunciationAttempt;
    if (_attemptResult != null && _attemptResult!.isCorrect) {
      _wordPronunciationCorrect[_currentWord.wordId] = true;
    }

    // Exit the recording/practice modal but stay in the module
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _startStreamingRecognition(String targetWord) async {
    _liveTranscriptNotifier.value = '';

    try {
      await _streamingSttService.startListening(
        localeId: 'en_US',
        onResult: (transcript, isFinal) {
          if (!mounted || !_recordingSessionActive || _attemptResult != null) {
            return;
          }

          final t = transcript.trim();
          _liveTranscriptNotifier.value = t;

          if (t.isNotEmpty && PronunciationMatcher.matchesTranscript(t, targetWord)) {
            _handleStreamingMatch(t);
          }
        },
        onStatus: (status) {
          if (!mounted || !_recordingSessionActive || _attemptResult != null) {
            return;
          }

          if (status == 'done' || status == 'notListening') {
            _liveTranscriptNotifier.value = _liveTranscriptNotifier.value.trim();
          }
        },
        onError: (errorMsg) {
          if (!mounted) return;
          _liveTranscriptNotifier.value = _liveTranscriptNotifier.value.trim();
        },
      );
    } catch (_) {
      // The fallback recorder remains available if device speech recognition is not available.
    }
  }

  Future<void> _handleStreamingMatch(String transcript) async {
    if (!_recordingSessionActive || _attemptResult != null || !_isRecording || _disposed) {
      return;
    }

    _recordingSessionActive = false;
    _stopAutoEvaluationMonitoring();
    await _streamingSttService.stopListening();
    await _recorderService.stopRecording();

    if (_disposed || !mounted) {
      return;
    }

    setState(() {
      _attemptResult = PronunciationAttemptModel(
        attemptId: '',
        isCorrect: true,
        transcribedText: transcript,
        phoneticTarget: null,
        phonologicalTip: null,
        attemptNumber: _pronunciationAttempt,
        isInconclusive: false,
      );
      _isRecording = false;
      _isEvaluating = false;
    });

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _startAutoEvaluationMonitoring() {
    _stopAutoEvaluationMonitoring();
    _recordingStartedAt = DateTime.now();

    _amplitudeSubscription = _recorderService.onAmplitudeChanged.listen((amplitude) {
      if (!_isRecording || _isEvaluating || _attemptResult != null) return;
      if (amplitude > 0.18) {
        _lastSpeechAt = DateTime.now();
      }
    });

    _silenceTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !_isRecording || _isEvaluating || _attemptResult != null) return;
      final startedAt = _recordingStartedAt;
      if (startedAt == null) return;

      final elapsed = DateTime.now().difference(startedAt);
      final lastSpeechAt = _lastSpeechAt;
      final shouldFinishForSilence = lastSpeechAt != null && DateTime.now().difference(lastSpeechAt) >= const Duration(milliseconds: 900);
      final shouldFinishForTimeout = elapsed >= const Duration(seconds: 30);

      if (shouldFinishForSilence || shouldFinishForTimeout) {
        _finishRecordingAndEvaluate();
      }
    });
  }

  Future<void> _finishRecordingAndEvaluate() async {
    if (_isEvaluating || !_isRecording || _attemptResult != null || _disposed) return;

    // Minimum duration guard (1.5 seconds)
    final startedAt = _recordingStartedAt;
    if (startedAt != null) {
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < const Duration(milliseconds: 1500)) {
        return;
      }
    }

    setState(() {
      _isEvaluating = true;
    });

    _stopAutoEvaluationMonitoring();
    final path = await _recorderService.stopRecording();

    if (_disposed || !mounted) return;

    // Modules 2-4 use longer active-recall loops, so allow more pronunciation retries.
    _maxAttempts = _attemptLimitForModule();

    if (path == null) {
      setState(() {
        _isRecording = false;
        _isEvaluating = false;
      });
      return;
    }

    _totalPronunciationAttempts++;
    final result = await _sttService.evaluatePronunciation(
      audioFilePath: path,
      sessionId: widget.sessionId,
      wordId: _currentWord.wordId,
      lessonId: widget.lessonId,
      moduleNumber: widget.moduleNumber,
      targetWord: _currentWord.englishWord,
      attemptNumber: _pronunciationAttempt,
    );

    if (_disposed || !mounted) return;

    setState(() {
      _attemptResult = result;
      _isRecording = false;
      _isEvaluating = false;
    });

    final bool isPassed = result.isCorrect && ((result.similarityScore ?? 1.0) >= 0.80);
    if (isPassed) {
      _recordingSessionActive = false;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (result.isInconclusive) {
      _recordingSessionActive = false;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final shouldRetry = _recordingSessionActive && _pronunciationAttempt < _maxAttempts;
    if (!shouldRetry) {
      // Only pop if the session is still active but we reached max attempts. 
      // If _recordingSessionActive was already set to false (by cancel), don't pop again.
      if (_recordingSessionActive) {
        _recordingSessionActive = false;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 650));
    if (_disposed || !mounted || !_recordingSessionActive) return;

    setState(() {
      _pronunciationAttempt++;
      _attemptResult = null;
      _isRecording = true;
    });

    await _recorderService.startRecording();
    _startAutoEvaluationMonitoring();
  }

  void _skipPronunciation() async {
    _advancePronunciationPhase();
  }

  void _advancePronunciationPhase() async {
    final provider = Provider.of<LessonProvider>(context, listen: false);
    await provider.updateWordProgress(
      widget.sessionId,
      _currentWord.wordId,
      'FULL',
      4,
      'INTRODUCED',
      moduleNumber: widget.moduleNumber,
    );

    if (_isReinforcementPass) {
      _reinforcementCompletedCount++;
    } else {
      _initialPassCompletedCount++;
    }
    setState(() {
      _currentPhase = Phase.sentenceActivity;
    });
    _startNextItem();
  }

  void _handleContinueFromPronunciation() async {
    final correct = _attemptResult?.isCorrect ?? false;
    final reachedMaxAttempts = _pronunciationAttempt >= _maxAttempts;

    if (correct || reachedMaxAttempts) {
      _advancePronunciationPhase();
    } else {
      // Try again (increment attempts only if not inconclusive)
      setState(() {
        if (_attemptResult?.isInconclusive != true) {
          _pronunciationAttempt++;
        }
        _attemptResult = null;
      });
    }
  }

  String _getPhonologicalTip(String? tipKey) {
    switch (tipKey) {
      case 'f_sound':
        return "The /f/ sound doesn't exist in Cebuano. "
            "Gently touch your upper front teeth to your lower lip and push air out — "
            "like blowing out a candle slowly. Practice: 'fff-ish', 'fff-ather'.";
      case 'v_sound':
        return "The /v/ sound doesn't exist in Cebuano. "
            "Touch your upper teeth to your lower lip and hum — feel the vibration. "
            "It's like /f/ but with your voice on. Practice: 'vvv-ery', 'vvv-oice'.";
      case 'th_sound':
        return "The /θ/ (TH) sound doesn't exist in Cebuano. "
            "Place the tip of your tongue lightly between your upper and lower front teeth, "
            "then blow air out gently. Practice: 'th-ink', 'th-ree', 'th-ank'.";
      case 'th_voiced':
        return "The voiced /ð/ (TH) sound is like 'th' in 'the' or 'this'. "
            "Put your tongue between your teeth and hum — feel the buzz. "
            "Practice: 'th-is', 'th-at', 'broth-er'.";
      case 'r_sound':
        return "English /r/ is different from Cebuano. "
            "Keep your tongue back and curved — don't roll it. "
            "The tongue should not touch the roof of your mouth. Practice: 'rr-un', 'rr-ead'.";
      case 'l_sound':
        return "For English /l/, place the tip of your tongue on the ridge just behind "
            "your upper front teeth and let air flow around the sides. "
            "Practice: 'll-ight', 'll-ove', 'bell'.";
      case 'short_i':
        return "The short /ɪ/ sound (as in 'sit') is shorter and more relaxed than the long /iː/ in 'see'. "
            "Relax your lips and say a quick 'ih'. Practice: 'f-ih-sh', 's-ih-t', 'th-ih-s'.";
      case 'short_e':
        return "The /ɛ/ sound (as in 'bed') is made with your mouth slightly open and lips relaxed. "
            "It is between 'a' and 'ee'. Practice: 'b-eh-d', 'p-eh-n', 'h-eh-lp'.";
      case 'schwa':
        return "Many English unstressed syllables use the schwa /ə/ — a neutral, relaxed sound "
            "like a quick 'uh'. The vowel in 'the', 'a', and the 2nd syllable of 'pencil' are schwa. "
            "Practice: 'penc-uh-l', 'erase-uh-r'.";
      default:
        return "Speak slowly and clearly. Listen to the correct audio again, "
            "then try to match the mouth shape and rhythm. "
            "Focus on each syllable: say the word one part at a time.";
    }
  }

  /// Returns a score-aware failure coaching message.
  String _buildFailureMessage(double? score) {
    if (score == null) return 'Not quite — give it another try!';
    final pct = (score * 100).round();
    if (pct >= 70) {
      return 'Very close ($pct%)! Small adjustment needed — try again.';
    } else if (pct >= 50) {
      return 'Getting there ($pct%). Focus on each syllable and try again.';
    } else if (pct >= 30) {
      return 'Not quite ($pct%). Listen to the audio and try to match the sound.';
    } else {
      return 'Keep practicing! Listen carefully and try to copy the pronunciation.';
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF06A6FF)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              )
            ],
          ),
        ),
      );
    }

    if (_currentPhase == Phase.summary) {
      return _buildSummaryScreen();
    }

    final totalWords = _words.length;
    final remainingWordIds = _queue.map((word) => word.wordId).toSet();
    final completedWordsCount = _words.map((word) => word.wordId).toSet().difference(remainingWordIds).length;
    final progressVal = totalWords > 0 ? (completedWordsCount / totalWords) : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF1E293B)),
            onPressed: _showExitConfirmation,
          ),
          title: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: TweenAnimationBuilder<double>(
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
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  '$completedWordsCount/$totalWords',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _currentPhase == Phase.confusableDistinction
            ? _buildConfusableBody(theme)
            : _currentPhase == Phase.sentenceActivity
                ? _buildSentenceActivityBody(theme)
                : _buildPronunciationBody(theme),
      ),
    );
  }

  Widget _buildCompletionBlankSentence({
    required List<String> parts,
    required String answer,
  }) {
    String blankText = '_______';
    Color blankColor = const Color(0xFF94A3B8);
    Color blankBgColor = const Color(0xFFF1F5F9);

    if (_selectedCompletionWord != null) {
      blankText = _selectedCompletionWord!;
      blankColor = const Color(0xFF06A6FF);
      blankBgColor = const Color(0xFFEFF6FF);
    }

    if (_isChecked && _selectedCompletionWord != null) {
      final correct = _selectedCompletionWord!.toLowerCase() == answer.toLowerCase();
      blankText = _selectedCompletionWord!;
      blankColor = correct ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
      blankBgColor = correct ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    }

    const wordStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Color(0xFF1E293B),
      height: 1.5,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (parts[0].isNotEmpty) Text(parts[0], style: wordStyle),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: blankBgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: blankColor, width: 2),
          ),
          child: Text(
            blankText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: blankColor == const Color(0xFF94A3B8)
                  ? const Color(0xFF64748B)
                  : blankColor,
            ),
          ),
        ),
        if (parts.length > 1 && parts[1].isNotEmpty) Text(parts[1], style: wordStyle),
      ],
    );
  }

  Widget _buildConfusableBody(ThemeData theme) {
    final pair = _activeConfusablePair!;
    final wordA = pair['wordA'] as Map<String, dynamic>;
    final wordB = pair['wordB'] as Map<String, dynamic>;
    final wordAEnglish = wordA['englishWord'] as String;
    final wordACebuano = wordA['cebuanoMeaning'] as String;
    final wordBEnglish = wordB['englishWord'] as String;
    final wordBCebuano = wordB['cebuanoMeaning'] as String;
    final sentenceA = pair['contrastiveSentenceA'] as String;
    final sentenceB = pair['contrastiveSentenceB'] as String;
    final sentenceAFrame = sentenceA.replaceAll(RegExp('(?i)\\b${RegExp.escape(wordAEnglish)}\\b'), '________');
    final sentenceBFrame = sentenceB.replaceAll(RegExp('(?i)\\b${RegExp.escape(wordBEnglish)}\\b'), '________');
    final isCorrectA = _confusableSelectedForA?.toLowerCase() == wordAEnglish.toLowerCase();
    final isCorrectB = _confusableSelectedForB?.toLowerCase() == wordBEnglish.toLowerCase();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Phase badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CONFUSABLE WORDS CHALLENGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'These words look similar but mean different things. Fill in the blanks correctly.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Side-by-side word cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(wordAEnglish,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0369A1))),
                              const SizedBox(height: 6),
                              Text('Cebuano: $wordACebuano',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () => _ttsService.speak(wordAEnglish),
                                icon: const Icon(Icons.volume_up_rounded, size: 15),
                                label: const Text('Listen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(wordBEnglish,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                              const SizedBox(height: 6),
                              Text('Cebuano: $wordBCebuano',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () => _ttsService.speak(wordBEnglish),
                                icon: const Icon(Icons.volume_up_rounded, size: 15),
                                label: const Text('Listen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Blank sentence A
                  _buildConfusableBlankCard(
                    sentenceFrame: sentenceAFrame,
                    wordAEnglish: wordAEnglish,
                    wordBEnglish: wordBEnglish,
                    selectedWord: _confusableSelectedForA,
                    isChecked: _confusableChecked,
                    isCorrect: isCorrectA,
                    correctSentence: sentenceA,
                    onSelectA: () {
                      if (!_confusableChecked) setState(() => _confusableSelectedForA = wordAEnglish);
                    },
                    onSelectB: () {
                      if (!_confusableChecked) setState(() => _confusableSelectedForA = wordBEnglish);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Blank sentence B
                  _buildConfusableBlankCard(
                    sentenceFrame: sentenceBFrame,
                    wordAEnglish: wordAEnglish,
                    wordBEnglish: wordBEnglish,
                    selectedWord: _confusableSelectedForB,
                    isChecked: _confusableChecked,
                    isCorrect: isCorrectB,
                    correctSentence: sentenceB,
                    onSelectA: () {
                      if (!_confusableChecked) setState(() => _confusableSelectedForB = wordAEnglish);
                    },
                    onSelectB: () {
                      if (!_confusableChecked) setState(() => _confusableSelectedForB = wordBEnglish);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Footer button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
            ),
            child: _confusableChecked
                ? Column(
                    children: [
                      if (!_confusableCorrect)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Not quite! Review the meanings above and try again.',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _handleConfusableContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _confusableCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          _confusableCorrect ? 'CONTINUE' : 'TRY AGAIN',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: (_confusableSelectedForA != null && _confusableSelectedForB != null)
                        ? _checkConfusableAnswers
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBF24),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'CHECK ANSWERS',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfusableBlankCard({
    required String sentenceFrame,
    required String wordAEnglish,
    required String wordBEnglish,
    required String? selectedWord,
    required bool isChecked,
    required bool isCorrect,
    required String correctSentence,
    required VoidCallback onSelectA,
    required VoidCallback onSelectB,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChecked
            ? (isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2))
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isChecked
              ? (isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
              : const Color(0xFFE2E8F0),
          width: isChecked ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sentenceFrame,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSelectA,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedWord == wordAEnglish ? const Color(0xFFEFF6FF) : Colors.white,
                    side: BorderSide(
                      color: selectedWord == wordAEnglish ? const Color(0xFF06A6FF) : const Color(0xFFCBD5E1),
                      width: selectedWord == wordAEnglish ? 2 : 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    wordAEnglish,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selectedWord == wordAEnglish ? const Color(0xFF06A6FF) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSelectB,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedWord == wordBEnglish ? const Color(0xFFEFF6FF) : Colors.white,
                    side: BorderSide(
                      color: selectedWord == wordBEnglish ? const Color(0xFF06A6FF) : const Color(0xFFCBD5E1),
                      width: selectedWord == wordBEnglish ? 2 : 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    wordBEnglish,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selectedWord == wordBEnglish ? const Color(0xFF06A6FF) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isChecked && !isCorrect)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                'Correct: "$correctSentence"',
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          if (isChecked && isCorrect)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
                  SizedBox(width: 6),
                  Text('Correct!', style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSentenceActivityBody(ThemeData theme) {

    final sentence = _activitySentence(_currentWord);

    // Pre-split the sentence for the completion format so both the instruction
    // text and the sentence display widget share the same computed state.
    List<String> completionParts = const [];
    if (_currentFormat == ActivityFormat.completion) {
      final answer = _activityAnswer(_currentWord);
      if (sentence.contains('___')) {
        final split = sentence.split('___');
        completionParts = [split.first, split.skip(1).join('___')];
      } else {
        final regex = RegExp(RegExp.escape(answer), caseSensitive: false);
        final split = sentence.split(regex);
        if (split.length >= 2) {
          completionParts = [split.first, split.skip(1).join(answer)];
        }
      }
    }
    final completionHasBlank = completionParts.length >= 2;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModule3Header(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Phase indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isReinforcementPass ? Colors.purple.withValues(alpha: 0.08) : Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isReinforcementPass
                          ? "REINFORCEMENT PASS (PRACTICE FAILS)"
                          : "INITIAL SENTENCE PRACTICE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isReinforcementPass ? Colors.purple : Colors.blue,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Instructions text
                  Text(
                    _currentFormat == ActivityFormat.completion
                        ? (completionHasBlank
                            ? 'Select the correct word to fill the blank:'
                            : 'Select the correct word that matches the sentence:')
                        : 'Drag or tap the words to build the sentence:',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_currentFormat == ActivityFormat.rearrangement && !_isChecked) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'WORD BANK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 12,
                            children: _scrambledWords.map((word) {
                              return Draggable<String>(
                                data: word,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: ActionChip(
                                    label: Text(
                                      word,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFF06A6FF), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.35,
                                  child: ActionChip(
                                    label: Text(
                                      word,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                child: ActionChip(
                                  label: Text(
                                    word,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  shadowColor: Colors.black.withValues(alpha: 0.04),
                                  elevation: 2,
                                  onPressed: () {
                                    setState(() {
                                      _scrambledWords.remove(word);
                                      _assembledWords.add(word);
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // English Sentence Frame with visual blank/tapped words
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Opacity(
                              opacity: 0,
                              child: IconButton(
                                icon: Icon(Icons.volume_up_rounded),
                                onPressed: null,
                              ),
                            ),
                            Expanded(
                              child: _currentFormat == ActivityFormat.completion
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: completionHasBlank
                                          ? _buildCompletionBlankSentence(
                                              parts: completionParts,
                                              answer: _activityAnswer(_currentWord),
                                            )
                                          : Text(
                                              sentence,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1E293B),
                                                height: 1.5,
                                              ),
                                            ),
                                    )
                                  : DragTarget<String>(
                                      onWillAcceptWithDetails: (_) => !_isChecked,
                                      onAcceptWithDetails: (details) {
                                        if (_isChecked) return;
                                        final word = details.data;
                                        if (_assembledWords.contains(word)) return;
                                        setState(() {
                                          _scrambledWords.remove(word);
                                          _assembledWords.add(word);
                                        });
                                      },
                                      builder: (context, candidateData, rejectedData) {
                                        return Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: candidateData.isNotEmpty ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: candidateData.isNotEmpty ? const Color(0xFF06A6FF) : const Color(0xFFE2E8F0),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 8,
                                            runSpacing: 10,
                                            children: _assembledWords.isEmpty
                                                ? [
                                                    const Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 16),
                                                      child: Text(
                                                        "Drop or tap words here",
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          color: Color(0xFF94A3B8),
                                                          fontSize: 15,
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                : _assembledWords.map((word) {
                                                    return ActionChip(
                                                      label: Text(
                                                        word,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: Color(0xFF06A6FF),
                                                        ),
                                                      ),
                                                      backgroundColor: const Color(0xFFEFF6FF),
                                                      side: const BorderSide(color: Color(0xFF06A6FF), width: 1.5),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      onPressed: () {
                                                        if (_isChecked) return;
                                                        setState(() {
                                                          _assembledWords.remove(word);
                                                          _scrambledWords.add(word);
                                                        });
                                                      },
                                                    );
                                                  }).toList(),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF06A6FF)),
                              onPressed: _speakFullSentence,
                              tooltip: "Listen to full sentence",
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),

                        // Cebuano Translation Scaffold
                        Row(
                          children: [
                            const Text(
                              '🇵🇭',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentWord.exampleSentenceCebuano ?? _currentWord.cebuanoMeaning,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF06A6FF)),
                              onPressed: () => _ttsService.speakCebuano(_currentWord.exampleSentenceCebuano ?? _currentWord.cebuanoMeaning),
                              tooltip: "Listen to sentence translation",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  if (!_isChecked && _currentFormat == ActivityFormat.completion) ...[
                    const SizedBox(height: 36),
                    Column(
                      children: _completionOptions.map((opt) {
                        final isSel = _selectedCompletionWord == opt;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCompletionWord = opt;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF06A6FF) : const Color(0xFFE2E8F0),
                                  width: isSel ? 2.5 : 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSel ? const Color(0xFF06A6FF) : const Color(0xFF94A3B8),
                                        width: isSel ? 7 : 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    opt,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSel ? const Color(0xFF06A6FF) : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Feedbacks
                  if (_isChecked) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isCorrect ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isCorrect ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: _isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isCorrect ? "Correct!" : "Let's review the correct structure:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _isCorrect ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!_isCorrect) ...[
                            const SizedBox(height: 12),
                            Text(
                              sentence,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Remember: '${_currentWord.englishWord}' means '${_currentWord.cebuanoMeaning}' in Cebuano.",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),

          // Footer action bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
            ),
            child: _isChecked
                ? ElevatedButton(
                    onPressed: _handleContinueFromSentence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.isSandbox ? "CONTINUE" : (_isCorrect ? "CONTINUE TO PRONUNCIATION" : "CONTINUE"),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  )
                : ElevatedButton(
                    onPressed: (_currentFormat == ActivityFormat.completion
                            ? _selectedCompletionWord != null
                            : _scrambledWords.isEmpty)
                        ? _checkAnswer
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06A6FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "CHECK ANSWER",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPronunciationBody(ThemeData theme) {
    final sentence = _activitySentence(_currentWord);
    final target = _activityAnswer(_currentWord);

    // Highlight target word in sentence
    final parts = sentence.split(' ');

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModule3Header(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isSandbox ? "Speech Feedback" : "Module 3 Speech Feedback",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.8),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Display full sentence highlighting target
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      runSpacing: 8,
                      children: parts.map((part) {
                        final cleanPart = part.replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~(?)]'), '');
                        final isTarget = cleanPart.toLowerCase() == target.toLowerCase();
                        if (isTarget) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              part,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF047857),
                              ),
                            ),
                          );
                        }
                        return Text(
                          part,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Give it a try — say the sentence aloud. Tap skip if you would rather move on.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Premium card with the target word
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _attemptResult != null
                            ? (_attemptResult!.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                            : const Color(0xFFE2E8F0),
                        width: _attemptResult != null ? 3.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              target,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.volume_up_rounded, size: 28, color: Color(0xFF06A6FF)),
                              onPressed: () => _ttsService.speak(target),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Phonologicalinterference tip helper displayed on attempt 1 and 2
                        if (_pronunciationAttempt <= 2 && _attemptResult == null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.isSandbox && _currentWord.phonologicalTipKey != null
                                  ? _currentWord.phonologicalTipKey!
                                  : _getPhonologicalTip(_currentWord.phonologicalTipKey),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Evaluator Feedbacks
                        if (_attemptResult != null) ...[
                          const SizedBox(height: 12),
                          if (_attemptResult!.isCorrect)
                            Column(
                              children: [
                                const Text(
                                  'Excellent! You said it correctly.',
                                  style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '🎉',
                                  style: TextStyle(fontSize: 32),
                                ),
                                if (_attemptResult!.transcribedText != null && _attemptResult!.transcribedText!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFBBF7D0)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'You said: "${_attemptResult!.transcribedText}"',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            color: Color(0xFF166534),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (_attemptResult!.similarityScore != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Match score: ${(_attemptResult!.similarityScore! * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF22C55E),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            )
                          else ...[
                            // --- Contextual failure headline ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 28),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _attemptResult!.isInconclusive
                                        ? "Couldn't hear you clearly. Please try again."
                                        : _pronunciationAttempt >= 3
                                            ? 'No attempts left — keep practicing!'
                                            : _buildFailureMessage(_attemptResult!.similarityScore),
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            if (_attemptResult!.transcribedText != null && _attemptResult!.transcribedText!.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'You said: "${_attemptResult!.transcribedText}"',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF991B1B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_attemptResult!.similarityScore != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Match: ${(_attemptResult!.similarityScore! * 100).toStringAsFixed(0)}% — need 80% to pass',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFEF4444),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // --- IPA phonetic target ---
                            if (_attemptResult!.phoneticTarget != null &&
                                _attemptResult!.phoneticTarget!.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.record_voice_over_rounded, color: Color(0xFF7C3AED), size: 18),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Target pronunciation:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _attemptResult!.phoneticTarget!,
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // --- Phonological / articulation tip ---
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFED7AA)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.tips_and_updates_rounded, color: Color(0xFFD97706), size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'HOW TO IMPROVE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF92400E),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    // Priority: use backend tip → fallback to local tip
                                    (_attemptResult!.phonologicalTip != null &&
                                            _attemptResult!.phonologicalTip!.trim().isNotEmpty)
                                        ? _attemptResult!.phonologicalTip!
                                        : _getPhonologicalTip(_currentWord.phonologicalTipKey),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),

                            // --- Listen again prompt ---
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () => _ttsService.speak(target),
                              icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF06A6FF), size: 18),
                              label: const Text(
                                'Hear correct pronunciation',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF06A6FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Mic indicator / button
                  if (_attemptResult == null && !_isEvaluating)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _skipPronunciation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                              ),
                              child: Column(
                                children: const [
                                  Icon(Icons.skip_next_rounded, size: 36, color: Color(0xFF64748B)),
                                  SizedBox(height: 8),
                                  Text("SKIP", style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: _startRecording,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF06A6FF), width: 2),
                              ),
                              child: Column(
                                children: const [
                                  Icon(Icons.mic_rounded, size: 36, color: Color(0xFF06A6FF)),
                                  SizedBox(height: 8),
                                  Text("SPEAK", style: TextStyle(fontSize: 14, color: Color(0xFF06A6FF), fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (_isEvaluating)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF06A6FF)),
                          SizedBox(height: 16),
                          Text(
                            "Evaluating speech accuracy...",
                            style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action bar
          if (_attemptResult != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
              ),
              child: ElevatedButton(
                onPressed: _handleContinueFromPronunciation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _attemptResult!.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  (_attemptResult!.isCorrect || _pronunciationAttempt >= 3)
                      ? "CONTINUE TO NEXT WORD"
                      : "TRY AGAIN",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingModal(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        widthFactor: 1,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 24,
                spreadRadius: 3,
                offset: Offset(0, -6),
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Listening...',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pronounce: ${_currentWord.englishWord}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Speak naturally. It will score automatically when you pause, or stop after 30 seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                ),
                const SizedBox(height: 36),
                StreamBuilder<double>(
                  stream: _recorderService.onAmplitudeChanged,
                  builder: (context, snapshot) {
                    final amplitude = (snapshot.data ?? 0.0).clamp(0.0, 1.0);
                    final isSpeechActive = amplitude > 0.18;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSpeechActive 
                            ? const Color(0xFF10B981).withValues(alpha: 0.15 + (amplitude * 0.15))
                            : const Color(0xFF06A6FF).withValues(alpha: 0.08 + (amplitude * 0.12)),
                        border: Border.all(
                          color: isSpeechActive ? const Color(0xFF10B981) : const Color(0xFF06A6FF),
                          width: isSpeechActive ? 4 + (amplitude * 8) : 3 + (amplitude * 7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSpeechActive 
                                ? const Color(0xFF10B981).withValues(alpha: 0.25 + (amplitude * 0.20))
                                : const Color(0xFF06A6FF).withValues(alpha: 0.18 + (amplitude * 0.12)),
                            blurRadius: isSpeechActive ? 28 : 20,
                            spreadRadius: isSpeechActive ? 4 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        size: 54 + (amplitude * 12),
                        color: isSpeechActive ? const Color(0xFF10B981) : const Color(0xFF06A6FF),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelRecordingSession,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _finishRecordingAndEvaluate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06A6FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryScreen() {
    // Computes stats
    final averageAttempts = _totalPronunciationWords > 0
        ? (_totalPronunciationAttempts / _totalPronunciationWords).toStringAsFixed(1)
        : '0.0';

    final confusableMasteredCount = _confusableMastery.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isSandbox ? 'Completed' : 'Module 3 Completed',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEFF6FF),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06A6FF).withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 72)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nice work completing sentence practice.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You have reached the last step before cumulative review. Missed words will come back in the next module.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatRow('Total Words Applied', '$_totalUniqueWords'),
                    const Divider(height: 24),
                    _buildStatRow('Initial-Pass Correct', '$_initialPassCorrectCount / $_totalUniqueWords'),
                    const Divider(height: 24),
                    _buildStatRow('Reinforcement Correct', '$_reinforcementPassCorrectCount'),
                    if (_confusablePairs.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildStatRow('Confusable Pairs Mastered', '$confusableMasteredCount / ${_confusablePairs.length}'),
                    ],
                    const Divider(height: 24),
                    _buildStatRow('Avg. Pronunciation Attempts', '$averageAttempts per word'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  // Push cumulative review with a small slide+fade animation so user can go back to Module 3 without restarting
                  Navigator.of(context).push(PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 420),
                    reverseTransitionDuration: const Duration(milliseconds: 350),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.04, 0.0), end: Offset.zero).animate(
                            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                          ),
                          child: CumulativeMixedReviewScreen(
                            sessionId: widget.sessionId,
                            allWords: widget.allWords,
                            categoryId: widget.categoryId,
                            isSandbox: widget.isSandbox,
                          ),
                        ),
                      );
                    },
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'PROCEED CUMULATIVE REVIEW',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'BACK TO HOME',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Activity?'),
        content: const Text('Leaving now will discard your progress in this sentence building module.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('EXIT', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
