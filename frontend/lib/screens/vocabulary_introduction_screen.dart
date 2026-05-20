import 'package:flutter/material';
import 'package:go_router/go_router.dart';
import 'package:provider/provider';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../models/vocabulary_word_model.dart';
import '../services/tts_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/stt_service.dart';
import '../models/pronunciation_attempt_model.dart';
import '../services/localization_service.dart';

class VocabularyIntroductionScreen extends StatefulWidget {
  final String sessionId;
  final String lessonId;
  final List<String> knownWordIds;
  final List<String> unknownWordIds;
  final List<Map<String, dynamic>> allWords;

  const VocabularyIntroductionScreen({
    super.key,
    required this.sessionId,
    required this.lessonId,
    required this.knownWordIds,
    required this.unknownWordIds,
    required this.allWords,
  });

  @override
  State<VocabularyIntroductionScreen> createState() => _VocabularyIntroductionScreenState();
}

class _VocabularyIntroductionScreenState extends State<VocabularyIntroductionScreen> {
  String? get _pref => Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;
  final TtsService _ttsService = TtsService();
  final AudioRecorderService _recorderService = AudioRecorderService();
  final SttService _sttService = SttService();

  List<VocabularyWordModel> _words = [];
  int _currentWordIndex = 0;
  
  // Card learning state
  int _currentStep = 0; // 0: Form & Meaning, 1: Contextual Practice, 2: Phonology, 3: Speech Feedback
  String _pathway = 'FULL'; // 'FULL' or 'ACCELERATED'

  // Speech evaluation state variables
  bool _isRecording = false;
  bool _isEvaluating = false;
  int _attemptNumber = 1;
  PronunciationAttemptModel? _attemptResult;

  @override
  void initState() {
    super.initState();
    _words = widget.allWords.map((w) => VocabularyWordModel.fromJson(w)).toList();
    _initializeWordState();
  }

  @override
  void dispose() {
    _recorderService.dispose();
    super.dispose();
  }

  void _initializeWordState() {
    if (_words.isEmpty) return;
    final currentWord = _words[_currentWordIndex];
    final isKnown = widget.knownWordIds.contains(currentWord.wordId);
    setState(() {
      _pathway = isKnown ? 'ACCELERATED' : 'FULL';
      _currentStep = isKnown ? 2 : 0; // Accelerated starts at step 2 (Phonology)
      _attemptNumber = 1;
      _attemptResult = null;
      _isRecording = false;
      _isEvaluating = false;
    });

    // Auto-speak English word on start
    _ttsService.speak(currentWord.englishWord);
  }

  void _speakWord() {
    _ttsService.speak(_words[_currentWordIndex].englishWord);
  }

  void _speakSentence() {
    _ttsService.speak(_words[_currentWordIndex].exampleSentenceEnglish);
  }

