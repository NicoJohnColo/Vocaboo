import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import 'loading_screen.dart';
import '../models/vocabulary_word_model.dart';
import '../models/pronunciation_attempt_model.dart';
import '../services/audio_recorder_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/streaming_stt_service.dart';
import '../services/local_storage_service.dart';
import '../services/localization_service.dart';
import '../widgets/mascot_bubble.dart';
import '../widgets/cebuano_text_highlighter.dart';

class CompletionToken {
  final String text;
  final bool isBlank;
  final String? answer;
  CompletionToken({required this.text, this.isBlank = false, this.answer});
}

enum Phase {
  sentenceActivity,
  pronunciationFeedback,
  confusableDistinction,
  summary,
}

enum ActivityFormat { completion, rearrangement }

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

class _SentenceBuildingScreenState extends State<SentenceBuildingScreen> with WidgetsBindingObserver {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final SttService _sttService = SttService();
  final TtsService _ttsService = TtsService();
  final StreamingSttService _streamingSttService = StreamingSttService();
  final ValueNotifier<String> _liveTranscriptNotifier = ValueNotifier<String>(
    '',
  );
  StreamSubscription<double>? _amplitudeSubscription;
  Timer? _silenceTimer;
  DateTime? _lastSpeechAt;
  DateTime? _recordingStartedAt;
  bool _recordingSessionActive = false;
  bool _disposed = false;

  // Active Time Tracking
  DateTime? _moduleStartTime;
  Duration _totalPausedDuration = Duration.zero;
  DateTime? _pauseStartTime;

  // Timer state
  Timer? _activityTimer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;

  // Lesson data
  List<VocabularyWordModel> _words = [];
  bool _isLoading = true;
  String? _error;
  Map<String, String> _wordDifficulties = {};
  final Set<String> _sentenceMasteredWordIds = {};

  // Queues and Progression State
  List<VocabularyWordModel> _queue = [];
  final Set<String> _seenWordIds = {};
  final List<VocabularyWordModel> _failedSentenceWords = [];
  bool _isReinforcementPass = false;
  Phase _currentPhase = Phase.sentenceActivity;
  int _totalUniqueWords = 0;
  int _initialPassCompletedCount = 0;

  // Stats for Summary Screen
  int _initialPassCorrectCount = 0;
  int _reinforcementPassCorrectCount = 0;
  int _totalPronunciationAttempts = 0;
  final int _totalPronunciationWords = 0;
  List<Map<String, dynamic>> _confusablePairs = [];
  final Map<String, bool> _confusableMastery = {};
  bool _pronunciationBatchCompleted = false;

  // Per-word stage progression tracking in Module 3 (Sentence Building):
  // REVISED FORMAT: 1 correct answer per activity type = advance (no collective rounds)
  // 1: LEARNING (Sentence Completion: 1 blank, 2 distractors, 40s timer -> Sentence Arrangement: 1 tile + 2 distractors, 40s timer)
  // 2: FAMILIAR (Sentence Completion: 2 blanks, 3 distractors, 40s timer -> Sentence Arrangement: 2 tiles + 2 distractors, 40s timer)
  // 3: PROFICIENT (Sentence Completion: 3 blanks, free type, 40s timer -> Sentence Arrangement: 3 tiles, no distractors, 35s timer -> Pronunciation)
  // 4: MASTERED (Word complete)
  final Map<String, int> _wordStage = {};
  
  // Track maximum stage reached for consistent progress calculation (progress never decreases)
  final Map<String, int> _maxWordStage = {};
  final Map<String, int> _consecutiveFailures = {};

  int _getWordStage(String wordId) {
    if (_wordStage.containsKey(wordId)) {
      return _wordStage[wordId]!;
    }
    final cleanId = wordId.toLowerCase().trim();
    for (final entry in _wordStage.entries) {
      if (entry.key.toLowerCase().trim() == cleanId) {
        return entry.value;
      }
    }
    // Module 3: All words start at FAMILIAR (Stage 2) by default
    // Only use stored difficulty if it's MASTERED
    final diff = (_wordDifficulties[wordId] ?? _wordDifficulties[cleanId] ?? 'FAMILIAR').toUpperCase();
    if (diff == 'MASTERED') return 4;
    return 2; // FAMILIAR (Default for Module 3 - all words start at Stage 2)
  }

  String _getStageTier(int stage) {
    if (stage <= 1) return 'LEARNING';
    if (stage == 2) return 'FAMILIAR';
    if (stage == 3) return 'PROFICIENT';
    return 'MASTERED';
  }

  // Sandbox dual-clear tracking per word
  final Map<String, bool> _sandboxCompletionCleared = {};
  final Map<String, bool> _sandboxRearrangementCleared = {};

  // Inline confusable distinction state
  Map<String, dynamic>? _activeConfusablePair;
  String? _confusableSelectedForA;
  String? _confusableSelectedForB;
  bool _confusableChecked = false;
  bool _confusableCorrect = false;

  // Per-word pronunciation tracking for score screen
  List<String> _expectedArrangementTokens = [];
  int _arrangementStartIndex = 0;
  int _arrangementEndIndex = -1;
  final Map<String, bool> _wordPronunciationCorrect = {}; // wordId -> isCorrect
  final Map<String, int> _wordPronunciationAttempts =
      {}; // wordId -> attemptCount

  // Current item state
  late VocabularyWordModel _currentWord;
  ActivityFormat _currentFormat = ActivityFormat.completion;
  bool _isChecked = false;
  bool _submittingAnswer = false; // Guard against duplicate answer submissions
  bool _isCorrect = false;

  // Activity alternation index
  int _activityIndex = 0;

  // Format 1: Completion Options & Free-type Controllers
  List<String> _completionOptions = [];
  final Map<int, String> _selectedCompletionWords = {};
  final Map<int, TextEditingController> _completionControllers = {};
  final List<CompletionToken> _completionTokens = [];

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
    WidgetsBinding.instance.addObserver(this);
    _moduleStartTime = DateTime.now();
    
    if (!widget.isSandbox) {
      LocalStorageService.saveActiveLessonSession(
        widget.lessonId,
        widget.sessionId,
        '/session/${widget.sessionId}/sentence-building',
      );
    }
    
