import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../models/vocabulary_word_model.dart';
import '../widgets/mascot_bubble.dart';
import '../services/local_storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/image_matching_widget.dart';
import '../widgets/custom_image_viewer.dart';
import '../widgets/app_3d_progress_bar.dart';
import '../widgets/cebuano_text_highlighter.dart';
import 'short_reintroduction_screen.dart';
import '../widgets/streak_and_break_animations.dart';
import '../services/lesson_audio_service.dart';

class ActivePracticeScreen extends StatefulWidget {
  final String sessionId;
  final String lessonId;
  final String categoryId;
  final String? lessonTitle;
  final List<String> knownWordIds;
  final List<String> unknownWordIds;
  final List<Map<String, dynamic>> allWords;
  final bool isSandbox;

  const ActivePracticeScreen({
    super.key,
    required this.sessionId,
    required this.lessonId,
    required this.categoryId,
    this.lessonTitle,
    required this.knownWordIds,
    required this.unknownWordIds,
    required this.allWords,
    this.isSandbox = false,
  });

  @override
  State<ActivePracticeScreen> createState() => _ActivePracticeScreenState();
}

class _ActivePracticeScreenState extends State<ActivePracticeScreen> {
  // Services
  final TtsService _ttsService = TtsService();

  // Words List
  List<VocabularyWordModel> _words = [];

  // Practice Queue
  List<PracticeItemModel> _practiceQueue = [];
  int _currentIndex = 0;
  int _completedScreens = 0;
  int _plannedScreens = 0;

  // State Management
  bool _isLoading = true;
  bool _checked = false;
  bool _isAnswerCorrect = false;
  bool _showFeedback = false;

  // Matching Activity Temporary States
  String? _selectedCebuano;
  String? _selectedEnglish;
  final Map<String, String> _currentMatches = {}; // Cebuano -> English
  List<String> _matchingCebuanoList = [];
  List<String> _matchingEnglishList = [];
  final List<Color> _pairColors = [
    const Color(0xFF818CF8), // Indigo
    const Color(0xFF34D399), // Emerald
    const Color(0xFFFBBF24), // Amber
    const Color(0xFFF472B6), // Pink
  ];

  // Multiple Choice / Fill In The Blank Selected Index
  int _selectedOptionIndex = -1;
  List<String> _options = [];
  final TextEditingController _typingController = TextEditingController();

  // Flashcard Recall State
  bool _flashcardFlipped = false;

  // Rearrangement State
  List<String> _scrambledTokens = [];
  List<String> _assembledTokens = [];

  // Reinforcement & Scoring Variables
  final Map<String, int> _wordWrongAttempts = {};
  /// Tracks the highest difficulty tier each word has ever reached in this session.
  /// Scale: 0=LEARNING, 1=FAMILIAR, 2=PROFICIENT, 3=MASTERED
  /// Only advances on a backend level-up confirmation — wrong answers never move it.
  final Map<String, int> _wordBestTier = {};
  /// Tracks consecutive correct answers in the current tier to provide dynamic ladder climbing progress.
  final Map<String, int> _wordCorrectStreak = {};
  /// Tracks consecutive incorrect answers in the current tier.
  final Map<String, int> _wordIncorrectStreak = {};
  int _initialPassCorrectCount = 0;
  int _reinforcementPassCorrectCount = 0;
  bool _hasLeveledUpAnyWord = false;
  double _moduleScore = 0.0;

  // Session-wide consecutive streak for celebration overlay (Module 2)
  int _consecutiveStreak = 0;
  int _streakCelebrationThreshold = 3;
  int _upgradeStreakRequired = 2;
  int _demotionThreshold = 2;
  int? _module3UpgradeStreakRequired;
  int? _module3DemotionThreshold;
  String? _module2Activities;

  int _getUpgradeStreakForWord(String wordId) {
    final currentTier = _wordBestTier[wordId] ?? 0;
    if (currentTier == 2) {
      return _module3UpgradeStreakRequired ?? _upgradeStreakRequired;
    }
    return _upgradeStreakRequired;
  }

  int _getDemotionThresholdForWord(String wordId) {
    final currentTier = _wordBestTier[wordId] ?? 0;
    if (currentTier == 2) {
      return _module3DemotionThreshold ?? _demotionThreshold;
    }
    return _demotionThreshold;
  }

  // Session Completed State
  final bool _isCompleted = false;
  bool _isNavigating = false;
  bool _isAdvancingNext = false; // Guard against rapid multi-tap on Continue button

