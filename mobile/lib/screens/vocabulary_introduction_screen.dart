import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../models/vocabulary_word_model.dart';
import '../services/tts_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/stt_service.dart';
import '../services/streaming_stt_service.dart';
import '../services/pronunciation_matcher.dart';
import '../models/pronunciation_attempt_model.dart';
import '../services/localization_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/custom_image_viewer.dart';
import '../widgets/cebuano_text_highlighter.dart';
import '../config/app_config.dart';

class VocabularyIntroductionScreen extends StatefulWidget {
  final String sessionId;
  final String lessonId;
  final String categoryId;
  final List<String> knownWordIds;
  final List<String> unknownWordIds;
  final List<Map<String, dynamic>> allWords;
  final bool returnToPractice;
  final int moduleNumber;
  final bool isSandbox;

  const VocabularyIntroductionScreen({
    super.key,
    required this.sessionId,
    required this.lessonId,
    required this.categoryId,
    required this.knownWordIds,
    required this.unknownWordIds,
    required this.allWords,
    this.returnToPractice = false,
    this.moduleNumber = 3,
    this.isSandbox = false,
  });

  @override
  State<VocabularyIntroductionScreen> createState() => _VocabularyIntroductionScreenState();
}

class _VocabularyIntroductionScreenState extends State<VocabularyIntroductionScreen> {
  String? get _pref => Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;
  final TtsService _ttsService = TtsService();
  final AudioRecorderService _recorderService = AudioRecorderService();
  final SttService _sttService = SttService();
  final StreamingSttService _streamingSttService = StreamingSttService();
  final ValueNotifier<String> _liveTranscriptNotifier = ValueNotifier<String>('');
  StreamSubscription<double>? _amplitudeSubscription;
  Timer? _silenceTimer;
  DateTime? _lastSpeechAt;
  DateTime? _recordingStartedAt;
  bool _recordingSessionActive = false;
  bool _disposed = false;
  bool _isPlayingAudio = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<VocabularyWordModel> _words = [];
  int _currentWordIndex = 0;
  
  // Card learning state
  int _currentStep = 0; // 0 to 4 (5-step introduction flow)
  final String _pathway = 'FULL'; // 'FULL' or 'ACCELERATED'
  bool _isFlashcardFlipped = false;

  // Speech evaluation state variables
  bool _isRecording = false;
  bool _isEvaluating = false;
  int _attemptNumber = 1;
  PronunciationAttemptModel? _attemptResult;
  late int _maxAttempts;

