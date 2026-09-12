import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../models/vocabulary_word_model.dart';
import '../services/local_storage_service.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import '../core/motion/motion.dart';

class DiagnosticCheckScreen extends StatefulWidget {
  final String lessonId;
  final String categoryId;
  final String? lessonTitle;

  const DiagnosticCheckScreen({
    super.key,
    required this.lessonId,
    required this.categoryId,
    this.lessonTitle,
  });

  @override
  State<DiagnosticCheckScreen> createState() => _DiagnosticCheckScreenState();
}

class _DiagnosticCheckScreenState extends State<DiagnosticCheckScreen> {
  List<VocabularyWordModel> _localWords = [];
  int _currentIndex = 0;
  final Map<String, bool> _answers = {};
  bool _submitting = false;
  final TtsService _ttsService = TtsService();

  // Confusable pairs loaded for this lesson: raw list from API
  List<Map<String, dynamic>> _confusablePairs = [];

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final posFocus = auth.learner?.posFocus;
      final filter = (posFocus != null && posFocus != 'ALL') ? posFocus : null;
      final words = await provider.loadVocabulary(widget.lessonId, partOfSpeech: filter);
      final wordDifficulties = await provider.loadWordDifficulties(widget.lessonId);
      final pairs = await provider.loadConfusablePairs(widget.lessonId);

      // If doing ALL words, exclude words that are already MASTERED so user only practices remaining words
      List<VocabularyWordModel> activeWords = words;
      if (filter == null || filter == 'ALL') {
        final unmastered = words.where((w) => wordDifficulties[w.wordId] != 'MASTERED').toList();
        if (unmastered.isNotEmpty) {
          activeWords = unmastered;
        }
      }

      setState(() {
        _localWords = activeWords;
        _confusablePairs = pairs;
      });

      LocalStorageService.saveActiveLessonSession(
        widget.lessonId,
        'diag_${widget.lessonId}',
        '/lesson/${widget.lessonId}/diagnostic',
        posFocus: filter ?? 'ALL',
        allWords: activeWords.map((w) => w.toJson()).toList(),
        categoryId: widget.categoryId,
      );
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  /// Returns the confusable pair data for [word] if one exists, otherwise null.
  Map<String, dynamic>? _findPairForWord(VocabularyWordModel word) {
    for (final pair in _confusablePairs) {
      final wordA = pair['wordA'] as Map<String, dynamic>?;
      final wordB = pair['wordB'] as Map<String, dynamic>?;
      if (wordA == null || wordB == null) continue;
      if (wordA['wordId'] == word.wordId || wordB['wordId'] == word.wordId) {
        return pair;
      }
    }
    return null;
  }

  void _answerCurrent(bool isKnown) async {
    final word = _localWords[_currentIndex];

    // If user doesn't know the word and it has a confusable pair, show comparison
    if (!isKnown) {
      final pair = _findPairForWord(word);
      if (pair != null) {
        final shouldContinue = await _showConfusablePairSheet(pair);
        if (!mounted) return;
        // If user dismissed the sheet without tapping "Got it", don't advance
        if (shouldContinue != true) return;
      }
    }

    _answers[word.wordId] = isKnown;

    if (_currentIndex < _localWords.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _submitting = true;
      });

      final provider = Provider.of<LessonProvider>(context, listen: false);
      final result = await provider.submitDiagnostic(widget.lessonId, _answers);