    _initializeTts();
    _loadLessonData();
  }

  Future<void> _initializeTts() async {
    try {
      await _ttsService.initialize();
    } catch (e) {
      debugPrint('TTS initialization warning: $e');
    }
    try {
      await _streamingSttService.initialize();
    } catch (e) {
      debugPrint('STT initialization warning: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _recordingSessionActive = false;
    _amplitudeSubscription?.cancel();
    _silenceTimer?.cancel();
    _ttsService.stop();
    _sttService.dispose();
    _streamingSttService.dispose();
    _liveTranscriptNotifier.dispose();
    _recorderService.dispose();
    _activityTimer?.cancel();
    for (final c in _completionControllers.values) {
      c.dispose();
    }
    _completionControllers.clear();
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

  Future<void> _loadLessonData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessonProvider = Provider.of<LessonProvider>(
        context,
        listen: false,
      );
      List<VocabularyWordModel> fetchedWords = [];
      List<Map<String, dynamic>> fetchedConfusables = [];

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final posFocus = auth.learner?.posFocus;
      final String? filter = (posFocus != null && posFocus != 'ALL' && posFocus.isNotEmpty)
          ? posFocus
          : null;

      // Prefer words passed via navigation (preserves user's selection: ALL vs NOUN/VERB)
      if (widget.allWords.isNotEmpty) {
        fetchedWords = widget.allWords
            .map((w) => VocabularyWordModel.fromJson(w))
            .toList();
      } else if (widget.isSandbox) {
        // Sandbox: fetch the sandbox session words only
        try {
          final mixed = await lessonProvider.getCumulativeMixedReview(
            widget.sessionId,
            isSandbox: true,
          );
          if (mixed.isNotEmpty) {
            fetchedWords = mixed
                .map(
                  (m) => VocabularyWordModel.fromJson({
                    'wordId': m['wordId'] ?? m['word'] ?? '',
                    'lessonId': widget.lessonId,
                    'englishWord': m['word'] ?? m['englishWord'] ?? '',
                    'cebuanoMeaning':
                        m['definition'] ?? m['cebuanoMeaning'] ?? '',
                    'exampleSentenceEnglish':
                        m['example'] ?? m['exampleSentenceEnglish'] ?? '',
                  }),
                )
                .toList();
          }
        } catch (e) {
          setState(() {
            _error = 'Failed to load sandbox lesson: ${e.toString()}';
            _isLoading = false;
          });
          return;
        }
      } else {
        // Primary backend fetch: respects filter ('NOUN', 'VERB', or null for 'ALL')
        fetchedWords = await lessonProvider.loadVocabulary(
          widget.lessonId,
          partOfSpeech: filter,
        );
      }

      if (!widget.isSandbox) {
        _wordDifficulties = await lessonProvider.loadWordDifficulties(widget.lessonId, moduleNumber: 3);
        
        // Module 3: Force all non-MASTERED words to start at FAMILIAR (Stage 2)
        // This ensures the Round 1: Familiar Level behavior as specified
        for (final word in fetchedWords) {
          final currentTier = (_wordDifficulties[word.wordId] ?? 'FAMILIAR').toUpperCase();
          if (currentTier != 'MASTERED') {
            _wordDifficulties[word.wordId] = 'FAMILIAR';
          }
        }
      }

      // Fallback 1: try lesson activity endpoint if still empty
      if (fetchedWords.isEmpty) {
        final activity = await lessonProvider.loadLessonActivity(
          widget.lessonId,
          partOfSpeech: filter,
        );
        if (activity.isNotEmpty) {
          fetchedWords = activity
              .map(
                (m) => VocabularyWordModel.fromJson({
                  'wordId': m['wordId'] ?? m['id'] ?? '',
                  'lessonId': widget.lessonId,
                  'englishWord': m['word'] ?? m['englishWord'] ?? '',
                  'cebuanoMeaning':
                      m['definition'] ?? m['cebuanoMeaning'] ?? '',
                  'exampleSentenceEnglish':
                      m['example'] ?? m['exampleSentenceEnglish'] ?? '',
                }),
              )
              .toList();
        }
      }

      fetchedConfusables = (!widget.isSandbox && widget.moduleNumber == 3)
          ? await lessonProvider.loadConfusablePairs(widget.lessonId)
          : <Map<String, dynamic>>[];

      debugPrint(
        'SentenceBuilding: allWords=${widget.allWords.length}, fetchedWords=${fetchedWords.length}, confusables=${fetchedConfusables.length}',
      );

      if (!mounted) return;

      if (fetchedWords.isEmpty) {
        setState(() {
          _error = "Failed to load vocabulary words.";
          _isLoading = false;
        });
        return;
      }

      // Restore progress snapshot if the learner exited mid-session
      if (!widget.isSandbox) {
        final snapshot = await LocalStorageService.getModuleProgressSnapshot(widget.sessionId);
        if (snapshot != null && snapshot['lessonId'] == widget.lessonId) {
          final savedDiffs = snapshot['wordDifficulties'];
          if (savedDiffs is Map) {
            final overrides = Map<String, String>.fromEntries(
              savedDiffs.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())),
            );
            // Merge saved difficulties — but force non-MASTERED to FAMILIAR for Module 3
            for (final entry in overrides.entries) {
              final tier = entry.value.toUpperCase();
              if (tier == 'MASTERED') {
                _wordDifficulties[entry.key] = 'MASTERED';
              } else {
                _wordDifficulties[entry.key] = 'FAMILIAR'; // Force to FAMILIAR for Module 3
              }
            }
            debugPrint('SentenceBuilding: Restored ${overrides.length} word difficulties from prior session snapshot.');
          }

          final savedStages = snapshot['wordStages'];
          if (savedStages is Map) {
            for (final entry in savedStages.entries) {
              final stageVal = int.tryParse(entry.value.toString());
              if (stageVal != null) {
                // Only restore stage if it's MASTERED, otherwise default to FAMILIAR (Stage 2)
                // This ensures Round 1: Familiar Level behavior as specified
                if (stageVal >= 4) {
                  _wordStage[entry.key.toString()] = stageVal;
                } else {
                  _wordStage[entry.key.toString()] = 2; // Force to FAMILIAR
                }
              }
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _words = fetchedWords;
        _totalUniqueWords = fetchedWords.length;
        _confusablePairs = fetchedConfusables;

        // Fresh words entering Module 3 start at FAMILIAR (Stage 2: Sentence Completion).
        // If answered correctly -> advances to Proficient. If answered wrong -> drops to Learning.
        // Preserve MASTERED words - only initialize new words to FAMILIAR
        for (final w in fetchedWords) {
          final currentTier = (_wordDifficulties[w.wordId] ?? 'FAMILIAR').toUpperCase();
          if (currentTier == 'MASTERED') {
            // Keep MASTERED words at Stage 4
            _wordStage.putIfAbsent(w.wordId, () => 4);
            _wordDifficulties.putIfAbsent(w.wordId, () => 'MASTERED');
          } else {
            // Force all non-MASTERED words to Stage 2 (FAMILIAR)
            _wordStage[w.wordId] = 2;
            _wordDifficulties[w.wordId] = 'FAMILIAR';
          }
        }

        // Build queue: start all active words at Familiar (Stage 2)
        _queue = List<VocabularyWordModel>.from(fetchedWords);
        
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
    final raw = (word.sentenceCompletionSentence?.trim().isNotEmpty ?? false)
        ? word.sentenceCompletionSentence!.trim()
        : word.exampleSentenceEnglish;
    return raw.replaceAll(
      RegExp(r'^Complete the sentence:\s*', caseSensitive: false),
      '',
    );
  }

  String _activityAnswer(VocabularyWordModel word) {
    final answerRaw = (word.sentenceCompletionAnswer?.trim().isNotEmpty ?? false)
        ? word.sentenceCompletionAnswer!.trim()
        : word.englishWord;
    return answerRaw;
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


  List<String> _activityArrangementTokens(VocabularyWordModel word) {
    final sentence =
        (word.tileSentence != null && word.tileSentence!.trim().isNotEmpty)
        ? word.tileSentence!
        : (word.exampleSentenceEnglish.trim().isNotEmpty
              ? word.exampleSentenceEnglish
              : word.englishWord);
    return _tokensFromSentence(sentence);
  }

  List<String> _tokensFromSentence(String sentence) {
    return sentence
        .replaceAll(RegExp(r"[^\p{L}\p{N}' ]", unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
  }


  void _startNextItem() {
    while (_queue.isNotEmpty) {
      final candidate = _queue.removeAt(0);
      final stage = _getWordStage(candidate.wordId);
      if (stage < 4) {
        _currentWord = candidate;
        _currentPhase = Phase.sentenceActivity;
        
        // Every word starts with Sentence Completion at its current level
        _currentFormat = ActivityFormat.completion;

        setState(() {
          _resetItemState();
        });
        return;
      }
    }

    // All words in the queue are completed or mastered
    _handleQueueEmpty();
  }

  void _resetItemState() {
    _isChecked = false;
    _submittingAnswer = false; // Reset dedupe guard for new question
    _isCorrect = false;
    for (final c in _completionControllers.values) {
      c.dispose();
    }
    _completionControllers.clear();
    _selectedCompletionWords.clear();
    _completionTokens.clear();
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
    
    _startActivityTimer();
  }
  
  void _startActivityTimer() {
    _activityTimer?.cancel();
    
    final stage = _getWordStage(_currentWord.wordId);
    if (stage == 1 || stage == 2) {
      _totalSeconds = 40; // Learning & Familiar: 40 seconds
    } else if (stage == 3) {
      _totalSeconds = 35; // Proficient: 35 seconds
    } else {
      _totalSeconds = 0;
    }
    
    _remainingSeconds = _totalSeconds;
    
    if (_totalSeconds <= 0) return;

    _activityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isChecked) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _checkAnswer(timeUp: true);
        }
      });
    });
  }




  void _parseDynamicBlanks() {
    _completionTokens.clear();
    final sentence = _activitySentence(_currentWord);
    final targetWord = _activityAnswer(_currentWord).trim().toLowerCase();
    final stage = _getWordStage(_currentWord.wordId);
    
    // Determine number of blanks based on stage (revised format)
    // Stage 1 (LEARNING): 1 blank
    // Stage 2 (FAMILIAR): 2 blanks  
    // Stage 3 (PROFICIENT): 3 blanks (free type)
    int numBlanks;
    switch (stage) {
      case 1: numBlanks = 1; break;
      case 2: numBlanks = 2; break;
      case 3: numBlanks = 3; break;
      default: numBlanks = 2; break; // Default to Familiar
    }
    
    // First, check if the sentence explicitly contains a placeholder
    final placeholderExp = RegExp(r"\{\s*BLANK\s*\}|_{3,}", caseSensitive: false);
    final placeholderMatches = placeholderExp.allMatches(sentence).toList();
    
    if (placeholderMatches.isNotEmpty) {
      // Use explicit placeholders - but limit to stage-appropriate number
      int lastEnd = 0;
      int blanksUsed = 0;
      for (final match in placeholderMatches) {
        if (blanksUsed >= numBlanks) {
          // Don't add more blanks than stage allows
          if (match.start > lastEnd) {
            _completionTokens.add(CompletionToken(text: sentence.substring(lastEnd, match.start), isBlank: false));
          }
          _completionTokens.add(CompletionToken(
            text: match.group(0)!, // Keep original placeholder as text
            isBlank: false, 
            answer: null
          ));
          lastEnd = match.end;
          continue;
        }
        
        if (match.start > lastEnd) {
          _completionTokens.add(CompletionToken(text: sentence.substring(lastEnd, match.start), isBlank: false));
        }
        _completionTokens.add(CompletionToken(
          text: '____', 
          isBlank: true, 
          answer: targetWord
        ));
        lastEnd = match.end;
        blanksUsed++;
      }
      if (lastEnd < sentence.length) {
        _completionTokens.add(CompletionToken(text: sentence.substring(lastEnd), isBlank: false));
      }
      return;
    }
    
    final RegExp wordExp = RegExp(r"[\w'-]+");
    final matches = wordExp.allMatches(sentence).toList();
    
    // Find target word index
    int targetMatchIdx = -1;
    for (int i = 0; i < matches.length; i++) {
      if (matches[i].group(0)!.toLowerCase() == targetWord) {
        targetMatchIdx = i;
        break;
      }
    }
    // If not found exactly, match partial word or pick longest word
    if (targetMatchIdx == -1 && matches.isNotEmpty) {
      for (int i = 0; i < matches.length; i++) {
        final m = matches[i].group(0)!.toLowerCase();
        if (m.contains(targetWord) || targetWord.contains(m)) {
          targetMatchIdx = i;
          break;
        }
      }
    }
    if (targetMatchIdx == -1 && matches.isNotEmpty) {
      int maxLen = 0;
      for (int i = 0; i < matches.length; i++) {
        if (matches[i].group(0)!.length > maxLen) {
          maxLen = matches[i].group(0)!.length;
          targetMatchIdx = i;
        }
      }
    }

    // Select words to blank based on stage
    List<int> blankIndices = [];
    if (targetMatchIdx != -1) {
      blankIndices.add(targetMatchIdx);
      
      // Add additional blanks based on stage
      if (numBlanks > 1 && matches.length > 1) {
        // Add adjacent words for additional blanks
        for (int offset = 1; blankIndices.length < numBlanks; offset++) {
          // Try word before target
          if (targetMatchIdx - offset >= 0 && !blankIndices.contains(targetMatchIdx - offset)) {
            blankIndices.add(targetMatchIdx - offset);
          }
          // Try word after target
          if (blankIndices.length < numBlanks && targetMatchIdx + offset < matches.length && !blankIndices.contains(targetMatchIdx + offset)) {
            blankIndices.add(targetMatchIdx + offset);
          }
          // If still need more blanks, add any other words
          if (blankIndices.length < numBlanks) {
            for (int i = 0; i < matches.length; i++) {
              if (!blankIndices.contains(i)) {
                blankIndices.add(i);
                if (blankIndices.length >= numBlanks) break;
              }
            }
          }
        }
      }
    }

    int lastEnd = 0;
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start > lastEnd) {
         _completionTokens.add(CompletionToken(text: sentence.substring(lastEnd, match.start), isBlank: false));
      }
      
      bool isBlank = blankIndices.contains(i);
      _completionTokens.add(CompletionToken(
        text: isBlank ? '____' : match.group(0)!, 
        isBlank: isBlank, 
        answer: isBlank ? match.group(0)! : null
      ));
      lastEnd = match.end;
    }
    if (lastEnd < sentence.length) {
      _completionTokens.add(CompletionToken(text: sentence.substring(lastEnd), isBlank: false));
    }
  }

  void _generateCompletionOptions() {
    _parseDynamicBlanks();
    
    final stage = _getWordStage(_currentWord.wordId);
    
    // Stage 3 (PROFICIENT) should be free type - no multiple choice options
    if (stage >= 3) {
      _completionOptions = [];
      return;
    }
    
    // The correct answers are all the blanked words
    final correctAnswers = _completionTokens
        .where((t) => t.isBlank && t.answer != null)
        .map((t) => t.answer!)
        .toList();

    // Use options from the database!
    final List<String> dbOptions = [];
    if (_currentWord.sentenceCompletionOption1?.trim().isNotEmpty ?? false) dbOptions.add(_currentWord.sentenceCompletionOption1!.trim());
    if (_currentWord.sentenceCompletionOption2?.trim().isNotEmpty ?? false) dbOptions.add(_currentWord.sentenceCompletionOption2!.trim());
    if (_currentWord.sentenceCompletionOption3?.trim().isNotEmpty ?? false) dbOptions.add(_currentWord.sentenceCompletionOption3!.trim());
    
    if (dbOptions.isEmpty) {
      if (_currentWord.mcDistractor1?.trim().isNotEmpty ?? false) dbOptions.add(_currentWord.mcDistractor1!.trim());
      if (_currentWord.mcDistractor2?.trim().isNotEmpty ?? false) dbOptions.add(_currentWord.mcDistractor2!.trim());
      if (_currentWord.mcDistractor3?.trim().isNotEmpty ?? false) dbOptions.add(_currentWord.mcDistractor3!.trim());
    }

    final pool = dbOptions.toSet().toList();

    // Only fallback if the database has absolutely no distractors for this word
    if (pool.isEmpty) {
      // Build a pool from other words in the session
      final sessionWords = _words
          .where((word) => word.wordId != _currentWord.wordId)
          .map((word) => word.englishWord)
          .toList();
      pool.addAll(sessionWords);

      final fallbackDistractors = [
        'apple', 'house', 'water', 'friend', 'school',
        'book', 'tree', 'happy', 'run', 'big', 'small', 'quickly'
      ];
      pool.addAll(fallbackDistractors);
    }
    
    pool.removeWhere((w) => correctAnswers.any((ans) => ans.toLowerCase() == w.toLowerCase()));

    // Calculate distractors based on stage (revised format)
    // Stage 1 (LEARNING): 1 blank + 2 distractors = 3 total options
    // Stage 2 (FAMILIAR): 2 blanks + 3 distractors = 5 total options
    int numDistractors = (stage == 1) ? 2 : 3;

    pool.shuffle();
    // Use whatever distractors we have up to numDistractors
    final distractors = pool.take(numDistractors).toList();

    _completionOptions = [...correctAnswers, ...distractors];
    _completionOptions.shuffle();
  }

  void _generateRearrangementChips() {
    final List<String> allTokens = _activityArrangementTokens(_currentWord);
    if (allTokens.length < 2) {
      _currentFormat = ActivityFormat.completion;
      _generateCompletionOptions();
      return;
    }

    final stage = _getWordStage(_currentWord.wordId);
    int n = allTokens.length;
    int tileCount = 3;
    int fakeCount = 0;

    // Revised tile counts based on stage
    if (stage == 1) {
      // Stage 1 (Learning): 1 tile to place (target word) + 2 distractors
      tileCount = 1;
      fakeCount = 2;
    } else if (stage == 2) {
      // Stage 2 (Familiar): 2 tiles to place + 2 distractors
      tileCount = 2;
      fakeCount = 2;
    } else if (stage == 3) {
      // Stage 3 (Proficient): 3 tiles to arrange, NO distractors
      tileCount = 3;
      fakeCount = 0;
    } else {
      tileCount = 3;
      fakeCount = 0;
    }
    if (tileCount > n) tileCount = n;

    // Identify target index for centering the partial tiles
    String targetWord = _currentWord.englishWord.trim();
    int targetIdx = -1;
    for (int i = 0; i < allTokens.length; i++) {
      if (allTokens[i].toLowerCase() == targetWord.toLowerCase()) {
        targetIdx = i;
        break;
      }
    }
    if (targetIdx == -1) targetIdx = 0;

    int radiusLeft = ((tileCount - 1) / 2.0).floor();
    int radiusRight = ((tileCount - 1) / 2.0).ceil();

    int startIndex = targetIdx - radiusLeft;
    int endIndex = targetIdx + radiusRight;

    if (startIndex < 0) {
      int shiftAmount = 0 - startIndex;
      startIndex = 0;
      endIndex = (endIndex + shiftAmount) < (n - 1)
          ? (endIndex + shiftAmount)
          : (n - 1);
    } else if (endIndex >= n) {
      int shiftAmount = endIndex - (n - 1);
      endIndex = n - 1;
      startIndex = (startIndex - shiftAmount) > 0
          ? (startIndex - shiftAmount)
          : 0;
    }

    _expectedArrangementTokens = allTokens.sublist(startIndex, endIndex + 1);
    _arrangementStartIndex = startIndex;
    _arrangementEndIndex = endIndex;
    _scrambledWords = List.from(_expectedArrangementTokens);

    if (fakeCount > 0) {
      final ownDistractors = [
        _currentWord.mcDistractor1,
        _currentWord.mcDistractor2,
        _currentWord.mcDistractor3,
      ].whereType<String>().where((d) => d.trim().isNotEmpty).toList();
      
      ownDistractors.shuffle();
      
      int added = 0;
      for (int i = 0; i < fakeCount && i < ownDistractors.length; i++) {
        _scrambledWords.add(ownDistractors[i]);
        added++;
      }
      
      if (added < fakeCount) {
        final fallback = ['apple', 'house', 'water', 'friend', 'school', 'book'];
        fallback.shuffle();
        for (int i = 0; i < (fakeCount - added) && i < fallback.length; i++) {
          if (!_scrambledWords.contains(fallback[i]) && !_expectedArrangementTokens.contains(fallback[i])) {
            _scrambledWords.add(fallback[i]);
          }
        }
      }
    }

    // Keep scrambling until it's not the same as the original (or up to 10 tries)
    int attempts = 0;
    bool isSame = true;
    while (isSame && attempts < 10) {
      _scrambledWords.shuffle();
      isSame = false;
      if (_scrambledWords.length == _expectedArrangementTokens.length) {
        for (int i = 0; i < _scrambledWords.length; i++) {
          if (_scrambledWords[i] != _expectedArrangementTokens[i]) {
            isSame = false;
            break;
          }
          isSame = true;
        }
      }
      attempts++;
    }
  }

  Future<void> _handleQueueEmpty() async {
    debugPrint(
      'Queue empty! isReinforcementPass: $_isReinforcementPass, failedWords: ${_failedSentenceWords.length}',
    );
    // 1. If we finished the initial pass
    if (!_isReinforcementPass) {
      // Transition to reinforcement pass if we failed any words
      if (_failedSentenceWords.isNotEmpty) {
        debugPrint(
          'Starting reinforcement pass with ${_failedSentenceWords.length} failed words',
        );
        setState(() {
          _isReinforcementPass = true;
          _queue = List.from(_failedSentenceWords);
          _failedSentenceWords.clear();
          _startNextItem();
        });
      } else {
        debugPrint('No failed words, checking mastery...');
        await _checkMasteryAndLoopOrComplete();
      }
    } else {
      debugPrint('Reinforcement pass complete, checking mastery...');
      await _checkMasteryAndLoopOrComplete();
    }
  }

  Future<void> _checkMasteryAndLoopOrComplete() async {
    final unmasteredWords = _words.where((w) {
      final stage = _getWordStage(w.wordId);
      return stage < 4;
    }).toList();

    if (unmasteredWords.isNotEmpty) {
      debugPrint('SentenceBuilding: ${unmasteredWords.length} words not yet MASTERED (Stage 4). Re-queuing...');
      
      // Shuffle the words that still need to advance
      final List<VocabularyWordModel> requeue = List.from(unmasteredWords)..shuffle();
      
      setState(() {
        _queue = requeue;
        _isReinforcementPass = false;
      });
      
      _startNextItem();
    } else {
      debugPrint('SentenceBuilding: All words reached MASTERED (Stage 4). Completing module...');
      await _completeModuleAndAdvance();
    }
  }

  void _checkConfusableAnswers() {
    final pair = _activeConfusablePair!;
    final wordA = pair['wordA']['englishWord'] as String;
    final wordB = pair['wordB']['englishWord'] as String;
    final isCorrectA =
        _confusableSelectedForA?.toLowerCase() == wordA.toLowerCase();
    final isCorrectB =
        _confusableSelectedForB?.toLowerCase() == wordB.toLowerCase();
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
        setState(() {
          _isReinforcementPass = true;
          _queue = List.from(_failedSentenceWords);
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

    final totalAttempts = (_initialPassCorrectCount + _failedSentenceWords.length).clamp(1, 9999);
    final totalCorrect = _initialPassCorrectCount;
    final overallScore = ((totalCorrect / totalAttempts) * 100.0).clamp(0.0, 100.0);
    final int activeSeconds = _computeActiveSeconds();

    try {
      await Provider.of<LessonProvider>(
        context,
        listen: false,
      ).persistModuleScore(
        widget.lessonId,
        widget.isSandbox ? null : 3,
        totalCorrect,
        totalAttempts,
        isSandbox: widget.isSandbox,
        sessionId: widget.sessionId,
        timeSeconds: activeSeconds,
      );
    } catch (e) {
      debugPrint('Module 3 score sync failed, continuing anyway: $e');
    }

    // Clear the saved progress snapshot and active lesson session now that the module is complete
    await LocalStorageService.clearModuleProgressSnapshot(widget.sessionId);
    await LocalStorageService.clearActiveLessonSession(widget.lessonId);

    if (!mounted) return;

    debugPrint(
      'Module 3 score: completedCount=$totalCorrect, totalActivities=$totalAttempts, totalWords=$_totalUniqueWords, score=$overallScore%',
    );

    // Get failed sentence word IDs
    final failedSentenceWordIds = _failedSentenceWords
        .map((w) => w.wordId)
        .toSet();

    // Use provided lessonTitle or fall back to formatted string
    final displayTitle = widget.isSandbox
        ? 'Sandbox Lesson Complete'
        : (widget.lessonTitle?.isNotEmpty == true
              ? widget.lessonTitle!
              : 'Lesson Complete');
    final confusableMasteredCount = _confusableMastery.values
        .where((v) => v)
        .length;

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

    debugPrint('Navigating to lesson score screen...');
    // ignore: use_build_context_synchronously
    navContext.push(
      '/loading',
      extra: {
        'duration': 13000,
        'redirectPath': '/session/${widget.sessionId}/lesson-score',
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


  void _checkAnswer({bool timeUp = false}) {
    // Dedupe guard: prevent timer + button tap from both firing
    if (_submittingAnswer || _isChecked) return;
    _submittingAnswer = true;
    if (timeUp) {
      _isCorrect = false;
    } else {
      if (_currentFormat == ActivityFormat.completion) {
        final blanks = _completionTokens.where((t) => t.isBlank).toList();
        if (_selectedCompletionWords.length < blanks.length) return; // not all filled
        
        bool allCorrect = true;
        int blankIndex = 0;
        for (final token in _completionTokens) {
          if (token.isBlank) {
            final userWord = _selectedCompletionWords[blankIndex]?.toLowerCase().trim();
            final targetWord = token.answer?.toLowerCase().trim();
            if (userWord != targetWord) {
              allCorrect = false;
              break;
            }
            blankIndex++;
          }
        }
        _isCorrect = allCorrect;
      } else {
        final expected = _expectedArrangementTokens
            .join(' ')
            .toLowerCase()
            .trim();
        final learner = _assembledWords.join(' ').toLowerCase().trim();
        _isCorrect = learner == expected;
      }
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

    if (widget.isSandbox) {
      if (_isCorrect) {
        if (_currentFormat == ActivityFormat.rearrangement) {
          final currentStage = _getWordStage(_currentWord.wordId);
          final nextStage = (currentStage + 1).clamp(0, 5);
          final nextTier = _getStageTier(nextStage);

          setState(() {
            _wordStage[_currentWord.wordId] = nextStage;
            _wordDifficulties[_currentWord.wordId] = nextTier;
            if (nextStage == 5) {
              _sentenceMasteredWordIds.add(_currentWord.wordId);
            }
          });
        }
      }
    } else {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      provider.submitPracticeResult(
        widget.sessionId,
        _currentWord.wordId,
        _isCorrect,
        activityType: _currentFormat == ActivityFormat.completion
            ? 'SENTENCE_COMPLETION'
            : 'SENTENCE_ARRANGEMENT',
      );
      provider.submitReviewItem(
        sessionId: widget.sessionId,
        wordId: _currentWord.wordId,
        isCorrect: _isCorrect,
        confidence: 3,
      );
      
      // Wire up Difficulty API for Module 3
      provider.submitDifficultyResult(
        _currentWord.wordId,
        _isCorrect,
        activityType: _currentFormat == ActivityFormat.completion ? 'SENTENCE_COMPLETION' : 'SENTENCE_ARRANGEMENT',
        moduleNumber: widget.moduleNumber,
      ).then((res) {
        if (mounted && res != null) {
          final newLevel = res['currentLevel']?.toString() ?? '';
          if (newLevel == 'MASTERED') {
            setState(() {
              _wordStage[_currentWord.wordId] = 4;
              _wordDifficulties[_currentWord.wordId] = 'MASTERED';
              _sentenceMasteredWordIds.add(_currentWord.wordId);
            });
          }
        }
      });
    }

    setState(() {
      _isChecked = true;
    });
  }

  void _advanceCurrentWordStage() {
    final currentStage = _getWordStage(_currentWord.wordId);
    final nextStage = (currentStage + 1).clamp(1, 4);
    final nextTier = _getStageTier(nextStage);

    setState(() {
      _wordStage[_currentWord.wordId] = nextStage;
      _wordDifficulties[_currentWord.wordId] = nextTier;
      // Update max stage for consistent progress (never decreases)
      _maxWordStage[_currentWord.wordId] = _maxWordStage[_currentWord.wordId] != null 
          ? max(_maxWordStage[_currentWord.wordId]!, nextStage)
          : nextStage;
    });

    final provider = Provider.of<LessonProvider>(context, listen: false);
    if (!widget.isSandbox) {
      provider.updateWordProgress(
        widget.sessionId,
        _currentWord.wordId,
        'FULL',
        4,
        nextTier,
        moduleNumber: widget.moduleNumber,
      );
    }
    
    if (!_isReinforcementPass) {
      _initialPassCompletedCount++;
    }

    if (nextStage < 4) {
      // Add to the back of queue so word cycles into the next tier (Learning -> Familiar -> Proficient)!
      // But if there are failed words needing priority, add after them
      if (_failedSentenceWords.isNotEmpty) {
        _queue.insert(_failedSentenceWords.length, _currentWord);
      } else {
        _queue.add(_currentWord);
      }
      debugPrint('SentenceBuilding: Word ${_currentWord.englishWord} advanced to Stage $nextStage ($nextTier). Queued for next cycle.');
    } else {
      _sentenceMasteredWordIds.add(_currentWord.wordId);
      debugPrint('SentenceBuilding: Word ${_currentWord.englishWord} reached MASTERED (Stage 4)!');
    }
  }

  Future<void> _handleContinueFromSentence() async {
    final stage = _getWordStage(_currentWord.wordId);
    debugPrint('Continue button tapped in Module 3 (format: $_currentFormat, phase: $_currentPhase, stage: $stage)');
    
    if (_isCorrect) {
      // 1 correct answer = advance - simplified progression
      if (_currentFormat == ActivityFormat.completion) {
        // Sentence Completion correct -> Immediately transition to Sentence Arrangement for same word
        setState(() {
          _currentFormat = ActivityFormat.rearrangement;
          _resetItemState();
        });
        return;
      }

      // Sentence Arrangement correct
      if (stage < 3) {
        // Stages 1 & 2 (Learning & Familiar): 1 correct answer -> Advance to next stage immediately
        _advanceCurrentWordStage();
        _startNextItem();
      } else {
        // Stage 3 (Proficient): Sentence Arrangement correct -> Trigger Pronunciation
        setState(() {
          _currentPhase = Phase.pronunciationFeedback;
          _resetItemState();
        });
      }
    } else {
      // Simplified downgrade: 1 mistake -> drop 1 stage, continue from there
      // Don't restart entire cycle - just continue from the dropped stage
      final prevStage = (stage - 1).clamp(1, 4);
      final prevTier = _getStageTier(prevStage);

      setState(() {
        _wordStage[_currentWord.wordId] = prevStage;
        _wordDifficulties[_currentWord.wordId] = prevTier;
        // Max stage is not decreased - progress stays consistent
        _maxWordStage[_currentWord.wordId] = _maxWordStage[_currentWord.wordId] != null 
            ? max(_maxWordStage[_currentWord.wordId]!, stage)
            : stage;
        // Reset consecutive failure counter on downgrade
        _consecutiveFailures[_currentWord.wordId] = 0;
      });

      final provider = Provider.of<LessonProvider>(context, listen: false);
      if (!widget.isSandbox) {
        provider.updateWordProgress(
          widget.sessionId,
          _currentWord.wordId,
          'FULL',
          4,
          prevTier,
          moduleNumber: widget.moduleNumber,
        );
      }

      if (!_failedSentenceWords.any((w) => w.wordId == _currentWord.wordId)) {
        _failedSentenceWords.add(_currentWord);
      }
      
      // Priority requeue - continue from the dropped stage (don't restart cycle)
      _queue.insert(0, _currentWord);
      debugPrint('SentenceBuilding: Word ${_currentWord.englishWord} failed at Stage $stage ($_currentFormat), dropped to Stage $prevStage ($prevTier). Requeued with priority to continue from dropped stage.');
      _startNextItem();
    }
  }

  // Pronunciation flow
  Future<void> _startRecording() async {
    if (_isRecording || _isEvaluating || _attemptResult != null || _disposed) {
      return;
    }

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
      // that Deepgram cannot transcribe (returns empty transcript â†’ 400).
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
    final wasActiveAttempt =
        _recordingSessionActive && _isRecording && _attemptResult == null;
    final shouldMarkFailure =
        wasActiveAttempt && _pronunciationAttempt >= _maxAttempts;

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
          _pronunciationAttempt = _pronunciationAttempt < _maxAttempts
              ? _pronunciationAttempt + 1
              : _maxAttempts;
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



  void _startAutoEvaluationMonitoring() {
    _stopAutoEvaluationMonitoring();
    _recordingStartedAt = DateTime.now();

    _amplitudeSubscription = _recorderService.onAmplitudeChanged.listen((
      amplitude,
    ) {
      if (!_isRecording || _isEvaluating || _attemptResult != null) return;
      if (amplitude > 0.18) {
        _lastSpeechAt = DateTime.now();
      }
    });

    _silenceTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !_isRecording || _isEvaluating || _attemptResult != null) {
        return;
      }
      final startedAt = _recordingStartedAt;
      if (startedAt == null) return;

      final elapsed = DateTime.now().difference(startedAt);
      final lastSpeechAt = _lastSpeechAt;
      final shouldFinishForSilence =
          lastSpeechAt != null &&
          DateTime.now().difference(lastSpeechAt) >=
              const Duration(milliseconds: 900);
      final shouldFinishForTimeout = elapsed >= const Duration(seconds: 30);

      if (shouldFinishForSilence || shouldFinishForTimeout) {
        _finishRecordingAndEvaluate();
      }
    });
  }

  Future<void> _finishRecordingAndEvaluate() async {
    if (_isEvaluating || !_isRecording || _attemptResult != null || _disposed) {
      return;
    }

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

    final bool isPassed =
        result.isCorrect && ((result.similarityScore ?? 1.0) >= 0.80);
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

    final shouldRetry =
        _recordingSessionActive && _pronunciationAttempt < _maxAttempts;
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

    // Pronunciation is practice-only and not part of core scoring
    if (!widget.isSandbox) {
      await provider.updateWordProgress(
        widget.sessionId,
        _currentWord.wordId,
        'FULL',
        4,
        'MASTERED',
        moduleNumber: widget.moduleNumber,
      );
    }
    // Advance word stage to MASTERED (Stage 4)
    _advanceCurrentWordStage();
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
            "Gently touch your upper front teeth to your lower lip and push air out â€” "
            "like blowing out a candle slowly. Practice: 'fff-ish', 'fff-ather'.";
      case 'v_sound':
        return "The /v/ sound doesn't exist in Cebuano. "
            "Touch your upper teeth to your lower lip and hum â€” feel the vibration. "
            "It's like /f/ but with your voice on. Practice: 'vvv-ery', 'vvv-oice'.";
      case 'th_sound':
        return "The /Î¸/ (TH) sound doesn't exist in Cebuano. "
            "Place the tip of your tongue lightly between your upper and lower front teeth, "
            "then blow air out gently. Practice: 'th-ink', 'th-ree', 'th-ank'.";
      case 'th_voiced':
        return "The voiced /Ã°/ (TH) sound is like 'th' in 'the' or 'this'. "
            "Put your tongue between your teeth and hum â€” feel the buzz. "
            "Practice: 'th-is', 'th-at', 'broth-er'.";
      case 'r_sound':
        return "English /r/ is different from Cebuano. "
            "Keep your tongue back and curved â€” don't roll it. "
            "The tongue should not touch the roof of your mouth. Practice: 'rr-un', 'rr-ead'.";
      case 'l_sound':
        return "For English /l/, place the tip of your tongue on the ridge just behind "
            "your upper front teeth and let air flow around the sides. "
            "Practice: 'll-ight', 'll-ove', 'bell'.";
      case 'short_i':
        return "The short /Éª/ sound (as in 'sit') is shorter and more relaxed than the long /iË/ in 'see'. "
            "Relax your lips and say a quick 'ih'. Practice: 'f-ih-sh', 's-ih-t', 'th-ih-s'.";
      case 'short_e':
        return "The /É›/ sound (as in 'bed') is made with your mouth slightly open and lips relaxed. "
            "It is between 'a' and 'ee'. Practice: 'b-eh-d', 'p-eh-n', 'h-eh-lp'.";
      case 'schwa':
        return "Many English unstressed syllables use the schwa /É™/ â€” a neutral, relaxed sound "
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
    if (score == null) return 'Not quite â€” give it another try!';
    final pct = (score * 100).round();
    if (pct >= 70) {
      return 'Very close ($pct%)! Small adjustment needed â€” try again.';
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
              const Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPhase == Phase.summary) {
      return _buildSummaryScreen();
    }

    double totalStagePoints = 0.0;
    for (final w in _words) {
      // Use max stage reached for consistent progress (never decreases)
      final maxStage = _maxWordStage[w.wordId] ?? _getWordStage(w.wordId);
      totalStagePoints += (maxStage - 1).clamp(0, 3);
    }

    final maxStagePoints = _words.length * 3.0;
    final progressVal = maxStagePoints > 0 ? (totalStagePoints / maxStagePoints).clamp(0.0, 1.0) : 0.0;
    final progressPercent = (progressVal * 100).round();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
            onPressed: _showExitConfirmation,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  '$progressPercent%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
          title: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progressVal),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFBBF24),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        body: _currentPhase == Phase.confusableDistinction
            ? _buildConfusableBody(theme)
            : _currentPhase == Phase.sentenceActivity
            ? _buildSentenceActivityBody(theme)
            : _buildPronunciationBody(theme),
      ),
    );
  }

  Widget _buildCompletionBlankSentence() {
    const wordStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Color(0xFF1E293B),
      height: 1.5,
    );

    final stage = _getWordStage(_currentWord.wordId);
    final isFreeType = stage >= 3;

    int blankIndex = 0;
    
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 8,
      children: _completionTokens.map((token) {
        if (!token.isBlank) {
          return Text(token.text, style: wordStyle);
        }

        final currentIndex = blankIndex;
        blankIndex++;

        if (isFreeType) {
          final isCorrect = _isChecked &&
              _selectedCompletionWords[currentIndex]?.toLowerCase().trim() ==
                  token.answer?.toLowerCase().trim();

          final controller = _completionControllers.putIfAbsent(
            currentIndex,
            () => TextEditingController(text: _selectedCompletionWords[currentIndex] ?? ''),
          );

          return Container(
            constraints: const BoxConstraints(minWidth: 110, maxWidth: 170),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: controller,
              enabled: !_isChecked,
              textAlign: TextAlign.center,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'type word',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                filled: true,
                fillColor: _isChecked
                    ? (isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2))
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF06A6FF), width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isChecked
                    ? (isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                    : const Color(0xFF1E293B),
              ),
              onChanged: (val) {
                setState(() {
                  if (val.trim().isEmpty) {
                    _selectedCompletionWords.remove(currentIndex);
                  } else {
                    _selectedCompletionWords[currentIndex] = val.trim();
                  }
                });
              },
            ),
          );
        } else {
          // Tap-to-choose Blank
          final filledWord = _selectedCompletionWords[currentIndex];
          final isCorrect = _isChecked &&
              filledWord?.toLowerCase() == token.answer?.toLowerCase();
          
          Color blankColor = const Color(0xFF94A3B8);
          Color blankBgColor = const Color(0xFFF1F5F9);
          String displayText = '_______';

          if (filledWord != null) {
            displayText = filledWord;
            blankColor = const Color(0xFF06A6FF);
            blankBgColor = const Color(0xFFEFF6FF);
          }
          if (_isChecked && filledWord != null) {
            blankColor = isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
            blankBgColor = isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
          }

          return GestureDetector(
            onTap: () {
              if (_isChecked || filledWord == null) return;
              setState(() {
                _selectedCompletionWords.remove(currentIndex);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: blankBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: blankColor, width: 2),
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: blankColor == const Color(0xFF94A3B8)
                      ? const Color(0xFF64748B)
                      : blankColor,
                ),
              ),
            ),
          );
        }
      }).toList(),
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
    final sentenceAFrame = sentenceA.replaceAll(
      RegExp('(?i)\\b${RegExp.escape(wordAEnglish)}\\b'),
      '________',
    );
    final sentenceBFrame = sentenceB.replaceAll(
      RegExp('(?i)\\b${RegExp.escape(wordBEnglish)}\\b'),
      '________',
    );
    final isCorrectA =
        _confusableSelectedForA?.toLowerCase() == wordAEnglish.toLowerCase();
    final isCorrectB =
        _confusableSelectedForB?.toLowerCase() == wordBEnglish.toLowerCase();

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
                  // Mascot
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: MascotBubble(
                      speechText: 'These words look similar but mean different things. Fill in the blanks correctly.',
                      mascotName: 'sippy',
                    ),
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
                            border: Border.all(
                              color: const Color(0xFF0284C7),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                wordAEnglish,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cebuano: $wordACebuano',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0284C7),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _ttsService.speak(wordAEnglish),
                                icon: const Icon(
                                  Icons.volume_up_rounded,
                                  size: 15,
                                ),
                                label: const Text('Listen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                            border: Border.all(
                              color: const Color(0xFFD97706),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                wordBEnglish,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cebuano: $wordBCebuano',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _ttsService.speak(wordBEnglish),
                                icon: const Icon(
                                  Icons.volume_up_rounded,
                                  size: 15,
                                ),
                                label: const Text('Listen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                      if (!_confusableChecked) {
                        setState(() => _confusableSelectedForA = wordAEnglish);
                      }
                    },
                    onSelectB: () {
                      if (!_confusableChecked) {
                        setState(() => _confusableSelectedForA = wordBEnglish);
                      }
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
                      if (!_confusableChecked) {
                        setState(() => _confusableSelectedForB = wordAEnglish);
                      }
                    },
                    onSelectB: () {
                      if (!_confusableChecked) {
                        setState(() => _confusableSelectedForB = wordBEnglish);
                      }
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
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: _confusableChecked
                ? Column(
                    children: [
                      if (!_confusableCorrect)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'Not quite! Review the meanings above and try again.',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _handleConfusableContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _confusableCorrect
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _confusableCorrect
                              ? LocalizationService.translate(
                                      Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference, 'continue')
                                  .toUpperCase()
                              : 'TRY AGAIN',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed:
                        (_confusableSelectedForA != null &&
                            _confusableSelectedForB != null)
                        ? _checkConfusableAnswers
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBF24),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'CHECK ANSWERS',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSelectA,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedWord == wordAEnglish
                        ? const Color(0xFFEFF6FF)
                        : Colors.white,
                    side: BorderSide(
                      color: selectedWord == wordAEnglish
                          ? const Color(0xFF06A6FF)
                          : const Color(0xFFCBD5E1),
                      width: selectedWord == wordAEnglish ? 2 : 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    wordAEnglish,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selectedWord == wordAEnglish
                          ? const Color(0xFF06A6FF)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSelectB,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedWord == wordBEnglish
                        ? const Color(0xFFEFF6FF)
                        : Colors.white,
                    side: BorderSide(
                      color: selectedWord == wordBEnglish
                          ? const Color(0xFF06A6FF)
                          : const Color(0xFFCBD5E1),
                      width: selectedWord == wordBEnglish ? 2 : 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    wordBEnglish,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: selectedWord == wordBEnglish
                          ? const Color(0xFF06A6FF)
                          : const Color(0xFF475569),
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
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (isChecked && isCorrect)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF22C55E),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Correct!',
                    style: TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildSentenceActivityBody(ThemeData theme) {
    final stage = _getWordStage(_currentWord.wordId);
    final isFreeType = stage >= 3;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    String mascotText;
    if (_isReinforcementPass) {
      mascotText = LocalizationService.translate(pref, 'prompt_sentence_review');
    } else if (_currentFormat == ActivityFormat.completion) {
      mascotText = isFreeType
          ? LocalizationService.translate(pref, 'prompt_sentence_type')
          : LocalizationService.translate(pref, 'prompt_sentence_select');
    } else {
      mascotText = LocalizationService.translate(pref, 'prompt_sentence_build');
    }

    String instructionText;
    if (_currentFormat == ActivityFormat.completion) {
      instructionText = isFreeType
          ? LocalizationService.translate(pref, 'instruction_sentence_type')
          : LocalizationService.translate(pref, 'instruction_sentence_select');
    } else {
      instructionText = LocalizationService.translate(pref, 'instruction_sentence_drag');
    }

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
                  // Mascot
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: MascotBubble(
                      speechText: mascotText,
                      mascotName: 'sippy',
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_totalSeconds > 0 && !_isChecked) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                LocalizationService.translate(pref, 'time_remaining'),
                                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '${_remainingSeconds}s',
                                style: TextStyle(
                                  color: _remainingSeconds <= 5 ? Colors.redAccent : const Color(0xFF06A6FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _totalSeconds > 0 ? (_remainingSeconds / _totalSeconds) : 0.0,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _remainingSeconds <= 5 ? Colors.redAccent : const Color(0xFF06A6FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Instructions text and Level indicator dot
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          instructionText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      () {
                        final int currentStage = _getWordStage(_currentWord.wordId);
                        Color dotColor;
                        String label;
                        switch (currentStage) {
                          case 1:
                          case 2:
                            dotColor = const Color(0xFF3B82F6);
                            label = 'Familiar';
                            break;
                          case 3:
                          case 4:
                          case 5:
                            dotColor = const Color(0xFFF59E0B);
                            label = 'Proficient';
                            break;
                          default:
                            dotColor = const Color(0xFF94A3B8);
                            label = 'Learning';
                            break;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: dotColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: dotColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: dotColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }(),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (_currentFormat == ActivityFormat.rearrangement &&
                      !_isChecked) ...[
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
                                    side: const BorderSide(
                                      color: Color(0xFF06A6FF),
                                      width: 1.5,
                                    ),
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
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
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
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  shadowColor: Colors.black.withValues(
                                    alpha: 0.04,
                                  ),
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: _buildCompletionBlankSentence(),
                                    )
                                  : Builder(
                                      builder: (context) {
                                        final allTokens = _activityArrangementTokens(_currentWord);
                                        int startIndex = _arrangementStartIndex;
                                        int endIndex = _arrangementEndIndex;
                                        
                                        if (_expectedArrangementTokens.isEmpty) {
                                          startIndex = 0;
                                          endIndex = -1;
                                        }
                                        
                                        final prefix = startIndex > 0 ? allTokens.sublist(0, startIndex) : <String>[];
                                        final suffix = endIndex != -1 && endIndex < allTokens.length - 1 ? allTokens.sublist(endIndex + 1) : <String>[];
                                        
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
                                                fontSize: 15,
                                                color: Color(0xFF0369A1),
                                              ),
                                            ),
                                          );
                                        }

                                        return Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 10,
                                          children: [
                                            ...prefix.map((w) => buildLockedChip(w)),
                                            DragTarget<String>(
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
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: candidateData.isNotEmpty ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
                                                    borderRadius: BorderRadius.circular(18),
                                                    border: Border.all(
                                                      color: candidateData.isNotEmpty ? const Color(0xFF06A6FF) : const Color(0xFFE2E8F0),
                                                      width: 1.5,
                                                      style: _assembledWords.isEmpty ? BorderStyle.solid : BorderStyle.none,
                                                    ),
                                                  ),
                                                  child: Wrap(
                                                    alignment: WrapAlignment.center,
                                                    spacing: 8,
                                                    runSpacing: 10,
                                                    children: _assembledWords.isEmpty
                                                        ? [
                                                            const Padding(
                                                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                              child: Text(
                                                                "Drop words here",
                                                                textAlign: TextAlign.center,
                                                                style: TextStyle(
                                                                  color: Color(0xFF94A3B8),
                                                                  fontSize: 14,
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
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                            ...suffix.map((w) => buildLockedChip(w)),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up_rounded,
                                color: Color(0xFF06A6FF),
                              ),
                              onPressed: _speakFullSentence,
                              tooltip: "Listen to full sentence",
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),

                        // Cebuano Translation Scaffold (Always shown with target word underlined)
                        ...[
                          Row(
                            children: [
                              const Text('🇵🇭', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CebuanoTextHighlighter(
                                  text: (_currentWord.exampleSentenceCebuano ??
                                          _currentWord.cebuanoMeaning)
                                      .replaceAll('**', ''),
                                  highlightWord: _currentWord.cebuanoMeaning.replaceAll('**', ''),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                    height: 1.4,
                                  ),
                                  highlightStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0369A1),
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF0284C7),
                                    decorationThickness: 2.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_up_rounded,
                                  color: Color(0xFF06A6FF),
                                ),
                                onPressed: () => _ttsService.speakCebuano(
                                  (_currentWord.exampleSentenceCebuano ??
                                          _currentWord.cebuanoMeaning)
                                      .replaceAll('**', ''),
                                ),
                                tooltip: "Listen to sentence translation",
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  if (!_isChecked &&
                      _currentFormat == ActivityFormat.completion) ...[
                    const SizedBox(height: 36),
                    Builder(
                      builder: (context) {
                        final stage = _getWordStage(_currentWord.wordId);
                        if (stage == 4) {
                          return const SizedBox.shrink(); // No word bank for free-type (Proficient Free-Typing)
                        }

                        return Column(
                          children: _completionOptions.map((opt) {
                            final isSel = _selectedCompletionWords.values.contains(opt);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: () {
                                  if (_isChecked) return;
                                  
                                  // Find the target blank (first empty blank, or blank 0 if all filled)
                                  int targetBlank = -1;
                                  int blankCount = 0;
                                  for (int i = 0; i < _completionTokens.length; i++) {
                                    if (_completionTokens[i].isBlank) {
                                      if (!_selectedCompletionWords.containsKey(blankCount)) {
                                        targetBlank = blankCount;
                                        break;
                                      }
                                      blankCount++;
                                    }
                                  }

                                  // If all blanks are filled, replace blank 0 (or single blank)
                                  if (targetBlank == -1) {
                                    targetBlank = 0;
                                  }

                                  setState(() {
                                    _selectedCompletionWords[targetBlank] = opt;
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
                        );
                      },
                    ),
                  ],

                ],
              ),
            ),
          ),

          // Bottom action bar / Feedback banner
          (() {
            bool isActionEnabled = false;
            if (_currentFormat == ActivityFormat.completion) {
              final blanksCount = _completionTokens.where((t) => t.isBlank).length;
              isActionEnabled = blanksCount > 0 &&
                  _selectedCompletionWords.length >= blanksCount &&
                  _selectedCompletionWords.values.every((w) => w.trim().isNotEmpty);
            } else {
              isActionEnabled = _assembledWords.length == _expectedArrangementTokens.length;
            }

            if (!_isChecked) {
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
                        onPressed: (isActionEnabled && !_submittingAnswer && !_isChecked) ? _checkAnswer : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          LocalizationService.translate(pref, 'check'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final Color panelBg = _isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
            final Color textColor = _isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
            final Color btnBg = _isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

            return Container(
              color: panelBg,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: textColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCorrect 
                                  ? ((_failedSentenceWords.any((w) => w.wordId == _currentWord.wordId) || _isReinforcementPass)
                                      ? 'Correct (+5 pts)'
                                      : (_currentFormat == ActivityFormat.rearrangement
                                          ? 'Correct (+15 pts)'
                                          : 'Correct (+10 pts)'))
                                  : 'Incorrect (0 pts)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (!_isCorrect) ...[
                              const SizedBox(height: 4),
                              () {
                                final ans = _activityAnswer(_currentWord);
                                final raw = _activitySentence(_currentWord);
                                final blankRegex = RegExp(
                                  r'\{BLANK\}|\[BLANK\]|<BLANK>|\(BLANK\)|\{blank\}|\[blank\]|<blank>|\(blank\)|\(\.\.\.\)|\[\.\.\.\]|\.\.\.|_{1,}|-{2,}|\[_\]',
                                  caseSensitive: false,
                                );
                                String displaySentence = raw;
                                if (raw.contains(blankRegex)) {
                                  displaySentence = raw.replaceFirst(blankRegex, ans);
                                }
                                return Text(
                                  'Correct sentence: "$displaySentence"',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textColor.withValues(alpha: 0.9),
                                  ),
                                );
                              }(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleContinueFromSentence,
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
                    child: Text(
                      LocalizationService.translate(pref, 'continue'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
            );
          })(),
        ],
      ),
    );
  }

  Widget _buildPronunciationBody(ThemeData theme) {
    final sentence = _activitySentence(_currentWord);
    final target = _activityAnswer(_currentWord);
    final pref = Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;

    // Highlight target word in sentence
    final parts = sentence.split(' ');

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
                  Text(
                    widget.isSandbox
                        ? "Speech Feedback"
                        : "Module 3 Speech Feedback",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.8,
                    ),
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
                        final cleanPart = part.replaceAll(
                          RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~(?)]'),
                          '',
                        );
                        final isTarget =
                            cleanPart.toLowerCase() == target.toLowerCase();
                        if (isTarget) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 1.5,
                              ),
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
                    "Give it a try â€” say the sentence aloud. Tap skip if you would rather move on.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Premium card with the target word
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _attemptResult != null
                            ? (_attemptResult!.isCorrect
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                            : const Color(0xFFE2E8F0),
                        width: _attemptResult != null ? 3.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
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
                              icon: const Icon(
                                Icons.volume_up_rounded,
                                size: 28,
                                color: Color(0xFF06A6FF),
                              ),
                              onPressed: () => _ttsService.speak(target),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Phonologicalinterference tip helper displayed on attempt 1 and 2
                        if (_pronunciationAttempt <= 2 &&
                            _attemptResult == null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.isSandbox &&
                                      _currentWord.phonologicalTipKey != null
                                  ? _currentWord.phonologicalTipKey!
                                  : _getPhonologicalTip(
                                      _currentWord.phonologicalTipKey,
                                    ),
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
                                  style: TextStyle(
                                    color: Color(0xFF047857),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'ðŸŽ‰',
                                  style: TextStyle(fontSize: 32),
                                ),
                                if (_attemptResult!.transcribedText != null &&
                                    _attemptResult!.transcribedText!
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFBBF7D0),
                                      ),
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
                                        if (_attemptResult!.similarityScore !=
                                            null) ...[
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
                                const Icon(
                                  Icons.cancel_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _attemptResult!.isInconclusive
                                        ? "Couldn't hear you clearly. Please try again."
                                        : _pronunciationAttempt >= 3
                                        ? 'No attempts left â€” keep practicing!'
                                        : _buildFailureMessage(
                                            _attemptResult!.similarityScore,
                                          ),
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
                            if (_attemptResult!.transcribedText != null &&
                                _attemptResult!.transcribedText!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                  ),
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
                                    if (_attemptResult!.similarityScore !=
                                        null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Match: ${(_attemptResult!.similarityScore! * 100).toStringAsFixed(0)}% â€” need 80% to pass',
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
                                _attemptResult!.phoneticTarget!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.record_voice_over_rounded,
                                    color: Color(0xFF7C3AED),
                                    size: 18,
                                  ),
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
                                border: Border.all(
                                  color: const Color(0xFFFED7AA),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.tips_and_updates_rounded,
                                        color: Color(0xFFD97706),
                                        size: 18,
                                      ),
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
                                    // Priority: use backend tip â†’ fallback to local tip
                                    (_attemptResult!.phonologicalTip != null &&
                                            _attemptResult!.phonologicalTip!
                                                .trim()
                                                .isNotEmpty)
                                        ? _attemptResult!.phonologicalTip!
                                        : _getPhonologicalTip(
                                            _currentWord.phonologicalTipKey,
                                          ),
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
                              icon: const Icon(
                                Icons.volume_up_rounded,
                                color: Color(0xFF06A6FF),
                                size: 18,
                              ),
                              label: const Text(
                                'Hear correct pronunciation',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF06A6FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.skip_next_rounded,
                                    size: 36,
                                    color: Color(0xFF64748B),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "SKIP",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
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
                                border: Border.all(
                                  color: const Color(0xFF06A6FF),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.mic_rounded,
                                    size: 36,
                                    color: Color(0xFF06A6FF),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "SPEAK",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF06A6FF),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
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
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: ElevatedButton(
                onPressed: _handleContinueFromPronunciation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _attemptResult!.isCorrect
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  (_attemptResult!.isCorrect || _pronunciationAttempt >= 3)
                      ? LocalizationService.translate(pref, 'continue').toUpperCase()
                      : "TRY AGAIN",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
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
              ),
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pronounce: ${_currentWord.englishWord}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Speak naturally. It will score automatically when you pause, or stop after 30 seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
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
                            ? const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.15 + (amplitude * 0.15))
                            : const Color(
                                0xFF06A6FF,
                              ).withValues(alpha: 0.08 + (amplitude * 0.12)),
                        border: Border.all(
                          color: isSpeechActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFF06A6FF),
                          width: isSpeechActive
                              ? 4 + (amplitude * 8)
                              : 3 + (amplitude * 7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSpeechActive
                                ? const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.25 + (amplitude * 0.20))
                                : const Color(0xFF06A6FF).withValues(
                                    alpha: 0.18 + (amplitude * 0.12),
                                  ),
                            blurRadius: isSpeechActive ? 28 : 20,
                            spreadRadius: isSpeechActive ? 4 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        size: 54 + (amplitude * 12),
                        color: isSpeechActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF06A6FF),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
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
        ? (_totalPronunciationAttempts / _totalPronunciationWords)
              .toStringAsFixed(1)
        : '0.0';

    final confusableMasteredCount = _confusableMastery.values
        .where((v) => v)
        .length;

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
                    child: Text('ðŸ†', style: TextStyle(fontSize: 72)),
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
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
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
                    _buildStatRow(
                      'Initial-Pass Correct',
                      '$_initialPassCorrectCount / $_totalUniqueWords',
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Reinforcement Correct',
                      '$_reinforcementPassCorrectCount',
                    ),
                    if (_confusablePairs.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildStatRow(
                        'Confusable Pairs Mastered',
                        '$confusableMasteredCount / ${_confusablePairs.length}',
                      ),
                    ],
                    const Divider(height: 24),
                    _buildStatRow(
                      'Avg. Pronunciation Attempts',
                      '$averageAttempts per word',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  // Push loading screen before cumulative review
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 420),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 350,
                      ),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0.04, 0.0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: LoadingScreen(
                              duration: const Duration(seconds: 5),
                              redirectPath: '/cumulative-mixed-review',
                              extraParams: {
                                'sessionId': widget.sessionId,
                                'lessonId': widget.lessonId,
                                'allWords': widget.allWords,
                                'categoryId': widget.categoryId,
                                'isSandbox': widget.isSandbox,
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'PROCEED CUMULATIVE REVIEW',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'BACK TO HOME',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Activity?'),
        content: const Text(
          'Your progress will be saved. You can continue from where you left off when you return.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              // Save progress snapshot so user can resume later
              await LocalStorageService.saveModuleProgressSnapshot(
                widget.sessionId,
                {
                  'wordDifficulties': _wordDifficulties,
                  'wordStages': _wordStage,
                  'lessonId': widget.lessonId,
                  'moduleNumber': widget.moduleNumber,
                  'savedAt': DateTime.now().toIso8601String(),
                },
              );
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              final provider = Provider.of<LessonProvider>(context, listen: false);
              provider.recordPartialModuleTime(widget.sessionId, 3, _computeActiveSeconds(), lessonId: widget.lessonId);
              // ignore: use_build_context_synchronously
              Navigator.of(ctx).pop();
              // ignore: use_build_context_synchronously
              context.go('/home');
            },
            child: const Text(
              'EXIT',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