  @override
  void initState() {
    super.initState();
    if (widget.isSandbox) {
      // In sandbox mode, show all generated custom words
      _words = widget.allWords.map((w) => VocabularyWordModel.fromJson(w)).toList();
    } else {
      // Otherwise, filter to only unknown words
      final unknownIds = widget.unknownWordIds.toSet();
      _words = widget.allWords
          .map((w) => VocabularyWordModel.fromJson(w))
          .where((word) => unknownIds.contains(word.wordId))
          .toList();
    }

    if (_words.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(
            '/session/${widget.sessionId}/practice',
            extra: {
              'lessonId': widget.lessonId,
              'categoryId': widget.categoryId,
              'knownWordIds': widget.knownWordIds,
              'unknownWordIds': widget.unknownWordIds,
              'allWords': widget.allWords,
              'isSandbox': widget.isSandbox,
            },
          );
        }
      });
    } else {
      _initializeServicesAndState();
    }
  }

  Future<void> _initializeServicesAndState() async {
    try {
      await _ttsService.initialize();
      await _streamingSttService.initialize();
    } catch (_) {
      // ignore tts init errors; speak calls will fail silently
    }
    _initializeWordState();
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
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeWordState() {
    if (_words.isEmpty) return;
    final currentWord = _words[_currentWordIndex];
    setState(() {
      _currentStep = 0;
      _attemptNumber = 1;
      _attemptResult = null;
      _isRecording = false;
      _isEvaluating = false;
      _isFlashcardFlipped = false;
    });

    // Sandbox should allow a single attempt but not persist penalties.
    _maxAttempts = widget.isSandbox ? 1 : 3;

    // UC-3.1 Cebuano-first: auto-speak the Cebuano meaning on word init (Step 0).
    // English TTS is reserved for Step 1 (phonology/reveal step).
    _playCebuanoAudio(currentWord.cebuanoMeaning);
  }

  Future<void> _playWordAudio(VocabularyWordModel word) async {
    if (_isPlayingAudio) return;
    if (mounted) setState(() => _isPlayingAudio = true);

    try {
      final success = await _ttsService.speakEnglish(word.englishWord);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio unavailable')),
        );
      }
      if (word.audioAssetPath != null && word.audioAssetPath!.trim().isNotEmpty) {
        final path = AppConfig.sanitizeAssetPath(word.audioAssetPath!);
        
        Source source;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          source = UrlSource(path);
        } else {
          source = AssetSource(path.startsWith('assets/') ? path.replaceFirst('assets/', '') : path);
        }
        
        Completer<void> completer = Completer<void>();
        StreamSubscription? sub;
        sub = _audioPlayer.onPlayerComplete.listen((_) {
          if (!completer.isCompleted) completer.complete();
          sub?.cancel();
        });
        
        await _audioPlayer.play(source);
        await completer.future;
      }
    } catch (e) {
      debugPrint('Error playing audio asset: $e');
    } finally {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  void _speakWord() {
    _playWordAudio(_words[_currentWordIndex]);
  }

  Future<void> _playCebuanoAudio(String text) async {
    if (_isPlayingAudio) return;
    if (mounted) setState(() => _isPlayingAudio = true);

    try {
      final success = await _ttsService.speakCebuano(text);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio unavailable')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio unavailable')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  Future<void> _speakSentence() async {
    if (_isPlayingAudio) return;
    if (mounted) setState(() => _isPlayingAudio = true);
    
    try {
      final success = await _ttsService.speakEnglish(_words[_currentWordIndex].exampleSentenceEnglish);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio unavailable')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio unavailable')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlayingAudio = false);
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
    // Only consider attempts exhausted when maxAttempts > 0
    final shouldMarkFailure = wasActiveAttempt && (_maxAttempts > 0 && _attemptNumber >= _maxAttempts);

    _recordingSessionActive = false;
    _stopAutoEvaluationMonitoring();
    await _streamingSttService.stopListening();
    await _recorderService.stopRecording();

    if (_disposed || !mounted) return;

    setState(() {
      _isRecording = false;
      _isEvaluating = false;
      _liveTranscriptNotifier.value = '';

      if (wasActiveAttempt) {
        if (shouldMarkFailure) {
          _attemptResult = PronunciationAttemptModel(
            attemptId: '',
            isCorrect: false,
            transcribedText: null,
            phoneticTarget: null,
            phonologicalTip: null,
            attemptNumber: _attemptNumber,
            isInconclusive: true,
          );
        } else {
          _attemptNumber = _attemptNumber < _maxAttempts ? _attemptNumber + 1 : _maxAttempts;
          _attemptResult = null;
        }
      } else {
        _attemptResult = null;
      }
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
    await _streamingSttService.stopListening();
    final path = await _recorderService.stopRecording();

    if (_disposed || !mounted) return;

    if (path == null) {
      setState(() {
        _isRecording = false;
        _isEvaluating = false;
      });
      return;
    }

    final currentWord = _words[_currentWordIndex];
    final result = await _sttService.evaluatePronunciation(
      audioFilePath: path,
      sessionId: widget.sessionId,
      wordId: currentWord.wordId,
      lessonId: widget.lessonId,
      moduleNumber: widget.moduleNumber,
      targetWord: currentWord.englishWord,
      attemptNumber: _attemptNumber,
    );

    if (_disposed || !mounted) return;

    setState(() {
      _attemptResult = _applyLocalBypassIfSpoken(result, currentWord.englishWord);
      _isRecording = false;
      _isEvaluating = false;
    });

    if (_attemptResult?.isCorrect ?? false) {
      _recordingSessionActive = false;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _playWordAudio(currentWord);
      return;
    }

    if (_attemptResult?.isInconclusive ?? false) {
      _recordingSessionActive = false;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final shouldRetry = _recordingSessionActive && _attemptNumber < _maxAttempts;
    if (!shouldRetry) {
      _recordingSessionActive = false;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 650));
    if (_disposed || !mounted || !_recordingSessionActive) return;

    setState(() {
      _attemptNumber++;
      _attemptResult = null;
      _isRecording = true;
    });

    await _recorderService.startRecording();
    _startAutoEvaluationMonitoring();
  }

  Future<void> _handleMicPress() async {
    if (_isEvaluating || _isRecording || _disposed) return;

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
      // await _startStreamingRecognition(_words[_currentWordIndex].englishWord);
      _startAutoEvaluationMonitoring();

      // Show the recording visualizer modal
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
        // If we got a result (correct or reached max attempts), auto-advance
        if (_attemptResult!.isCorrect || (_maxAttempts > 0 && _attemptNumber >= _maxAttempts)) {
          if (mounted) _nextStep();
        }
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
        final currentWord = _words[_currentWordIndex];
        final result = await _sttService.evaluatePronunciation(
          audioFilePath: path,
          sessionId: widget.sessionId,
          wordId: currentWord.wordId,
          lessonId: widget.lessonId,
          moduleNumber: widget.moduleNumber,
          targetWord: currentWord.englishWord,
          attemptNumber: _attemptNumber,
        );

        if (_disposed || !mounted) return;
        setState(() {
          _attemptResult = result;
          _isEvaluating = false;
        });
        if (result.isCorrect) {
          _playWordAudio(currentWord);
          _nextStep();
        } else if (_maxAttempts > 0 && _attemptNumber >= _maxAttempts) {
          // All attempts exhausted — continue automatically
          _nextStep();
        }
      } else {
        if (_disposed || !mounted) return;
        setState(() => _isEvaluating = false);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required.')),
      );
    }
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
                  'Pronounce: ${_words[_currentWordIndex].englishWord}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 6),
                      Text(
                        '+15 PTS for correct pronunciation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Speak naturally. It will score automatically when you pause, or stop after 30 seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                ),
                const SizedBox(height: 14),
                ValueListenableBuilder<String>(
                  valueListenable: _liveTranscriptNotifier,
                  builder: (context, transcript, _) {
                    if (transcript.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Heard: "$transcript"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    );
                  },
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

  void _nextStep() {
    final currentWord = _words[_currentWordIndex];
    final provider = Provider.of<LessonProvider>(context, listen: false);

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _isFlashcardFlipped = false;
      });
      if (_currentStep == 1) _speakWord();
      if (_currentStep == 2) _speakSentence();
    } else {
      // Step 5 Confirmation: Mark word as INTRODUCED in database and advance to next word or Module 2
      final finalStatus = 'INTRODUCED';
      provider.updateWordProgress(widget.sessionId, currentWord.wordId, _pathway, 4, finalStatus);

      if (_currentWordIndex < _words.length - 1) {
        setState(() {
          _currentWordIndex++;
        });
        _initializeWordState();
      } else {
        // Automatically transition to Module 2 with loading screen
        context.push(
          '/loading',
          extra: {
            'duration': 13000,
            'redirectPath': '/session/${widget.sessionId}/practice',
            'lessonId': widget.lessonId,
            'categoryId': widget.categoryId,
            'knownWordIds': widget.knownWordIds,
            'unknownWordIds': widget.unknownWordIds,
            'allWords': widget.allWords,
            'isSandbox': widget.isSandbox,
          },
        );
      }
    }
  }

  // retry pronunciation removed — not used in current flows

  PronunciationAttemptModel _applyLocalBypassIfSpoken(PronunciationAttemptModel result, String target) {
    final trans = (result.transcribedText ?? '').trim();
    if (trans.isEmpty) return result;
    final similarity = result.similarityScore ?? 0.0;
    if (similarity >= 0.80 || PronunciationMatcher.matchesTranscript(trans, target)) {
      return PronunciationAttemptModel(
        attemptId: result.attemptId,
        isCorrect: true,
        transcribedText: result.transcribedText,
        phoneticTarget: result.phoneticTarget,
        phonologicalTip: result.phonologicalTip,
        attemptNumber: result.attemptNumber,
        isInconclusive: false,
        similarityScore: result.similarityScore ?? 0.80,
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_words.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final word = _words[_currentWordIndex];
    final totalWords = _words.length;
    final completedWordsCount = _currentWordIndex.clamp(0, totalWords);
    final progressVal = totalWords > 0 ? (completedWordsCount / totalWords) : 0.0;

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
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: _showExitConfirmation,
        ),
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
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepCard(theme, word),
                ),
              ),

              const SizedBox(height: 24),
              _buildBottomButton(theme),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Lesson?'),
        content: const Text('Leaving now will lose your progress for this vocabulary session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('EXIT', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(ThemeData theme, VocabularyWordModel word) {
    if (widget.isSandbox) {
      return _buildSandboxIntroCard(theme, word);
    }

    switch (_currentStep) {
      case 0:
        return _buildCebuanoStep(theme, word);
      case 1:
        return _buildEnglishWordStep(theme, word);
      case 2:
        return _buildEnglishSentenceStep(theme, word);
      case 3:
        return _buildPhonologyCard(theme, word);
      case 4:
        return _buildSummaryCard(theme, word);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepHeaderBadge(String stepText, String titleText, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$stepText: $titleText',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, VocabularyWordModel word) {
    final ipaText = word.phonologicalTipKey != null ? getIPA(word.englishWord) : '/${word.englishWord.toLowerCase()}/';

    return Card(
      key: const ValueKey('summary_card'),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'WORD SUMMARY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (word.imageAssetPath != null && word.imageAssetPath!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomImageViewer(
                    imagePath: word.imageAssetPath!,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CEBUANO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            word.cebuanoMeaning,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: _isPlayingAudio ? Colors.grey : const Color(0xFF15803D),
                            size: 24,
                          ),
                          onPressed: _isPlayingAudio ? null : () => _playCebuanoAudio(word.cebuanoMeaning),
                        ),
                      ],
                    ),
                    if (word.exampleSentenceCebuano != null &&
                        word.exampleSentenceCebuano!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      CebuanoTextHighlighter(
                        text: word.exampleSentenceCebuano!,
                        highlightWord: word.cebuanoMeaning,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF166534),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ENGLISH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            word.englishWord,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: _isPlayingAudio ? Colors.grey : const Color(0xFFB45309),
                            size: 24,
                          ),
                          onPressed: _isPlayingAudio ? null : _speakWord,
                        ),
                      ],
                    ),
                    if (word.partOfSpeech != null) ...[
                      Text(
                        '(${word.partOfSpeech})',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      word.exampleSentenceEnglish,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF78350F),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: _isPlayingAudio ? Colors.grey : const Color(0xFFB45309),
                        size: 20,
                      ),
                      onPressed: _isPlayingAudio ? null : _speakSentence,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.graphic_eq_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      ipaText,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 16,
                      width: 1,
                      color: const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _attemptResult?.isCorrect == true
                          ? Icons.check_circle_rounded
                          : Icons.task_alt_rounded,
                      color: const Color(0xFF06A6FF),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _attemptResult?.isCorrect == true ? 'Pronounced' : 'Practiced',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCebuanoStep(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey('cebuano_step'),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepHeaderBadge('STEP 1 OF 5', 'CEBUANO WORD & SENTENCE', const Color(0xFF10B981)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    word.cebuanoMeaning,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.volume_up_rounded,
                      color: _isPlayingAudio ? Colors.grey : const Color(0xFF10B981), size: 30),
                  onPressed: _isPlayingAudio ? null : () => _playCebuanoAudio(word.cebuanoMeaning),
                ),
              ],
            ),
            if (word.partOfSpeech != null) ...[
              const SizedBox(height: 6),
              Text(
                '(${word.partOfSpeech})',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF6B7280)),
              ),
            ],
            if (word.exampleSentenceCebuano != null &&
                word.exampleSentenceCebuano!.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE6E7EA)),
              const SizedBox(height: 16),
              const Text(
                'CEBUANO EXAMPLE SENTENCE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              CebuanoTextHighlighter(
                text: word.exampleSentenceCebuano!,
                highlightWord: word.cebuanoMeaning,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnglishWordStep(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey('english_word_step'),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _isFlashcardFlipped = !_isFlashcardFlipped;
          });
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isFlashcardFlipped 
              ? _buildFlashcardBack(theme, word)
              : _buildFlashcardFront(theme, word),
        ),
      ),
    );
  }

  Widget _buildFlashcardFront(ThemeData theme, VocabularyWordModel word) {
    return Padding(
      key: const ValueKey('front'),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepHeaderBadge('STEP 2 OF 5', 'ENGLISH WORD', const Color(0xFF06A6FF)),
            const SizedBox(height: 24),
            if (word.imageAssetPath != null && word.imageAssetPath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomImageViewer(
                  imagePath: word.imageAssetPath!,
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                        child: Icon(Icons.broken_image, color: Color(0xFF94A3B8))),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'In English, this is:',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    word.englishWord,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.volume_up_rounded,
                      color: _isPlayingAudio ? Colors.grey : const Color(0xFF06A6FF), size: 30),
                  onPressed: _isPlayingAudio ? null : _speakWord,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Icon(Icons.touch_app, color: Color(0xFF94A3B8), size: 24),
            const SizedBox(height: 4),
            const Text(
              'Tap card to reveal explanation',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardBack(ThemeData theme, VocabularyWordModel word) {
    return Padding(
      key: const ValueKey('back'),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepHeaderBadge('EXPLANATION', 'DETAILS', const Color(0xFFF59E0B)),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                children: [
                  const Text(
                    'CEBUANO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.cebuanoMeaning,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (word.explanationText != null && word.explanationText!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'EXPLANATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word.explanationText!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF78350F),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Icon(Icons.touch_app, color: Color(0xFF94A3B8), size: 24),
            const SizedBox(height: 4),
            const Text(
              'Tap card to flip back',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnglishSentenceStep(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey('english_sentence_step'),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepHeaderBadge('STEP 3 OF 5', 'ENGLISH EXAMPLE SENTENCE', const Color(0xFF8B5CF6)),
            const SizedBox(height: 28),
            Text(
              word.englishWord,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    word.exampleSentenceEnglish,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.volume_up_rounded,
                      color: _isPlayingAudio ? Colors.grey : const Color(0xFF8B5CF6), size: 30),
                  onPressed: _isPlayingAudio ? null : _speakSentence,
                ),
              ],
            ),
            if (word.exampleSentenceCebuano != null) ...[
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              CebuanoTextHighlighter(
                text: word.exampleSentenceCebuano!,
                highlightWord: word.cebuanoMeaning,
                style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhonologyCard(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey('pronounce'),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Listen and Repeat',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 18),
                    SizedBox(width: 6),
                    Text(
                      '+15 PTS for correct pronunciation',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                word.englishWord,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  word.phonologicalTipKey != null ? getIPA(word.englishWord) : '/${word.englishWord.toLowerCase()}/',
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 18, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: _isPlayingAudio ? Colors.grey : const Color(0xFFF59E0B), size: 36),
                    onPressed: _isPlayingAudio ? null : _speakWord,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_attemptResult != null) ...[
                if (_attemptResult!.isCorrect) ...[
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'Sounds good! 🎉',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.stars_rounded, color: Color(0xFF16A34A), size: 18),
                        SizedBox(width: 6),
                        Text(
                          '+15 Points Earned!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
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
                              fontSize: 14, fontStyle: FontStyle.italic,
                              color: Color(0xFF166534), fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_attemptResult!.similarityScore != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Match: ${(_attemptResult!.similarityScore! * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // Failure headline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 28),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _attemptResult!.isInconclusive
                              ? "Couldn't hear you clearly. Please try again."
                              : _attemptNumber >= 3
                                  ? 'No attempts left — keep practicing!'
                                  : _buildFailureMessage(_attemptResult!.similarityScore),
                          style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // What you said + match score
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
                              fontSize: 14, fontStyle: FontStyle.italic,
                              color: Color(0xFF991B1B), fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_attemptResult!.similarityScore != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Match: ${(_attemptResult!.similarityScore! * 100).toStringAsFixed(0)}% — need 80% to pass',
                              style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  // IPA phonetic target
                  if (_attemptResult!.phoneticTarget != null && _attemptResult!.phoneticTarget!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.record_voice_over_rounded, color: Color(0xFF7C3AED), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Target:',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _attemptResult!.phoneticTarget!,
                          style: const TextStyle(
                            fontFamily: 'Courier', fontSize: 16,
                            fontWeight: FontWeight.bold, color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // HOW TO IMPROVE tip box
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tips_and_updates_rounded, color: Color(0xFFD97706), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'HOW TO IMPROVE',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E), letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (_attemptResult!.phonologicalTip != null && _attemptResult!.phonologicalTip!.trim().isNotEmpty)
                              ? _attemptResult!.phonologicalTip!
                              : _getPhonologicalTip(word.phonologicalTipKey),
                          style: const TextStyle(
                            fontSize: 13, color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600, height: 1.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                const Text(
                  'Want to try saying it? Tap the mic to practice your pronunciation — or just continue when you are ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
              const SizedBox(height: 24),
              _isEvaluating
                  ? const CircularProgressIndicator(color: Color(0xFF06A6FF))
                  : GestureDetector(
                      onTap: _handleMicPress,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red.withValues(alpha: 0.10) : const Color(0xFF06A6FF).withValues(alpha: 0.10),
                          border: Border.all(
                            color: _isRecording ? Colors.redAccent : const Color(0xFF06A6FF),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 32,
                          color: _isRecording ? Colors.redAccent : const Color(0xFF06A6FF),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String getIPA(String englishWord) {
    final lower = englishWord.toLowerCase();
    if (lower == "mother") return "/ˈmʌð.ər/";
    if (lower == "father") return "/ˈfɑː.ðər/";
    if (lower == "brother") return "/ˈbrʌð.ər/";
    if (lower == "fish") return "/fɪʃ/";
    if (lower == "church") return "/tʃɜːrtʃ/";
    return "/$lower/";
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

  Widget _buildSandboxIntroCard(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey('sandbox_intro'),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sandbox Word Preview',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                word.englishWord,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isPlayingAudio ? null : _speakWord,
                icon: Icon(Icons.volume_up_rounded, color: _isPlayingAudio ? Colors.grey : const Color(0xFFF59E0B)),
                label: const Text('Listen'),
              ),
              const SizedBox(height: 20),
              Text(
                LocalizationService.translate(_pref, 'cebuano_meaning'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      word.cebuanoMeaning,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: _isPlayingAudio ? Colors.grey : const Color(0xFF10B981), size: 26),
                    onPressed: _isPlayingAudio ? null : () => _playCebuanoAudio(word.cebuanoMeaning),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                LocalizationService.translate(_pref, 'english_example'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                word.exampleSentenceEnglish,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: Icon(Icons.volume_up_rounded, color: _isPlayingAudio ? Colors.grey : const Color(0xFFF59E0B)),
                onPressed: _isPlayingAudio ? null : _speakSentence,
              ),
              if (word.exampleSentenceCebuano != null) ...[
                const SizedBox(height: 8),
                CebuanoTextHighlighter(
                  text: word.exampleSentenceCebuano!,
                  highlightWord: word.cebuanoMeaning,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
              if (word.phonologicalTipKey != null) ...[ 
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    widget.isSandbox ? (word.phonologicalTipKey ?? '') : _getPhonologicalTip(word.phonologicalTipKey),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(ThemeData theme) {
    if (widget.isSandbox) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _completeSandboxIntro,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06A6FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
          ),
          child: const Text(
            'CONTINUE',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
        ),
      );
    }

    String buttonText = 'NEXT: ENGLISH WORD';
    if (_currentStep == 1) buttonText = 'NEXT: EXAMPLE SENTENCE';
    if (_currentStep == 2) buttonText = 'NEXT: PRONUNCIATION';
    if (_currentStep == 3) {
      if (_attemptResult != null && _attemptResult!.isCorrect == false && _attemptNumber >= 3) {
        buttonText = 'SKIP TO CONFIRMATION';
      } else {
        buttonText = 'NEXT: CONFIRMATION';
      }
    }
    if (_currentStep == 4) {
      buttonText = 'I UNDERSTAND THIS WORD';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _nextStep(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentStep == 4 ? const Color(0xFF10B981) : const Color(0xFF06A6FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _completeSandboxIntro() async {
    if (_words.isEmpty) return;
    final currentWord = _words[_currentWordIndex];
    final provider = Provider.of<LessonProvider>(context, listen: false);

    await provider.updateSandboxProgress(
      sessionId: widget.sessionId,
      wordId: currentWord.wordId,
      pathway: 'FULL',
      stepCompleted: 4,
      status: 'MASTERED',
      moduleNumber: widget.moduleNumber,
    );

    try {
      await provider.persistModuleScore(
        widget.lessonId,
        widget.isSandbox ? null : widget.moduleNumber,
        1,
        1,
        isSandbox: widget.isSandbox,
        sessionId: widget.sessionId,
      );
    } catch (e) {
      debugPrint('Module 1 score sync failed, continuing anyway: $e');
    }

    if (!mounted) return;
    debugPrint(widget.isSandbox ? 'Navigating to sandbox review...' : 'Navigating to Module 2...');

    String targetSessionId = widget.sessionId;
    if (!widget.isSandbox) {
      final practiceSessionId = await provider.startPracticeSession(widget.lessonId, moduleNumber: 2);
      if (practiceSessionId != null && practiceSessionId.isNotEmpty) {
        targetSessionId = practiceSessionId;
      }
    }

    if (!mounted) return;
    context.go(
      '/session/$targetSessionId/practice',
      extra: {
        'lessonId': widget.lessonId,
        'categoryId': widget.categoryId,
        'knownWordIds': widget.knownWordIds,
        'unknownWordIds': widget.unknownWordIds,
        'allWords': widget.allWords,
        'isSandbox': widget.isSandbox,
      },
    );
  }
}

