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
  int _currentStep = 0; // 0: Flashcard Recall, 1: Pronunciation Confirmation
  bool _isFlipped = false;
  final String _pathway = 'FULL'; // 'FULL' or 'ACCELERATED'

  // Speech evaluation state variables
  bool _isRecording = false;
  bool _isEvaluating = false;
  int _attemptNumber = 1;
  PronunciationAttemptModel? _attemptResult;
  late int _maxAttempts;
  int _totalPronunciationAttempts = 0;

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
      _isFlipped = false;
      _attemptNumber = 1;
      _attemptResult = null;
      _isRecording = false;
      _isEvaluating = false;
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
        _totalPronunciationAttempts++;

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
      // If the device speech engine is unavailable, the recording fallback still works.
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

    final currentWord = _words[_currentWordIndex];
    setState(() {
      _attemptResult = PronunciationAttemptModel(
        attemptId: '',
        isCorrect: true,
        transcribedText: transcript,
        phoneticTarget: null,
        phonologicalTip: null,
        attemptNumber: _attemptNumber,
        isInconclusive: false,
      );
      _isRecording = false;
      _isEvaluating = false;
    });

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    _playWordAudio(currentWord);
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
        _totalPronunciationAttempts++;
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

    if (_currentStep == 0) {
      if (!_isFlipped) return; // Must flip card first
      setState(() {
        _currentStep = 1;
      });
      provider.updateWordProgress(widget.sessionId, currentWord.wordId, _pathway, 1, 'INTRODUCED');
      _playWordAudio(currentWord);
    } else if (_currentStep == 1) {
      // Complete word learning and advance index
      // Mic attempt and mic skip both advance session state identically with no score side effects
      final finalStatus = 'INTRODUCED';
      
      provider.updateWordProgress(widget.sessionId, currentWord.wordId, _pathway, 4, finalStatus);

      if (_currentWordIndex < _words.length - 1) {
        setState(() {
          _currentWordIndex++;
        });
        _initializeWordState();
      } else {
        // Automatically transition to Module 2
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
    }
  }

  // retry pronunciation removed — not used in current flows

  PronunciationAttemptModel _applyLocalBypassIfSpoken(PronunciationAttemptModel result, String target) {
    final trans = (result.transcribedText ?? '').trim();
    if (trans.isEmpty) return result;
    if (PronunciationMatcher.matchesTranscript(trans, target)) {
      return PronunciationAttemptModel(
        attemptId: result.attemptId,
        isCorrect: true,
        transcribedText: result.transcribedText,
        phoneticTarget: result.phoneticTarget,
        phonologicalTip: result.phonologicalTip,
        attemptNumber: result.attemptNumber,
        isInconclusive: false,
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
        return _buildFormAndMeaningCard(theme, word);
      case 1:
        return _buildPhonologyCard(theme, word);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFormAndMeaningCard(ThemeData theme, VocabularyWordModel word) {
    if (!_isFlipped) {
      // ── Step 0 FRONT: Cebuano-first ──────────────────────────────
      // UC-3.1: Show Cebuano word and Cebuano example sentence first.
      // Cebuano TTS has already auto-played on entering this word.
      // The learner's task is to think of the English equivalent.
      return Card(
        key: const ValueKey('front'),
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'What is this word in English?',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 32),
              // Cebuano word — primary display
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
                        color: _isPlayingAudio ? Colors.grey : const Color(0xFF10B981), size: 28),
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
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFE6E7EA)),
                const SizedBox(height: 12),
                const Text(
                  'CEBUANO EXAMPLE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  word.exampleSentenceCebuano!,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFlipped = true;
                  });
                  // UC-3.1: Play English TTS on flip to reveal English word
                  _playWordAudio(word);
                },
                icon: const Icon(Icons.flip_to_back_rounded),
                label: const Text('REVEAL IN ENGLISH'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Step 0 BACK: English reveal ───────────────────────────────
    // English word is now the reveal after seeing Cebuano first.
    // English TTS has already played when the learner tapped REVEAL.
    return Card(
      key: const ValueKey('back'),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image (if available)
              if (word.imageAssetPath != null && word.imageAssetPath!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomImageViewer(
                    imagePath: word.imageAssetPath!,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 180,
                      height: 180,
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
              // English word — revealed
              const Text(
                'In English, this is:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      word.englishWord,
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded,
                        color: _isPlayingAudio ? Colors.grey : const Color(0xFFF59E0B), size: 28),
                    onPressed: _isPlayingAudio ? null : _speakWord,
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
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE6E7EA)),
              const SizedBox(height: 12),
              Text(
                LocalizationService.translate(_pref, 'english_example'),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                word.exampleSentenceEnglish,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: Icon(Icons.volume_up_rounded,
                    color: _isPlayingAudio ? Colors.grey : const Color(0xFFF59E0B)),
                onPressed: _isPlayingAudio ? null : _speakSentence,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFlipped = false;
                  });
                },
                icon: const Icon(Icons.flip_to_front_rounded),
                label: const Text('REVIEW CEBUANO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64748B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
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
              const SizedBox(height: 16),
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
                Icon(
                  _attemptResult!.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _attemptResult!.isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  _attemptResult!.isCorrect 
                      ? 'Sounds good!' 
                      : (_attemptResult!.isInconclusive 
                          ? "Speech couldn't be recognized. Please try again." 
                          : 'Try saying it again (Attempt $_attemptNumber/3)'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _attemptResult!.isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                  ),
                ),
                if (_attemptResult!.transcribedText != null && _attemptResult!.transcribedText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'You said: "${_attemptResult!.transcribedText}"',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_attemptResult!.similarityScore != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Match score: ${(_attemptResult!.similarityScore! * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _attemptResult!.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
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
    if (tipKey == 'f_sound') {
      return "Tip: Cebuano has no /f/ sound. Touch your upper teeth to your lower lip and blow air out: 'fff' (like Fish).";
    } else if (tipKey == 'v_sound') {
      return "Tip: Cebuano has no /v/ sound. Place your upper teeth on your lower lip and buzz like a bee: 'vvv' (like Very).";
    } else if (tipKey == 'th_sound') {
      return "Tip: Cebuano has no /θ/ sound. Put the tip of your tongue between your front teeth and blow gently (like Brother).";
    }
    return "Tip: Listen closely and copy the correct pronunciation.";
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
                Text(
                  word.exampleSentenceCebuano!,
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

    String buttonText = 'FLIP CARD';
    if (_currentStep == 0 && _isFlipped) buttonText = 'GOT IT';
    if (_currentStep == 1) {
      if (_attemptResult != null && _attemptResult!.isCorrect == false && _attemptNumber >= 3) {
        buttonText = 'TEACHER SKIP';
      } else {
        buttonText = 'CONTINUE';
      }
    }

    // Require correct pronunciation or 3 failed attempts to continue step 1
    final bool canContinue = _currentStep == 0 
        ? _isFlipped 
        : (_attemptResult != null && (_attemptResult!.isCorrect == true || _attemptNumber >= 3));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
          onPressed: canContinue
              ? () {
                  if (_currentStep == 0 && !_isFlipped) {
                    setState(() {
                      _isFlipped = true;
                    });
                  } else {
                    _nextStep();
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06A6FF),
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF94A3B8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
          ),
          child: Text(
            buttonText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
        isSandbox: true,
        sessionId: widget.sessionId,
      );
    } catch (e) {
      debugPrint('Module 1 score sync failed, continuing anyway: $e');
    }

    if (!mounted) return;
    debugPrint(widget.isSandbox ? 'Navigating to sandbox review...' : 'Navigating to Module 2...');
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
}

