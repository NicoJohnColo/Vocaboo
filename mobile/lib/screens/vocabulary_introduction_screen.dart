import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../models/vocabulary_word_model.dart';
import '../services/local_storage_service.dart';
import '../services/tts_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/stt_service.dart';
import '../services/streaming_stt_service.dart';
import '../services/pronunciation_matcher.dart';
import '../models/pronunciation_attempt_model.dart';
import '../services/localization_service.dart';
import '../services/phonetic_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/custom_image_viewer.dart';
import '../widgets/cebuano_text_highlighter.dart';
import '../widgets/app_3d_progress_bar.dart';
import '../config/app_config.dart';
import '../core/motion/motion.dart';

class VocabularyIntroductionScreen extends StatefulWidget {
  final String sessionId;
  final String lessonId;
  final String categoryId;
  final String? lessonTitle;
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
    this.lessonTitle,
    required this.knownWordIds,
    required this.unknownWordIds,
    required this.allWords,
    this.returnToPractice = false,
    this.moduleNumber = 3,
    this.isSandbox = false,
  });

  @override
  State<VocabularyIntroductionScreen> createState() =>
      _VocabularyIntroductionScreenState();
}

class _VocabularyIntroductionScreenState
    extends State<VocabularyIntroductionScreen> {
  int _currentWordIndex = 0;
  int _currentStep =
      0; // 0: Cebuano, 1: English word, 2: English sentence, 3: Phonology, 4: Summary
  List<VocabularyWordModel> _words = [];
  bool _isPlayingAudio = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TtsService _ttsService = TtsService();
  final AudioRecorderService _recorderService = AudioRecorderService();
  final SttService _sttService = SttService();
  final StreamingSttService _streamingSttService = StreamingSttService();
  final PronunciationMatcher _pronunciationMatcher = PronunciationMatcher();
  bool _isRecording = false;
  bool _isEvaluating = false;
  bool _isFlashcardFlipped = false;
  final String _pref = 'en';

  int _attemptNumber = 0;
  PronunciationAttemptModel? _attemptResult;
  late int _maxAttempts;

  final ValueNotifier<String> _liveTranscriptNotifier = ValueNotifier<String>(
    '',
  );
  StreamSubscription<double>? _amplitudeSubscription;
  Timer? _silenceTimer;
  DateTime? _lastSpeechAt;
  DateTime? _recordingStartedAt;
  bool _recordingSessionActive = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isSandbox) {
      // In sandbox mode, show all generated custom words
      _words = widget.allWords
          .map((w) => VocabularyWordModel.fromJson(w))
          .toList();
    } else {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final posFocus = auth.learner?.posFocus;
      final posFilter =
          (posFocus != null && posFocus != 'ALL' && posFocus.isNotEmpty)
          ? posFocus
          : null;

      // Filter all available words by target POS strictly first
      var allModels = widget.allWords
          .map((w) => VocabularyWordModel.fromJson(w))
          .toList();
      if (posFilter != null) {
        final posMatched = allModels
            .where(
              (w) =>
                  (w.partOfSpeech ?? '').trim().toUpperCase() ==
                  posFilter.trim().toUpperCase(),
            )
            .toList();
        if (posMatched.isNotEmpty) {
          allModels = posMatched;
        }
      }

      final knownIds = widget.knownWordIds.toSet();
      final unknownIds = widget.unknownWordIds.toSet();

      // Exclude words that are already known from diagnostic check
      List<VocabularyWordModel> filtered = allModels.where((word) {
        if (knownIds.contains(word.wordId)) {
          return false; // Skip words known in diagnostic!
        }
        if (unknownIds.isNotEmpty) {
          return unknownIds.contains(word.wordId);
        }
        return true;
      }).toList();

      _words = filtered;
    }

    if (!widget.isSandbox) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final posFocus = auth.learner?.posFocus;
      LocalStorageService.saveActiveLessonSession(
        widget.lessonId,
        widget.sessionId,
        '/session/${widget.sessionId}/introduction',
        posFocus: posFocus ?? 'ALL',
        allWords: widget.allWords,
        knownWordIds: widget.knownWordIds,
        unknownWordIds: widget.unknownWordIds,
        categoryId: widget.categoryId,
      );
    }

    if (_words.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(
            '/session/${widget.sessionId}/practice',
            extra: {
              'lessonId': widget.lessonId,
              'categoryId': widget.categoryId,
              'lessonTitle': widget.lessonTitle,
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

    if (!widget.isSandbox) {
      final snapshot = await LocalStorageService.getModuleProgressSnapshot(
        widget.sessionId,
      );
      if (snapshot != null &&
          snapshot['lessonId'] == widget.lessonId &&
          snapshot['module'] == 'vocab-intro') {
        final savedIndex = (snapshot['currentWordIndex'] as num?)?.toInt();
        final savedStep = (snapshot['currentStep'] as num?)?.toInt();
        if (savedIndex != null &&
            savedIndex >= 0 &&
            savedIndex < _words.length) {
          _currentWordIndex = savedIndex;
        }
        if (savedStep != null && savedStep >= 0 && savedStep <= 4) {
          _currentStep = savedStep;
        }
      }
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

    if (!widget.isSandbox) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      LocalStorageService.saveModuleProgressSnapshot(widget.sessionId, {
        'lessonId': widget.lessonId,
        'module': 'vocab-intro',
        'currentWordIndex': _currentWordIndex,
        'currentStep': _currentStep,
        'posFocus': auth.learner?.posFocus,
      });
    }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Audio unavailable')));
      }
      if (word.audioAssetPath != null &&
          word.audioAssetPath!.trim().isNotEmpty) {
        final path = AppConfig.sanitizeAssetPath(word.audioAssetPath!);

        Source source;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          source = UrlSource(path);
        } else {
          source = AssetSource(
            path.startsWith('assets/')
                ? path.replaceFirst('assets/', '')
                : path,
          );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Audio unavailable')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Audio unavailable')));
      }
    } finally {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  Future<void> _speakSentence() async {
    if (_isPlayingAudio) return;
    if (mounted) setState(() => _isPlayingAudio = true);

    try {
      final success = await _ttsService.speakEnglish(
        _words[_currentWordIndex].exampleSentenceEnglish,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Audio unavailable')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Audio unavailable')));
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
    final wasActiveAttempt =
        _recordingSessionActive && _isRecording && _attemptResult == null;
    // Only consider attempts exhausted when maxAttempts > 0
    final shouldMarkFailure =
        wasActiveAttempt &&
        (_maxAttempts > 0 && _attemptNumber >= _maxAttempts);

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
          _attemptNumber = _attemptNumber < _maxAttempts
              ? _attemptNumber + 1
              : _maxAttempts;
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
      _attemptResult = _applyLocalBypassIfSpoken(
        result,
        currentWord.englishWord,
      );
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

    final shouldRetry =
        _recordingSessionActive && _attemptNumber < _maxAttempts;
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
        if (_attemptResult!.isCorrect ||
            (_maxAttempts > 0 && _attemptNumber >= _maxAttempts)) {
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
                  'Pronounce: ${_words[_currentWordIndex].englishWord}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF0284C7),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Practice speaking the word aloud',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Speak naturally. It will check your pronunciation when you pause, or after 30 seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
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

  Future<void> _nextStep() async {
    final currentWord = _words[_currentWordIndex];
    final provider = Provider.of<LessonProvider>(context, listen: false);

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _isFlashcardFlipped = false;
      });
      if (!widget.isSandbox) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        LocalStorageService.saveModuleProgressSnapshot(widget.sessionId, {
          'lessonId': widget.lessonId,
          'module': 'vocab-intro',
          'currentWordIndex': _currentWordIndex,
          'currentStep': _currentStep,
          'posFocus': auth.learner?.posFocus,
        });
      }
      if (_currentStep == 1) _speakWord();
      if (_currentStep == 2) _speakSentence();
    } else {
      // Step 5 Confirmation: Mark word as INTRODUCED in database and advance to next word or Module 2
      final finalStatus = 'INTRODUCED';
      provider.updateWordProgress(
        widget.sessionId,
        currentWord.wordId,
        'FULL',
        4,
        finalStatus,
      );

      if (_currentWordIndex < _words.length - 1) {
        setState(() {
          _currentWordIndex++;
        });
        _initializeWordState();
      } else {
        String targetSessionId = widget.sessionId;
        if (!widget.isSandbox) {
          final practiceSessionId = await provider.startPracticeSession(
            widget.lessonId,
            moduleNumber: 2,
            classroomId: provider.activeClassroomId,
          );
          if (practiceSessionId != null && practiceSessionId.isNotEmpty) {
            targetSessionId = practiceSessionId;
          }
        }
        if (!mounted) return;
        // Seamless slide transition to Module 2 (Active Practice)
        context.pushReplacement(
          '/session/$targetSessionId/practice',
          extra: {
            'lessonId': widget.lessonId,
            'categoryId': widget.categoryId,
            'lessonTitle': widget.lessonTitle,
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

  PronunciationAttemptModel _applyLocalBypassIfSpoken(
    PronunciationAttemptModel result,
    String target,
  ) {
    final trans = (result.transcribedText ?? '').trim();
    if (trans.isEmpty) return result;
    final similarity = result.similarityScore ?? 0.0;
    if (similarity >= 0.80 ||
        PronunciationMatcher.matchesTranscript(trans, target)) {
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
    if (_words.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final word = _words[_currentWordIndex];
    final totalWords = _words.length;
    final displayIndex = (_currentWordIndex + 1).clamp(
      1,
      totalWords > 0 ? totalWords : 1,
    );
    final progressVal = totalWords > 0
        ? ((_currentWordIndex + ((_currentStep + 1) / 5.0).clamp(0.0, 1.0)) /
                  totalWords)
              .clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progressVal * 100).toInt();

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
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF0F172A),
              size: 22,
            ),
            onPressed: _showExitConfirmation,
          ),
          title: App3DProgressBar(value: progressVal, height: 22.0),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  '$progressPercent%',
                  style: AppTypography.baloo2(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: AppQuestionTransition(
                      child: KeyedSubtree(
                        key: ValueKey(
                          'vocab_step_${_currentWordIndex}_$_currentStep',
                        ),
                        child: _buildStepCard(theme, word),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _buildBottomButton(theme),
              ),
            ],
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
        title: Text(
          'Exit Lesson?',
          style: AppTypography.baloo2(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Leaving now will lose your progress for this vocabulary session.',
          style: AppTypography.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: AppTypography.baloo2(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (context.canPop()) {
                context.pop();
              } else if (widget.isSandbox) {
                context.go('/sandbox');
              } else {
                context.go('/home');
              }
            },
            child: Text(
              'EXIT',
              style: AppTypography.baloo2(
                fontWeight: FontWeight.w800,
                color: Colors.redAccent,
              ),
            ),
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

  Widget _buildUnifiedPill({
    required String label,
    required Color accentColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: accentColor, size: 15),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.baloo2(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineAudioButton({
    required VoidCallback? onTap,
    required Color color,
    bool isPlaying = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.10),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.volume_up_rounded,
              color: isPlaying ? Colors.grey : color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, VocabularyWordModel word) {
    final ipaText = PhoneticService.getIPA(word.englishWord);

    return Card(
      key: const ValueKey('summary_card'),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 320),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUnifiedPill(
              label: 'WORD SUMMARY',
              accentColor: const Color(0xFF059669),
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 24),

            if (word.imageAssetPath != null &&
                word.imageAssetPath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(16),
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
                border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
              ),
              child: Column(
                children: [
                  Text(
                    'CEBUANO',
                    style: AppTypography.baloo2(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF166534),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          word.cebuanoMeaning,
                          style: AppTypography.baloo2(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildInlineAudioButton(
                        onTap: _isPlayingAudio
                            ? null
                            : () => _playCebuanoAudio(word.cebuanoMeaning),
                        color: const Color(0xFF15803D),
                        isPlaying: _isPlayingAudio,
                      ),
                    ],
                  ),
                  if (word.exampleSentenceCebuano != null &&
                      word.exampleSentenceCebuano!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    CebuanoTextHighlighter(
                      text: word.exampleSentenceCebuano!,
                      highlightWord: word.cebuanoMeaning,
                      style: AppTypography.nunito(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF166534),
                        height: 1.4,
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
                border: Border.all(color: const Color(0xFFFEF3C7), width: 1.2),
              ),
              child: Column(
                children: [
                  Text(
                    'ENGLISH',
                    style: AppTypography.baloo2(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF92400E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          word.englishWord,
                          style: AppTypography.baloo2(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildInlineAudioButton(
                        onTap: _isPlayingAudio ? null : _speakWord,
                        color: const Color(0xFFB45309),
                        isPlaying: _isPlayingAudio,
                      ),
                    ],
                  ),
                  if (word.partOfSpeech != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '(${word.partOfSpeech})',
                      style: AppTypography.nunito(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          word.exampleSentenceEnglish,
                          style: AppTypography.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF78350F),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildInlineAudioButton(
                        onTap: _isPlayingAudio ? null : _speakSentence,
                        color: const Color(0xFFB45309),
                        isPlaying: _isPlayingAudio,
                      ),
                    ],
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
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ipaText,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 14,
                    width: 1,
                    color: const Color(0xFFCBD5E1),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _attemptResult?.isCorrect == true
                        ? Icons.check_circle_rounded
                        : Icons.task_alt_rounded,
                    color: const Color(0xFF06A6FF),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _attemptResult?.isCorrect == true
                        ? 'Pronounced'
                        : 'Practiced',
                    style: AppTypography.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCebuanoStep(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey('cebuano_step'),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 280),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUnifiedPill(
              label: 'CEBUANO WORD',
              accentColor: const Color(0xFF10B981),
              icon: Icons.translate_rounded,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    word.cebuanoMeaning,
                    style: AppTypography.baloo2(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                _buildInlineAudioButton(
                  onTap: _isPlayingAudio
                      ? null
                      : () => _playCebuanoAudio(word.cebuanoMeaning),
                  color: const Color(0xFF10B981),
                  isPlaying: _isPlayingAudio,
                ),
              ],
            ),
            if (word.partOfSpeech != null) ...[
              const SizedBox(height: 8),
              Text(
                '(${word.partOfSpeech})',
                style: AppTypography.nunito(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
            if (word.exampleSentenceCebuano != null &&
                word.exampleSentenceCebuano!.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 16),
              Text(
                'CEBUANO EXAMPLE SENTENCE',
                style: AppTypography.baloo2(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              CebuanoTextHighlighter(
                text: word.exampleSentenceCebuano!,
                highlightWord: word.cebuanoMeaning,
                style: AppTypography.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                  height: 1.45,
                ),
                highlightStyle: AppTypography.baloo2(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF10B981),
                  height: 1.45,
                ),
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
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
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
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildUnifiedPill(
            label: 'ENGLISH WORD',
            accentColor: const Color(0xFF06A6FF),
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 20),
          if (word.imageAssetPath != null &&
              word.imageAssetPath!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomImageViewer(
                imagePath: word.imageAssetPath!,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
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
          Text(
            'In English, this is:',
            style: AppTypography.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  word.englishWord,
                  style: AppTypography.baloo2(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              _buildInlineAudioButton(
                onTap: _isPlayingAudio ? null : _speakWord,
                color: const Color(0xFF06A6FF),
                isPlaying: _isPlayingAudio,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.touch_app_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Tap card to reveal explanation',
                style: AppTypography.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardBack(ThemeData theme, VocabularyWordModel word) {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildUnifiedPill(
            label: 'EXPLANATION',
            accentColor: const Color(0xFFF59E0B),
            icon: Icons.lightbulb_rounded,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
            ),
            child: Column(
              children: [
                Text(
                  'CEBUANO',
                  style: AppTypography.baloo2(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF166534),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  word.cebuanoMeaning,
                  style: AppTypography.baloo2(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF15803D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (word.explanationText != null &&
              word.explanationText!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFEF3C7), width: 1.2),
              ),
              child: Column(
                children: [
                  Text(
                    'EXPLANATION',
                    style: AppTypography.baloo2(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF92400E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    word.explanationText!,
                    style: AppTypography.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF78350F),
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.touch_app_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Tap card to flip back',
                style: AppTypography.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnglishSentenceStep(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey('english_sentence_step'),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 280),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUnifiedPill(
              label: 'EXAMPLE SENTENCE',
              accentColor: const Color(0xFF2563EB),
              icon: Icons.chat_bubble_outline_rounded,
            ),
            const SizedBox(height: 20),
            Text(
              word.englishWord,
              style: AppTypography.baloo2(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: CebuanoTextHighlighter(
                    text: word.exampleSentenceEnglish,
                    highlightWord: word.englishWord,
                    style: AppTypography.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      height: 1.45,
                    ),
                    highlightStyle: AppTypography.baloo2(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF2563EB),
                      decorationThickness: 2.2,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                _buildInlineAudioButton(
                  onTap: _isPlayingAudio ? null : _speakSentence,
                  color: const Color(0xFF2563EB),
                  isPlaying: _isPlayingAudio,
                ),
              ],
            ),
            if (word.exampleSentenceCebuano != null) ...[
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 14),
              CebuanoTextHighlighter(
                text: word.exampleSentenceCebuano!,
                highlightWord: word.cebuanoMeaning,
                style: AppTypography.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhonologyCard(ThemeData theme, VocabularyWordModel word) {
    final ipaText = PhoneticService.getIPA(word.englishWord);

    return Card(
      key: const ValueKey('pronounce'),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 280),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUnifiedPill(
              label: 'PRONUNCIATION PRACTICE',
              accentColor: const Color(0xFFD97706),
              icon: Icons.mic_rounded,
            ),
            const SizedBox(height: 12),
            _buildUnifiedPill(
              label: '+15 PTS FOR CORRECT PRONUNCIATION',
              accentColor: const Color(0xFFB45309),
              icon: Icons.stars_rounded,
            ),
            const SizedBox(height: 20),
            Text(
              word.englishWord,
              style: AppTypography.baloo2(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
              ),
              child: Text(
                ipaText,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 18,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildInlineAudioButton(
              onTap: _isPlayingAudio ? null : _speakWord,
              color: const Color(0xFFF59E0B),
              isPlaying: _isPlayingAudio,
            ),
            const SizedBox(height: 16),
            if (_attemptResult != null) ...[
              if (_attemptResult!.isCorrect) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 44,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sounds good! 🎉',
                  style: AppTypography.baloo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 8),
                _buildUnifiedPill(
                  label: '+15 POINTS EARNED!',
                  accentColor: const Color(0xFF15803D),
                  icon: Icons.stars_rounded,
                ),
                if (_attemptResult!.transcribedText != null &&
                    _attemptResult!.transcribedText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'You said: "${_attemptResult!.transcribedText}"',
                          style: AppTypography.nunito(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF166534),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_attemptResult!.similarityScore != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Match: ${(_attemptResult!.similarityScore! * 100).toStringAsFixed(0)}%',
                            style: AppTypography.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
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
                    const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _attemptResult!.isInconclusive
                            ? "Couldn't hear you clearly. Please try again."
                            : _attemptNumber >= 3
                            ? 'No attempts left — keep practicing!'
                            : _buildFailureMessage(
                                _attemptResult!.similarityScore,
                              ),
                        style: AppTypography.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB91C1C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // What you said + match score
                if (_attemptResult!.transcribedText != null &&
                    _attemptResult!.transcribedText!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'You said: "${_attemptResult!.transcribedText}"',
                          style: AppTypography.nunito(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_attemptResult!.similarityScore != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Match: ${(_attemptResult!.similarityScore! * 100).toStringAsFixed(0)}% — need 80% to pass',
                            style: AppTypography.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                // Target phonetic text
                if (_attemptResult!.phoneticTarget != null &&
                    _attemptResult!.phoneticTarget!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.record_voice_over_rounded,
                        color: Color(0xFF2563EB),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Target:',
                        style: AppTypography.nunito(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _attemptResult!.phoneticTarget!,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.tips_and_updates_rounded,
                            color: Color(0xFFD97706),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'HOW TO IMPROVE',
                            style: AppTypography.baloo2(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (_attemptResult!.phonologicalTip != null &&
                                _attemptResult!.phonologicalTip!
                                    .trim()
                                    .isNotEmpty)
                            ? _attemptResult!.phonologicalTip!
                            : _getPhonologicalTip(word.phonologicalTipKey),
                        style: AppTypography.nunito(
                          fontSize: 13,
                          color: const Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Want to try saying it? Tap the mic to practice your pronunciation — or just continue when you are ready.',
                  textAlign: TextAlign.center,
                  style: AppTypography.nunito(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _isEvaluating
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Color(0xFF06A6FF)),
                  )
                : GestureDetector(
                    onTap: _handleMicPress,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFEFF6FF),
                        border: Border.all(
                          color: _isRecording
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF06A6FF),
                          width: 3.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isRecording
                                ? const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.25)
                                : const Color(
                                    0xFF06A6FF,
                                  ).withValues(alpha: 0.20),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 34,
                        color: _isRecording
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF06A6FF),
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String getIPA(String englishWord) => PhoneticService.getIPA(englishWord);

  String _getPhonologicalTip(String? tipKey, [String? wordText]) {
    final pref = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).learner?.languagePreference;
    return PhoneticService.getPhonologicalTip(
      tipKey: tipKey,
      word:
          wordText ??
          (_words.isNotEmpty ? _words[_currentWordIndex].englishWord : ''),
      languagePreference: pref,
    );
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
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 280),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildUnifiedPill(
              label: 'SANDBOX WORD PREVIEW',
              accentColor: const Color(0xFF06A6FF),
              icon: Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    word.englishWord,
                    style: AppTypography.baloo2(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                _buildInlineAudioButton(
                  onTap: _isPlayingAudio ? null : _speakWord,
                  color: const Color(0xFF06A6FF),
                  isPlaying: _isPlayingAudio,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
              ),
              child: Column(
                children: [
                  Text(
                    LocalizationService.translate(
                      _pref,
                      'cebuano_meaning',
                    ).toUpperCase(),
                    style: AppTypography.baloo2(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF166534),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          word.cebuanoMeaning,
                          style: AppTypography.baloo2(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF15803D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildInlineAudioButton(
                        onTap: _isPlayingAudio
                            ? null
                            : () => _playCebuanoAudio(word.cebuanoMeaning),
                        color: const Color(0xFF15803D),
                        isPlaying: _isPlayingAudio,
                      ),
                    ],
                  ),
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
                border: Border.all(color: const Color(0xFFFEF3C7), width: 1.2),
              ),
              child: Column(
                children: [
                  Text(
                    LocalizationService.translate(
                      _pref,
                      'english_example',
                    ).toUpperCase(),
                    style: AppTypography.baloo2(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF92400E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: CebuanoTextHighlighter(
                          text: word.exampleSentenceEnglish,
                          highlightWord: word.englishWord,
                          style: AppTypography.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF78350F),
                            height: 1.4,
                          ),
                          highlightStyle: AppTypography.baloo2(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD97706),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFD97706),
                            decorationThickness: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildInlineAudioButton(
                        onTap: _isPlayingAudio ? null : _speakSentence,
                        color: const Color(0xFFD97706),
                        isPlaying: _isPlayingAudio,
                      ),
                    ],
                  ),
                  if (word.exampleSentenceCebuano != null) ...[
                    const SizedBox(height: 8),
                    CebuanoTextHighlighter(
                      text: word.exampleSentenceCebuano!,
                      highlightWord: word.cebuanoMeaning,
                      style: AppTypography.nunito(
                        fontSize: 13,
                        color: const Color(0xFF92400E),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            if (word.phonologicalTipKey != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  widget.isSandbox
                      ? (word.phonologicalTipKey ?? '')
                      : _getPhonologicalTip(word.phonologicalTipKey),
                  textAlign: TextAlign.center,
                  style: AppTypography.nunito(
                    fontSize: 13,
                    color: const Color(0xFF334155),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
    }

    String buttonText = 'NEXT: ENGLISH WORD';
    if (_currentStep == 1) buttonText = 'NEXT: EXAMPLE SENTENCE';
    if (_currentStep == 2) buttonText = 'NEXT: PRONUNCIATION';
    if (_currentStep == 3) {
      if (_attemptResult != null &&
          _attemptResult!.isCorrect == false &&
          _attemptNumber >= 3) {
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
              backgroundColor: _currentStep == 4
                  ? const Color(0xFF10B981)
                  : const Color(0xFF06A6FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
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
    debugPrint(
      widget.isSandbox
          ? 'Navigating to sandbox review...'
          : 'Navigating to Module 2...',
    );

    String targetSessionId = widget.sessionId;
    if (!widget.isSandbox) {
      final practiceSessionId = await provider.startPracticeSession(
        widget.lessonId,
        moduleNumber: 2,
        classroomId: provider.activeClassroomId,
      );
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