      if (result != null && mounted) {
        final List<Map<String, dynamic>> known = [];
        final List<Map<String, dynamic>> unknown = [];
        final List<Map<String, dynamic>> all = [];

        for (var w in _localWords) {
          final isKnownWord = _answers[w.wordId] ?? false;
          final wordMap = w.toJson();
          if (isKnownWord) {
            known.add(wordMap);
          } else {
            unknown.add(wordMap);
          }
          all.add(wordMap);
        }

        context.go(
          '/lesson/${widget.lessonId}/diagnostic-summary',
          extra: {
            'knownWords': known,
            'unknownWords': unknown,
            'allWords': all,
            'sessionId': result.sessionId,
            'categoryId': widget.categoryId,
            'lessonTitle': widget.lessonTitle,
          },
        );
      } else {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  /// Shows a draggable bottom sheet with a side-by-side confusable pair comparison.
  /// Returns true when the user taps "Got it, continue".
  Future<bool?> _showConfusablePairSheet(Map<String, dynamic> pair) {
    final wordA = pair['wordA'] as Map<String, dynamic>;
    final wordB = pair['wordB'] as Map<String, dynamic>;
    final wordAEnglish = wordA['englishWord'] as String? ?? '';
    final wordACebuano = wordA['cebuanoMeaning'] as String? ?? '';
    final wordBEnglish = wordB['englishWord'] as String? ?? '';
    final wordBCebuano = wordB['cebuanoMeaning'] as String? ?? '';
    final sentenceA = pair['contrastiveSentenceA'] as String? ?? '';
    final sentenceB = pair['contrastiveSentenceB'] as String? ?? '';

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfusablePairSheet(
        wordAEnglish: wordAEnglish,
        wordACebuano: wordACebuano,
        wordBEnglish: wordBEnglish,
        wordBCebuano: wordBCebuano,
        sentenceA: sentenceA,
        sentenceB: sentenceB,
        ttsService: _ttsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LessonProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    if (provider.isLoading && _localWords.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_localWords.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(
          child: Text('No words loaded. Make sure the backend is seeded.',
              style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    if (_submitting) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                LocalizationService.translate(pref, 'saving_results'),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final currentWord = _localWords[_currentIndex];
    final progress = (_currentIndex + 1) / _localWords.length;
    final hasPair = _findPairForWord(currentWord) != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            try {
              context.pop();
            } catch (e) {
              context.go('/home');
            }
          },
        ),
        title: Text(
          LocalizationService.translate(pref, 'diagnostic_check'),
          style: AppTypography.baloo2(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF06A6FF),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              App3DProgressBar(
                value: progress,
                height: 20.0,
              ),
              const SizedBox(height: 12),
              Text(
                LocalizationService.translate(pref, 'card_indicator',
                    args: ['${_currentIndex + 1}', '${_localWords.length}']),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Word Card with Smooth Directional Slide Transition
              AppQuestionTransition(
                child: Container(
                  key: ValueKey('diag_card_${currentWord.wordId}_$_currentIndex'),
                  height: hasPair ? 270 : 240,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentWord.englishWord,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          LocalizationService.translate(pref, 'know_word_prompt'),
                          style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                        ),
                        // Confusable badge shown only when this word has a pair
                        if (hasPair) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFFD97706)),
                                SizedBox(width: 5),
                                Text(
                                  'Has confusable pair',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFD97706),
                                    fontWeight: FontWeight.w600,
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
              ),
              const Spacer(),

              // Buttons (Chunky 3D Duolingo Style)
              App3DButton(
                onPressed: () => _answerCurrent(true),
                variant: App3DButtonVariant.primary,
                height: 54,
                depth: 4.5,
                isFullWidth: true,
                icon: Icons.check_circle_outline,
                text: LocalizationService.translate(pref, 'yes_know'),
              ),
              const SizedBox(height: 14),
              App3DButton(
                onPressed: () => _answerCurrent(false),
                variant: App3DButtonVariant.secondary,
                height: 50,
                depth: 3.5,
                isFullWidth: true,
                icon: Icons.school_outlined,
                text: LocalizationService.translate(pref, 'not_yet'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Confusable pair bottom sheet ─────────────────────────────────────────────

class _ConfusablePairSheet extends StatelessWidget {
  final String wordAEnglish;
  final String wordACebuano;
  final String wordBEnglish;
  final String wordBCebuano;
  final String sentenceA;
  final String sentenceB;
  final TtsService ttsService;

  const _ConfusablePairSheet({
    required this.wordAEnglish,
    required this.wordACebuano,
    required this.wordBEnglish,
    required this.wordBCebuano,
    required this.sentenceA,
    required this.sentenceB,
    required this.ttsService,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 32, color: Color(0xFFF59E0B)),
                    const SizedBox(height: 8),
                    Text(
                      'Confusable Words',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        fontFamily: AppTypography.displayFontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'These words look or sound similar, but have different meanings. Compare them:',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Side-by-side cards — matches ConfusableWordsDistinctionScreen style
                      Row(
                        children: [
                          // Word A — blue
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
                                  Text(
                                    wordAEnglish,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0369A1),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cebuano: $wordACebuano',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF0284C7),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  App3DButton(
                                    onPressed: () => ttsService.speak(wordAEnglish),
                                    icon: Icons.volume_up_rounded,
                                    text: LocalizationService.translate(pref, 'listen'),
                                    customBaseColor: const Color(0xFF0284C7),
                                    customDepthColor: const Color(0xFF0369A1),
                                    height: 38,
                                    depth: 3.0,
                                    borderRadius: 12,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Word B — amber
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      LocalizationService.translate(pref, 'bonus_word'),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    wordBEnglish,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cebuano: $wordBCebuano',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFD97706),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  App3DButton(
                                    onPressed: () => ttsService.speak(wordBEnglish),
                                    icon: Icons.volume_up_rounded,
                                    text: LocalizationService.translate(pref, 'listen'),
                                    customBaseColor: const Color(0xFFD97706),
                                    customDepthColor: const Color(0xFFB45309),
                                    height: 38,
                                    depth: 3.0,
                                    borderRadius: 12,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Example sentences (if available)
                      if (sentenceA.isNotEmpty || sentenceB.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Example Usage',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (sentenceA.isNotEmpty)
                          _ExampleCard(
                            word: wordAEnglish,
                            sentence: sentenceA,
                            wordColor: const Color(0xFF0369A1),
                            bgColor: const Color(0xFFF0F9FF),
                            borderColor: const Color(0xFFBAE6FD),
                          ),
                        if (sentenceA.isNotEmpty && sentenceB.isNotEmpty)
                          const SizedBox(height: 12),
                        if (sentenceB.isNotEmpty)
                          _ExampleCard(
                            word: wordBEnglish,
                            sentence: sentenceB,
                            wordColor: const Color(0xFFB45309),
                            bgColor: const Color(0xFFFFF7ED),
                            borderColor: const Color(0xFFFDE68A),
                          ),
                      ],

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              // Footer "Got it" button
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 8, 24, MediaQuery.of(context).padding.bottom + 16),
                child: App3DButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  variant: App3DButtonVariant.dark,
                  height: 54,
                  depth: 4.5,
                  isFullWidth: true,
                  text: LocalizationService.translate(pref, 'got_it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Example sentence card with the target word bolded ───────────────────────

class _ExampleCard extends StatelessWidget {
  final String word;
  final String sentence;
  final Color wordColor;
  final Color bgColor;
  final Color borderColor;

  const _ExampleCard({
    required this.word,
    required this.sentence,
    required this.wordColor,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    // Split on the target word (case-insensitive) and rebuild with bold span
    final regex = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
    final parts = sentence.split(regex);
    final matches = regex.allMatches(sentence).map((m) => m.group(0)!).toList();

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
      ));
      if (i < matches.length) {
        spans.add(TextSpan(
          text: matches[i],
          style: TextStyle(
            fontSize: 14,
            color: wordColor,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}