  Future<void> _handleMicPress() async {
    if (_isEvaluating) return;

    if (_isRecording) {
      // Stop recording and evaluate
      setState(() {
        _isRecording = false;
        _isEvaluating = true;
      });

      final path = await _recorderService.stopRecording();
      if (path != null) {
        final currentWord = _words[_currentWordIndex];
        final result = await _sttService.evaluatePronunciation(
          audioFilePath: path,
          sessionId: widget.sessionId,
          wordId: currentWord.wordId,
          lessonId: widget.lessonId,
          moduleNumber: 1,
          targetWord: currentWord.englishWord,
          attemptNumber: _attemptNumber,
        );

        setState(() {
          _attemptResult = result;
          _isEvaluating = false;
        });

        // Trigger TTS positive reinforcement on success
        if (result.isCorrect) {
          _ttsService.speak(currentWord.englishWord);
        }
      } else {
        setState(() {
          _isEvaluating = false;
        });
      }
    } else {
      // Start recording
      final permission = await Permission.microphone.request();
      if (permission.isGranted) {
        setState(() {
          _isRecording = true;
          _attemptResult = null;
        });
        await _recorderService.startRecording();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to practice pronunciation.')),
        );
      }
    }
  }

  void _nextStep() {
    final currentWord = _words[_currentWordIndex];
    final provider = Provider.of<LessonProvider>(context, listen: false);

    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      provider.updateWordProgress(widget.sessionId, currentWord.wordId, _pathway, 1, 'INTRODUCED');
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
      provider.updateWordProgress(widget.sessionId, currentWord.wordId, _pathway, 2, 'INTRODUCED');
      _ttsService.speak(currentWord.englishWord);
    } else if (_currentStep == 2) {
      setState(() => _currentStep = 3);
      provider.updateWordProgress(widget.sessionId, currentWord.wordId, _pathway, 3, 'INTRODUCED');
    } else if (_currentStep == 3) {
      // Complete word learning and advance index
      final isFinalSuccess = _attemptResult?.isCorrect ?? false;
      final finalStatus = isFinalSuccess ? 'MASTERED' : 'NEEDS_PRONUNCIATION_REVIEW';
      
      provider.updateWordProgress(widget.sessionId, currentWord.wordId, _pathway, 4, finalStatus);

      if (_currentWordIndex < _words.length - 1) {
        setState(() {
          _currentWordIndex++;
        });
        _initializeWordState();
      } else {
        // Complete session
        context.go(
          '/session/${widget.sessionId}/round-completed',
          extra: {
            'introducedCount': _words.length,
            'knownCount': widget.knownWordIds.length,
          },
        );
      }
    }
  }

  void _retryPronunciation() {
    setState(() {
      _attemptNumber++;
      _attemptResult = null;
      _isRecording = false;
      _isEvaluating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;
    if (_words.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final word = _words[_currentWordIndex];
    final totalSteps = _pathway == 'ACCELERATED' ? 2 : 4;
    final stepPercentage = (_currentStep + (_pathway == 'ACCELERATED' ? -1 : 1)) / totalSteps;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          LocalizationService.translate(pref, 'learning_progress', args: ['${_currentWordIndex + 1}', '${_words.length}']),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Horizontal progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stepPercentage.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 24),

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
    );
  }

  Widget _buildStepCard(ThemeData theme, VocabularyWordModel word) {
    switch (_currentStep) {
      case 0:
        return _buildFormAndMeaningCard(theme, word);
      case 1:
        return _buildContextualPracticeCard(theme, word);
      case 2:
        return _buildPhonologyCard(theme, word);
      case 3:
        return _buildSpeechFeedbackCard(theme, word);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFormAndMeaningCard(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey(0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  word.englishWord,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFF59E0B), size: 28),
                  onPressed: _speakWord,
                ),
              ],
            ),
            if (word.partOfSpeech != null) ...[
              const SizedBox(height: 6),
              Text(
                '(${word.partOfSpeech})',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 20),
            const Text(
              LocalizationService.translate(_pref, 'cebuano_meaning'),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              word.cebuanoMeaning,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualPracticeCard(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey(1),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFF6366F1)),
            const SizedBox(height: 24),
            const Text(
              LocalizationService.translate(_pref, 'english_example'),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              word.exampleSentenceEnglish,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFF59E0B)),
              onPressed: _speakSentence,
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 16),
            const Text(
              LocalizationService.translate(_pref, 'cebuano_translation'),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              word.exampleSentenceCebuano ?? 'Walay hubad nga makita.',
              style: const TextStyle(fontSize: 15, color: Color(0xFFCBD5E1), height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhonologyCard(ThemeData theme, VocabularyWordModel word) {
    return Card(
      key: const ValueKey(2),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (word.isConfusablePairMember) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Confusable Word Alert!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              LocalizationService.translate(_pref, 'how_to_pronounce'),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              word.englishWord,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            // Phonetic IPA Rendering
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                word.phonologicalTipKey != null ? getIPA(word.englishWord) : '/${word.englishWord.toLowerCase()}/',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 18, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFF59E0B), size: 32),
              onPressed: _speakWord,
            ),
          ],
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

  Widget _buildSpeechFeedbackCard(ThemeData theme, VocabularyWordModel word) {
    if (_attemptResult == null) {
      // Speak prompting phase
      return Card(
        key: const ValueKey(3),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                word.englishWord,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                _isRecording ? LocalizationService.translate(_pref, 'mic_prompt_recording') : LocalizationService.translate(_pref, 'mic_prompt_idle'),
                style: TextStyle(color: _isRecording ? theme.colorScheme.secondary : const Color(0xFF94A3B8), fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _isEvaluating
                  ? const CircularProgressIndicator()
                  : GestureDetector(
                      onTap: _handleMicPress,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? theme.colorScheme.error.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.15),
                          border: Border.all(
                            color: _isRecording ? theme.colorScheme.error : theme.colorScheme.primary,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 40,
                          color: _isRecording ? theme.colorScheme.error : theme.colorScheme.primary,
                        ),
                      ),
                    ),
              if (_isRecording) ...[
                const SizedBox(height: 12),
                Text(
                  LocalizationService.translate(_pref, 'tap_to_stop'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 1.0),
                )
              ]
            ],
          ),
        ),
      );
    }

    // Results feedback phase
    final result = _attemptResult!;
    final isSuccess = result.isCorrect;

    return Card(
      key: const ValueKey(4),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isSuccess ? theme.colorScheme.tertiary : theme.colorScheme.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? LocalizationService.translate(_pref, 'pronunciation_excellent') : LocalizationService.translate(_pref, 'pronunciation_try_again'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? theme.colorScheme.tertiary : theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Transcriptions comparison
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(LocalizationService.translate(_pref, 'target_word'), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Text(word.englishWord, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(result.phoneticTarget ?? '', style: const TextStyle(fontFamily: 'Courier', color: Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(width: 48),
                  Column(
                    children: [
                      Text(LocalizationService.translate(_pref, 'you_said'), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Text(result.transcribedText ?? '...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('/${(result.transcribedText ?? '').toLowerCase()}/', style: const TextStyle(fontFamily: 'Courier', color: Colors.orange)),
                    ],
                  ),
                ],
              ),
              
              if (!isSuccess && result.phonologicalTip != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result.phonologicalTip!,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
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
    if (_currentStep == 3 && _attemptResult != null) {
      final isSuccess = _attemptResult!.isCorrect;
      final showTryAgain = !isSuccess && _attemptNumber < 3;

      if (showTryAgain) {
        return ElevatedButton(
          onPressed: _retryPronunciation,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            LocalizationService.translate(_pref, 'try_again'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        );
      }
    }

    // Default step advance button
    String buttonText = LocalizationService.translate(_pref, 'next');
    if (_currentStep == 0) buttonText = LocalizationService.translate(_pref, 'got_it');
    if (_currentStep == 2) buttonText = LocalizationService.translate(_pref, 'practice_pronunciation');
    if (_currentStep == 3) buttonText = LocalizationService.translate(_pref, 'continue');

    return ElevatedButton(
      onPressed: (_currentStep == 3 && _attemptResult == null) ? null : _nextStep,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }
}