  // Timer Variables
  Timer? _questionTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    LessonAudioService().playBgm();
    _words = widget.allWords
        .map((w) => VocabularyWordModel.fromJson(w))
        .toList();
    if (!widget.isSandbox) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final posFocus = auth.learner?.posFocus;
      LocalStorageService.saveActiveLessonSession(
        widget.lessonId,
        widget.sessionId,
        '/session/${widget.sessionId}/practice',
        posFocus: posFocus ?? 'ALL',
        allWords: widget.allWords,
        categoryId: widget.categoryId,
        lessonTitle: widget.lessonTitle,
      );
    }
    _initializeSession();
  }

  @override
  void dispose() {
    LessonAudioService().stopBgm();
    _questionTimer?.cancel();
    _typingController.dispose();
    super.dispose();
  }

  final List<ReinforcementQueueItem> _reinforcementQueue = [];

  Future<void> _initializeSession() async {
    setState(() => _isLoading = true);

    // 1. Load streak-celebration threshold and lesson config first.
    if (!widget.isSandbox && mounted) {
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      var lesson = lessonProvider.lessons
          .where((l) => l.lessonId == widget.lessonId)
          .firstOrNull;
      if (lesson == null && widget.lessonId.isNotEmpty) {
        lesson = await lessonProvider.fetchLessonDetails(widget.lessonId);
      }
      if (lesson == null && widget.categoryId.isNotEmpty) {
        try {
          await lessonProvider.loadLessons(widget.categoryId);
          lesson = lessonProvider.lessons
              .where((l) => l.lessonId == widget.lessonId)
              .firstOrNull;
        } catch (_) {}
      }
      if (lesson != null) {
        _upgradeStreakRequired = lesson.upgradeStreakRequired ?? 2;
        _demotionThreshold = lesson.demotionThreshold ?? 2;
        _module3UpgradeStreakRequired = lesson.module3UpgradeStreakRequired ?? _upgradeStreakRequired;
        _module3DemotionThreshold = lesson.module3DemotionThreshold ?? _demotionThreshold;
        _streakCelebrationThreshold = lesson.streakCelebrationThreshold ?? 3;
        _module2Activities = lesson.module2Activities;
        debugPrint(
          'ActivePractice: config loaded -> upgradeStreakRequired=$_upgradeStreakRequired, demotionThreshold=$_demotionThreshold, module3UpgradeStreakRequired=$_module3UpgradeStreakRequired, module3DemotionThreshold=$_module3DemotionThreshold, streakCelebrationThreshold=$_streakCelebrationThreshold, module2Activities=$_module2Activities',
        );
      }
    }

    // 2. Check if there is an existing saved session state
    final savedState = await LocalStorageService.getPracticeSessionState(
      widget.sessionId,
    );

    if (savedState != null) {
      _practiceQueue = (savedState['queue'] as List<dynamic>?)
              ?.map((item) => item is PracticeItemModel
                  ? item
                  : PracticeItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      _currentIndex = (savedState['currentIndex'] as int?) ?? 0;
      _completedScreens =
          (savedState['completedScreens'] as int?) ?? _currentIndex;
      _plannedScreens =
          (savedState['plannedScreens'] as int?) ?? _practiceQueue.length;
      if (savedState['maxWordTierPoints'] != null) {
        final tiers = savedState['maxWordTierPoints'] as Map;
        tiers.forEach((k, v) {
          if (v is num) _wordBestTier[k.toString()] = v.toInt();
        });
      }
      _initWordTierProgress();

      // Purge any remaining items for words that are already MASTERED
      _practiceQueue.removeWhere((qItem) =>
          _practiceQueue.indexOf(qItem) >= _currentIndex &&
          ((_wordBestTier[qItem.wordId] ?? 0) >= 3 ||
              qItem.difficultyLevel?.toUpperCase() == 'MASTERED'));
      _plannedScreens = _practiceQueue.length;

      if (_practiceQueue.isNotEmpty && _currentIndex >= _practiceQueue.length) {
        await _completeModuleAndAdvance();
      } else if (_practiceQueue.isNotEmpty) {
        await _fetchAndLoadCurrentItem();
      } else {
        await _completeModuleAndAdvance();
      }
    } else {
      // Build new session queue
      _initWordTierProgress();

      // If all words are already mastered, advance to Module 3 immediately
      final allAlreadyMastered = _words.isNotEmpty &&
          _words.every((w) =>
              (_wordBestTier[w.wordId] ?? 0) >= 3 ||
              w.difficultyLevel?.toUpperCase() == 'MASTERED');
      if (allAlreadyMastered) {
        debugPrint(
          'ActivePractice: All words are already MASTERED -> advancing to Module 3 immediately',
        );
        await _completeModuleAndAdvance();
        return;
      }

      if (widget.isSandbox) {
        _buildPracticeQueue();
      } else {
        if (!mounted) return;
        final provider = Provider.of<LessonProvider>(context, listen: false);
        final backendQuestions = await provider.loadRetrievalQuestions(
          widget.sessionId,
        );
        if (!mounted) return;

        // Filter out questions for words that are already MASTERED
        final unmasteredQuestions = backendQuestions.where((q) {
          final wId = q['wordId']?.toString();
          final lvl = q['difficultyLevel']?.toString().toUpperCase();
          if (lvl == 'MASTERED') return false;
          if (wId != null && (_wordBestTier[wId] ?? 0) >= 3) return false;
          final wordObj = _words.where((w) => w.wordId == wId).firstOrNull;
          if (wordObj != null &&
              (wordObj.difficultyLevel?.toUpperCase() == 'MASTERED' ||
                  _tierOrdinal(wordObj.difficultyLevel) >= 3)) {
            return false;
          }
          return true;
        }).toList();

        _practiceQueue = unmasteredQuestions.map((q) {
          final formatStr = q['activityFormat'] as String? ?? 'MULTIPLE_CHOICE';
          ActivityFormat format;
          switch (formatStr) {
            case 'MULTIPLE_CHOICE':
              format = ActivityFormat.multipleChoice;
              break;
            case 'FILL_IN_BLANK':
              format = ActivityFormat.fillInTheBlank;
              break;
            case 'MATCHING':
              format = ActivityFormat.matching;
              break;
            case 'TYPE_WHAT_YOU_HEAR':
              format = ActivityFormat.listeningTyping;
              break;
            case 'SENTENCE_ARRANGEMENT':
              // Sentence arrangement is exclusive to Module 3 (Sentence Building)
              format = ActivityFormat.fillInTheBlank;
              break;
            case 'WORD_SCRAMBLE':
              format = ActivityFormat.wordScramble;
              break;
            case 'IMAGE_LABELING':
              format = ActivityFormat.imageLabeling;
              break;
            case 'TRUE_OR_FALSE':
              format = ActivityFormat.trueOrFalse;
              break;
            case 'HINT_TO_WORD':
              format = ActivityFormat.hintToWord;
              break;
            default:
              format = ActivityFormat.multipleChoice;
          }

          final options = List<String>.from(q['options'] ?? []);
          final correctAnswer = q['correctAnswer'] as String? ?? '';
          final distractors = options.where((o) => o != correctAnswer).toList();
          final scrambledTokens = List<String>.from(q['scrambledTokens'] ?? []);

          List<Map<String, dynamic>>? matchingSet;
          if (q['matchingPairs'] != null) {
            matchingSet = (q['matchingPairs'] as List<dynamic>)
                .map(
                  (e) => {
                    'englishWord': e['english'],
                    'cebuanoMeaning': e['cebuano'],
                  },
                )
                .toList();
          }

          final rawExample = (q['exampleSentenceEnglish'] as String?)?.trim();
          final exampleSentence = (rawExample != null && rawExample.isNotEmpty)
              ? rawExample
              : '';

          final rawQuestionText = (q['questionText'] as String?)?.trim();
          final fitbSentence =
              (format == ActivityFormat.fillInTheBlank &&
                  rawQuestionText != null &&
                  rawQuestionText.contains('_'))
              ? rawQuestionText
              : null;

          return PracticeItemModel(
            wordId: q['wordId'],
            englishWord:
                q['word']?.toString() ?? q['englishWord']?.toString() ?? '',
            displayWord: q['displayWord']?.toString(),
            cebuanoMeaning: q['cebuanoMeaning'] ?? '',
            exampleSentenceEnglish: exampleSentence,
            exampleSentenceCebuano:
                q['exampleSentenceCebuano'] ?? q['cebuanoMeaning'],
            activityFormat: format,
            eligibleActivityTypes:
                q['eligibleActivityTypes']?.toString() ??
                q['activityType']?.toString(),
            distractors: distractors,
            mcDistractor1: distractors.isNotEmpty ? distractors[0] : null,
            mcDistractor2: distractors.length > 1 ? distractors[1] : null,
            mcDistractor3: distractors.length > 2 ? distractors[2] : null,
            fitbSentence: fitbSentence,
            fitbAnswer: format == ActivityFormat.trueOrFalse
                ? q['correctAnswer']?.toString()
                : correctAnswer,
            matchingSet: matchingSet,
            sentenceArrangementTokens: scrambledTokens,
            imageAssetPath: q['imageAssetPath'],
            timeLimitSeconds: q['timeLimitSeconds'] as int?,
            difficultyLevel: q['difficultyLevel'] as String? ?? 'LEARNING',
            showHint: q['showHints'] == true,
            hintLanguage: (q['hintLanguage'] as String?) ?? 'CEBUANO',
            hintText: q['hintText'] as String?,
            anchoredWord: q['anchoredWord'] as String?,
            hintToWordClue: q['hintToWordClue'] as String?,
            hintToWordClueType: q['hintToWordClueType'] as String?,
            hintDefinition: q['hintDefinition']?.toString(),
            hintCebuanoSentence: q['hintCebuanoSentence']?.toString(),
          );
        }).toList();
        if (_practiceQueue.isEmpty) {
          final allNowMastered = _words.isNotEmpty &&
              _words.every((w) =>
                  (_wordBestTier[w.wordId] ?? 0) >= 3 ||
                  w.difficultyLevel?.toUpperCase() == 'MASTERED');
          if (allNowMastered) {
            await _completeModuleAndAdvance();
            return;
          }
          _buildPracticeQueue();
        } else {
          _practiceQueue.shuffle(Random());
          _separateAdjacentSameWords(_practiceQueue, fromIndex: 0);
        }
      }

      _currentIndex = 0;
      _completedScreens = 0;
      _plannedScreens = _practiceQueue.length;

      // Seed the tier-progress map from the queue's current difficulty levels.
      _initWordTierProgress();
      if (_practiceQueue.isNotEmpty) {
        await _fetchAndLoadCurrentItem();
      } else {
        await _completeModuleAndAdvance();
        return;
      }
      await _saveCurrentState();
    }

    setState(() => _isLoading = false);
  }

  void _buildPracticeQueue() {
    _practiceQueue.clear();

    if (widget.isSandbox) {
      // Sandbox mode: fixed sequence of activities
      // 1. Flashcard recall
      // 2. Multiple choice
      // 3. Fill in the blank
      for (var word in _words) {
        if ((_wordBestTier[word.wordId] ?? 0) >= 3 ||
            word.difficultyLevel?.toUpperCase() == 'MASTERED') {
          continue;
        }
        _practiceQueue.add(
          _createPracticeItem(word, ActivityFormat.flashcardRecall),
        );
        _practiceQueue.add(
          _createPracticeItem(word, ActivityFormat.multipleChoice),
        );
        _practiceQueue.add(
          _createPracticeItem(word, ActivityFormat.fillInTheBlank),
        );
      }
    } else {
      final random = Random();
      final shuffledWords = List<VocabularyWordModel>.from(_words)
        ..shuffle(random);

      ActivityFormat parseFormat(String f) {
        switch (f.trim().toUpperCase()) {
          case 'FILL_IN_BLANK':
            return ActivityFormat.fillInTheBlank;
          case 'MATCHING':
            return ActivityFormat.matching;
          case 'SENTENCE_ARRANGEMENT':
            // Sentence arrangement belongs in Module 3
            return ActivityFormat.fillInTheBlank;
          case 'TYPE_WHAT_YOU_HEAR':
            return ActivityFormat.listeningTyping;
          case 'WORD_SCRAMBLE':
            return ActivityFormat.wordScramble;
          case 'IMAGE_LABELING':
          case 'IMAGE_MATCHING':
            return ActivityFormat.imageLabeling;
          case 'TRUE_OR_FALSE':
            return ActivityFormat.trueOrFalse;
          case 'HINT_TO_WORD':
            return ActivityFormat.hintToWord;
          default:
            return ActivityFormat.multipleChoice;
        }
      }

      final activeWords = shuffledWords.where((w) =>
          (_wordBestTier[w.wordId] ?? 0) < 3 &&
          w.difficultyLevel?.toUpperCase() != 'MASTERED'
      ).toList();

      for (final word in activeWords) {
        List<ActivityFormat> wordFormats = [];
        final eligible = word.eligibleActivityTypes;
        if (eligible != null && eligible.isNotEmpty) {
          wordFormats = eligible.split(';').map((s) => parseFormat(s)).toList();
        }
        if (_module2Activities != null && _module2Activities!.trim().isNotEmpty) {
          final allowed = _module2Activities!
              .split(';')
              .map((s) => parseFormat(s))
              .toSet();
          final filtered = wordFormats.where((f) => allowed.contains(f)).toList();
          if (filtered.isNotEmpty) {
            wordFormats = filtered;
          } else {
            wordFormats = allowed.toList();
          }
        }
        if (wordFormats.isEmpty) {
          wordFormats = [
            ActivityFormat.multipleChoice,
            ActivityFormat.fillInTheBlank,
            ActivityFormat.matching,
            ActivityFormat.listeningTyping,
          ];
        }

        var format1 = wordFormats[random.nextInt(wordFormats.length)];
        if (word.imageAssetPath != null &&
            word.imageAssetPath!.isNotEmpty &&
            (word.imageAssetPath!.startsWith('http') ||
                word.imageAssetPath!.startsWith('assets/')) &&
            random.nextDouble() < 0.3) {
          format1 = ActivityFormat.imageLabeling;
        }
        _practiceQueue.add(_createPracticeItem(word, format1));

        final remainingFormats = wordFormats
            .where((f) => f != format1)
            .toList();
        var format2 = remainingFormats.isNotEmpty
            ? remainingFormats[random.nextInt(remainingFormats.length)]
            : wordFormats[random.nextInt(wordFormats.length)];

        _practiceQueue.add(_createPracticeItem(word, format2));
      }
    }

    if (_practiceQueue.isEmpty && _words.isNotEmpty) {
      debugPrint('ActivePractice: All words are MASTERED in _buildPracticeQueue -> advancing to Module 3');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _completeModuleAndAdvance();
      });
    }
  }

  PracticeItemModel _createPracticeItem(
    VocabularyWordModel word,
    ActivityFormat format,
  ) {
    var resolvedFormat = format;
    // Keep image matching even if no image - will show placeholder
    // if (resolvedFormat == ActivityFormat.imageMatching && (word.imageAssetPath == null || word.imageAssetPath!.isEmpty)) {
    //   resolvedFormat = ActivityFormat.multipleChoice;
    // }

    return PracticeItemModel(
      wordId: word.wordId,
      englishWord: word.englishWord,
      cebuanoMeaning: word.cebuanoMeaning,
      exampleSentenceEnglish: word.exampleSentenceEnglish,
      exampleSentenceCebuano: word.exampleSentenceCebuano,
      activityFormat: resolvedFormat,
      imageAssetPath: word.imageAssetPath,
      distractors: _resolveDistractors(word),
      mcDistractor1: word.mcDistractor1,
      mcDistractor2: word.mcDistractor2,
      mcDistractor3: word.mcDistractor3,
      fitbSentence: word.fitbSentence,
      fitbAnswer: word.fitbAnswer,
      matchingSet: word.matchingSet,
      sentenceArrangementTokens: word.sentenceArrangementTokens,
      tileSentence: word.tileSentence,
      hintText: word.explanationText,
      hintDefinition: word.hintDefinition,
      hintCebuanoSentence: word.hintCebuanoSentence,
      sentenceCompletionSentence: word.sentenceCompletionSentence,
      sentenceCompletionAnswer: word.sentenceCompletionAnswer,
      sentenceCompletionOption1: word.sentenceCompletionOption1,
      sentenceCompletionOption2: word.sentenceCompletionOption2,
      sentenceCompletionOption3: word.sentenceCompletionOption3,
      difficultyLevel: word.difficultyLevel,
      showHint: word.showExplanation,
      timeLimitSeconds: word.timeLimitSeconds,
    );
  }

  /// Maps a difficulty-level string to a 0–3 integer ordinal.
  static String _tierName(int ord) {
    switch (ord) {
      case 1:  return 'FAMILIAR';
      case 2:  return 'PROFICIENT';
      case 3:  return 'MASTERED';
      default: return 'LEARNING';
    }
  }

  /// LEARNING=0, FAMILIAR=1, PROFICIENT=2, MASTERED=3
  static int _tierOrdinal(String? level) {
    switch ((level ?? '').toUpperCase()) {
      case 'FAMILIAR':   return 1;
      case 'PROFICIENT': return 2;
      case 'MASTERED':   return 3;
      default:           return 0; // LEARNING or unknown
    }
  }

  /// Seeds [_wordBestTier] from [_words] and the current [_practiceQueue].
  /// Uses max() so the value never decreases across session loops.
  void _initWordTierProgress() {
    for (final word in _words) {
      final ordinal = _tierOrdinal(word.difficultyLevel);
      final existing = _wordBestTier[word.wordId] ?? 0;
      if (ordinal > existing) {
        _wordBestTier[word.wordId] = ordinal;
      }
    }
    for (final item in _practiceQueue) {
      final ordinal = _tierOrdinal(item.difficultyLevel);
      final existing = _wordBestTier[item.wordId] ?? 0;
      if (ordinal > existing) {
        _wordBestTier[item.wordId] = ordinal;
      }
    }
  }

  String _getEffectiveLevel(PracticeItemModel? item) {
    if (item == null) return 'LEARNING';
    final bestOrdinal = _wordBestTier[item.wordId];
    if (bestOrdinal != null) {
      switch (bestOrdinal) {
        case 1:
          return 'FAMILIAR';
        case 2:
          return 'PROFICIENT';
        case 3:
          return 'MASTERED';
        default:
          return 'LEARNING';
      }
    }
    return (item.difficultyLevel ?? 'LEARNING').toUpperCase();
  }

  List<String> _resolveDistractors(VocabularyWordModel targetWord) {
    // Helper function to check if a string is a sentence (not a single word)
    bool isSentence(String value) {
      final wordCount = value.trim().split(RegExp(r'\s+')).length;
      return wordCount > 3 || value.contains('__') || value.contains('.');
    }

    final provided =
        [
          targetWord.mcDistractor1,
          targetWord.mcDistractor2,
          targetWord.mcDistractor3,
        ].whereType<String>().where((value) => value.trim().isNotEmpty).where((
          value,
        ) {
          // Filter out sentences - only allow single words or very short phrases (max 2-3 words)
          final isSent = isSentence(value);
          if (isSent) {
            debugPrint(
              'WARNING: Filtering out sentence distractor from mcDistractor: "$value"',
            );
          }
          return !isSent;
        }).toList();

    if (widget.isSandbox) {
      // Sandbox must always have exactly 3 distractors (individual words, not sentences)
      if (provided.length >= 3) {
        return provided.take(3).toList();
      }

      // Generate fallback distractors - use other words from session or common words
      final fallbackDistractors = <String>[];

      // First, try to use other words from the session - FILTER OUT SENTENCES
      final otherWords = _words
          .where((w) => w.wordId != targetWord.wordId)
          .map((w) => w.englishWord)
          .where((w) => w.trim().isNotEmpty)
          .where((w) {
            final isSent = isSentence(w);
            if (isSent) {
              debugPrint(
                'WARNING: Filtering out sentence from otherWords: "$w"',
              );
            }
            return !isSent;
          })
          .toList();

      if (otherWords.isNotEmpty) {
        otherWords.shuffle();
        fallbackDistractors.addAll(otherWords);
      }

      // Add common English words as additional fallbacks
      final commonWords = [
        'apple',
        'house',
        'water',
        'friend',
        'school',
        'book',
        'tree',
        'happy',
        'run',
        'big',
        'cat',
        'dog',
        'sun',
        'moon',
        'star',
        'hand',
        'eye',
        'ear',
        'nose',
        'foot',
      ];
      final targetLower = targetWord.englishWord.toLowerCase();
      final availableCommon =
          commonWords.where((w) => w.toLowerCase() != targetLower).toList()
            ..shuffle();
      fallbackDistractors.addAll(availableCommon);

      // Combine provided + fallbacks and take exactly 3
      final allDistractors = [...provided, ...fallbackDistractors];
      final uniqueDistractors = allDistractors.toSet().toList();

      if (uniqueDistractors.length < 3) {
        debugPrint(
          'WARNING: Could not generate 3 distractors for ${targetWord.englishWord}, only got ${uniqueDistractors.length}',
        );
      }

      return uniqueDistractors.take(3).toList();
    }

    if (provided.length >= 2) {
      return provided.take(2).toList();
    }

    return _generateDistractors(targetWord);
  }

  List<Map<String, dynamic>> _resolveMatchingSet(PracticeItemModel targetItem) {
    // Force distractors to strictly come from the current session/lesson words
    // ignoring backend matchingSets which might contain out-of-lesson words.
    
    // Prefer words that have been practiced in this session
    final practicedWordIds = _practiceQueue.map((p) => p.wordId).toSet();
    final practicedOthers = _words
        .where(
          (w) =>
              w.wordId != targetItem.wordId &&
              practicedWordIds.contains(w.wordId),
        )
        .toList();
    final remainingOthers = _words
        .where(
          (w) =>
              w.wordId != targetItem.wordId &&
              !practicedWordIds.contains(w.wordId),
        )
        .toList();
    final otherWords = [
      ...practicedOthers,
      ...remainingOthers,
    ].take(3).toList();
    return [
      {
        'englishWord': targetItem.englishWord,
        'cebuanoMeaning': targetItem.cebuanoMeaning,
      },
      ...otherWords.map(
        (word) => {
          'englishWord': word.englishWord,
          'cebuanoMeaning': word.cebuanoMeaning,
        },
      ),
    ];
  }

  List<String> _generateDistractors(VocabularyWordModel targetWord) {
    final list = _words
        .where((w) => w.wordId != targetWord.wordId)
        .map((w) => w.englishWord)
        .toList();

    list.shuffle();
    return list.take(2).toList();
  }

  double _maxProgress = 0.0;
  double? _progressOverride;

  double get _scorePoints {
    final practicedWordIds = _practiceQueue.map((p) => p.wordId).toSet();
    final relevantWordIds = practicedWordIds.isNotEmpty
        ? practicedWordIds
        : _words.map((w) => w.wordId).toSet();
    if (relevantWordIds.isEmpty) return 0.0;
    double score = 0.0;
    for (final wordId in relevantWordIds) {
      if ((_wordWrongAttempts[wordId] ?? 0) == 0) {
        score += 1.0;
      }
    }
    return score;
  }

  Future<void> _fetchCurrentQuestionDetails() async {
    if (widget.isSandbox || _currentIndex >= _practiceQueue.length) return;

    final item = _practiceQueue[_currentIndex];
    final provider = Provider.of<LessonProvider>(context, listen: false);

    String formatStr;
    switch (item.activityFormat) {
      case ActivityFormat.multipleChoice:
        formatStr = 'MULTIPLE_CHOICE';
        break;
      case ActivityFormat.fillInTheBlank:
        formatStr = 'FILL_IN_BLANK';
        break;
      case ActivityFormat.matching:
        formatStr = 'MATCHING';
        break;
      case ActivityFormat.listeningTyping:
        formatStr = 'TYPE_WHAT_YOU_HEAR';
        break;
      case ActivityFormat.rearrangement:
        formatStr = 'SENTENCE_ARRANGEMENT';
        break;
      case ActivityFormat.wordScramble:
        formatStr = 'WORD_SCRAMBLE';
        break;
      case ActivityFormat.imageLabeling:
        formatStr = 'IMAGE_LABELING';
        break;
      case ActivityFormat.trueOrFalse:
        formatStr = 'TRUE_OR_FALSE';
        break;
      case ActivityFormat.hintToWord:
        formatStr = 'HINT_TO_WORD';
        break;
      default:
        formatStr = 'MULTIPLE_CHOICE';
    }

    try {
      final q = await provider.loadSingleRetrievalQuestion(
        widget.sessionId,
        item.wordId,
        format: formatStr,
      );

      if (q != null) {
        final options = List<String>.from(q['options'] ?? []);
        final correctAnswer = q['correctAnswer'] as String? ?? '';
        final distractors = options.where((o) => o != correctAnswer).toList();
        final scrambledTokens = List<String>.from(q['scrambledTokens'] ?? []);

        List<Map<String, dynamic>>? matchingSet;
        if (q['matchingPairs'] != null) {
          matchingSet = (q['matchingPairs'] as List<dynamic>)
              .map(
                (e) => {
                  'englishWord': e['english'],
                  'cebuanoMeaning': e['cebuano'],
                },
              )
              .toList();
        }

        final rawExample = (q['exampleSentenceEnglish'] as String?)?.trim();
        final exampleSentence = (rawExample != null && rawExample.isNotEmpty)
            ? rawExample
            : '';

        final rawQuestionText = (q['questionText'] as String?)?.trim();
        final fitbSentence =
            (item.activityFormat == ActivityFormat.fillInTheBlank &&
                rawQuestionText != null &&
                rawQuestionText.contains('_'))
            ? rawQuestionText
            : null;

        _practiceQueue[_currentIndex] = PracticeItemModel(
          wordId: q['wordId'] ?? item.wordId,
          englishWord: item.activityFormat == ActivityFormat.trueOrFalse
              ? (q['word'] ?? q['englishWord'] ?? item.englishWord)
              : (q['englishWord'] ?? item.englishWord),
          displayWord: q['displayWord']?.toString() ?? item.displayWord,
          cebuanoMeaning: q['cebuanoMeaning'] ?? item.cebuanoMeaning,
          exampleSentenceEnglish: exampleSentence,
          exampleSentenceCebuano:
              q['exampleSentenceCebuano'] ??
              q['cebuanoMeaning'] ??
              item.exampleSentenceCebuano,
          activityFormat: item.activityFormat,
          eligibleActivityTypes:
              q['eligibleActivityTypes']?.toString() ??
              q['activityType']?.toString() ??
              item.eligibleActivityTypes,
          distractors: distractors,
          mcDistractor1: distractors.isNotEmpty ? distractors[0] : null,
          mcDistractor2: distractors.length > 1 ? distractors[1] : null,
          mcDistractor3: distractors.length > 2 ? distractors[2] : null,
          fitbSentence: fitbSentence,
          fitbAnswer: item.activityFormat == ActivityFormat.trueOrFalse
              ? q['correctAnswer']?.toString()
              : correctAnswer,
          matchingSet: matchingSet,
          sentenceArrangementTokens: scrambledTokens,
          imageAssetPath: q['imageAssetPath'] ?? item.imageAssetPath,
          timeLimitSeconds: q['timeLimitSeconds'] as int?,
          difficultyLevel: q['difficultyLevel'] as String? ?? 'LEARNING',
          showHint: q['showHints'] == true,
          hintLanguage: (q['hintLanguage'] as String?) ?? 'CEBUANO',
          hintText: q['hintText'] as String?,
          anchoredWord: q['anchoredWord'] as String?,
          hintToWordClue: q['hintToWordClue'] as String?,
          hintToWordClueType: q['hintToWordClueType'] as String?,
          hintDefinition: q['hintDefinition']?.toString() ?? item.hintDefinition,
          hintCebuanoSentence: q['hintCebuanoSentence']?.toString() ?? item.hintCebuanoSentence,
        );
      }
    } catch (e) {
      debugPrint('Error loading single question details: $e');
    }
  }

  Future<void> _fetchAndLoadCurrentItem() async {
    if (_currentIndex >= _practiceQueue.length) return;
    setState(() => _isLoading = true);
    await _fetchCurrentQuestionDetails();
    _loadCurrentItemState();
    setState(() => _isLoading = false);
  }

  void _loadCurrentItemState() {
    _questionTimer?.cancel();
    _secondsRemaining = 0;
    _checked = false;
    _isAdvancingNext = false; // Unlock continue button for new question
    _showFeedback = false;
    _selectedOptionIndex = -1;
    _selectedCebuano = null;
    _selectedEnglish = null;
    _currentMatches.clear();
    _typingController.clear();
    _flashcardFlipped = false;

    if (_currentIndex >= _practiceQueue.length) return;
    final item = _practiceQueue[_currentIndex];

    if (item.activityFormat == ActivityFormat.multipleChoice ||
        item.activityFormat == ActivityFormat.imageMatching ||
        item.activityFormat == ActivityFormat.imageLabeling ||
        item.activityFormat == ActivityFormat.hintToWord) {
      final lvl = _getEffectiveLevel(item);
      final isFamiliarMC = item.activityFormat == ActivityFormat.multipleChoice &&
          lvl == 'FAMILIAR';
      final isProficientMC = item.activityFormat == ActivityFormat.multipleChoice &&
          (lvl == 'PROFICIENT' || lvl == 'MASTERED');

      // Prompt = Cebuano meaning, Answer = English word
      var correctAnswer = item.englishWord.trim();
      if (correctAnswer.split(RegExp(r'\s+')).length > 2 ||
          correctAnswer.contains('__') ||
          correctAnswer.contains('.')) {
        correctAnswer = correctAnswer
            .split(RegExp(r'\s+'))[0]
            .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
        debugPrint(
          'WARNING: Correct answer was sentence, using first word: $correctAnswer',
        );
      }

      final List<String> distractorPool = [];
      if (item.distractors.isNotEmpty) {
        distractorPool.addAll(item.distractors.map((d) => d.trim()));
      }
      final sessionEnglishWords = _words
          .where((w) => w.wordId != item.wordId && w.englishWord.trim().isNotEmpty)
          .map((w) => w.englishWord.trim());
      distractorPool.addAll(sessionEnglishWords);

      List<String> distractors = distractorPool
          .where((c) => c.toLowerCase() != correctAnswer.toLowerCase())
          .toSet()
          .toList()
        ..shuffle();

      final targetOptionCount = item.activityFormat == ActivityFormat.multipleChoice
          ? (isProficientMC ? 5 : (isFamiliarMC ? 4 : 3))
          : 4;

      debugPrint(
        'MC: level=$lvl, isFamiliarMC=$isFamiliarMC, correctAnswer="$correctAnswer", distractors=$distractors, targetCount=$targetOptionCount',
      );
      _options = [correctAnswer, ...distractors];

      _options = _options.where((opt) {
        final wordCount = opt.trim().split(RegExp(r'\s+')).length;
        final isSentence =
            wordCount > 2 || opt.contains('__') || opt.contains('.');
        return !isSentence;
      }).toSet().toList();

      if (_options.length < targetOptionCount) {
        final fallbacks = [
          'Water',
          'House',
          'Book',
          'Tree',
          'Friend',
          'School',
          'Dog',
          'Cat',
          'Sun',
          'Moon',
          'Road',
          'Heart',
          'Bread',
          'Apple',
          'River',
          'Bird',
          'Door',
          'Table',
        ];
        final needed = targetOptionCount - _options.length;
        final available = fallbacks
            .where((f) => !_options.any((o) => o.toLowerCase() == f.toLowerCase()))
            .toList()
          ..shuffle();
        _options.addAll(available.take(needed));
      }

      // Safety: ensure correct answer is always in options
      if (!_options.any(
        (o) => o.toLowerCase() == correctAnswer.toLowerCase(),
      )) {
        if (_options.length >= targetOptionCount) _options.removeLast();
        _options.add(correctAnswer);
      }

      // Trim excess options to maintain target count
      if (_options.length > targetOptionCount) {
        final correctFound = _options.firstWhere(
          (o) => o.toLowerCase() == correctAnswer.toLowerCase(),
          orElse: () => correctAnswer,
        );
        final otherOptions = _options
            .where((o) => o.toLowerCase() != correctAnswer.toLowerCase())
            .toList()
          ..shuffle();
        _options = [correctFound, ...otherOptions.take(targetOptionCount - 1)];
      }

      _options.shuffle(Random(item.wordId.hashCode));
      debugPrint('MC options before render: $_options');
    } else if (item.activityFormat == ActivityFormat.fillInTheBlank) {
      final distractors = item.distractors.isNotEmpty
          ? item.distractors
          : _resolveDistractors(
              _words.firstWhere((w) => w.wordId == item.wordId),
            );

      var correctOption =
          (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
          ? item.fitbAnswer!
          : item.englishWord;

      if (correctOption.split(RegExp(r'\s+')).length > 2 ||
          correctOption.contains('__') ||
          correctOption.contains('.')) {
        correctOption = item.englishWord;
      }

      debugPrint(
        'FITB: correctAnswer="$correctOption", distractors=$distractors',
      );
      _options = [correctOption, ...distractors];

      _options = _options.where((opt) {
        final wordCount = opt.trim().split(RegExp(r'\s+')).length;
        final isSentence =
            wordCount > 2 || opt.contains('__') || opt.contains('.');
        return !isSentence;
      }).toList();

      if (_options.length < 4) {
        final fallbacks = [
          'apple',
          'house',
          'water',
          'friend',
          'school',
          'book',
          'tree',
          'happy',
          'run',
          'big',
          'cat',
          'dog',
        ];
        final needed = 4 - _options.length;
        final available = fallbacks.where((f) => !_options.contains(f)).toList()
          ..shuffle();
        _options.addAll(available.take(needed));
      }

      // Safety: ensure correct answer is always in options
      if (!_options.any(
        (o) => o.toLowerCase() == correctOption.toLowerCase(),
      )) {
        if (_options.length >= 4) _options.removeLast();
        _options.add(correctOption);
      }

      _options.shuffle(Random(item.wordId.hashCode));
      debugPrint('FITB options before render: $_options');
    } else if (item.activityFormat == ActivityFormat.matching ||
        item.activityFormat == ActivityFormat.translationMatching) {
      final matchingList = _resolveMatchingSet(item);
      _matchingCebuanoList =
          matchingList
              .map((entry) => (entry['cebuanoMeaning'] ?? '').toString())
              .where((value) => value.isNotEmpty)
              .toList()
            ..shuffle();
      _matchingEnglishList =
          matchingList
              .map((entry) => (entry['englishWord'] ?? '').toString())
              .where((value) => value.isNotEmpty)
              .toList()
            ..shuffle();
    } else if (item.activityFormat == ActivityFormat.rearrangement ||
        item.activityFormat == ActivityFormat.wordScramble) {
      // Word Scramble uses individual letters from the canonical word. The
      // backend's sentence token payload may contain punctuation/placeholders
      // intended for sentence rearrangement, which must not become letter tiles.
      final tokens = item.activityFormat == ActivityFormat.wordScramble
          ? item.englishWord
                .trim()
                .toUpperCase()
                .split('')
                .where((token) => RegExp(r'[A-Z0-9]').hasMatch(token))
                .toList()
          : (item.sentenceArrangementTokens ?? []);
      if (tokens.isNotEmpty) {
        _scrambledTokens = List<String>.from(tokens)
          ..shuffle(Random(item.wordId.hashCode));
      } else {
        if (item.activityFormat == ActivityFormat.rearrangement) {
          final sentence = (item.tileSentence?.trim().isNotEmpty ?? false)
              ? item.tileSentence!.trim()
              : item.exampleSentenceEnglish.trim();
          _scrambledTokens =
              sentence.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList()
                ..shuffle(Random(item.wordId.hashCode));
        } else {
          final wordToScramble = item.englishWord.trim().toUpperCase();
          _scrambledTokens = wordToScramble.split('').toList()
            ..shuffle(Random(item.wordId.hashCode));
        }
      }
      _assembledTokens = [];
      if ((item.activityFormat == ActivityFormat.wordScramble ||
              item.activityFormat == ActivityFormat.rearrangement) &&
          item.anchoredWord != null &&
          item.anchoredWord!.isNotEmpty) {
        if (item.activityFormat == ActivityFormat.wordScramble &&
            _scrambledTokens.isNotEmpty) {
          final canonicalLetters = item.englishWord
              .trim()
              .toUpperCase()
              .split('')
              .where((token) => RegExp(r'[A-Z0-9]').hasMatch(token))
              .toList();
          if (canonicalLetters.isNotEmpty) {
            final anchor = canonicalLetters.first;
            final anchorIndex = _scrambledTokens.indexOf(anchor);
            if (anchorIndex >= 0) _scrambledTokens.removeAt(anchorIndex);
            _assembledTokens.add(anchor);
          }
        } else {
          _assembledTokens.add(item.anchoredWord!.trim());
        }
      }
    }

    if (item.timeLimitSeconds != null && item.timeLimitSeconds! > 0) {
      _startQuestionTimer(item.timeLimitSeconds!);
    }
  }

  void _startQuestionTimer(int seconds) {
    _questionTimer?.cancel();
    _secondsRemaining = seconds;
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          _questionTimer?.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    if (_checked) return;
    
    // Auto-submit if an answer is selected
    if (_selectedOptionIndex != -1 || _selectedCebuano != null || _assembledTokens.isNotEmpty || _typingController.text.isNotEmpty) {
      _checkAnswer();
      return;
    }
    
    // Play time's up sound using the shared audio service
    LessonAudioService().playTimeUp();
    
    setState(() {
      _selectedOptionIndex = -1;
      _checked = true;
      _isAnswerCorrect = false;
      _showFeedback = true;
    });
  }

  Future<void> _saveCurrentState() async {
    await LocalStorageService.savePracticeSessionState(
      widget.sessionId,
      _practiceQueue,
      _currentIndex,
      completedScreens: _completedScreens,
      plannedScreens: _plannedScreens,
      maxWordTierPoints: _wordBestTier,
    );
    await LocalStorageService.saveReinforcementQueue(
      widget.sessionId,
      _reinforcementQueue,
    );
    if (!widget.isSandbox && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final posFocus = auth.learner?.posFocus;
      await LocalStorageService.saveActiveLessonSession(
        widget.lessonId,
        widget.sessionId,
        '/session/${widget.sessionId}/practice',
        posFocus: posFocus ?? 'ALL',
        allWords: widget.allWords,
        categoryId: widget.categoryId,
        lessonTitle: widget.lessonTitle,
      );
    }
  }

  String _getMascotName() {
    // Alternate mascots based on index
    final names = ['Bibo', 'Toti', 'Sippy', 'Starry'];
    return names[_currentIndex % names.length];
  }

  String _getInstructionText(ActivityFormat format, [PracticeItemModel? item]) {
    switch (format) {
      case ActivityFormat.multipleChoice:
        return 'Select the correct English word for the Cebuano word below.';
      case ActivityFormat.imageMatching:
      case ActivityFormat.imageLabeling:
        return 'Look at the image and choose the correct word.';
      case ActivityFormat.trueOrFalse:
        return 'Is this translation correct? Select True or False.';
      case ActivityFormat.matching:
      case ActivityFormat.translationMatching:
        return 'Help our mascots find the matching words! Tap a Cebuano word, then its English match.';
      case ActivityFormat.fillInTheBlank:
        return 'Select the missing word to complete the sentence.';
      case ActivityFormat.listeningTyping:
        return 'Listen carefully, type what you hear, then check your answer.';
      case ActivityFormat.flashcardRecall:
        return 'Think first, then flip to reveal the answer and confirm you know it.';
      case ActivityFormat.rearrangement:
        return 'Arrange the words to form the correct sentence.';
      case ActivityFormat.wordScramble:
        return 'Unscramble the letters to spell the English word.';
      case ActivityFormat.hintToWord:
        return 'Read the clue carefully and choose the matching word.';
    }
  }

  static bool _containsCebuanoKeywords(String text) {
    final lower = text.toLowerCase();
    return lower.contains('ang ') ||
        lower.contains('mga ') ||
        lower.contains('sa ') ||
        lower.contains('ug ') ||
        lower.contains('og ') ||
        lower.contains('nga ') ||
        lower.contains('para ') ||
        lower.contains('pahimangno') ||
        lower.contains('pasabot');
  }

  static String? _getEnglishClueFallback(String word) {
    const definitions = {
      'bread': 'A food made of flour, water, and yeast mixed and baked.',
      'sharp': 'Having a thin edge or pointed tip that cuts easily.',
      'read': 'To look at and comprehend the meaning of written words.',
      'notebook': 'A book of blank or ruled pages for writing notes.',
      'pencil': 'An instrument for writing or drawing with a graphite core.',
      'mother': 'A female parent.',
      'father': 'A male parent.',
      'sister': 'A female sibling.',
      'brother': 'A male sibling.',
      'cook': 'To prepare food by heating it.',
      'rice': 'A staple grain boiled and eaten with everyday meals.',
      'water': 'A clear liquid essential for drinking and living.',
      'milk': 'A nutritious white liquid produced by mammals.',
      'apple': 'A round edible fruit with red, yellow, or green skin.',
      'sweet': 'Having the pleasant taste characteristic of sugar.',
      'share': 'To divide and distribute a portion among others.',
      'warm': 'Having or producing a comfortable amount of heat.',
      'write': 'To make words or letters on paper with a pen or pencil.',
      'clean': 'Free from dirt, marks, or stains.',
      'neat': 'Arranged in an orderly and tidy way.',
      'school': 'An institution where students learn and study.',
      'dog': 'A loyal domesticated mammal that barks.',
      'cat': 'A small domesticated feline animal.',
      'bird': 'A warm-blooded feathered creature with wings.',
      'fish': 'A limbless cold-blooded animal that swims in water.',
      'horse': 'A large animal with hooves used for riding.',
    };
    return definitions[word.trim().toLowerCase()];
  }

  String? _getHintTextForActivity(PracticeItemModel item) {
    final lvl = _getEffectiveLevel(item);
    final isLearning = lvl == 'LEARNING';
    final isFamiliar = lvl == 'FAMILIAR';
    final isProficient = lvl == 'PROFICIENT' || lvl == 'MASTERED';
    final hintLang = item.hintLanguage; // CEBUANO, ENGLISH, CEBUANO_ENGLISH, or NONE

    // PROFICIENT tier or hintLanguage == NONE: strictly NO HINTS
    if (isProficient || hintLang == 'NONE') return null;
    if (!isLearning && !isFamiliar && !item.showHint) return null;

    // For HINT_TO_WORD and MATCHING, no hint box is shown
    if (item.activityFormat == ActivityFormat.hintToWord ||
        item.activityFormat == ActivityFormat.matching) {
      return null;
    }

    // 1. LEARNING Tier: Hints MUST be in Bisaya/Cebuano (from HINT CEB / hint_cebuano_sentence)
    if (isLearning) {
      // Primary: configured HINT (CEB) from the database table (hint_cebuano_sentence)
      if (item.hintCebuanoSentence != null && item.hintCebuanoSentence!.trim().isNotEmpty) {
        final text = item.hintCebuanoSentence!.trim();
        return text.toLowerCase().startsWith('pahimangno') || text.toLowerCase().startsWith('hint')
            ? text
            : 'Pahimangno: $text';
      }

      // Secondary: custom explanation text if provided and in Cebuano
      if (item.hintText != null && item.hintText!.trim().isNotEmpty) {
        final hint = item.hintText!.trim();
        if (!hint.toLowerCase().contains(item.englishWord.toLowerCase())) {
          return hint.toLowerCase().startsWith('pahimangno') || hint.toLowerCase().startsWith('hint')
              ? hint
              : 'Pahimangno: $hint';
        }
      }

      // Fallback per activity format if no explicit HINT (CEB) is configured
      switch (item.activityFormat) {
        case ActivityFormat.multipleChoice:
        case ActivityFormat.imageMatching:
        case ActivityFormat.imageLabeling:
          return 'Pahimangno: Ang buot ipasabot kay "${item.cebuanoMeaning}"';

        case ActivityFormat.fillInTheBlank:
        case ActivityFormat.listeningTyping:
          return 'Bisaya: ${item.cebuanoMeaning}';

        case ActivityFormat.wordScramble:
          return 'Pahimangno: Nagsugod sa "${item.englishWord.isNotEmpty ? item.englishWord[0].toUpperCase() : '?'}" (${item.cebuanoMeaning})';

        case ActivityFormat.rearrangement:
        case ActivityFormat.trueOrFalse:
          return 'Pahimangno: "${item.englishWord}" nagpasabot og "${item.cebuanoMeaning}"';

        default:
          return 'Pahimangno: Hinumdumi ang "${item.cebuanoMeaning}"';
      }
    }

    // 2. FAMILIAR Tier: Hints/tips MUST be in English (from HINT DEF / hint_definition / English clues)
    if (isFamiliar) {
      // Primary: configured HINT (DEF) from the database table (hint_definition)
      if (item.hintDefinition != null && item.hintDefinition!.trim().isNotEmpty) {
        final text = item.hintDefinition!.trim();
        return text.toLowerCase().startsWith('hint:') ||
                text.toLowerCase().startsWith('tip:')
            ? text
            : 'Hint: $text';
      }

      // Secondary: custom explanation / hintText if provided in English
      if (item.hintText != null && item.hintText!.trim().isNotEmpty) {
        final hint = item.hintText!.trim();
        if (!_containsCebuanoKeywords(hint)) {
          return hint.toLowerCase().startsWith('hint:') ||
                  hint.toLowerCase().startsWith('tip:')
              ? hint
              : 'Hint: $hint';
        }
      }

      // Fallback: English dictionary definition clue
      final clue = _getEnglishClueFallback(item.englishWord);
      if (clue != null && clue.isNotEmpty) {
        return 'Hint: $clue';
      }

      // Fallback per activity format if no explicit English definition is found
      switch (item.activityFormat) {
        case ActivityFormat.multipleChoice:
        case ActivityFormat.imageMatching:
        case ActivityFormat.imageLabeling:
          return 'Hint: Focus on the meaning of "${item.englishWord}".';

        case ActivityFormat.fillInTheBlank:
        case ActivityFormat.listeningTyping:
          return 'Hint: Complete the sentence with the correct English word.';

        case ActivityFormat.wordScramble:
          return 'Hint: Unscramble the letters to form "${item.englishWord.isNotEmpty ? item.englishWord[0].toUpperCase() : ''}...".';

        case ActivityFormat.rearrangement:
        case ActivityFormat.trueOrFalse:
          return 'Hint: Determine if the meaning matches "${item.englishWord}".';

        default:
          return 'Hint: Think of what "${item.englishWord}" means.';
      }
    }

    return null;
  }

  String _getListeningTypingAudioText(PracticeItemModel item) {
    final lvl = _getEffectiveLevel(item);
    if (lvl == 'LEARNING') {
      return item.englishWord;
    } else if (lvl == 'FAMILIAR') {
      return _extractPhrase(item.exampleSentenceEnglish, item.englishWord);
    } else {
      return item.exampleSentenceEnglish;
    }
  }

  String _extractPhrase(String sentence, String word) {
    final clean = sentence.replaceAll(RegExp(r'[.,!?;:]'), '');
    final wordsList = clean
        .split(RegExp(r'\s+'))
        .where((t) => t.trim().isNotEmpty)
        .toList();
    int targetIndex = wordsList.indexWhere(
      (w) => w.toLowerCase().contains(word.toLowerCase()),
    );
    if (targetIndex == -1) return word;

    int start = (targetIndex - 1).clamp(0, wordsList.length - 1);
    int end = (targetIndex + 1).clamp(0, wordsList.length - 1);

    if (start == targetIndex && end == targetIndex) return word;
    return wordsList.sublist(start, end + 1).join(' ');
  }

  // --- Handlers ---
  void _selectMcOption(int index) {
    if (_checked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _tapCebuanoMatch(String ceb) {
    if (_checked) return;
    _ttsService.speakCebuano(ceb);
    setState(() {
      if (_currentMatches.containsKey(ceb)) {
        _currentMatches.remove(ceb);
      }
      _selectedCebuano = ceb;
      _checkAndMatch();
    });
  }

  void _tapEnglishMatch(String eng) {
    if (_checked) return;
    _ttsService.speak(eng);
    setState(() {
      if (_currentMatches.containsValue(eng)) {
        // Remove existing match
        _currentMatches.removeWhere((k, v) => v == eng);
      }
      _selectedEnglish = eng;
      _checkAndMatch();
    });
  }

  void _checkAndMatch() {
    if (_selectedCebuano != null && _selectedEnglish != null) {
      _currentMatches[_selectedCebuano!] = _selectedEnglish!;
      _selectedCebuano = null;
      _selectedEnglish = null;
    }
  }

  // Check Answer Button pressed
  Future<void> _checkAnswer() async {
    final item = _practiceQueue[_currentIndex];
    bool correct = false;
    String learnerAns = '';
    String correctAns = item.englishWord;

    if (item.activityFormat == ActivityFormat.multipleChoice ||
        (item.activityFormat == ActivityFormat.fillInTheBlank &&
            _options.isNotEmpty) ||
        item.activityFormat == ActivityFormat.imageMatching ||
        item.activityFormat == ActivityFormat.imageLabeling ||
        item.activityFormat == ActivityFormat.hintToWord) {
      if (_selectedOptionIndex == -1) return;
      if (_selectedOptionIndex < 0 || _selectedOptionIndex >= _options.length) {
        debugPrint(
          'Selected option index out of range ($_selectedOptionIndex) for options length ${_options.length}',
        );
        return;
      }
      learnerAns = _options[_selectedOptionIndex];

      final lvl = _getEffectiveLevel(item);
      String targetCorrect = item.englishWord;

      // For fill-in-the-blank, use the same logic as option building
      if (item.activityFormat == ActivityFormat.fillInTheBlank) {
        targetCorrect =
            (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
            ? item.fitbAnswer!
            : item.englishWord;

        // If backend sent a sentence, use target word instead (same logic as option building)
        if (targetCorrect.split(RegExp(r'\s+')).length > 2 ||
            targetCorrect.contains('__') ||
            targetCorrect.contains('.')) {
          targetCorrect = item.englishWord;
          debugPrint(
            'FITB check: backend sent sentence, using target word for comparison: $targetCorrect',
          );
        }
      }

      debugPrint(
        'MC/FITB check: selected="$learnerAns", comparing against="$targetCorrect"',
      );
      correct = (learnerAns.trim().toLowerCase() == targetCorrect.trim().toLowerCase());
      correctAns = targetCorrect;
    } else if (item.activityFormat == ActivityFormat.listeningTyping) {
      learnerAns = _typingController.text.trim();
      final lvl = _getEffectiveLevel(item);
      String correctTarget;
      if (lvl == 'LEARNING') {
        correctTarget = item.englishWord;
      } else if (lvl == 'FAMILIAR') {
        correctTarget = _getListeningTypingAudioText(item);
      } else {
        correctTarget = item.exampleSentenceEnglish;
      }

      if (lvl == 'PROFICIENT') {
        final cleanLearner = _cleanStringForCompare(learnerAns);
        final cleanCorrect = _cleanStringForCompare(correctTarget);
        final dist = _levenshtein(cleanLearner, cleanCorrect);
        correct = (cleanCorrect.length >= 4) ? (dist <= 1) : (dist == 0);
      } else if (lvl == 'MASTERED') {
        final cleanLearner = learnerAns
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ')
            .toLowerCase();
        final cleanCorrect = correctTarget
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ')
            .toLowerCase();
        correct = cleanLearner == cleanCorrect;
      } else {
        final cleanLearner = _cleanStringForCompare(learnerAns);
        final cleanCorrect = _cleanStringForCompare(correctTarget);
        correct = cleanLearner == cleanCorrect;
      }
      correctAns = correctTarget;
    } else if (item.activityFormat == ActivityFormat.fillInTheBlank &&
        _options.isEmpty) {
      learnerAns = _typingController.text.trim();
      // Use single-word target for comparison. If fitbAnswer is multi-word, fall back to englishWord.
      String correctTarget = (item.fitbAnswer ?? '').trim();
      if (correctTarget.isEmpty) correctTarget = item.englishWord.trim();
      final tokens = correctTarget
          .split(RegExp(r'\s+'))
          .where((t) => t.trim().isNotEmpty)
          .toList();
      if (tokens.length > 1) {
        // prefer the canonical vocabulary word when fitbAnswer is a sentence
        correctTarget = item.englishWord.trim();
      }
      correct = learnerAns.toLowerCase() == correctTarget.toLowerCase();
      correctAns = correctTarget;
    } else if (item.activityFormat == ActivityFormat.matching ||
        item.activityFormat == ActivityFormat.translationMatching) {
      // Matching is correct if the target word is matched correctly AND all matching inputs are correct
      bool targetCorrect =
          _currentMatches[item.cebuanoMeaning] == item.englishWord;

      // Also ensure all other matched pairs are indeed correct translations
      bool othersCorrect = true;
      _currentMatches.forEach((ceb, eng) {
        final actualWordObj = _words.firstWhere(
          (w) => w.cebuanoMeaning == ceb,
          orElse: () => VocabularyWordModel(
            wordId: '',
            lessonId: '',
            englishWord: '',
            cebuanoMeaning: '',
            exampleSentenceEnglish: '',
            gradeLevel: '',
            wordOrder: 0,
            isConfusablePairMember: false,
          ),
        );
        if (actualWordObj.englishWord.isNotEmpty &&
            actualWordObj.englishWord != eng) {
          othersCorrect = false;
        }
      });

      correct = targetCorrect && othersCorrect;
      learnerAns = _currentMatches.toString();
      correctAns = 'All correct matches';
    } else if (item.activityFormat == ActivityFormat.trueOrFalse) {
      if (_selectedOptionIndex == -1) return;
      learnerAns = _selectedOptionIndex == 0 ? 'True' : 'False';
      correctAns = item.fitbAnswer ?? 'True';
      correct = learnerAns.toLowerCase() == correctAns.toLowerCase();
    } else if (item.activityFormat == ActivityFormat.flashcardRecall) {
      // Flashcard recall is always considered correct if the user flips and confirms
      correct = _flashcardFlipped;
      learnerAns = 'Flashcard flipped';
      correctAns = 'Flashcard confirmed';
    } else if (item.activityFormat == ActivityFormat.rearrangement ||
        item.activityFormat == ActivityFormat.wordScramble) {
      final String rawTarget =
          (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
          ? item.fitbAnswer!
          : (item.activityFormat == ActivityFormat.wordScramble
                ? item.englishWord
                : item.exampleSentenceEnglish);

      final List<String> targetTokens =
          item.activityFormat == ActivityFormat.wordScramble
          ? rawTarget.split('')
          : rawTarget.split(RegExp(r'\s+'));

      String normalize(String s) =>
          s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final targetNormalized = targetTokens
          .map(normalize)
          .where((t) => t.isNotEmpty)
          .toList();
      final assembledNormalized = _assembledTokens
          .map(normalize)
          .where((t) => t.isNotEmpty)
          .toList();

      if (targetNormalized.isEmpty) {
        correct = false;
      } else if (item.activityFormat == ActivityFormat.wordScramble) {
        correct = assembledNormalized.join('') == targetNormalized.join('');
      } else {
        correct = assembledNormalized.join(' ') == targetNormalized.join(' ');
      }

      final separator = item.activityFormat == ActivityFormat.wordScramble
          ? ''
          : ' ';
      learnerAns = _assembledTokens.join(separator);
      correctAns = targetTokens.join(separator);
    }

    // Save practice result log
    final result = PracticeEvaluationResult(
      wordId: item.wordId,
      activityFormat: item.activityFormat,
      learnerResponse: learnerAns,
      correctAnswer: correctAns,
      isCorrect: correct,
      evaluatedAt: DateTime.now(),
      isReinforcementAttempt: (_wordWrongAttempts[item.wordId] ?? 0) > 0
          ? 1
          : 0,
    );
    final provider = Provider.of<LessonProvider>(context, listen: false);

    debugPrint(
      'CHECK_ANS item=${item.wordId} format=${item.activityFormat} assembled=${_assembledTokens.join(' ')} target="$correctAns" normalizedCorrect=$correct',
    );
    _questionTimer?.cancel();
    await LocalStorageService.saveEvaluationResult(widget.sessionId, result);

    if (!widget.isSandbox &&
        item.activityFormat != ActivityFormat.flashcardRecall) {
      String formatName;
      switch (item.activityFormat) {
        case ActivityFormat.multipleChoice:
          formatName = 'MULTIPLE_CHOICE';
          break;
        case ActivityFormat.fillInTheBlank:
          formatName = 'FILL_IN_BLANK';
          break;
        case ActivityFormat.matching:
          formatName = 'MATCHING';
          break;
        case ActivityFormat.listeningTyping:
          formatName = 'TYPE_WHAT_YOU_HEAR';
          break;
        case ActivityFormat.rearrangement:
          formatName = 'SENTENCE_ARRANGEMENT';
          break;
        case ActivityFormat.wordScramble:
          formatName = 'WORD_SCRAMBLE';
          break;
        case ActivityFormat.imageLabeling:
          formatName = 'IMAGE_LABELING';
          break;
        case ActivityFormat.trueOrFalse:
          formatName = 'TRUE_OR_FALSE';
          break;
        case ActivityFormat.hintToWord:
          formatName = 'HINT_TO_WORD';
          break;
        default:
          formatName = 'MULTIPLE_CHOICE';
      }
      Map<String, dynamic>? submitResp;
      try {
        submitResp = await provider.submitRetrievalAnswer(
          widget.sessionId,
          item.wordId,
          correct,
          wrongAnswer: correct ? null : learnerAns,
          activityFormat: formatName,
        );
        debugPrint('submitRetrievalAnswer response for ${item.wordId}: $submitResp');
      } catch (e) {
        debugPrint('submitRetrievalAnswer exception for ${item.wordId}: $e');
      }

      bool leveledUp = false;
      String newLevel = '';

      if (submitResp != null) {
        final currentLvl = submitResp['currentLevel']?.toString();
        if (currentLvl != null) {
          final tierOrd = _tierOrdinal(currentLvl);
          _wordBestTier[item.wordId] = tierOrd;
        }
        if (submitResp['consecutiveCorrect'] != null) {
          _wordCorrectStreak[item.wordId] = (submitResp['consecutiveCorrect'] as num).toInt();
        }
        if (submitResp['consecutiveIncorrect'] != null) {
          _wordIncorrectStreak[item.wordId] = (submitResp['consecutiveIncorrect'] as num).toInt();
        }

        if (submitResp['leveledUp'] == true) {
          leveledUp = true;
          newLevel = submitResp['currentLevel']?.toString() ?? '';
          _wordCorrectStreak[item.wordId] = 0;
          _wordIncorrectStreak[item.wordId] = 0;
        } else if (correct && (_wordBestTier[item.wordId] ?? 0) >= 2) {
          // When at PROFICIENT (tier 2), answering correctly immediately promotes the word to MASTERED (tier 3)
          _wordBestTier[item.wordId] = 3;
          leveledUp = true;
          newLevel = 'MASTERED';
          _wordCorrectStreak[item.wordId] = 0;
          _wordIncorrectStreak[item.wordId] = 0;
        } else if (submitResp['demoted'] == true) {
          _wordCorrectStreak[item.wordId] = 0;
          _wordIncorrectStreak[item.wordId] = 0;
          debugPrint('DEMOTED: word=${item.wordId} demoted to ${submitResp['currentLevel']}');
        }

        if (submitResp['goalJustCompleted'] == true) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('🎉 Goal Complete!'),
                content: const Text('You hit your daily goal! +50 points!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Awesome!'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        // Fallback / Sandbox / Missing session resolution:
        if (correct) {
          _wordIncorrectStreak[item.wordId] = 0;
          final currentStreak = (_wordCorrectStreak[item.wordId] ?? 0) + 1;
          _wordCorrectStreak[item.wordId] = currentStreak;
          final prevTier = _wordBestTier[item.wordId] ?? 0;
          final targetStreak = prevTier >= 2 ? 1 : _getUpgradeStreakForWord(item.wordId);
          debugPrint('Word ${item.wordId} correct streak: $currentStreak/$targetStreak');
          if (currentStreak >= targetStreak) {
            final nextTier = (prevTier + 1).clamp(0, 3);
            _wordBestTier[item.wordId] = nextTier;
            _wordCorrectStreak[item.wordId] = 0;
            leveledUp = nextTier > prevTier;
            newLevel = _tierName(nextTier);
          }
        } else {
          _wordCorrectStreak[item.wordId] = 0;
          final currentIncorrect = (_wordIncorrectStreak[item.wordId] ?? 0) + 1;
          _wordIncorrectStreak[item.wordId] = currentIncorrect;
          final demotionTarget = _getDemotionThresholdForWord(item.wordId);
          if (currentIncorrect >= demotionTarget) {
            final prevTier = _wordBestTier[item.wordId] ?? 0;
            final lowerTier = (prevTier - 1).clamp(0, 3);
            _wordBestTier[item.wordId] = lowerTier;
            _wordIncorrectStreak[item.wordId] = 0;
            debugPrint('DEMOTED (local): word=${item.wordId} demoted to ${_tierName(lowerTier)}');
          }
        }
      }

      final isMasteredNow = newLevel.toUpperCase() == 'MASTERED' ||
          (_wordBestTier[item.wordId] ?? 0) >= 3 ||
          item.difficultyLevel?.toUpperCase() == 'MASTERED';

      if (isMasteredNow) {
        _hasLeveledUpAnyWord = true;
        _wordBestTier[item.wordId] = 3;
        debugPrint(
          'MASTERED: word=${item.wordId} reached MASTERED. Purging all future queue items for this word in Module 2.',
        );
        _practiceQueue.removeWhere((qItem) =>
            _practiceQueue.indexOf(qItem) > _currentIndex &&
            qItem.wordId == item.wordId);
        _plannedScreens = _practiceQueue.length;
      } else if (leveledUp) {
        _hasLeveledUpAnyWord = true;
        debugPrint(
          'LEVEL_UP: word=${item.wordId} to $newLevel — refreshing remaining queue items',
        );
        bool foundRemaining = false;
        for (int i = _currentIndex + 1; i < _practiceQueue.length; i++) {
          if (_practiceQueue[i].wordId == item.wordId) {
            foundRemaining = true;
            // Re-fetch this question from backend at the new difficulty level
            try {
              String refetchFormat;
              switch (_practiceQueue[i].activityFormat) {
                case ActivityFormat.multipleChoice:
                  refetchFormat = 'MULTIPLE_CHOICE';
                  break;
                case ActivityFormat.fillInTheBlank:
                  refetchFormat = 'FILL_IN_BLANK';
                  break;
                case ActivityFormat.matching:
                  refetchFormat = 'MATCHING';
                  break;
                case ActivityFormat.listeningTyping:
                  refetchFormat = 'TYPE_WHAT_YOU_HEAR';
                  break;
                case ActivityFormat.rearrangement:
                  refetchFormat = 'SENTENCE_ARRANGEMENT';
                  break;
                case ActivityFormat.wordScramble:
                  refetchFormat = 'WORD_SCRAMBLE';
                  break;
                case ActivityFormat.imageLabeling:
                  refetchFormat = 'IMAGE_LABELING';
                  break;
                case ActivityFormat.trueOrFalse:
                  refetchFormat = 'TRUE_OR_FALSE';
                  break;
                case ActivityFormat.hintToWord:
                  refetchFormat = 'HINT_TO_WORD';
                  break;
                default:
                  refetchFormat = 'MULTIPLE_CHOICE';
              }
              final q = await provider.loadSingleRetrievalQuestion(
                widget.sessionId,
                item.wordId,
                format: refetchFormat,
              );
              if (q != null) {
                final refreshedDistractors = (q['options'] != null && q['correctAnswer'] != null)
                    ? List<String>.from(q['options'])
                        .where((o) => o != q['correctAnswer'])
                        .toList()
                    : _practiceQueue[i].distractors;
                _practiceQueue[i] = PracticeItemModel(
                  wordId: _practiceQueue[i].wordId,
                  englishWord:
                      q['englishWord'] ?? _practiceQueue[i].englishWord,
                  displayWord:
                      q['displayWord']?.toString() ?? _practiceQueue[i].displayWord,
                  cebuanoMeaning:
                      q['cebuanoMeaning'] ?? _practiceQueue[i].cebuanoMeaning,
                  exampleSentenceEnglish:
                      q['exampleSentenceEnglish'] ??
                      _practiceQueue[i].exampleSentenceEnglish,
                  exampleSentenceCebuano:
                      _practiceQueue[i].exampleSentenceCebuano,
                  activityFormat: _practiceQueue[i].activityFormat,
                  distractors: refreshedDistractors,
                  eligibleActivityTypes:
                      _practiceQueue[i].eligibleActivityTypes,
                  difficultyLevel: q['difficultyLevel'] ?? newLevel,
                  timeLimitSeconds: q['timeLimitSeconds'] as int?,
                  showHint: q['showHints'] == true,
                  hintLanguage: (q['hintLanguage'] as String?) ?? 'CEBUANO',
                  hintText: q['hintText'] as String?,
                  hintToWordClue: q['hintToWordClue'] as String?,
                  hintToWordClueType: q['hintToWordClueType'] as String?,
                  hintDefinition: q['hintDefinition']?.toString() ?? _practiceQueue[i].hintDefinition,
                  hintCebuanoSentence: q['hintCebuanoSentence']?.toString() ?? _practiceQueue[i].hintCebuanoSentence,
                  imageAssetPath:
                      q['imageAssetPath'] ?? _practiceQueue[i].imageAssetPath,
                );
                debugPrint(
                  'LEVEL_UP: refreshed queue item $i for word=${item.wordId} to level=$newLevel',
                );
              } else {
                _practiceQueue[i] = _practiceQueue[i].copyWith(
                  difficultyLevel: newLevel,
                );
              }
            } catch (e) {
              debugPrint('LEVEL_UP: failed to refresh queue item $i: $e');
              _practiceQueue[i] = _practiceQueue[i].copyWith(
                difficultyLevel: newLevel,
              );
            }
          }
        }
        if (!foundRemaining && newLevel.toUpperCase() != 'MASTERED') {
          try {
            final targetWord = _words.firstWhere(
              (w) => w.wordId == item.wordId,
              orElse: () => VocabularyWordModel(
                wordId: item.wordId,
                lessonId: widget.lessonId,
                englishWord: item.englishWord,
                cebuanoMeaning: item.cebuanoMeaning,
                exampleSentenceEnglish: item.exampleSentenceEnglish,
                gradeLevel: 'GRADE_4',
                wordOrder: 1,
                isConfusablePairMember: false,
                difficultyLevel: newLevel,
              ),
            );
            final newFormat = (item.activityFormat == ActivityFormat.multipleChoice)
                ? ActivityFormat.fillInTheBlank
                : ActivityFormat.multipleChoice;
            final newItem = _createPracticeItem(targetWord, newFormat);
            _practiceQueue.add(newItem);
            _plannedScreens = _practiceQueue.length;
            debugPrint(
              'LEVEL_UP: Appended next-tier practice item for word=${item.wordId} (level=$newLevel) to practice queue',
            );
          } catch (e) {
            debugPrint('LEVEL_UP: Error appending next-tier item: $e');
          }
        }
      }
    }

    if (correct) {
      _consecutiveStreak++;
      if (_consecutiveStreak >= _streakCelebrationThreshold &&
          _consecutiveStreak % _streakCelebrationThreshold == 0) {
        if (mounted) {
          StreakCelebrationOverlay.show(context, streakCount: _consecutiveStreak);
        }
      }
      if ((_wordWrongAttempts[item.wordId] ?? 0) > 0) {
        _reinforcementPassCorrectCount++;
      } else {
        _initialPassCorrectCount++;
      }
    } else {
      _consecutiveStreak = 0; // Reset session-wide streak on any wrong answer
      _wordWrongAttempts[item.wordId] =
          (_wordWrongAttempts[item.wordId] ?? 0) + 1;
    }

    setState(() {
      _checked = true;
      _isAnswerCorrect = correct;
      _showFeedback = true;
    });

    if (correct) {
      LessonAudioService().playCorrect();
    } else {
      LessonAudioService().playWrong();
    }
  }

  /// Returns the earliest queue index >= [startFrom] such that there are at
  /// least [minGap] distinct wordIds between [startFrom] and that index
  /// (not counting [targetWordId] itself). Falls back to queue length (append)
  /// if there aren't enough distinct words to satisfy the gap.
  int _findInsertionIndex(int startFrom, String targetWordId, int minGap) {
    int uniqueOthersSeen = 0;
    final seenIds = <String>{};
    for (int i = startFrom; i < _practiceQueue.length; i++) {
      final id = _practiceQueue[i].wordId;
      if (id != targetWordId && seenIds.add(id)) {
        uniqueOthersSeen++;
      }
      if (uniqueOthersSeen >= minGap) {
        // Insert AFTER this position so there are minGap words before the target
        return i + 1;
      }
    }
    // Not enough unique words — just append at the end
    return _practiceQueue.length;
  }

  /// Scans [queue] from [fromIndex] onwards and whenever two adjacent entries
  /// share the same wordId, swaps the second one with the first later entry
  /// that has a different wordId. If no such entry exists, leaves it in place.
  void _separateAdjacentSameWords(
    List<PracticeItemModel> queue, {
    required int fromIndex,
  }) {
    for (int i = fromIndex; i < queue.length - 1; i++) {
      if (queue[i].wordId == queue[i + 1].wordId) {
        // Find the first item after i+1 with a different wordId
        for (int j = i + 2; j < queue.length; j++) {
          if (queue[j].wordId != queue[i].wordId) {
            // Swap queue[i+1] and queue[j]
            final tmp = queue[i + 1];
            queue[i + 1] = queue[j];
            queue[j] = tmp;
            break;
          }
        }
      }
    }
  }

  Future<void> _advanceNext() async {
    // Guard against double-tap: drop any tap that arrives while already advancing
    if (_isAdvancingNext) return;
    _isAdvancingNext = true;
    debugPrint(
      'Continue button tapped, currentIndex: $_currentIndex, queueLength: ${_practiceQueue.length}',
    );

    // Bounds check to prevent RangeError
    if (_currentIndex >= _practiceQueue.length) {
      debugPrint('Index out of bounds, transitioning to next phase');
      await _completeModuleAndAdvance();
      _isAdvancingNext = false;
      return;
    }

    final item = _practiceQueue[_currentIndex];
    final wasKnown = widget.knownWordIds.contains(item.wordId);

    if (!_isAnswerCorrect) {
      // Keep missed words in the same session and reintroduce them later.
      final provider = Provider.of<LessonProvider>(context, listen: false);
      if (widget.isSandbox) {
        await provider.updateSandboxProgress(
          sessionId: widget.sessionId,
          wordId: item.wordId,
          pathway: 'FULL',
          stepCompleted: 0,
          status: 'NEEDS_REVIEW',
          moduleNumber: 2,
        );
      } else if (wasKnown) {
        await provider.updateWordProgress(
          widget.sessionId,
          item.wordId,
          'FULL',
          0,
          'NEEDS_PRONUNCIATION_REVIEW',
        );
      }

      // Continuous Reinforcement: generate a varied format exercise for the failed word and append to queue
      List<ActivityFormat> eligibleFormats;
      final eligibleStr = item.eligibleActivityTypes;
      if (eligibleStr != null && eligibleStr.isNotEmpty) {
        eligibleFormats = eligibleStr.split(';').map((s) {
          switch (s.trim().toUpperCase()) {
            case 'MULTIPLE_CHOICE':
              return ActivityFormat.multipleChoice;
            case 'FILL_IN_BLANK':
              return ActivityFormat.fillInTheBlank;
            case 'MATCHING':
              return ActivityFormat.matching;
            case 'TYPE_WHAT_YOU_HEAR':
              return ActivityFormat.listeningTyping;
            case 'SENTENCE_ARRANGEMENT':
              return ActivityFormat.fillInTheBlank;
            case 'IMAGE_LABELING':
            case 'IMAGE_MATCHING':
              return ActivityFormat.imageLabeling;
            case 'TRUE_OR_FALSE':
              return ActivityFormat.trueOrFalse;
            default:
              return ActivityFormat.multipleChoice;
          }
        }).toList();
      } else {
        eligibleFormats = [
          ActivityFormat.multipleChoice,
          ActivityFormat.fillInTheBlank,
          ActivityFormat.matching,
          ActivityFormat.wordScramble,
          ActivityFormat.imageLabeling,
          ActivityFormat.trueOrFalse,
        ];
      }

      final variedFormats = eligibleFormats
          .where((format) => format != item.activityFormat)
          .toList();
      final nextFormat = variedFormats.isNotEmpty
          ? variedFormats[Random().nextInt(variedFormats.length)]
          : item.activityFormat;

      bool isInstructionText(String? text) {
        if (text == null || text.trim().isEmpty) return false;
        final lower = text.toLowerCase().trim();
        return lower.startsWith('match') ||
            lower.startsWith('what is') ||
            lower.startsWith('listen to') ||
            lower.startsWith('complete the sentence');
      }

      final cleanExampleEnglish = isInstructionText(item.exampleSentenceEnglish)
          ? ''
          : item.exampleSentenceEnglish;

      final cleanFitbSentence =
          isInstructionText(item.fitbSentence) ||
              (item.fitbSentence != null && !item.fitbSentence!.contains('_'))
          ? null
          : item.fitbSentence;

      String newDifficulty = item.difficultyLevel ?? 'LEARNING';
      bool newShowHint = item.showHint;
      int? newTimeLimit = item.timeLimitSeconds;

      if (newDifficulty == 'MASTERED') {
        newDifficulty = 'PROFICIENT';
      } else if (newDifficulty == 'PROFICIENT') {
        newDifficulty = 'FAMILIAR';
      } else if (newDifficulty == 'FAMILIAR') {
        newDifficulty = 'LEARNING';
        newShowHint = true;
        newTimeLimit = null;
      }

      final wordModel = VocabularyWordModel(
        wordId: item.wordId,
        lessonId: widget.lessonId,
        englishWord: item.englishWord,
        cebuanoMeaning: item.cebuanoMeaning,
        exampleSentenceEnglish: cleanExampleEnglish,
        exampleSentenceCebuano: item.exampleSentenceCebuano,
        difficultyLevel: newDifficulty,
        showExplanation: newShowHint,
        timeLimitSeconds: newTimeLimit,
        gradeLevel: '',
        wordOrder: 0,
        isConfusablePairMember: false,
        imageAssetPath: item.imageAssetPath,
        mcDistractor1: item.mcDistractor1,
        mcDistractor2: item.mcDistractor2,
        mcDistractor3: item.mcDistractor3,
        fitbSentence: cleanFitbSentence,
        fitbAnswer: item.fitbAnswer,
        matchingSet: item.matchingSet,
        sentenceArrangementTokens: item.sentenceArrangementTokens,
        tileSentence: item.tileSentence,
        explanationText: item.hintText,
      );
      final failedItem = _createPracticeItem(wordModel, nextFormat);
      // Re-insert the failed item with a minimum spacing so the same word
      // doesn't come back immediately. We count how many DISTINCT wordIds
      // exist between currentIndex+1 and the end of the queue; if there are
      // fewer than MIN_GAP unique other words, we just append.  Otherwise we
      // find the earliest slot that is at least MIN_GAP unique words away.
      const int minGapWords = 2;
      final int insertAt = _findInsertionIndex(
        _currentIndex + 1,
        failedItem.wordId,
        minGapWords,
      );
      _practiceQueue.insert(insertAt, failedItem);
      _plannedScreens++;
      // Ensure no accidental adjacency after the insertion
      _separateAdjacentSameWords(_practiceQueue, fromIndex: _currentIndex + 1);


      if ((_wordWrongAttempts[item.wordId] ?? 0) >= 2 && mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (ctx) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: ShortReintroductionScreen(
                word: wordModel,
                onCompleted: () {},
              ),
            ),
          ),
        );
      } else if (wasKnown && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${item.englishWord}" will be reviewed again in this session.',
            ),
            backgroundColor: const Color(0xFFF59E0B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // Increment current index
    _completedScreens++;
    _currentIndex++;
    await _saveCurrentState();

    if (_currentIndex >= _practiceQueue.length) {
      await _completeModuleAndAdvance();
    } else {
      await _fetchAndLoadCurrentItem();
    }
  }

  Future<void> _completeModuleAndAdvance() async {
    if (_isNavigating) return;
    _isNavigating = true;

    // Strict guard: ensure all practice queue items are completed before advancing
    if (_currentIndex < _practiceQueue.length) {
      await _fetchAndLoadCurrentItem();
      _isNavigating = false;
      return;
    }

    setState(() {
      _progressOverride = 1.0;
    });
    await Future.delayed(const Duration(milliseconds: 450));

    // Compute overall mastery percentage using point-based scoring per word.
    final practicedWordIds = _practiceQueue.map((p) => p.wordId).toSet();
    final allLessonWordIds = _words.map((w) => w.wordId).toSet();
    final uniqueWordCount = practicedWordIds.isNotEmpty
        ? practicedWordIds.length
        : (allLessonWordIds.isNotEmpty ? allLessonWordIds.length : 1);
    final denom = uniqueWordCount == 0 ? 1 : uniqueWordCount;
    var moduleScore = ((_scorePoints / denom) * 100.0).clamp(0.0, 100.0);
    if (moduleScore.isNaN || moduleScore.isInfinite) moduleScore = 0.0;
    _moduleScore = moduleScore;
    if (!mounted) return;
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final total = denom;
    final int passCorrect = _scorePoints.toInt().clamp(0, denom);
    _initialPassCorrectCount = passCorrect;
    try {
      await lessonProvider.persistModuleScore(
        widget.lessonId,
        widget.isSandbox ? null : 2,
        passCorrect,
        denom,
        customScore: moduleScore,
        isSandbox: widget.isSandbox,
        sessionId: widget.sessionId,
      );
    } catch (e) {
      debugPrint('Module 2 score sync failed (attempt 1): $e — retrying in 2 s...');
      // Retry once after a short delay to handle transient network issues
      await Future.delayed(const Duration(seconds: 2));
      try {
        await lessonProvider.persistModuleScore(
          widget.lessonId,
          widget.isSandbox ? null : 2,
          passCorrect,
          denom,
          customScore: moduleScore,
          isSandbox: widget.isSandbox,
          sessionId: widget.sessionId,
        );
        debugPrint('Module 2 score sync succeeded on retry.');
      } catch (e2) {
        debugPrint('Module 2 score sync failed after retry: $e2 — score will be saved locally.');
      }
    }

    if (!widget.isSandbox) {
      final summary = SessionSummaryModel(
        sessionId: widget.sessionId,
        learnerId: authProvider.learner?.learnerId ?? 'anonymous',
        lessonId: widget.lessonId,
        totalWordsPracticed: uniqueWordCount,
        initialPassCorrectCount: _initialPassCorrectCount,
        reinforcementPassCorrectCount: _reinforcementPassCorrectCount,
        overallMasteryPercentage: moduleScore,
        summaryGeneratedAt: DateTime.now(),
      );

      await LocalStorageService.saveSessionSummary(summary);
      await LocalStorageService.clearPracticeSessionState(widget.sessionId);
      await LocalStorageService.clearCumulativeReviewState(widget.sessionId);
      await LocalStorageService.saveCumulativeReviewState(widget.sessionId, {
        'lessonIds': [widget.lessonId],
        'reviewItems': [],
        'queue': [],
        'currentIndex': 0,
        'results': {},
        'retryQueue': [],
        'weightedScore': moduleScore,
      });
    }

    bool hasUnfinishedWords = false;

    if (widget.isSandbox) {
      hasUnfinishedWords =
          false; // Always allow advancing in Sandbox mode for testing
    } else {
      // In Module 2 (Active Practice), words are ready for Module 3 once they reach PROFICIENT (tier >= 2) or MASTERED (tier >= 3).
      final practicedWordIds = _practiceQueue.map((p) => p.wordId).toSet();
      final allPracticedProficient = practicedWordIds.isNotEmpty &&
          practicedWordIds.every((id) => (_wordBestTier[id] ?? 0) >= 2);
      final allWordsProficient = _words.isNotEmpty &&
          _words.every((w) => (_wordBestTier[w.wordId] ?? 0) >= 2);

      if (allPracticedProficient || allWordsProficient) {
        hasUnfinishedWords = false;
        debugPrint(
          'ActivePractice: words reached PROFICIENT/MASTERED -> advancing to Module 3',
        );
      } else {
        final masteryStatus = await lessonProvider.checkLessonMasteryStatus(
          widget.lessonId,
          moduleNumber: 2,
        );
        if (masteryStatus != null && masteryStatus['allMastered'] == true) {
          hasUnfinishedWords = false;
        } else {
          hasUnfinishedWords = practicedWordIds.isNotEmpty
              ? practicedWordIds.any((id) => (_wordBestTier[id] ?? 0) < 2)
              : _words.any((w) => (_wordBestTier[w.wordId] ?? 0) < 2);
        }
      }
    }

    if (hasUnfinishedWords) {
      if (!mounted) return;
      if (_hasLeveledUpAnyWord) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Level up! Generating harder questions to help you reach Proficient...',
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Round complete! Practicing active words to increase proficiency...',
            ),
            backgroundColor: Color(0xFF3B82F6),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Reset variables to seamlessly loop into the next mastery tier
      setState(() {
        _isNavigating = false;
        _currentIndex = 0;
        _completedScreens = 0;
        _initialPassCorrectCount = 0;
        _reinforcementPassCorrectCount = 0;
        _hasLeveledUpAnyWord = false;
        _progressOverride = null; // Preserve _maxProgress so ladder progress isn't wiped!
        _showFeedback = false;
        _checked = false;
        _practiceQueue.clear();
      });

      // Fetch fresh questions (which will now pull the upgraded difficulty levels)
      await _initializeSession();
      return;
    }

    // Module 2 is complete! Save active route for Module 3 so resuming opens Module 3
    if (!mounted) return;
    if (!widget.isSandbox) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final posFocus = auth.learner?.posFocus;
      await LocalStorageService.saveActiveLessonSession(
        widget.lessonId,
        widget.sessionId,
        '/session/${widget.sessionId}/sentence-building',
        posFocus: posFocus ?? 'ALL',
        allWords: widget.allWords,
        categoryId: widget.categoryId,
        lessonTitle: widget.lessonTitle,
      );
    }

    if (!mounted) return;
    debugPrint('Navigating to Module 3 (Sentence Building)...');
    context.go(
      '/session/${widget.sessionId}/sentence-building',
      extra: {
        'lessonId': widget.lessonId,
        'categoryId': widget.categoryId,
        'lessonTitle': widget.lessonTitle,
        'allWords': widget.allWords,
        'isSandbox': widget.isSandbox,
        'module2CorrectCount': _initialPassCorrectCount,
        'module2TotalCount': total,
        'module2WordWrongAttempts': Map<String, int>.from(_wordWrongAttempts),
        'module2Score': moduleScore,
      },
    );
  }

  // --- UI Builders ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pref = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).learner?.languagePreference;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isCompleted) {
      return _buildSummaryScreen(theme, pref);
    }

    // Guard against transient out-of-range index (can occur right after increment)
    if (_practiceQueue.isEmpty || _currentIndex >= _practiceQueue.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // If we've gone past the last item, finalize the module and advance.
        _completeModuleAndAdvance();
      });
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final item = _practiceQueue[_currentIndex];
    // Dynamic ladder-based progress:
    // Each word can climb 3 rungs on the ladder (0: LEARNING, 1: FAMILIAR, 2: PROFICIENT, 3: MASTERED).
    // Correct answers provide dynamic intermediate climbing steps towards the next rung.
    double totalMasteryPoints = 0.0;
    for (final w in _words) {
      final tier = (_wordBestTier[w.wordId] ?? 0).clamp(0, 3);
      double wordPoints = tier.toDouble();
      if (tier < 3) {
        final streak = (_wordCorrectStreak[w.wordId] ?? 0);
        final streakBonus = (streak / _upgradeStreakRequired * 0.9).clamp(0.0, 0.9);
        wordPoints += streakBonus;
      }
      totalMasteryPoints += wordPoints;
    }

    final maxPossiblePoints = _words.length * 3.0;
    final ladderProgress = maxPossiblePoints > 0
        ? (totalMasteryPoints / maxPossiblePoints).clamp(0.0, 1.0)
        : 0.0;

    final masteredCount = _words
        .where((w) => (_wordBestTier[w.wordId] ?? 0) >= 3)
        .length;
    final masteredProgress = _words.isNotEmpty
        ? (masteredCount / _words.length).clamp(0.0, 1.0)
        : 0.0;

    final rawProgress = max(ladderProgress, masteredProgress);
    // Monotonically non-decreasing: when wrong, progress stays and never drops!
    _maxProgress = max(_maxProgress, rawProgress);
    final progressVal = _progressOverride ?? _maxProgress;
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
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: _showExitConfirmation,
          ),
          title: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 22,
              child: App3DProgressBar(
                value: progressVal,
                height: 22,
                fillColor: const Color(0xFFFBBF24),
                depthColor: const Color(0xFFE6B400),
              ),
            ),
          ),
          actions: [
            if (_consecutiveStreak >= 1)
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDBA74)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFEA580C),
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$_consecutiveStreak',
                          style: const TextStyle(
                            color: Color(0xFFEA580C),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  '$progressPercent%',
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
                        speechText: _getInstructionText(item.activityFormat, item),
                        ttsText:
                            item.activityFormat ==
                                ActivityFormat.listeningTyping
                            ? _getInstructionText(item.activityFormat, item)
                            : null,
                        isSad: _checked && !_isAnswerCorrect,
                        isCelebrating: _checked && _isAnswerCorrect,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _getInstructionText(item.activityFormat, item),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildDifficultyIndicator(item),
                        ],
                      ),
                      const SizedBox(height: 12),
                      () {
                        if (item.activityFormat == ActivityFormat.matching) {
                          return const SizedBox.shrink();
                        }
                        final hintText = _getHintTextForActivity(item);
                        if (hintText == null) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF4FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE879F9),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    color: Color(0xFFD946EF),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CebuanoTextHighlighter(
                                      text: hintText,
                                      highlightWord: item.englishWord,
                                      style: const TextStyle(
                                        color: Color(0xFFA21CAF),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      highlightStyle: const TextStyle(
                                        color: Color(0xFF0284C7),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFF0284C7),
                                        decorationThickness: 2.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }(),
                      if (item.timeLimitSeconds != null &&
                          item.timeLimitSeconds! > 0 &&
                          !_checked) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Time Remaining:',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${_secondsRemaining}s',
                                    style: TextStyle(
                                      color: _secondsRemaining <= 5
                                          ? Colors.redAccent
                                          : const Color(0xFF06A6FF),
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
                                  value: item.timeLimitSeconds! > 0
                                      ? (_secondsRemaining /
                                            item.timeLimitSeconds!)
                                      : 0.0,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _secondsRemaining <= 5
                                        ? Colors.redAccent
                                        : const Color(0xFF06A6FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],

                      // Main Activity Body
                      _buildActivityBody(item),
                    ],
                  ),
                ),
              ),

              // Bottom Check / Feedback Panel
              _buildBottomPanel(theme, pref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(PracticeItemModel item) {
    final level = _getEffectiveLevel(item);
    const labels = {
      'LEARNING': 'Learning',
      'FAMILIAR': 'Familiar',
      'PROFICIENT': 'Proficient',
      'MASTERED': 'Mastered',
    };
    const colors = {
      'LEARNING': Color(0xFF94A3B8),
      'FAMILIAR': Color(0xFF3B82F6),
      'PROFICIENT': Color(0xFFF59E0B),
      'MASTERED': Color(0xFF10B981),
    };
    final color = colors[level] ?? colors['LEARNING']!;
    final label = labels[level] ?? 'Learning';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBody(PracticeItemModel item) {
    switch (item.activityFormat) {
      case ActivityFormat.multipleChoice:
        return _buildMultipleChoice(item);
      case ActivityFormat.imageMatching:
      case ActivityFormat.imageLabeling:
        return _buildImageLabeling(item);
      case ActivityFormat.trueOrFalse:
        return _buildTrueOrFalse(item);
      case ActivityFormat.wordScramble:
        return _buildWordScramble(item);
      case ActivityFormat.rearrangement:
        // Sentence arrangement belongs in Module 3; fallback to fill-in-the-blank
        return _buildFillInTheBlank(item);
      case ActivityFormat.matching:
      case ActivityFormat.translationMatching:
        return _buildMatching(item);
      case ActivityFormat.fillInTheBlank:
        return _buildFillInTheBlank(item);
      case ActivityFormat.listeningTyping:
        return _buildListeningTyping(item);
      case ActivityFormat.flashcardRecall:
        return _buildFlashcardRecall(item);
      case ActivityFormat.hintToWord:
        // Hint-to-Word: renders like multipleChoice but with a definition/clue as the prompt
        return _buildHintToWord(item);
    }
  }

  Widget _buildWordScramble(PracticeItemModel item) {
    // Dedicated Word Scramble UI — letter tiles, not word tiles.
    // LEARNING: first letter anchored (pre-placed), Cebuano meaning shown as guide
    // FAMILIAR: all letters scrambled, no pre-placed anchor
    // PROFICIENT: all letters + 2 fake letters
    // MASTERED: all letters + 3 fake letters
    final level = _getEffectiveLevel(item);
    final isLearning = level == 'LEARNING';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Context guide — show cebuano meaning only at LEARNING tier
        if (isLearning && item.cebuanoMeaning.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
            ),
            child: Text(
              'Bisaya: ${item.cebuanoMeaning}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0369A1),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        // Assembled word display area
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your Word',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: _assembledTokens.isEmpty
                      ? const Center(
                          child: Text(
                            'Tap letters below to spell the word',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _assembledTokens.asMap().entries.map((
                            entry,
                          ) {
                            final idx = entry.key;
                            final letter = entry.value;
                            // Anchored first letter — not tappable
                            final isAnchored =
                                isLearning &&
                                idx == 0 &&
                                item.anchoredWord != null;
                            return GestureDetector(
                              onTap: isAnchored || _checked
                                  ? null
                                  : () {
                                      setState(() {
                                        _assembledTokens.removeAt(idx);
                                        _scrambledTokens.add(letter);
                                      });
                                    },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isAnchored
                                      ? const Color(0xFFDDD6FE)
                                      : const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isAnchored
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFF4338CA),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isAnchored
                                          ? const Color(0xFF5B21B6)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Available Letters',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        // Scrambled letter tiles
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scrambledTokens.map((letter) {
            return GestureDetector(
              onTap: _checked
                  ? null
                  : () {
                      setState(() {
                        _scrambledTokens.remove(letter);
                        _assembledTokens.add(letter);
                      });
                    },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 4. Image-to-Word Labeling Widget (unified image activity)

  Widget _buildImageLabeling(PracticeItemModel item) {
    // Only show Cebuano meaning label at LEARNING tier
    final level = _getEffectiveLevel(item);
    final showCebuanoLabel = level == 'LEARNING';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCebuanoLabel && item.cebuanoMeaning.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Bisaya: ${item.cebuanoMeaning}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ImageMatchingWidget(
          item: item,
          options: _options,
          selectedIndex: _selectedOptionIndex,
          onSelect: (idx) => _selectMcOption(idx),
        ),
      ],
    );
  }

  Widget _buildTrueOrFalse(PracticeItemModel item) {
    final level = _getEffectiveLevel(item);
    final isTrueSelected = _selectedOptionIndex == 0;
    final isFalseSelected = _selectedOptionIndex == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show image only at LEARNING and FAMILIAR tiers
        if (level !=
                'PROFICIENT' &&
            level != 'MASTERED' &&
            item.imageAssetPath != null &&
            item.imageAssetPath!.isNotEmpty &&
            (item.imageAssetPath!.startsWith('http') ||
                item.imageAssetPath!.startsWith('assets/')))
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageAssetPath!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                item.englishWord,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF0284C7),
                  decorationThickness: 2.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Icon(
                  Icons.compare_arrows,
                  color: Color(0xFF94A3B8),
                  size: 30,
                ),
              ),
              Text(
                item.cebuanoMeaning,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF06A6FF),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectMcOption(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isTrueSelected
                        ? const Color(0xFF10B981)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTrueSelected
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'True',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isTrueSelected
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectMcOption(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isFalseSelected
                        ? const Color(0xFFEF4444)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFalseSelected
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'False',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isFalseSelected
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 1. Multiple Choice Activity Widget
  Widget _buildMultipleChoice(PracticeItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cebuano word prompt card with image
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display image if available
              if (item.imageAssetPath != null &&
                  item.imageAssetPath!.isNotEmpty &&
                  (item.imageAssetPath!.startsWith('http') ||
                      item.imageAssetPath!.startsWith('assets/')))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: CustomImageViewer(
                      imagePath: item.imageAssetPath!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => SizedBox(
                        width: 140,
                        height: 140,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              () {
                // In Multiple Choice, prompt is the Cebuano word and options are English words
                final promptWord = item.cebuanoMeaning.isNotEmpty
                    ? item.cebuanoMeaning
                    : item.englishWord;
                return Column(
                  children: [
                    Text(
                      promptWord,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: Color(0xFF06A6FF),
                        size: 24,
                      ),
                      onPressed: () => _ttsService.speakCebuano(promptWord),
                      tooltip: "Listen to Cebuano word",
                    ),
                  ],
                );
              }(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Choose the correct English word:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        // Choices (English words)
        ...List.generate(_options.length, (index) {
          final option = _options[index];
          final isSelected = _selectedOptionIndex == index;

          Color cardBorderColor = const Color(0xFFE2E8F0);
          Color cardBgColor = Colors.white;
          Color textColor = const Color(0xFF334155);

          if (isSelected) {
            cardBorderColor = const Color(0xFF3B82F6);
            cardBgColor = const Color(0xFFEFF6FF);
            textColor = const Color(0xFF1D4ED8);
          }

          if (_checked) {
            final expectedAnswer = item.englishWord;
            final isCorrectOption = (option.trim().toLowerCase() == expectedAnswer.trim().toLowerCase());
            if (isCorrectOption) {
              cardBorderColor = const Color(0xFF22C55E);
              cardBgColor = const Color(0xFFF0FDF4);
              textColor = const Color(0xFF15803D);
            } else if (isSelected) {
              cardBorderColor = const Color(0xFFEF4444);
              cardBgColor = const Color(0xFFFEF2F2);
              textColor = const Color(0xFFB91C1C);
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () => _selectMcOption(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorderColor, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => TTSService.speakEnglish(option),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                            size: 20,
                          ),
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
    );
  }

  // 1b. Hint-to-Word Activity Widget
  Widget _buildHintToWord(PracticeItemModel item) {
    final lvl = _getEffectiveLevel(item);
    final isLearning = lvl == 'LEARNING';
    final isFamiliar = lvl == 'FAMILIAR';

    String badgeLabel;
    IconData badgeIcon;
    Color badgeColor;
    Color badgeBg;

    if (item.hintToWordClueType == 'CEBUANO_SENTENCE' || isLearning) {
      badgeLabel = 'CEBUANO CONTEXT CLUE';
      badgeIcon = Icons.language_rounded;
      badgeColor = const Color(0xFF0284C7);
      badgeBg = const Color(0xFFE0F2FE);
    } else if (item.hintToWordClueType == 'ENGLISH_DEFINITION' || isFamiliar) {
      badgeLabel = 'DEFINITION CLUE';
      badgeIcon = Icons.menu_book_rounded;
      badgeColor = const Color(0xFF7C3AED);
      badgeBg = const Color(0xFFF3E8FF);
    } else {
      badgeLabel = 'SYNONYM / CLUE';
      badgeIcon = Icons.lightbulb_rounded;
      badgeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
    }

    final clueText = (item.hintToWordClue != null && item.hintToWordClue!.trim().isNotEmpty)
        ? item.hintToWordClue!.trim()
        : (isLearning
            ? ((item.exampleSentenceCebuano?.trim().isNotEmpty ?? false)
                ? item.exampleSentenceCebuano!.trim()
                : item.cebuanoMeaning)
            : item.cebuanoMeaning);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Clue Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 16, color: badgeColor),
                    const SizedBox(width: 6),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                clueText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Choose the correct English word:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        // English choices
        ...List.generate(_options.length, (index) {
          final option = _options[index];
          final isSelected = _selectedOptionIndex == index;

          Color cardBorderColor = const Color(0xFFE2E8F0);
          Color cardBgColor = Colors.white;
          Color textColor = const Color(0xFF334155);

          if (isSelected) {
            cardBorderColor = const Color(0xFF3B82F6);
            cardBgColor = const Color(0xFFEFF6FF);
            textColor = const Color(0xFF1D4ED8);
          }

          if (_checked) {
            final isCorrectOption = (option == item.englishWord);
            if (isCorrectOption) {
              cardBorderColor = const Color(0xFF22C55E);
              cardBgColor = const Color(0xFFF0FDF4);
              textColor = const Color(0xFF15803D);
            } else if (isSelected) {
              cardBorderColor = const Color(0xFFEF4444);
              cardBgColor = const Color(0xFFFEF2F2);
              textColor = const Color(0xFFB91C1C);
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () => _selectMcOption(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorderColor, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
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
    );
  }

  // 2. Matching Activity Widget
  Widget _buildMatching(PracticeItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Connect the pairs:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cebuano Column
            Expanded(
              child: Column(
                children: _matchingCebuanoList.map((ceb) {
                  final isSelected = _selectedCebuano == ceb;
                  final matchIndex = _currentMatches.keys.toList().indexOf(ceb);
                  final isMatched = matchIndex != -1;

                  Color cardBorderColor = const Color(0xFFE2E8F0);
                  Color cardBgColor = Colors.white;

                  if (isSelected) {
                    cardBorderColor = const Color(0xFF3B82F6);
                    cardBgColor = const Color(0xFFEFF6FF);
                  } else if (isMatched) {
                    cardBorderColor =
                        _pairColors[matchIndex % _pairColors.length];
                    cardBgColor = cardBorderColor.withValues(alpha: 0.08);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () => _tapCebuanoMatch(ceb),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorderColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ceb,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isMatched)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _pairColors[matchIndex %
                                          _pairColors.length],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Pair ${matchIndex + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 16),
            // English Column
            Expanded(
              child: Column(
                children: _matchingEnglishList.map((eng) {
                  final isSelected = _selectedEnglish == eng;
                  final matchesValues = _currentMatches.values.toList();
                  final matchIndex = matchesValues.indexOf(eng);
                  final isMatched = matchIndex != -1;

                  Color cardBorderColor = const Color(0xFFE2E8F0);
                  Color cardBgColor = Colors.white;

                  if (isSelected) {
                    cardBorderColor = const Color(0xFF3B82F6);
                    cardBgColor = const Color(0xFFEFF6FF);
                  } else if (isMatched) {
                    cardBorderColor =
                        _pairColors[matchIndex % _pairColors.length];
                    cardBgColor = cardBorderColor.withValues(alpha: 0.08);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () => _tapEnglishMatch(eng),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorderColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                eng,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isMatched)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _pairColors[matchIndex %
                                          _pairColors.length],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Pair ${matchIndex + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Fill in the Blank Activity Widget
  Widget _buildFillInTheBlank(PracticeItemModel item) {
    // Determine the answer word and sentence to display
    final target =
        (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
        ? item.fitbAnswer!
        : item.englishWord;
    final hasFitbSentence =
        item.fitbSentence != null && item.fitbSentence!.trim().isNotEmpty;
    final rawSentence = hasFitbSentence
        ? item.fitbSentence!
        : item.exampleSentenceEnglish;

    // Split sentence: use explicit ___ marker first, then {BLANK}, then split on target word
    List<String> parts;

    // Smart regex to match any sequence of 2+ underscores, including spaces inside or around them
    // (e.g., "_____ ____ coffee" becomes perfectly matched)
    final blankRegex = RegExp(r'\s*(?:_{2,}\s*)+');

    if (blankRegex.hasMatch(rawSentence)) {
      final match = blankRegex.firstMatch(rawSentence)!;
      parts = [
        rawSentence.substring(0, match.start),
        rawSentence.substring(match.end),
      ];
    } else if (rawSentence.contains('{BLANK}')) {
      final split = rawSentence.split('{BLANK}');
      parts = [split.first, split.skip(1).join('{BLANK}')];
    } else {
      final regex = RegExp(RegExp.escape(target), caseSensitive: false);
      final split = rawSentence.split(regex);
      if (split.length >= 2) {
        // Only blank the first occurrence
        parts = [split.first, split.skip(1).join(target)];
      } else {
        // Target word not found — hide sentence to avoid revealing answer
        parts = ['', ''];
      }
    }

    String blankText = '_______';
    Color blankColor = const Color(0xFF94A3B8);
    Color blankBgColor = const Color(0xFFF1F5F9);

    if (_options.isNotEmpty) {
      if (_selectedOptionIndex != -1) {
        if (_selectedOptionIndex >= 0 &&
            _selectedOptionIndex < _options.length) {
          blankText = _options[_selectedOptionIndex];
        } else {
          blankText = '_______';
        }
        blankColor = const Color(0xFF3B82F6);
        blankBgColor = const Color(0xFFEFF6FF);
      }

      if (_checked) {
        if (_selectedOptionIndex >= 0 &&
            _selectedOptionIndex < _options.length) {
          final selectedOption = _options[_selectedOptionIndex];
          String targetForColor = target;
          if (targetForColor.split(RegExp(r'\s+')).length > 2 ||
              targetForColor.contains('__') ||
              targetForColor.contains('.')) {
            targetForColor = item.englishWord;
          }
          final isCorrect =
              selectedOption.toLowerCase() == targetForColor.toLowerCase();
          if (isCorrect) {
            blankColor = const Color(0xFF22C55E);
            blankBgColor = const Color(0xFFF0FDF4);
          } else {
            blankColor = const Color(0xFFEF4444);
            blankBgColor = const Color(0xFFFEF2F2);
          }
        }
      }
    } else {
      if (_typingController.text.trim().isNotEmpty) {
        blankText = _typingController.text.trim();
        blankColor = const Color(0xFF3B82F6);
        blankBgColor = const Color(0xFFEFF6FF);
      }

      if (_checked) {
        final typedText = _typingController.text.trim();
        String targetForColor = target;
        if (targetForColor.split(RegExp(r'\s+')).length > 2 ||
            targetForColor.contains('__') ||
            targetForColor.contains('.')) {
          targetForColor = item.englishWord;
        }
        final isCorrect =
            typedText.toLowerCase() == targetForColor.toLowerCase();
        if (isCorrect) {
          blankColor = const Color(0xFF22C55E);
          blankBgColor = const Color(0xFFF0FDF4);
        } else {
          blankColor = const Color(0xFFEF4444);
          blankBgColor = const Color(0xFFFEF2F2);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sentence Prompt Box
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (parts.isNotEmpty)
                    Text(
                      parts[0],
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                  if (parts.length > 1)
                    Text(
                      parts[1],
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                ],
              ),
              if (item.exampleSentenceCebuano != null &&
                  item.exampleSentenceCebuano!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('🇵🇭', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CebuanoTextHighlighter(
                        text: item.exampleSentenceCebuano!,
                        highlightWord: item.cebuanoMeaning,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                          height: 1.4,
                        ),
                        highlightStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0369A1),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF0284C7),
                          decorationThickness: 2.2,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: Color(0xFF06A6FF),
                        size: 20,
                      ),
                      onPressed: () => _ttsService.speakCebuano(
                        item.exampleSentenceCebuano!.replaceAll('**', ''),
                      ),
                      tooltip: "Listen to sentence translation",
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Options List or Typing Input
        if (_options.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: TextField(
              controller: _typingController,
              enabled: !_checked,
              onChanged: (val) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Type the missing word here...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ] else ...[
          ...List.generate(_options.length, (index) {
            final option = _options[index];
            final isSelected = _selectedOptionIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: OutlinedButton(
                onPressed: _checked ? null : () => _selectMcOption(index),
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFF3B82F6)
                      : Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildFlashcardRecall(PracticeItemModel item) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Flashcard recall',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _flashcardFlipped
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _flashcardFlipped
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.englishWord,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_flashcardFlipped) ...[
                    Text(
                      item.cebuanoMeaning,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.exampleSentenceEnglish,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Think first, then flip to confirm.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _flashcardFlipped ? 'HIDE ANSWER' : 'REVEAL ANSWER',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningTyping(PracticeItemModel item) {
    final lvl = _getEffectiveLevel(item);
    final showCebuano = (lvl == 'LEARNING' || lvl == 'FAMILIAR');

    // Hide English prompt from the UI (the learner must listen); show Bisaya hint instead if enabled
    final bisayaHint = showCebuano
        ? ((item.exampleSentenceCebuano?.trim().isNotEmpty ?? false)
              ? item.exampleSentenceCebuano!.trim()
              : item.cebuanoMeaning.trim())
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Listen and type what you hear',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              if (bisayaHint.isNotEmpty) ...[
                Text(
                  'Bisaya: $bisayaHint',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 18),
              TextField(
                controller: _typingController,
                onChanged: (_) {
                  if (mounted) setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Type what you hear',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF06A6FF),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () =>
                    _ttsService.speak(_getListeningTypingAudioText(item)),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Hear it again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF06A6FF),
                  side: const BorderSide(color: Color(0xFF06A6FF), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bottom action bar (Check answers / Feedback banners)
  Widget _buildBottomPanel(ThemeData theme, String? pref) {
    final item = _practiceQueue[_currentIndex];
    // Compute a contextual correct answer string for feedback display
    String correctAnswerText() {
      if (item.activityFormat == ActivityFormat.rearrangement) {
        final tokens =
            item.sentenceArrangementTokens ??
            item.exampleSentenceEnglish.split(RegExp(r'\s+'));
        return tokens
            .map((t) => t.toString().trim())
            .where((t) => t.isNotEmpty)
            .join(' ')
            .trim();
      }
      if (item.activityFormat == ActivityFormat.listeningTyping) {
        final fitb = item.fitbAnswer?.trim() ?? '';
        if (fitb.isNotEmpty &&
            fitb
                    .split(RegExp(r'\s+'))
                    .where((t) => t.trim().isNotEmpty)
                    .length ==
                1) {
          return fitb;
        }
        return item.englishWord;
      }
      if (item.activityFormat == ActivityFormat.trueOrFalse) {
        return item.fitbAnswer ?? 'True';
      }
      if (item.activityFormat == ActivityFormat.multipleChoice) {
        return item.englishWord;
      }
      return item.englishWord;
    }

    String? getLearnerSentenceRestatement() {
      String learnerAns = '';
      if (item.activityFormat == ActivityFormat.multipleChoice ||
          (item.activityFormat == ActivityFormat.fillInTheBlank &&
              _options.isNotEmpty) ||
          item.activityFormat == ActivityFormat.imageMatching ||
          item.activityFormat == ActivityFormat.hintToWord) {
        if (_selectedOptionIndex >= 0 &&
            _selectedOptionIndex < _options.length) {
          learnerAns = _options[_selectedOptionIndex];
        }
      } else if (item.activityFormat == ActivityFormat.listeningTyping ||
          (item.activityFormat == ActivityFormat.fillInTheBlank &&
              _options.isEmpty)) {
        learnerAns = _typingController.text.trim();
      } else if (item.activityFormat == ActivityFormat.rearrangement) {
        return _assembledTokens.join(' ');
      }

      if (item.activityFormat == ActivityFormat.fillInTheBlank) {
        final sentence =
            item.fitbSentence ?? item.sentenceCompletionSentence ?? '';
        if (sentence.isNotEmpty) {
          final blankRegex = RegExp(r'_{2,}|-{2,}|\[_\]');
          if (sentence.contains(blankRegex)) {
            return sentence.replaceFirst(
              blankRegex,
              learnerAns.isEmpty ? '___' : learnerAns,
            );
          }
          return '$sentence (Answer: $learnerAns)';
        }
      }
      return null;
    }

    String? getCorrectSentenceRestatement() {
      if (item.activityFormat == ActivityFormat.rearrangement) {
        final tokens =
            item.sentenceArrangementTokens ??
            item.exampleSentenceEnglish.split(RegExp(r'\s+'));
        return tokens
            .map((t) => t.toString().trim())
            .where((t) => t.isNotEmpty)
            .join(' ')
            .trim();
      }
      if (item.activityFormat == ActivityFormat.fillInTheBlank) {
        final sentence =
            item.fitbSentence ?? item.sentenceCompletionSentence ?? '';
        final correctAns =
            (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
            ? item.fitbAnswer!
            : item.englishWord;
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

    // Determine button enabling
    bool isActionEnabled = false;
    if (item.activityFormat == ActivityFormat.multipleChoice ||
        (item.activityFormat == ActivityFormat.fillInTheBlank &&
            _options.isNotEmpty) ||
        item.activityFormat == ActivityFormat.imageMatching ||
        item.activityFormat == ActivityFormat.imageLabeling ||
        item.activityFormat == ActivityFormat.trueOrFalse ||
        item.activityFormat == ActivityFormat.hintToWord) {
      isActionEnabled = _selectedOptionIndex != -1;
    } else if (item.activityFormat == ActivityFormat.matching ||
        item.activityFormat == ActivityFormat.translationMatching) {
      isActionEnabled = _currentMatches.length == _matchingCebuanoList.length;
    } else if (item.activityFormat == ActivityFormat.listeningTyping ||
        (item.activityFormat == ActivityFormat.fillInTheBlank &&
            _options.isEmpty)) {
      isActionEnabled = _typingController.text.trim().isNotEmpty;
    } else if (item.activityFormat == ActivityFormat.flashcardRecall) {
      isActionEnabled = _flashcardFlipped;
    } else if (item.activityFormat == ActivityFormat.rearrangement ||
        item.activityFormat == ActivityFormat.wordScramble) {
      isActionEnabled = _assembledTokens.isNotEmpty;
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
                  backgroundColor: const Color(0xFF3B82F6), // Indigo/Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'CHECK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Feedback State
    final Color panelBg = _isAnswerCorrect
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEE2E2);
    final Color textColor = _isAnswerCorrect
        ? const Color(0xFF15803D)
        : const Color(0xFFB91C1C);
    final Color btnBg = _isAnswerCorrect
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    return Container(
      color: panelBg,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _isAnswerCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: textColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAnswerCorrect
                          ? 'Correct (+10 pts)'
                          : 'Incorrect. Review and continue.',
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
                          ] else if (!_isAnswerCorrect &&
                              correctSentence == null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Correct answer: ${correctAnswerText()}',
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
            onPressed: _advanceNext,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Session Summary Widget (UC-2.1 Metrics and UC-2.2 Reinforcement results)
  Widget _buildSummaryScreen(ThemeData theme, String? pref) {
    final masteredCount = _words
        .where((word) => (_wordWrongAttempts[word.wordId] ?? 0) == 0)
        .length;
    final needsReviewWords = _words
        .where((word) => (_wordWrongAttempts[word.wordId] ?? 0) > 0)
        .map((w) => w.englishWord)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Super cool celebration vector placeholder
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFEF3C7),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFBBF24).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 80)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Lesson Practice Completed!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Great job reinforcing your vocabulary words. You answered all questions correctly!',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Detailed stats panel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Total Words Practiced',
                      '${_words.length} words',
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Words Mastered',
                      '$masteredCount / ${_words.length}',
                      isBold: true,
                    ),
                    if (needsReviewWords.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildStatRow(
                        'Still Needs Review',
                        needsReviewWords.join(', '),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Continue to Sentence Building (Module 3) for this session
                  context.go(
                    '/session/${widget.sessionId}/sentence-building',
                    extra: {
                      'lessonId': widget.lessonId,
                      'categoryId': widget.categoryId,
                      'lessonTitle': widget.lessonTitle,
                      'allWords': widget.allWords,
                      'isSandbox': widget.isSandbox,
                      'module2CorrectCount': _initialPassCorrectCount,
                      'module2TotalCount': _practiceQueue.length,
                      'module2WordWrongAttempts': Map<String, int>.from(_wordWrongAttempts),
                      'module2Score': _moduleScore,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Green button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.isSandbox ? 'CONTINUE' : 'CONTINUE TO MODULE 3',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
        title: const Text('Exit Activity?'),
        content: const Text(
          'Your progress will be saved so you can resume where you left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await _saveCurrentState();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                context.go('/home');
              }
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

  Widget _buildStatRow(String label, String value, {bool isBold = false}) {
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
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
            color: isBold ? const Color(0xFF10B981) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  int _min3(int a, int b, int c) {
    int m = a;
    if (b < m) m = b;
    if (c < m) m = c;
    return m;
  }

  String _cleanStringForCompare(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.,!?;:]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
