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

  // Lesson data
  List<VocabularyWordModel> _words = [];
  bool _isLoading = true;
  String? _error;

  // Queues and Progression State
  List<VocabularyWordModel> _queue = [];
  final List<VocabularyWordModel> _failedSentenceWords = [];
  bool _isReinforcementPass = false;
  Phase _currentPhase = Phase.sentenceActivity;
  int _totalUniqueWords = 0;
  int _initialPassCompletedCount = 0;
  int _reinforcementCompletedCount = 0;

  // Stats for Summary Screen
  int _initialPassCorrectCount = 0;
  int _reinforcementPassCorrectCount = 0;
  int _totalPronunciationAttempts = 0;
  int _totalPronunciationWords = 0;
  List<Map<String, dynamic>> _confusablePairs = [];
  Map<String, bool> _confusableMastery = {};

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
    return widget.moduleNumber >= 2 ? 7 : 3;
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
    _amplitudeSubscription?.cancel();
    _silenceTimer?.cancel();
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
      } else {
        // Primary backend fetch
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

        // Fallback 2: try cumulative mixed review (sandbox/session endpoints)
        if (fetchedWords.isEmpty) {
          final mixed = await lessonProvider.getCumulativeMixedReview(widget.sessionId);
          if (mixed.isNotEmpty) {
            fetchedWords = mixed.map((m) => VocabularyWordModel.fromJson({
                  'wordId': m['wordId'] ?? m['word'] ?? '',
                  'lessonId': widget.lessonId,
                  'englishWord': m['word'] ?? m['englishWord'] ?? '',
                  'cebuanoMeaning': m['definition'] ?? m['cebuanoMeaning'] ?? '',
                  'exampleSentenceEnglish': m['example'] ?? m['exampleSentenceEnglish'] ?? '',
                })).toList();
          }
        }

        // Final fallback: small local sample so UI remains usable for debugging/dev
        if (fetchedWords.isEmpty) {
          fetchedWords = [
            VocabularyWordModel.fromJson({
              'wordId': 'sample_1',
              'lessonId': widget.lessonId,
              'englishWord': 'notebook',
              'cebuanoMeaning': 'kuwaderno',
              'exampleSentenceEnglish': 'I put my notebook inside my bag.',
            }),
            VocabularyWordModel.fromJson({
              'wordId': 'sample_2',
              'lessonId': widget.lessonId,
              'englishWord': 'pen',
              'cebuanoMeaning': 'bolpen',
              'exampleSentenceEnglish': 'Please pass me the pen.',
            }),
            VocabularyWordModel.fromJson({
              'wordId': 'sample_3',
              'lessonId': widget.lessonId,
              'englishWord': 'book',
              'cebuanoMeaning': 'libro',
              'exampleSentenceEnglish': 'She opened the book to read.',
            }),
          ];
        }
      }

      fetchedConfusables = widget.allWords.isNotEmpty
          ? <Map<String, dynamic>>[]
          : await lessonProvider.loadConfusablePairs(widget.lessonId);

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
        _confusablePairs = fetchedConfusables;

        // Populate initial practice queue
        _queue = List.from(fetchedWords);
        
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
    if (word.sentenceArrangementTokens != null && word.sentenceArrangementTokens!.isNotEmpty) {
      return List<String>.from(word.sentenceArrangementTokens!);
    }

    final sentence = word.exampleSentenceEnglish.trim().isEmpty ? word.englishWord : word.exampleSentenceEnglish;
    return sentence
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~(?)]'), '')
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .toList();
  }

  void _startNextItem() {
    if (_queue.isEmpty) {
      // End of current queue pass!
      _handleQueueEmpty();
      return;
    }

    _currentWord = _queue.removeAt(0);

    // Alternate format randomly or systematically
    _currentFormat = (_words.indexOf(_currentWord) % 2 == 0)
        ? ActivityFormat.completion
        : ActivityFormat.rearrangement;

    _resetItemState();
  }

  void _resetItemState() {
    _isChecked = false;
    _isCorrect = false;
    _selectedCompletionWord = null;
    _assembledWords = [];
    _pronunciationAttempt = 1;
    _attemptResult = null;

    // Modules 2-4 use longer active-recall loops, so allow more pronunciation retries.
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
      final others = _words
          .where((word) => word.wordId != _currentWord.wordId)
          .map((word) => word.englishWord)
          .toList();
      if (others.length < 2) {
        others.addAll(['apple', 'house', 'water', 'friend', 'school']);
      }
      others.shuffle();
      _completionOptions = [correct, ...others.take(2)];
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

  void _handleQueueEmpty() async {
    // 1. If we finished the initial pass
    if (!_isReinforcementPass) {
      // Check if we have confusable pairs to distinction first
      if (_confusablePairs.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        // Navigate to the confusable intervention screen and await result
        final result = await context.push<Map<String, bool>>(
          '/session/${widget.sessionId}/confusable-distinction',
          extra: {
            'lessonId': widget.lessonId,
            'confusablePairs': _confusablePairs,
          },
        );

        if (result != null) {
          _confusableMastery = result;
        }

        setState(() {
          _isLoading = false;
        });
      }

      // Transition to reinforcement pass if we failed any words
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
      await _completeModuleAndAdvance();
    }
  }

  Future<void> _completeModuleAndAdvance() async {
    await Provider.of<LessonProvider>(context, listen: false)
        .persistModuleScore(widget.lessonId, 3, _initialPassCorrectCount, _totalUniqueWords);

    if (!mounted) return;

    // Ensure all words have entries in pronunciation maps (default to false/0 if not attempted)
    for (final word in _words) {
      _wordPronunciationCorrect.putIfAbsent(word.wordId, () => false);
      _wordPronunciationAttempts.putIfAbsent(word.wordId, () => 0);
    }

    // Calculate overall score using the same formula as Module 3's internal scoring
    final overallScore = _totalUniqueWords > 0 
        ? (_initialPassCorrectCount / _totalUniqueWords) * 100 
        : 0.0;

    // Get failed sentence word IDs
    final failedSentenceWordIds = _failedSentenceWords.map((w) => w.wordId).toSet();

    // Use provided lessonTitle or fall back to formatted string
    final displayTitle = widget.lessonTitle?.isNotEmpty == true 
        ? widget.lessonTitle! 
        : 'Lesson ${widget.lessonId} Complete';

    // Persist full score details so the map screen can retrieve them later
    await LocalStorageService.saveLessonScoreDetails(widget.lessonId, {
      'wordPronunciationCorrect': _wordPronunciationCorrect,
      'wordPronunciationAttempts': _wordPronunciationAttempts,
      'failedSentenceWordIds': failedSentenceWordIds.toList(),
      'overallScore': overallScore,
    });

    // Navigate to lesson score screen
    context.go(
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

  void _checkAnswer() {
    if (_currentFormat == ActivityFormat.completion) {
      if (_selectedCompletionWord == null) return;
      _isCorrect = _selectedCompletionWord!.toLowerCase() == _activityAnswer(_currentWord).toLowerCase();
    } else {
      // Check rearrangement
      final sentenceClean = _activityArrangementTokens(_currentWord).join(' ')
          .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~(?)]'), '')
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final assembledSentence = _assembledWords.join(' ').toLowerCase().trim();
      _isCorrect = assembledSentence == sentenceClean;
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

    setState(() {
      _isChecked = true;
    });
  }

  void _handleContinueFromSentence() {
    if (_isCorrect) {
      // Advance to Pronunciation Mode for the current word!
      // Notify backend that Module 3 (pronunciation) has started for this word.
      final provider = Provider.of<LessonProvider>(context, listen: false);
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
    final completedCount = _isReinforcementPass ? _reinforcementCompletedCount : _initialPassCompletedCount;
    final progress = _totalUniqueWords > 0 ? completedCount / _totalUniqueWords : 0.0;
    final phaseLabel = _currentPhase == Phase.sentenceActivity ? 'Build' : 'Speak';

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEFF6FF),
                ),
                child: const Center(
                  child: Text('✍️', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'MODULE 3',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0369A1), letterSpacing: 1.0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sentence Building',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sequence: Build → Check → Speak',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06A6FF)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$phaseLabel ${_currentPhase == Phase.sentenceActivity ? '1/2' : '2/2'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Pronunciation flow
  Future<void> _startRecording() async {
    if (await _recorderService.hasPermission()) {
      _recordingSessionActive = true;
      _liveTranscriptNotifier.value = '';
      setState(() {
        _isRecording = true;
        _attemptResult = null;
      });
      await _recorderService.startRecording();
      await _startStreamingRecognition(_currentWord.englishWord);
      _startAutoEvaluationMonitoring();

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildRecordingModal(context),
      );

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

        if (mounted) {
          setState(() {
            _attemptResult = result;
            _isEvaluating = false;
          });

          if (result.isCorrect) {
            _ttsService.speak(_currentWord.englishWord);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isEvaluating = false;
          });
        }
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

  void _cancelRecordingSession() {
    // Treat cancel as a misattempt and auto-retry if attempts remain
    final wasActive = _recordingSessionActive;
    _stopAutoEvaluationMonitoring();
    _streamingSttService.stopListening();

    if (wasActive) {
      setState(() {
        _attemptResult = PronunciationAttemptModel(
          attemptId: '',
          isCorrect: false,
          transcribedText: null,
          phoneticTarget: null,
          phonologicalTip: null,
          attemptNumber: _pronunciationAttempt,
          isInconclusive: false,
        );
      });

      if (_pronunciationAttempt < _maxAttempts) {
        _pronunciationAttempt++;
        Future.delayed(const Duration(milliseconds: 600), () async {
          if (!mounted) return;
          _attemptResult = null;
          _isRecording = true;
          _recordingSessionActive = true;
          _liveTranscriptNotifier.value = '';
          await _recorderService.startRecording();
          await _startStreamingRecognition(_currentWord.englishWord);
          _startAutoEvaluationMonitoring();
        });
        return;
      }
    }

    _recordingSessionActive = false;
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isEvaluating = false;
        _liveTranscriptNotifier.value = '';
      });
    }
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
    if (!_recordingSessionActive || _attemptResult != null || !_isRecording) {
      return;
    }

    _recordingSessionActive = false;
    _stopAutoEvaluationMonitoring();
    await _streamingSttService.stopListening();
    await _recorderService.stopRecording();

    if (!mounted) {
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

    _ttsService.speak(_currentWord.englishWord);
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
    if (_isEvaluating || !_isRecording || _attemptResult != null) return;

    setState(() {
      _isEvaluating = true;
    });

    _stopAutoEvaluationMonitoring();
    final path = await _recorderService.stopRecording();

    if (!mounted) return;

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

    if (!mounted) return;

    setState(() {
      _attemptResult = result;
      _isRecording = false;
      _isEvaluating = false;
    });

    if (result.isCorrect) {
      _recordingSessionActive = false;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _ttsService.speak(_currentWord.englishWord);
      return;
    }

    final shouldRetry = _recordingSessionActive && _pronunciationAttempt < _maxAttempts;
    if (!shouldRetry) {
      _recordingSessionActive = false;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted || !_recordingSessionActive) return;

    setState(() {
      _pronunciationAttempt++;
      _attemptResult = null;
      _isRecording = true;
    });

    await _recorderService.startRecording();
    _startAutoEvaluationMonitoring();
  }

  void _handleContinueFromPronunciation() async {
    final correct = _attemptResult?.isCorrect ?? false;
    final reachedMaxAttempts = _pronunciationAttempt >= _maxAttempts;

    if (correct || reachedMaxAttempts) {
      _totalPronunciationWords++;

      // Track pronunciation data for score screen
      _wordPronunciationCorrect[_currentWord.wordId] = correct;
      _wordPronunciationAttempts[_currentWord.wordId] = _pronunciationAttempt;

      // Sync progress fire-and-forget to database
      final provider = Provider.of<LessonProvider>(context, listen: false);

      // Step 4 is complete status
      await provider.updateWordProgress(
        widget.sessionId,
        _currentWord.wordId,
        'FULL',
        4,
        correct ? 'MASTERED' : 'NEEDS_PRONUNCIATION_REVIEW',
        moduleNumber: widget.moduleNumber,
      );

      // Increment stats
      if (!_isReinforcementPass) {
        _initialPassCompletedCount++;
      } else {
        _reinforcementCompletedCount++;
      }

      setState(() {
        _currentPhase = Phase.sentenceActivity;
      });
      _startNextItem();
    } else {
      // Try again (increment attempts)
      setState(() {
        _pronunciationAttempt++;
        _attemptResult = null;
      });
    }
  }

  String _getPhonologicalTip(String? tipKey) {
    if (tipKey == 'f_sound') {
      return "Tip: Cebuano has no /f/ sound. Touch your upper teeth to your lower lip and blow air out: 'fff' (like Fish).";
    } else if (tipKey == 'v_sound') {
      return "Tip: Cebuano has no /v/ sound. Place your upper teeth on your lower lip and buzz like a bee: 'vvv' (like Very).";
    } else if (tipKey == 'th_sound') {
      return "Tip: Cebuano has no /θ/ sound. Put the tip of your tongue between your front teeth and blow gently (like Brother).";
    }
    return "Tip: Listen closely and copy the correct pronunciation.";
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
            child: LinearProgressIndicator(
              value: _totalUniqueWords > 0
                  ? ((_isReinforcementPass ? _reinforcementCompletedCount : _initialPassCompletedCount) / _totalUniqueWords)
                  : 0,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 10,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  '${_isReinforcementPass ? _reinforcementCompletedCount : _initialPassCompletedCount}/$_totalUniqueWords',
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
        body: _currentPhase == Phase.sentenceActivity
            ? _buildSentenceActivityBody(theme)
            : _buildPronunciationBody(theme),
      ),
    );
  }

  Widget _buildSentenceActivityBody(ThemeData theme) {
    final sentence = _activitySentence(_currentWord);

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

                  // Mascot Row with instructions
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEFF6FF),
                        ),
                        child: const Center(
                          child: Text(
                            '🦉',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                            _currentFormat == ActivityFormat.completion
                              ? "Select the correct word to fill the blank:"
                              : "Drag or tap the words to build the sentence:",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
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
                        if (_currentFormat == ActivityFormat.completion)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
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
                        else
                          // Rearrangement assembled area
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
                              onPressed: () => _ttsService.speak(_currentWord.englishWord),
                              tooltip: "Listen to vocabulary word",
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
                              Text(
                                _isCorrect ? "Correct!" : "Let's review the correct structure:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isCorrect ? const Color(0xFF065F46) : const Color(0xFF991B1B),
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
                      _isCorrect ? "CONTINUE TO PRONUNCIATION" : "CONTINUE",
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
                  const Text(
                    "Module 3 Speech Feedback",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.8),
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
                    "Speak the highlighted word only:",
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
                              _getPhonologicalTip(_currentWord.phonologicalTipKey),
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
                            const Column(
                              children: [
                                Text(
                                  'Excellent! You said it correctly.',
                                  style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '🎉',
                                  style: TextStyle(fontSize: 32),
                                )
                              ],
                            )
                          else ...[
                            Text(
                              _pronunciationAttempt >= 3
                                  ? 'Max attempts reached. Let\'s move to the next word!'
                                  : 'Incorrect. Let\'s try again!',
                              style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold, fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getPhonologicalTip(_currentWord.phonologicalTipKey),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
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
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _startRecording,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEFF6FF),
                                border: Border.all(color: const Color(0xFF06A6FF), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF06A6FF).withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                size: 48,
                                color: Color(0xFF06A6FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Tap to speak (Attempt $_pronunciationAttempt of 3)",
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
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
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF06A6FF).withValues(alpha: 0.08 + (amplitude * 0.12)),
                        border: Border.all(
                          color: const Color(0xFF06A6FF),
                          width: 3 + (amplitude * 7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06A6FF).withValues(alpha: 0.18 + (amplitude * 0.12)),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        size: 54 + (amplitude * 10),
                        color: const Color(0xFF06A6FF),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cancelRecordingSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06A6FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
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
        title: const Text(
          'Module 3 Completed',
          style: TextStyle(
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
