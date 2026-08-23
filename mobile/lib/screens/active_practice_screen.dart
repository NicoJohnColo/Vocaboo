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
import '../services/localization_service.dart';
import '../widgets/image_matching_widget.dart';
import '../widgets/custom_image_viewer.dart';
import '../widgets/cebuano_text_highlighter.dart';
import 'short_reintroduction_screen.dart';

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

class _ActivePracticeScreenState extends State<ActivePracticeScreen> with WidgetsBindingObserver {
  // Services
  final TtsService _ttsService = TtsService();

  // Words List
  List<VocabularyWordModel> _words = [];

  // Practice Queue
  List<PracticeItemModel> _practiceQueue = [];
  int _currentIndex = 0;
  int _completedScreens = 0;
  int _plannedScreens = 0;

  // Active Time Tracking
  DateTime? _moduleStartTime;
  Duration _totalPausedDuration = Duration.zero;
  DateTime? _pauseStartTime;

  // State Management
  String? get pref => Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;
  bool _isLoading = true;
  bool _checked = false;
  bool _submittingAnswer = false; // Guard against duplicate answer submissions
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
  final Map<String, String> _wordDifficulties = {};
  final Map<String, ActivityFormat> _lastTestedFormatByWord = {};
  int _initialPassCorrectCount = 0;
  int _reinforcementPassCorrectCount = 0;

  // Session Completed State
  final bool _isCompleted = false;
  bool _isNavigating = false;

  // Timer Variables
  Timer? _questionTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _moduleStartTime = DateTime.now();
    _words = widget.allWords.map((w) => VocabularyWordModel.fromJson(w)).toList();
    
    if (!widget.isSandbox) {
      LocalStorageService.saveActiveLessonSession(
        widget.lessonId,
        widget.sessionId,
        '/session/${widget.sessionId}/practice',
      );
    }
    
    _initializeSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionTimer?.cancel();
    _typingController.dispose();
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

  final List<ReinforcementQueueItem> _reinforcementQueue = [];

  String _formatToApiString(ActivityFormat format, {PracticeItemModel? item}) {
    switch (format) {
      case ActivityFormat.multipleChoice:
        return 'MULTIPLE_CHOICE';
      case ActivityFormat.fillInTheBlank:
        return 'FILL_IN_BLANK';
      case ActivityFormat.matching:
        return 'MATCHING';
      case ActivityFormat.listeningTyping:
        return (item?.eligibleActivityTypes?.contains('TRANSLATION_RECALL') == true)
            ? 'TRANSLATION_RECALL'
            : 'TYPE_WHAT_YOU_HEAR';
      case ActivityFormat.rearrangement:
        return 'SENTENCE_ARRANGEMENT';
      case ActivityFormat.wordScramble:
        return 'WORD_SCRAMBLE';
      case ActivityFormat.imageLabeling:
        return 'IMAGE_LABELING';
      case ActivityFormat.trueOrFalse:
        return 'TRUE_OR_FALSE';
      case ActivityFormat.imageMatching:
        return 'IMAGE_MATCHING';
      default:
        return 'MULTIPLE_CHOICE';
    }
  }

  ActivityFormat _parseFormatString(String f) {
    switch (f.trim().toUpperCase()) {
      case 'FILL_IN_BLANK':
        return ActivityFormat.fillInTheBlank;
      case 'MATCHING':
        return ActivityFormat.matching;
      case 'SENTENCE_ARRANGEMENT':
        return ActivityFormat.rearrangement;
      case 'TYPE_WHAT_YOU_HEAR':
      case 'TRANSLATION_RECALL':
        return ActivityFormat.listeningTyping;
      case 'WORD_SCRAMBLE':
        return ActivityFormat.wordScramble;
      case 'IMAGE_LABELING':
        return ActivityFormat.imageLabeling;
      case 'TRUE_OR_FALSE':
        return ActivityFormat.trueOrFalse;
      case 'IMAGE_MATCHING':
        return ActivityFormat.imageMatching;
      case 'FLASHCARD_RECALL':
        return ActivityFormat.flashcardRecall;
      default:
        return ActivityFormat.multipleChoice;
    }
  }

  List<ActivityFormat> _getEligibleFormatsForWord(VocabularyWordModel word) {
    final eligible = word.eligibleActivityTypes;
    if (eligible != null && eligible.isNotEmpty) {
      final parsed = eligible.split(';').map((s) => _parseFormatString(s)).toSet().toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return [
      ActivityFormat.multipleChoice,
      ActivityFormat.trueOrFalse,
      ActivityFormat.fillInTheBlank,
      ActivityFormat.wordScramble,
      if (word.exampleSentenceEnglish.isNotEmpty || (word.sentenceArrangementTokens != null && word.sentenceArrangementTokens!.isNotEmpty))
        ActivityFormat.rearrangement,
      ActivityFormat.listeningTyping,
    ];
  }

  ActivityFormat _pickAlternativeFormat(String wordId, ActivityFormat currentOrPreviousFormat, {List<ActivityFormat>? pool}) {
    final word = _words.firstWhere(
      (w) => w.wordId == wordId,
      orElse: () => VocabularyWordModel(
        wordId: wordId,
        lessonId: widget.lessonId,
        englishWord: '',
        cebuanoMeaning: '',
        exampleSentenceEnglish: '',
        difficultyLevel: 'LEARNING',
        gradeLevel: '',
        wordOrder: 0,
        isConfusablePairMember: false,
      ),
    );
    final candidates = pool ?? _getEligibleFormatsForWord(word);
    final alternatives = candidates.where((f) => f != currentOrPreviousFormat).toList();
    if (alternatives.isNotEmpty) {
      return alternatives[Random().nextInt(alternatives.length)];
    }
    final standardPool = [
      ActivityFormat.multipleChoice,
      ActivityFormat.trueOrFalse,
      ActivityFormat.fillInTheBlank,
      ActivityFormat.wordScramble,
      ActivityFormat.listeningTyping,
    ].where((f) => f != currentOrPreviousFormat).toList();
    if (standardPool.isNotEmpty) {
      return standardPool[Random().nextInt(standardPool.length)];
    }
    return ActivityFormat.multipleChoice;
  }

  PracticeItemModel _buildPracticeItemFromQuestion(Map<String, dynamic> q) {
    final formatStr = q['activityFormat'] as String? ?? q['activityType'] as String? ?? 'MULTIPLE_CHOICE';
    final format = _parseFormatString(formatStr);

    final options = List<String>.from(q['options'] ?? []);
    final correctAnswer = q['correctAnswer'] as String? ?? '';
    final distractors = options.where((o) => o != correctAnswer).toList();
    final scrambledTokens = List<String>.from(q['scrambledTokens'] ?? []);

    List<Map<String, dynamic>>? matchingSet;
    if (q['matchingPairs'] != null) {
      matchingSet = (q['matchingPairs'] as List<dynamic>)
          .map((e) => {
                'englishWord': e['english'],
                'cebuanoMeaning': e['cebuano'],
              })
          .toList();
    }

    final rawExample = (q['exampleSentenceEnglish'] as String?)?.trim();
    final exampleSentence = (rawExample != null && rawExample.isNotEmpty) ? rawExample : '';

    final rawQuestionText = (q['questionText'] as String?)?.trim();
    final fitbSentence = (format == ActivityFormat.fillInTheBlank && rawQuestionText != null && rawQuestionText.contains('_'))
        ? rawQuestionText
        : null;

    final isLearning = (q['difficultyLevel'] as String? ?? 'LEARNING').toUpperCase() == 'LEARNING';
    final showHint = q['showHints'] == true ||
        q['showHint'] == true ||
        q['showExplanation'] == true ||
        q['showExplanations'] == true ||
        isLearning;
    final hintText = q['explanationText'] as String? ??
        q['explanation'] as String? ??
        q['hintText'] as String? ??
        q['cebuanoMeaning'] as String?;

    return PracticeItemModel(
      wordId: q['wordId'],
      englishWord: q['englishWord']?.toString() ?? q['word']?.toString() ?? '',
      displayWord: q['displayWord'] as String? ?? q['word']?.toString() ?? q['englishWord']?.toString(),
      cebuanoMeaning: q['cebuanoMeaning'] ?? '',
      exampleSentenceEnglish: exampleSentence,
      exampleSentenceCebuano: q['exampleSentenceCebuano'] ?? q['cebuanoMeaning'],
      activityFormat: format,
      eligibleActivityTypes: q['eligibleActivityTypes']?.toString() ?? q['activityType']?.toString(),
      distractors: distractors,
      mcDistractor1: distractors.isNotEmpty ? distractors[0] : null,
      mcDistractor2: distractors.length > 1 ? distractors[1] : null,
      mcDistractor3: distractors.length > 2 ? distractors[2] : null,
      fitbSentence: fitbSentence,
      fitbAnswer: format == ActivityFormat.trueOrFalse
          ? (q['correctAnswer']?.toString() ?? 'True')
          : correctAnswer,
      matchingSet: matchingSet,
      sentenceArrangementTokens: scrambledTokens,
      imageAssetPath: q['imageAssetPath'],
      timeLimitSeconds: q['timeLimitSeconds'] as int?,
      difficultyLevel: q['difficultyLevel'] as String? ?? 'LEARNING',
      showHint: showHint,
      hintText: hintText,
      anchoredWord: q['anchoredWord'] as String?,
    );
  }

  Future<void> _initializeSession() async {
    setState(() => _isLoading = true);
    
    if (!widget.isSandbox) {
      try {
        final provider = Provider.of<LessonProvider>(context, listen: false);
        final diffs = await provider.loadWordDifficulties(widget.lessonId, moduleNumber: 2);
        _wordDifficulties.addAll(diffs);

        int getTierPoints(String tier) {
          switch (tier.toUpperCase()) {
            case 'LEARNING': return 0;
            case 'FAMILIAR': return 1;
            case 'PROFICIENT': return 2;
            case 'MASTERED': return 3;
            default: return 0;
          }
        }
        int totalMaxPoints = _words.length * 3;
        int currentPoints = 0;
        for (final w in _words) {
          currentPoints += getTierPoints(_wordDifficulties[w.wordId] ?? 'LEARNING');
        }
        final calculatedProgress = totalMaxPoints == 0 ? 0.0 : (currentPoints / totalMaxPoints);
        _maxProgress = max(_maxProgress, calculatedProgress);
      } catch (e) {
        debugPrint("Error loading difficulties: $e");
      }
    }

    // Check if there is an existing saved session state
    final savedState = await LocalStorageService.getPracticeSessionState(widget.sessionId);
    
    if (savedState != null) {
      _practiceQueue = savedState['queue'] as List<PracticeItemModel>;
      _currentIndex = savedState['currentIndex'] as int;
      _completedScreens = (savedState['completedScreens'] as int?) ?? _currentIndex;
      _plannedScreens = (savedState['plannedScreens'] as int?) ?? _practiceQueue.length;
      
      if (_currentIndex >= _practiceQueue.length) {
        await _completeModuleAndAdvance();
      } else {
        await _fetchAndLoadCurrentItem();
      }
    } else {
      // Build new session queue
      if (widget.isSandbox) {
        _buildPracticeQueue();
      } else {
        if (!mounted) return;
        final provider = Provider.of<LessonProvider>(context, listen: false);

        final backendQuestions = await provider.loadRetrievalQuestions(widget.sessionId);
        if (!mounted) return;
        final rawQueue = backendQuestions.map((q) => _buildPracticeItemFromQuestion(q)).toList();

        // Queue Diversification: Ensure multiple questions for the same word are assigned distinct activity formats
        final Map<String, Set<ActivityFormat>> usedFormatsPerWord = {};
        for (final item in rawQueue) {
          final used = usedFormatsPerWord.putIfAbsent(item.wordId, () => <ActivityFormat>{});
          if (used.contains(item.activityFormat)) {
            final altFormat = _pickAlternativeFormat(item.wordId, item.activityFormat);
            item.activityFormat = altFormat;
          }
          used.add(item.activityFormat);
        }
        _practiceQueue = rawQueue;
        _practiceQueue.shuffle(Random());
      }
      
      _currentIndex = 0;
      _completedScreens = 0;
      _plannedScreens = _practiceQueue.length;
      if (_practiceQueue.isNotEmpty) {
        await _fetchAndLoadCurrentItem();
      }
      await _saveCurrentState();
    }

    setState(() => _isLoading = false);
  }

  void _buildPracticeQueue() {
    _practiceQueue.clear();
    
    final candidateWords = _words.where((w) {
      final lvl = (_wordDifficulties[w.wordId] ?? w.difficultyLevel).toUpperCase();
      return lvl != 'MASTERED';
    }).toList();

    if (widget.isSandbox) {
      // Sandbox mode: fixed sequence of activities with variety
      for (var word in candidateWords) {
        _practiceQueue.add(_createPracticeItem(word, ActivityFormat.flashcardRecall));
        _practiceQueue.add(_createPracticeItem(word, ActivityFormat.multipleChoice));
        _practiceQueue.add(_createPracticeItem(word, ActivityFormat.fillInTheBlank));
      }
    } else {
      final random = Random();
      final shuffledWords = List<VocabularyWordModel>.from(candidateWords)..shuffle(random);

      for (final word in shuffledWords) {
        final wordFormats = _getEligibleFormatsForWord(word);

        var format1 = wordFormats[random.nextInt(wordFormats.length)];
        if (word.imageAssetPath != null && word.imageAssetPath!.isNotEmpty && 
            (word.imageAssetPath!.startsWith('http') || word.imageAssetPath!.startsWith('assets/')) && 
            random.nextDouble() < 0.3) {
          format1 = ActivityFormat.imageMatching;
        }
        _practiceQueue.add(_createPracticeItem(word, format1));

        final format2 = _pickAlternativeFormat(word.wordId, format1, pool: wordFormats);
        _practiceQueue.add(_createPracticeItem(word, format2));
      }
    }
  }

  PracticeItemModel _createPracticeItem(VocabularyWordModel word, ActivityFormat format) {
    final isLearning = word.difficultyLevel.toUpperCase() == 'LEARNING';
    final showHint = word.showExplanation || isLearning;
    final hintText = word.explanationText ?? (word.cebuanoMeaning.isNotEmpty ? word.cebuanoMeaning : null);

    String? fitbAnswer = word.fitbAnswer;
    String? displayWord = word.englishWord;

    if (format == ActivityFormat.trueOrFalse) {
      final isTrue = Random().nextBool();
      if (isTrue) {
        fitbAnswer = 'True';
        displayWord = word.englishWord;
      } else {
        fitbAnswer = 'False';
        final distractors = _resolveDistractors(word);
        displayWord = distractors.isNotEmpty ? distractors.first : 'word';
      }
    }

    return PracticeItemModel(
      wordId: word.wordId,
      englishWord: word.englishWord,
      displayWord: displayWord,
      cebuanoMeaning: word.cebuanoMeaning,
      exampleSentenceEnglish: word.exampleSentenceEnglish,
      exampleSentenceCebuano: word.exampleSentenceCebuano,
      activityFormat: format,
      imageAssetPath: word.imageAssetPath,
      distractors: _resolveDistractors(word),
      mcDistractor1: word.mcDistractor1,
      mcDistractor2: word.mcDistractor2,
      mcDistractor3: word.mcDistractor3,
      fitbSentence: word.fitbSentence,
      fitbAnswer: fitbAnswer,
      matchingSet: word.matchingSet,
      sentenceArrangementTokens: word.sentenceArrangementTokens,
      tileSentence: word.tileSentence,
      hintText: hintText,
      sentenceCompletionSentence: word.sentenceCompletionSentence,
      sentenceCompletionAnswer: word.sentenceCompletionAnswer,
      sentenceCompletionOption1: word.sentenceCompletionOption1,
      sentenceCompletionOption2: word.sentenceCompletionOption2,
      sentenceCompletionOption3: word.sentenceCompletionOption3,
      difficultyLevel: _wordDifficulties[word.wordId] ?? word.difficultyLevel,
      showHint: showHint,
      timeLimitSeconds: word.timeLimitSeconds,
      anchoredWord: word.anchoredWord,
    );
  }

  List<String> _resolveDistractors(VocabularyWordModel targetWord) {
    // Helper function to check if a string is a sentence (not a single word)
    bool isSentence(String value) {
      final wordCount = value.trim().split(RegExp(r'\s+')).length;
      return wordCount > 3 || value.contains('__') || value.contains('.');
    }
    
    final provided = [
      targetWord.mcDistractor1,
      targetWord.mcDistractor2,
      targetWord.mcDistractor3,
    ].whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .where((value) {
          // Filter out sentences - only allow single words or very short phrases (max 2-3 words)
          final isSent = isSentence(value);
          if (isSent) {
            debugPrint('WARNING: Filtering out sentence distractor from mcDistractor: "$value"');
          }
          return !isSent;
        })
        .toList();

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
              debugPrint('WARNING: Filtering out sentence from otherWords: "$w"');
            }
            return !isSent;
          })
          .toList();
      
      if (otherWords.isNotEmpty) {
        otherWords.shuffle();
        fallbackDistractors.addAll(otherWords);
      }
      
      // Add common English words as additional fallbacks
      final commonWords = ['apple', 'house', 'water', 'friend', 'school', 'book', 'tree', 'happy', 'run', 'big', 'cat', 'dog', 'sun', 'moon', 'star', 'hand', 'eye', 'ear', 'nose', 'foot'];
      final targetLower = targetWord.englishWord.toLowerCase();
      final availableCommon = commonWords.where((w) => w.toLowerCase() != targetLower).toList()..shuffle();
      fallbackDistractors.addAll(availableCommon);
      
      // Combine provided + fallbacks and take exactly 3
      final allDistractors = [...provided, ...fallbackDistractors];
      final uniqueDistractors = allDistractors.toSet().toList();
      
      if (uniqueDistractors.length < 3) {
        debugPrint('WARNING: Could not generate 3 distractors for ${targetWord.englishWord}, only got ${uniqueDistractors.length}');
      }
      
      return uniqueDistractors.take(3).toList();
    }

    if (provided.length >= 2) {
      return provided.take(2).toList();
    }

    return _generateDistractors(targetWord);
  }



  List<Map<String, dynamic>> _resolveMatchingSet(PracticeItemModel targetItem) {
    final matchingSet = targetItem.matchingSet ?? const [];
    if (matchingSet.isNotEmpty) {
      return matchingSet;
    }

    // Prefer words that have been practiced in this session (Strict Encounter Filter)
    final practicedWordIds = _practiceQueue.map((p) => p.wordId).toSet();
    final practicedOthers = _words.where((w) => w.wordId != targetItem.wordId && practicedWordIds.contains(w.wordId)).toList();
    
    // We only take up to 3 practiced words. We DO NOT fallback to unencountered words anymore!
    final otherWords = practicedOthers.take(3).toList();
    return [
      {
        'englishWord': targetItem.englishWord,
        'cebuanoMeaning': targetItem.cebuanoMeaning,
      },
      ...otherWords.map((word) => {
            'englishWord': word.englishWord,
            'cebuanoMeaning': word.cebuanoMeaning,
          }),
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
  
  // Track maximum tier points reached for consistent progress (progress never decreases)
  final Map<String, int> _maxWordTierPoints = {};

  double get _scorePoints {
    double score = 0.0;
    for (final word in _words) {
      if ((_wordWrongAttempts[word.wordId] ?? 0) == 0) {
        score += 1.0;
      }
    }
    return score;
  }

  Future<void> _fetchCurrentQuestionDetails() async {
    if (widget.isSandbox || _currentIndex >= _practiceQueue.length) return;
    
    final item = _practiceQueue[_currentIndex];

    // Dynamic screen check: If this word was just tested on the previous screen with the same format, alternate it!
    if (_lastTestedFormatByWord[item.wordId] != null && _lastTestedFormatByWord[item.wordId] == item.activityFormat) {
      final altFormat = _pickAlternativeFormat(item.wordId, item.activityFormat);
      item.activityFormat = altFormat;
    }

    final provider = Provider.of<LessonProvider>(context, listen: false);
    final formatStr = _formatToApiString(item.activityFormat, item: item);
    
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
              .map((e) => {
                    'englishWord': e['english'],
                    'cebuanoMeaning': e['cebuano'],
                  })
              .toList();
        }
        
        final rawExample = (q['exampleSentenceEnglish'] as String?)?.trim();
        final exampleSentence = (rawExample != null && rawExample.isNotEmpty) ? rawExample : '';
        
        final rawQuestionText = (q['questionText'] as String?)?.trim();
        final fitbSentence = (item.activityFormat == ActivityFormat.fillInTheBlank && rawQuestionText != null && rawQuestionText.contains('_'))
            ? rawQuestionText
            : null;

        final isLearning = (q['difficultyLevel'] as String? ?? (_wordDifficulties[item.wordId] ?? item.difficultyLevel ?? 'LEARNING')).toUpperCase() == 'LEARNING';
        final showHint = q['showHints'] == true ||
            q['showHint'] == true ||
            q['showExplanation'] == true ||
            q['showExplanations'] == true ||
            isLearning;
        final hintText = q['explanationText'] as String? ??
            q['explanation'] as String? ??
            q['hintText'] as String? ??
            q['cebuanoMeaning'] as String?;
            
        _practiceQueue[_currentIndex] = PracticeItemModel(
          wordId: q['wordId'] ?? item.wordId,
          englishWord: q['englishWord'] ?? item.englishWord,
          displayWord: q['displayWord'] as String? ?? item.displayWord,
          cebuanoMeaning: q['cebuanoMeaning'] ?? item.cebuanoMeaning,
          exampleSentenceEnglish: exampleSentence,
          exampleSentenceCebuano: q['exampleSentenceCebuano'] ?? q['cebuanoMeaning'] ?? item.exampleSentenceCebuano,
          activityFormat: item.activityFormat,
          eligibleActivityTypes: q['eligibleActivityTypes']?.toString() ?? q['activityType']?.toString() ?? item.eligibleActivityTypes,
          distractors: distractors,
          mcDistractor1: distractors.isNotEmpty ? distractors[0] : null,
          mcDistractor2: distractors.length > 1 ? distractors[1] : null,
          mcDistractor3: distractors.length > 2 ? distractors[2] : null,
          fitbSentence: fitbSentence,
          fitbAnswer: item.activityFormat == ActivityFormat.trueOrFalse
              ? (q['correctAnswer']?.toString() ?? item.fitbAnswer ?? 'True')
              : correctAnswer,
          matchingSet: matchingSet,
          sentenceArrangementTokens: scrambledTokens,
          imageAssetPath: q['imageAssetPath'] ?? item.imageAssetPath,
          timeLimitSeconds: q['timeLimitSeconds'] as int?,
          difficultyLevel: q['difficultyLevel'] as String? ?? (_wordDifficulties[item.wordId] ?? item.difficultyLevel ?? 'LEARNING'),
          showHint: showHint,
          hintText: hintText,
          anchoredWord: q['anchoredWord'] as String?,
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
    _submittingAnswer = false; // Reset dedupe guard for new question
    _showFeedback = false;
    _selectedOptionIndex = -1;
    _selectedCebuano = null;
    _selectedEnglish = null;
    _currentMatches.clear();
    _typingController.clear();
    _flashcardFlipped = false;
    _assembledTokens = []; // Reset assembled tokens so previous word's state doesn't bleed in
    _scrambledTokens = []; // Reset scrambled tokens too

    if (_currentIndex >= _practiceQueue.length) return;
    final item = _practiceQueue[_currentIndex];

    if (item.activityFormat == ActivityFormat.multipleChoice ||
        item.activityFormat == ActivityFormat.imageMatching ||
        item.activityFormat == ActivityFormat.imageLabeling) {
      final distractors = item.distractors.isNotEmpty ? item.distractors : _resolveDistractors(_words.firstWhere((w) => w.wordId == item.wordId));
      
      // Ensure correct answer is a single word, not a sentence
      var correctAnswer = item.englishWord;
      if (correctAnswer.split(RegExp(r'\s+')).length > 2 || correctAnswer.contains('__') || correctAnswer.contains('.')) {
        correctAnswer = correctAnswer.split(RegExp(r'\s+'))[0].replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
        debugPrint('WARNING: Correct answer was sentence, using first word: $correctAnswer');
      }
      
      debugPrint('MC: correctAnswer="$correctAnswer", distractors=$distractors');
      _options = [correctAnswer, ...distractors];
      
      _options = _options.where((opt) {
        final wordCount = opt.trim().split(RegExp(r'\s+')).length;
        final isSentence = wordCount > 2 || opt.contains('__') || opt.contains('.');
        return !isSentence;
      }).toList();
      
      int targetCount = 3;
      final lvl = item.difficultyLevel?.toUpperCase() ?? 'LEARNING';
      if (lvl == 'LEARNING') {
        targetCount = 2;
      } else if (lvl == 'FAMILIAR') {
        targetCount = 3;
      } else if (lvl == 'PROFICIENT') {
        targetCount = 4;
      } else if (lvl == 'MASTERED') {
        targetCount = 5;
      }

      if (item.activityFormat.name.toLowerCase().contains('matching')) {
        targetCount = 3;
      }

      if (_options.length < targetCount) {
        final fallbacks = ['apple', 'house', 'water', 'friend', 'school', 'book', 'tree', 'happy', 'run', 'big', 'cat', 'dog'];
        final needed = targetCount - _options.length;
        final available = fallbacks.where((f) => !_options.contains(f)).toList()..shuffle();
        _options.addAll(available.take(needed));
      } else if (_options.length > targetCount) {
        final otherOptions = _options.where((o) => o.toLowerCase() != correctAnswer.toLowerCase()).toList();
        _options = [correctAnswer, ...otherOptions.take(targetCount - 1)];
      }

      // Safety: ensure correct answer is always in options
      if (!_options.any((o) => o.toLowerCase() == correctAnswer.toLowerCase())) {
        if (_options.length >= targetCount) _options.removeLast();
        _options.add(correctAnswer);
      }
      
      _options.shuffle(Random(item.wordId.hashCode));
      debugPrint('MC options before render: $_options (tier=$lvl, count=${_options.length})');
    } else if (item.activityFormat == ActivityFormat.fillInTheBlank) {
      final distractors = item.distractors.isNotEmpty ? item.distractors : _resolveDistractors(_words.firstWhere((w) => w.wordId == item.wordId));
      
      var correctOption = (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
          ? item.fitbAnswer!
          : item.englishWord;
      
      if (correctOption.split(RegExp(r'\s+')).length > 2 || correctOption.contains('__') || correctOption.contains('.')) {
        correctOption = item.englishWord;
      }
      
      debugPrint('FITB: correctAnswer="$correctOption", distractors=$distractors');
      _options = [correctOption, ...distractors];
      
      _options = _options.where((opt) {
        final wordCount = opt.trim().split(RegExp(r'\s+')).length;
        final isSentence = wordCount > 2 || opt.contains('__') || opt.contains('.');
        return !isSentence;
      }).toList();
      
      int targetCount = 3;
      final lvl = item.difficultyLevel?.toUpperCase() ?? 'LEARNING';
      if (lvl == 'LEARNING') {
        targetCount = 2;
      } else if (lvl == 'FAMILIAR') {
        targetCount = 3;
      } else if (lvl == 'PROFICIENT') {
        targetCount = 4;
      } else if (lvl == 'MASTERED') {
        targetCount = 5;
      }

      if (_options.length < targetCount) {
        final fallbacks = ['apple', 'house', 'water', 'friend', 'school', 'book', 'tree', 'happy', 'run', 'big', 'cat', 'dog'];
        final needed = targetCount - _options.length;
        final available = fallbacks.where((f) => !_options.contains(f)).toList()..shuffle();
        _options.addAll(available.take(needed));
      } else if (_options.length > targetCount) {
        final otherOptions = _options.where((o) => o.toLowerCase() != correctOption.toLowerCase()).toList();
        _options = [correctOption, ...otherOptions.take(targetCount - 1)];
      }

      // Safety: ensure correct answer is always in options
      if (!_options.any((o) => o.toLowerCase() == correctOption.toLowerCase())) {
        if (_options.length >= targetCount) _options.removeLast();
        _options.add(correctOption);
      }
      
      _options.shuffle(Random(item.wordId.hashCode));
      debugPrint('FITB options before render: $_options (tier=$lvl, count=${_options.length})');
    } else if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
      final matchingList = _resolveMatchingSet(item);
      _matchingCebuanoList = matchingList.map((entry) => (entry['cebuanoMeaning'] ?? '').toString()).where((value) => value.isNotEmpty).toList()..shuffle();
      _matchingEnglishList = matchingList.map((entry) => (entry['englishWord'] ?? '').toString()).where((value) => value.isNotEmpty).toList()..shuffle();
    } else if (item.activityFormat == ActivityFormat.rearrangement || item.activityFormat == ActivityFormat.wordScramble) {
      final tokens = item.sentenceArrangementTokens ?? [];
      if (tokens.isNotEmpty) {
        _scrambledTokens = List<String>.from(tokens)..shuffle(Random(item.wordId.hashCode));
      } else {
        if (item.activityFormat == ActivityFormat.rearrangement) {
          final sentence = (item.tileSentence?.trim().isNotEmpty ?? false) ? item.tileSentence!.trim() : item.exampleSentenceEnglish.trim();
          _scrambledTokens = sentence.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList()..shuffle(Random(item.wordId.hashCode));
        } else {
          final wordToScramble = item.englishWord.trim().toUpperCase();
          _scrambledTokens = wordToScramble.split('').toList()..shuffle(Random(item.wordId.hashCode));
        }
      }
      if (item.activityFormat == ActivityFormat.wordScramble && item.anchoredWord != null && item.anchoredWord!.contains(',')) {
        _assembledTokens = item.anchoredWord!.split(',');
      } else {
        _assembledTokens = [];
        if ((item.activityFormat == ActivityFormat.wordScramble || item.activityFormat == ActivityFormat.rearrangement) &&
            item.anchoredWord != null &&
            item.anchoredWord!.isNotEmpty) {
          _assembledTokens.add(item.anchoredWord!);
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
    );
    await LocalStorageService.saveReinforcementQueue(widget.sessionId, _reinforcementQueue);
  }

  String _getMascotName() {
    // Alternate mascots based on index
    final names = ['Bibo', 'Toti', 'Sippy', 'Starry'];
    return names[_currentIndex % names.length];
  }

  String _getInstructionText(ActivityFormat format) {
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
    }
  }

  String? _getHintTextForActivity(PracticeItemModel item) {
    // Explicitly exclude matching/pairing activities
    if (item.activityFormat == ActivityFormat.matching ||
        item.activityFormat == ActivityFormat.translationMatching ||
        item.activityFormat == ActivityFormat.imageMatching) {
      return null;
    }

    final isLearning = (item.difficultyLevel?.toUpperCase() ?? 'LEARNING') == 'LEARNING' || item.showHint;
    if (!isLearning) return null;

    // 1. If explicit hintText or explanation is provided
    if (item.hintText != null && item.hintText!.trim().isNotEmpty) {
      final trimmed = item.hintText!.trim();
      if (item.activityFormat == ActivityFormat.fillInTheBlank ||
          item.activityFormat == ActivityFormat.listeningTyping) {
        if (!trimmed.toLowerCase().startsWith('cebuano:') && item.cebuanoMeaning.isNotEmpty) {
          return 'Cebuano: ${item.cebuanoMeaning}';
        }
      }
      return trimmed;
    }

    // 2. Fallback based on activity format
    if (item.cebuanoMeaning.isNotEmpty) {
      return 'Cebuano: ${item.cebuanoMeaning}';
    }
    return null;
  }

  String _getListeningTypingAudioText(PracticeItemModel item) {
    final lvl = item.difficultyLevel?.toUpperCase() ?? 'LEARNING';
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
    final wordsList = clean.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).toList();
    int targetIndex = wordsList.indexWhere((w) => w.toLowerCase().contains(word.toLowerCase()));
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
    // Dedupe guard: prevent double-tap or state-listener re-entry from firing twice
    if (_submittingAnswer || _checked) return;
    _submittingAnswer = true;

    final item = _practiceQueue[_currentIndex];

    // Validate that an answer has actually been provided before submitting
    if (item.activityFormat == ActivityFormat.multipleChoice ||
        (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isNotEmpty) ||
        item.activityFormat == ActivityFormat.imageMatching ||
        item.activityFormat == ActivityFormat.imageLabeling) {
      if (_selectedOptionIndex == -1 || _selectedOptionIndex < 0 || _selectedOptionIndex >= _options.length) {
        _submittingAnswer = false;
        return;
      }
    } else if (item.activityFormat == ActivityFormat.trueOrFalse) {
      if (_selectedOptionIndex != 0 && _selectedOptionIndex != 1) {
        _submittingAnswer = false;
        return;
      }
    } else if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
      if (_matchingCebuanoList.isEmpty || _currentMatches.length < _matchingCebuanoList.length) {
        _submittingAnswer = false;
        return;
      }
    } else if (item.activityFormat == ActivityFormat.listeningTyping ||
               (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isEmpty)) {
      if (_typingController.text.trim().isEmpty) {
        _submittingAnswer = false;
        return;
      }
    } else if (item.activityFormat == ActivityFormat.flashcardRecall) {
      if (!_flashcardFlipped) {
        _submittingAnswer = false;
        return;
      }
    } else if (item.activityFormat == ActivityFormat.rearrangement ||
               item.activityFormat == ActivityFormat.wordScramble) {
      if (_assembledTokens.isEmpty) {
        _submittingAnswer = false;
        return;
      }
    }

    bool correct = false;
    String learnerAns = '';
    String correctAns = item.englishWord;

    if (item.activityFormat == ActivityFormat.multipleChoice ||
        (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isNotEmpty) ||
        item.activityFormat == ActivityFormat.imageMatching ||
        item.activityFormat == ActivityFormat.imageLabeling) {
      learnerAns = _options[_selectedOptionIndex];
      
      // For fill-in-the-blank, use the same logic as option building
      String fitbCorrect = item.englishWord;
      if (item.activityFormat == ActivityFormat.fillInTheBlank) {
        fitbCorrect = (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
            ? item.fitbAnswer!
            : item.englishWord;
        
        // If backend sent a sentence, use target word instead (same logic as option building)
        if (fitbCorrect.split(RegExp(r'\s+')).length > 2 || 
            fitbCorrect.contains('__') || 
            fitbCorrect.contains('.')) {
          fitbCorrect = item.englishWord;
          debugPrint('FITB check: backend sent sentence, using target word for comparison: $fitbCorrect');
        }
      }
      
      debugPrint('FITB check: selected="$learnerAns", comparing against="$fitbCorrect"');
      correct = (learnerAns.toLowerCase() == fitbCorrect.toLowerCase());
      correctAns = fitbCorrect;
    } else if (item.activityFormat == ActivityFormat.listeningTyping) {
      learnerAns = _typingController.text.trim();
      final fitbAns = (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty && item.fitbAnswer!.trim().split(RegExp(r'\s+')).length == 1)
          ? item.fitbAnswer!.trim()
          : item.englishWord.trim();
      final correctTarget = fitbAns;

      String cleanCompare(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');
      final cleanLearner = cleanCompare(learnerAns);
      final cleanCorrect = cleanCompare(correctTarget);

      final dist = _levenshtein(cleanLearner, cleanCorrect);
      // Case-insensitive exact match or 1-character typo tolerance for words >= 4 chars
      correct = (cleanLearner == cleanCorrect) || (cleanCorrect.length >= 4 && dist <= 1);
      correctAns = correctTarget;
    } else if (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isEmpty) {
      learnerAns = _typingController.text.trim();
      // Use single-word target for comparison. If fitbAnswer is multi-word, fall back to englishWord.
      String correctTarget = (item.fitbAnswer ?? '').trim();
      if (correctTarget.isEmpty) correctTarget = item.englishWord.trim();
      final tokens = correctTarget.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).toList();
      if (tokens.length > 1) {
        // prefer the canonical vocabulary word when fitbAnswer is a sentence
        correctTarget = item.englishWord.trim();
      }
      correct = learnerAns.toLowerCase() == correctTarget.toLowerCase();
      correctAns = correctTarget;
    } else if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
      // For Matching, targetCorrect checks if the MAIN word is matched correctly.
      bool targetCorrect = false;
      _currentMatches.forEach((ceb, eng) {
        if (ceb.toLowerCase() == item.cebuanoMeaning.toLowerCase() && eng.toLowerCase() == item.englishWord.toLowerCase()) {
          targetCorrect = true;
        }
      });
      
      // Also ensure all other matched pairs are indeed correct translations
      bool othersCorrect = true;
      _currentMatches.forEach((ceb, eng) {
        final actualWordObj = _words.firstWhere(
          (w) => w.cebuanoMeaning.toLowerCase() == ceb.toLowerCase(),
          orElse: () => VocabularyWordModel(
            wordId: '', lessonId: '', englishWord: '', cebuanoMeaning: '', exampleSentenceEnglish: '', gradeLevel: '', wordOrder: 0, isConfusablePairMember: false,
          ),
        );
        if (actualWordObj.englishWord.isNotEmpty && actualWordObj.englishWord.toLowerCase() != eng.toLowerCase()) {
          othersCorrect = false;
        }
      });

      // The user must have made ALL the matches in the set for it to be fully correct
      bool matchesCountCorrect = _currentMatches.length == (item.matchingSet?.length ?? 0);
      if (item.matchingSet == null || item.matchingSet!.isEmpty) {
        matchesCountCorrect = true; // Fallback if missing
      }

      correct = targetCorrect && othersCorrect && matchesCountCorrect;
      learnerAns = _currentMatches.toString();
      
      // Build a nice string of the correct pairs for the feedback UI (only the ones they got wrong)
      List<String> incorrectExpectedPairs = [];
      if (item.matchingSet != null && item.matchingSet!.isNotEmpty) {
        for (var pair in item.matchingSet!) {
          final expectedCeb = (pair['cebuanoMeaning'] ?? pair['cebuano'] ?? '').toString();
          final expectedEng = (pair['englishWord'] ?? pair['english'] ?? '').toString();
          bool isMatchedCorrectly = _currentMatches.entries.any((e) => 
            e.key.toLowerCase() == expectedCeb.toLowerCase() && 
            e.value.toLowerCase() == expectedEng.toLowerCase()
          );
          if (!isMatchedCorrectly) {
            incorrectExpectedPairs.add('$expectedCeb = $expectedEng');
          }
        }
      } else {
        bool isMatchedCorrectly = _currentMatches.entries.any((e) => 
          e.key.toLowerCase() == item.cebuanoMeaning.toLowerCase() && 
          e.value.toLowerCase() == item.englishWord.toLowerCase()
        );
        if (!isMatchedCorrectly) {
          incorrectExpectedPairs.add('${item.cebuanoMeaning} = ${item.englishWord}');
        }
      }
      
      if (incorrectExpectedPairs.isNotEmpty) {
        correctAns = incorrectExpectedPairs.join(', ');
      } else {
        correctAns = 'All pairs correctly matched';
      }

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
    } else if (item.activityFormat == ActivityFormat.rearrangement || item.activityFormat == ActivityFormat.wordScramble) {
      final String rawTarget = (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
          ? item.fitbAnswer!
          : (item.activityFormat == ActivityFormat.wordScramble ? item.englishWord : item.exampleSentenceEnglish);

      final List<String> targetTokens = item.activityFormat == ActivityFormat.wordScramble
          ? rawTarget.split('') 
          : rawTarget.split(RegExp(r'\s+')); 

      String normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final targetNormalized = targetTokens.map(normalize).where((t) => t.isNotEmpty).toList();
      final assembledNormalized = _assembledTokens.map(normalize).where((t) => t.isNotEmpty).toList();

      if (targetNormalized.isEmpty) {
        correct = false;
      } else if (item.activityFormat == ActivityFormat.wordScramble) {
        correct = assembledNormalized.join('') == targetNormalized.join('');
      } else {
        correct = assembledNormalized.join(' ') == targetNormalized.join(' ');
      }

      final separator = item.activityFormat == ActivityFormat.wordScramble ? '' : ' ';
      learnerAns = _assembledTokens.join(separator);
      correctAns = targetTokens.join(separator);
    }

    // Save practice result log
    _lastTestedFormatByWord[item.wordId] = item.activityFormat;
    final result = PracticeEvaluationResult(
      wordId: item.wordId,
      activityFormat: item.activityFormat,
      learnerResponse: learnerAns,
      correctAnswer: correctAns,
      isCorrect: correct,
      evaluatedAt: DateTime.now(),
      isReinforcementAttempt: (_wordWrongAttempts[item.wordId] ?? 0) > 0 ? 1 : 0,
    );
    final provider = Provider.of<LessonProvider>(context, listen: false);

    debugPrint('CHECK_ANS item=${item.wordId} format=${item.activityFormat} assembled=${_assembledTokens.join(' ')} target="$correctAns" normalizedCorrect=$correct');
    _questionTimer?.cancel();
    await LocalStorageService.saveEvaluationResult(widget.sessionId, result);

    if (!widget.isSandbox) {
      final formatName = _formatToApiString(item.activityFormat, item: item);
      Future<void> processSubmission(String tWordId, bool isCorrect) async {
        final submitResp = await provider.submitRetrievalAnswer(
          widget.sessionId,
          tWordId,
          isCorrect,
          wrongAnswer: isCorrect ? null : learnerAns,
          activityFormat: formatName,
        );
        if (submitResp != null) {
          final newLevel = submitResp['currentLevel']?.toString() ?? '';
          final leveledUp = submitResp['leveledUp'] == true;
          if (newLevel.isNotEmpty) {
            _wordDifficulties[tWordId] = newLevel;
            
            // Update max tier points for consistent progress (never decreases)
            int newPoints = 0;
            switch (newLevel.toUpperCase()) {
              case 'MASTERED': newPoints = 3; break;
              case 'PROFICIENT': newPoints = 2; break;
              case 'FAMILIAR': newPoints = 1; break;
              default: newPoints = 0; break;
            }
            _maxWordTierPoints[tWordId] = _maxWordTierPoints[tWordId] != null 
                ? max(_maxWordTierPoints[tWordId]!, newPoints)
                : newPoints;
            
            debugPrint('PROGRESS_UPDATE: word=$tWordId to $newLevel (leveledUp=$leveledUp)');
            
            if (newLevel.toUpperCase() == 'MASTERED') {
              _practiceQueue.removeWhere((qItem) => 
                 qItem.wordId == tWordId && _practiceQueue.indexOf(qItem) > _currentIndex
              );
              _plannedScreens = _practiceQueue.length;
            } else {
              for (int i = _currentIndex + 1; i < _practiceQueue.length; i++) {
                if (_practiceQueue[i].wordId == tWordId) {
                  try {
                    final q = await provider.loadSingleRetrievalQuestion(widget.sessionId, tWordId);
                    if (q != null) {
                      ActivityFormat newFormat = _practiceQueue[i].activityFormat;
                      final formatStr = q['activityFormat'] as String?;
                      if (formatStr != null) {
                        newFormat = _parseFormatString(formatStr);
                      }
                      final isLearningItem = (q['difficultyLevel'] as String? ?? newLevel).toUpperCase() == 'LEARNING';
                      final showHintItem = q['showHints'] == true || q['showHint'] == true || q['showExplanation'] == true || q['showExplanations'] == true || isLearningItem;
                      final hintTextItem = q['explanationText'] as String? ?? q['explanation'] as String? ?? q['hintText'] as String? ?? q['cebuanoMeaning'] as String?;

                      _practiceQueue[i] = PracticeItemModel(
                        wordId: _practiceQueue[i].wordId,
                        englishWord: q['englishWord'] ?? _practiceQueue[i].englishWord,
                        displayWord: q['displayWord'] as String? ?? _practiceQueue[i].displayWord,
                        cebuanoMeaning: q['cebuanoMeaning'] ?? _practiceQueue[i].cebuanoMeaning,
                        exampleSentenceEnglish: q['exampleSentenceEnglish'] ?? _practiceQueue[i].exampleSentenceEnglish,
                        exampleSentenceCebuano: _practiceQueue[i].exampleSentenceCebuano,
                        activityFormat: newFormat,
                        eligibleActivityTypes: _practiceQueue[i].eligibleActivityTypes,
                        difficultyLevel: q['difficultyLevel'] ?? newLevel,
                        timeLimitSeconds: q['timeLimitSeconds'] as int?,
                        showHint: showHintItem,
                        hintText: hintTextItem,
                        imageAssetPath: q['imageAssetPath'] ?? _practiceQueue[i].imageAssetPath,
                        distractors: (q['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? _practiceQueue[i].distractors,
                        fitbSentence: q['fitbSentence'] as String? ?? _practiceQueue[i].fitbSentence,
                        fitbAnswer: (newFormat == ActivityFormat.trueOrFalse)
                            ? (q['correctAnswer']?.toString() ?? 'True')
                            : (q['fitbAnswer'] as String? ?? _practiceQueue[i].fitbAnswer),
                        matchingSet: (q['matchingPairs'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? _practiceQueue[i].matchingSet,
                        sentenceArrangementTokens: (q['sentenceArrangementTokens'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? _practiceQueue[i].sentenceArrangementTokens,
                        anchoredWord: q['anchoredWord'] as String? ?? _practiceQueue[i].anchoredWord,
                      );
                    }
                  } catch (e) {
                    debugPrint('LEVEL_SYNC: failed to refresh queue item $i: $e');
                  }
                }
              }
            }
          }
        }
      }

      if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
        // Universal Matching rule: evaluate EACH word's own correctness independently!
        bool targetCorrect = _currentMatches.entries.any((e) =>
          e.key.toLowerCase() == item.cebuanoMeaning.toLowerCase() &&
          e.value.toLowerCase() == item.englishWord.toLowerCase()
        );
        await processSubmission(item.wordId, targetCorrect);

        // Submit for all extra words in the matching set independently so each tracks its own tier/streak
        if (item.matchingSet != null && item.matchingSet!.isNotEmpty) {
          for (var pair in item.matchingSet!) {
            final expectedWordId = (pair['wordId'] ?? '').toString();
            if (expectedWordId.isNotEmpty && expectedWordId != item.wordId) {
              final expectedCeb = (pair['cebuanoMeaning'] ?? pair['cebuano'] ?? '').toString();
              final expectedEng = (pair['englishWord'] ?? pair['english'] ?? '').toString();
              bool isMatchedCorrectly = _currentMatches.entries.any((e) => 
                e.key.toLowerCase() == expectedCeb.toLowerCase() && 
                e.value.toLowerCase() == expectedEng.toLowerCase()
              );
              await processSubmission(expectedWordId, isMatchedCorrectly);
            }
          }
        }
      } else {
        await processSubmission(item.wordId, correct);
      }
    }

    if (correct) {
      if ((_wordWrongAttempts[item.wordId] ?? 0) > 0) {
        _reinforcementPassCorrectCount++;
      } else {
        _initialPassCorrectCount++;
      }
    } else {
      _wordWrongAttempts[item.wordId] = (_wordWrongAttempts[item.wordId] ?? 0) + 1;
    }

    setState(() {
      _checked = true;
      _isAnswerCorrect = correct;
      _showFeedback = true;
    });

    if (!correct && (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching)) {
      List<String> incorrectExpectedPairs = [];
      if (item.matchingSet != null && item.matchingSet!.isNotEmpty) {
        for (var pair in item.matchingSet!) {
          final expectedCeb = (pair['cebuanoMeaning'] ?? pair['cebuano'] ?? '').toString();
          final expectedEng = (pair['englishWord'] ?? pair['english'] ?? '').toString();
          bool isMatchedCorrectly = _currentMatches.entries.any((e) => 
            e.key.toLowerCase() == expectedCeb.toLowerCase() && 
            e.value.toLowerCase() == expectedEng.toLowerCase()
          );
          if (!isMatchedCorrectly) {
            incorrectExpectedPairs.add('$expectedCeb = $expectedEng');
          }
        }
      } else {
        bool isMatchedCorrectly = _currentMatches.entries.any((e) => 
          e.key.toLowerCase() == item.cebuanoMeaning.toLowerCase() && 
          e.value.toLowerCase() == item.englishWord.toLowerCase()
        );
        if (!isMatchedCorrectly) {
          incorrectExpectedPairs.add('${item.cebuanoMeaning} = ${item.englishWord}');
        }
      }
      
      if (!mounted) return;
      final mismatchedInfo = incorrectExpectedPairs.join('\n');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Incorrect Pairs', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'The correct pairs are:\n\n$mismatchedInfo',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _advanceNext() async {
    debugPrint('Continue button tapped, currentIndex: $_currentIndex, queueLength: ${_practiceQueue.length}');
    
    // Bounds check to prevent RangeError
    if (_currentIndex >= _practiceQueue.length) {
      debugPrint('Index out of bounds, transitioning to next phase');
      await _completeModuleAndAdvance();
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
        await provider.updateWordProgress(widget.sessionId, item.wordId, 'FULL', 0, 'NEEDS_PRONUNCIATION_REVIEW');
      }

      // Continuous Reinforcement: generate a varied format exercise for the failed word and append to queue
      final nextFormat1 = (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching)
          ? item.activityFormat
          : _pickAlternativeFormat(item.wordId, item.activityFormat);

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

      final cleanFitbSentence = isInstructionText(item.fitbSentence) ||
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
      
      final failedItem1 = _createPracticeItem(wordModel, nextFormat1);
      _practiceQueue.add(failedItem1);
      _plannedScreens++;

      // Tier-weighted resurfacing: words in LEARNING surface again with another alternate format
      final tierStr = (item.difficultyLevel ?? 'LEARNING').toUpperCase();
      if (tierStr == 'LEARNING' && item.activityFormat != ActivityFormat.matching) {
        final nextFormat2 = _pickAlternativeFormat(item.wordId, nextFormat1);
        final failedItem2 = _createPracticeItem(wordModel, nextFormat2);
        _practiceQueue.add(failedItem2);
        _plannedScreens++;
      }

      if ((_wordWrongAttempts[item.wordId] ?? 0) >= 2 && tierStr == 'LEARNING' && mounted) {
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
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
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
            content: Text('"${item.englishWord}" will be reviewed again in this session.'),
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
      // Strict rule: Module 2 must keep practicing until ALL words in this lesson path reach MASTERED!
      final unmasteredWords = _words.where((w) {
        final lvl = _wordDifficulties[w.wordId]?.toUpperCase() ?? '';
        return lvl != 'MASTERED';
      }).toList();

      if (unmasteredWords.isNotEmpty && !widget.isSandbox) {
        debugPrint('Active Practice: ${unmasteredWords.length} words not yet MASTERED (${unmasteredWords.map((w) => "${w.englishWord}:${_wordDifficulties[w.wordId] ?? 'LEARNING'}").join(', ')}). Generating adaptive practice questions...');
        if (!mounted) return;
        final provider = Provider.of<LessonProvider>(context, listen: false);
        for (final uWord in unmasteredWords) {
          try {
            final lastFormat = _lastTestedFormatByWord[uWord.wordId] ?? ActivityFormat.multipleChoice;
            final altFormat = _pickAlternativeFormat(uWord.wordId, lastFormat);
            final formatStr = _formatToApiString(altFormat);
            final q = await provider.loadSingleRetrievalQuestion(widget.sessionId, uWord.wordId, format: formatStr);
            if (q != null) {
              final newItem = _buildPracticeItemFromQuestion(q);
              newItem.activityFormat = altFormat;
              _practiceQueue.add(newItem);
              _plannedScreens++;
            }
          } catch (e) {
            debugPrint('Failed to load adaptive question for word ${uWord.wordId}: $e');
          }
        }

        if (_currentIndex < _practiceQueue.length) {
          await _saveCurrentState();
          await _fetchAndLoadCurrentItem();
          return;
        }
      }

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
    final uniqueWordCount = _practiceQueue.map((p) => p.wordId).toSet().length;
    final denom = uniqueWordCount == 0 ? 1 : uniqueWordCount;
    var moduleScore = ( _scorePoints / denom ) * 100.0;
    if (moduleScore.isNaN || moduleScore.isInfinite) moduleScore = 0.0;
    if (!mounted) return;
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final total = _practiceQueue.length;
    final int activeSeconds = _computeActiveSeconds();
    try {
      await lessonProvider.persistModuleScore(
        widget.lessonId,
        widget.isSandbox ? null : 2,
        _initialPassCorrectCount,
        total,
        isSandbox: widget.isSandbox,
        sessionId: widget.sessionId,
        timeSeconds: activeSeconds,
      );
    } catch (e) {
      debugPrint('Module 2 score sync failed, continuing anyway: $e');
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

    if (!mounted) return;
    debugPrint('Practice session complete! Navigating to Module 3 (Sentence Building)...');
    context.push(
      '/loading',
      extra: {
        'duration': 13000,
        'redirectPath': '/session/${widget.sessionId}/sentence-building',
        'lessonId': widget.lessonId,
        'categoryId': widget.categoryId,
        'lessonTitle': widget.lessonTitle,
        'allWords': widget.allWords,
        'isSandbox': widget.isSandbox,
      },
    );
  }

  // --- UI Builders ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pref = Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
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
    
    double totalTierPoints = 0.0;
    for (final w in _words) {
      // Use max tier points reached for consistent progress (never decreases)
      final maxPoints = _maxWordTierPoints[w.wordId] ?? 0;
      if (maxPoints > 0) {
        totalTierPoints += maxPoints.toDouble();
      } else {
        // Fallback to current tier if no max recorded yet
        final tier = (_wordDifficulties[w.wordId] ?? 'LEARNING').toUpperCase();
        switch (tier) {
          case 'MASTERED':
            totalTierPoints += 3.0;
            break;
          case 'PROFICIENT':
            totalTierPoints += 2.0;
            break;
          case 'FAMILIAR':
            totalTierPoints += 1.0;
            break;
          default:
            totalTierPoints += 0.0;
            break;
        }
      }
    }

    final maxTierPoints = _words.length * 3.0;
    final progressVal = _progressOverride ?? (maxTierPoints > 0 ? (totalTierPoints / maxTierPoints).clamp(0.0, 1.0) : 0.0);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)), // Yellow progress
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
                      speechText: item.activityFormat == ActivityFormat.listeningTyping
                        ? _getInstructionText(item.activityFormat)
                        : _getInstructionText(item.activityFormat),
                      ttsText: item.activityFormat == ActivityFormat.listeningTyping
                        ? _getInstructionText(item.activityFormat)
                        : null,
                      isSad: _checked && !_isAnswerCorrect,
                      isCelebrating: _checked && _isAnswerCorrect,
                    ),
                    const SizedBox(height: 16),
                    () {
                      // Do not show hint for matching/pairing activities
                      if (item.activityFormat == ActivityFormat.matching ||
                          item.activityFormat == ActivityFormat.translationMatching ||
                          item.activityFormat == ActivityFormat.imageMatching) {
                        return const SizedBox.shrink();
                      }
                      final hintText = _getHintTextForActivity(item);
                      if (hintText == null || hintText.trim().isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF4FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE879F9), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD946EF).withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0ABFC).withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFC026D3), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'LEARNING HINT',
                                        style: TextStyle(
                                          color: Color(0xFFC026D3),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hintText,
                                        style: const TextStyle(
                                          color: Color(0xFF86198F),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }(),
                    if (item.timeLimitSeconds != null && item.timeLimitSeconds! > 0 && !_checked) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Time Remaining:',
                                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  '${_secondsRemaining}s',
                                  style: TextStyle(
                                    color: _secondsRemaining <= 5 ? Colors.redAccent : const Color(0xFF06A6FF),
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
                                value: item.timeLimitSeconds! > 0 ? (_secondsRemaining / item.timeLimitSeconds!) : 0.0,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _secondsRemaining <= 5 ? Colors.redAccent : const Color(0xFF06A6FF),
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
                    
                    // Level indicator dot
                    () {
                      final lvl = item.difficultyLevel?.toUpperCase() ?? 'LEARNING';
                      Color dotColor;
                      String label;
                      switch (lvl) {
                        case 'FAMILIAR':
                          dotColor = const Color(0xFF3B82F6); // blue
                          label = 'Familiar';
                          break;
                        case 'PROFICIENT':
                        case 'MASTERED':
                          dotColor = const Color(0xFFF59E0B); // amber
                          label = 'Proficient';
                          break;
                        default:
                          dotColor = const Color(0xFF94A3B8); // slate
                          label = 'Learning';
                      }
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
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
                              const SizedBox(width: 5),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: dotColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }(),
                    
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

  Widget _buildActivityBody(PracticeItemModel item) {
    switch (item.activityFormat) {
      case ActivityFormat.multipleChoice:
        return _buildMultipleChoice(item);
      case ActivityFormat.imageMatching:
        return _buildImageMatching(item);
      case ActivityFormat.imageLabeling:
        return _buildImageLabeling(item);
      case ActivityFormat.trueOrFalse:
        return _buildTrueOrFalse(item);
      case ActivityFormat.wordScramble:
        return _buildWordScramble(item);
      case ActivityFormat.rearrangement:
        return _buildRearrangement(item);
      case ActivityFormat.matching:
      case ActivityFormat.translationMatching:
        return _buildMatching(item);
      case ActivityFormat.fillInTheBlank:
        return _buildFillInTheBlank(item);
      case ActivityFormat.listeningTyping:
        return _buildListeningTyping(item);
      case ActivityFormat.flashcardRecall:
        return _buildFlashcardRecall(item);
    }
  }

  Widget _buildWordScramble(PracticeItemModel item) {
    // Dedicated Word Scramble UI — letter tiles, not word tiles.
    // LEARNING: first letter anchored (pre-placed), Cebuano meaning shown as guide
    // FAMILIAR: all letters scrambled, no pre-placed anchor
    // PROFICIENT: all letters + 2 fake letters
    // MASTERED: all letters + 3 fake letters
    final level = (item.difficultyLevel ?? 'LEARNING').toUpperCase();
    final isLearning = level == 'LEARNING';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Context guide — always show cebuano meaning for Word Scramble
        if (item.cebuanoMeaning.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
            ),
            child: Text(
              'Cebuano: ${item.cebuanoMeaning}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: _assembledTokens.isEmpty
                    ? const Center(
                        child: Text(
                          'Tap letters below to spell the word',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _assembledTokens.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final letter = entry.value;
                          
                          final bool isNewFormat = item.anchoredWord != null && item.anchoredWord!.contains(',');
                          final bool isAnchored = isNewFormat 
                              ? item.anchoredWord!.split(',')[idx] != '_' 
                              : (isLearning && idx == 0 && item.anchoredWord != null);
                              
                          return GestureDetector(
                            onTap: (isAnchored || _checked || letter == '_') ? null : () {
                              setState(() {
                                if (isNewFormat) {
                                  _assembledTokens[idx] = '_';
                                  _scrambledTokens.add(letter);
                                } else {
                                  _assembledTokens.removeAt(idx);
                                  _scrambledTokens.add(letter);
                                }
                              });
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: letter == '_' 
                                    ? Colors.transparent 
                                    : (isAnchored ? const Color(0xFFDDD6FE) : const Color(0xFF6366F1)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: letter == '_' 
                                      ? const Color(0xFFCBD5E1) 
                                      : (isAnchored ? const Color(0xFF7C3AED) : const Color(0xFF4338CA)),
                                  width: letter == '_' ? 1.5 : 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  letter == '_' ? '' : letter,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isAnchored ? const Color(0xFF5B21B6) : Colors.white,
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
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        // Scrambled letter tiles
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scrambledTokens.map((letter) {
            return GestureDetector(
              onTap: _checked ? null : () {
                setState(() {
                  if (item.anchoredWord != null && item.anchoredWord!.contains(',')) {
                    final emptyIdx = _assembledTokens.indexOf('_');
                    if (emptyIdx != -1) {
                      _assembledTokens[emptyIdx] = letter;
                      _scrambledTokens.remove(letter);
                    }
                  } else {
                    _scrambledTokens.remove(letter);
                    _assembledTokens.add(letter);
                  }
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

  // 4. Image-to-Word Matching Widget
  Widget _buildImageMatching(PracticeItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.cebuanoMeaning.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
              ),
              child: Text(
                'Cebuano: ${item.cebuanoMeaning}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
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

  Widget _buildImageLabeling(PracticeItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.cebuanoMeaning.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
              ),
              child: Text(
                'Cebuano: ${item.cebuanoMeaning}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
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
    final isTrueSelected = _selectedOptionIndex == 0;
    final isFalseSelected = _selectedOptionIndex == 1;
    final bool isActuallyTrue = (item.fitbAnswer ?? 'True').trim().toLowerCase() == 'true';

    // Colors for TRUE button
    Color trueCardBg = Colors.white;
    Color trueBorderColor = const Color(0xFFBBF7D0); // Light green border
    Color trueTextColor = const Color(0xFF15803D); // Green text
    Color trueIconColor = const Color(0xFF16A34A);
    List<BoxShadow> trueShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];

    if (_checked) {
      if (isActuallyTrue) {
        // Correct answer is TRUE
        trueCardBg = isTrueSelected ? const Color(0xFF16A34A) : const Color(0xFFDCFCE7);
        trueBorderColor = const Color(0xFF16A34A);
        trueTextColor = isTrueSelected ? Colors.white : const Color(0xFF15803D);
        trueIconColor = isTrueSelected ? Colors.white : const Color(0xFF16A34A);
      } else if (isTrueSelected) {
        // User chose TRUE but correct was FALSE (Mistake)
        trueCardBg = const Color(0xFFDC2626);
        trueBorderColor = const Color(0xFFDC2626);
        trueTextColor = Colors.white;
        trueIconColor = Colors.white;
      } else {
        trueCardBg = const Color(0xFFF8FAFC);
        trueBorderColor = const Color(0xFFE2E8F0);
        trueTextColor = const Color(0xFF94A3B8);
        trueIconColor = const Color(0xFF94A3B8);
      }
    } else if (isTrueSelected) {
      trueCardBg = const Color(0xFF16A34A);
      trueBorderColor = const Color(0xFF16A34A);
      trueTextColor = Colors.white;
      trueIconColor = Colors.white;
      trueShadows = [
        BoxShadow(
          color: const Color(0xFF16A34A).withValues(alpha: 0.35),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }

    // Colors for FALSE button
    Color falseCardBg = Colors.white;
    Color falseBorderColor = const Color(0xFFFECDD3); // Light red border
    Color falseTextColor = const Color(0xFFBE123C); // Red text
    Color falseIconColor = const Color(0xFFE11D48);
    List<BoxShadow> falseShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];

    if (_checked) {
      if (!isActuallyTrue) {
        // Correct answer is FALSE
        falseCardBg = isFalseSelected ? const Color(0xFF16A34A) : const Color(0xFFDCFCE7);
        falseBorderColor = const Color(0xFF16A34A);
        falseTextColor = isFalseSelected ? Colors.white : const Color(0xFF15803D);
        falseIconColor = isFalseSelected ? Colors.white : const Color(0xFF16A34A);
      } else if (isFalseSelected) {
        // User chose FALSE but correct was TRUE (Mistake)
        falseCardBg = const Color(0xFFDC2626);
        falseBorderColor = const Color(0xFFDC2626);
        falseTextColor = Colors.white;
        falseIconColor = Colors.white;
      } else {
        falseCardBg = const Color(0xFFF8FAFC);
        falseBorderColor = const Color(0xFFE2E8F0);
        falseTextColor = const Color(0xFF94A3B8);
        falseIconColor = const Color(0xFF94A3B8);
      }
    } else if (isFalseSelected) {
      falseCardBg = const Color(0xFFDC2626);
      falseBorderColor = const Color(0xFFDC2626);
      falseTextColor = Colors.white;
      falseIconColor = Colors.white;
      falseShadows = [
        BoxShadow(
          color: const Color(0xFFDC2626).withValues(alpha: 0.35),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }

    final englishWord = (item.displayWord != null && item.displayWord!.isNotEmpty)
        ? item.displayWord!
        : item.englishWord;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Comparison Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Optional Image Viewer
              if (item.imageAssetPath != null &&
                  item.imageAssetPath!.isNotEmpty &&
                  (item.imageAssetPath!.startsWith('http') || item.imageAssetPath!.startsWith('assets/')))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: CustomImageViewer(
                      imagePath: item.imageAssetPath!,
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              // English Word with Audio Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      englishWord,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: const Color(0xFFEFF6FF),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => TTSService.speakEnglish(englishWord),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Stylized translation divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1.5, endIndent: 10)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.swap_vert_rounded, color: Color(0xFF64748B), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'translation',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1.5, indent: 10)),
                  ],
                ),
              ),

              // Cebuano Word Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🇵🇭 ', style: TextStyle(fontSize: 20)),
                    Flexible(
                      child: CebuanoTextHighlighter(
                        text: item.cebuanoMeaning.isNotEmpty ? item.cebuanoMeaning : '(Cebuano meaning missing)',
                        highlightWord: item.cebuanoMeaning,
                        style: TextStyle(
                          fontSize: item.cebuanoMeaning.isNotEmpty ? 22 : 16,
                          fontWeight: FontWeight.w700,
                          color: item.cebuanoMeaning.isNotEmpty ? const Color(0xFF0369A1) : const Color(0xFFEF4444),
                          fontStyle: item.cebuanoMeaning.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tactile TRUE / FALSE Buttons
        Row(
          children: [
            // TRUE Button (Option 0)
            Expanded(
              child: GestureDetector(
                onTap: () => _selectMcOption(0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: trueCardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: trueBorderColor, width: 2),
                    boxShadow: trueShadows,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: trueIconColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LocalizationService.translate(pref, 'true').toUpperCase(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: trueTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // FALSE Button (Option 1)
            Expanded(
              child: GestureDetector(
                onTap: () => _selectMcOption(1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: falseCardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: falseBorderColor, width: 2),
                    boxShadow: falseShadows,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel_rounded,
                        color: falseIconColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LocalizationService.translate(pref, 'false').toUpperCase(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: falseTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
              if (item.imageAssetPath != null && item.imageAssetPath!.isNotEmpty && (item.imageAssetPath!.startsWith('http') || item.imageAssetPath!.startsWith('assets/')))
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
                      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🇵🇭 ', style: TextStyle(fontSize: 22)),
                  Flexible(
                    child: CebuanoTextHighlighter(
                      text: item.cebuanoMeaning.isNotEmpty ? item.cebuanoMeaning : '(Cebuano meaning missing from database)',
                      highlightWord: item.cebuanoMeaning,
                      style: TextStyle(
                        fontSize: item.cebuanoMeaning.isNotEmpty ? 28 : 16,
                        fontWeight: FontWeight.bold,
                        color: item.cebuanoMeaning.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFFEF4444),
                        fontStyle: item.cebuanoMeaning.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
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
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
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
                    cardBorderColor = _pairColors[matchIndex % _pairColors.length];
                    cardBgColor = cardBorderColor.withValues(alpha: 0.08);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () => _tapCebuanoMatch(ceb),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorderColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CebuanoTextHighlighter(
                                text: ceb,
                                highlightWord: item.cebuanoMeaning,
                                style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                                enableUnderline: false,
                              ),
                            ),
                            if (isMatched)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _pairColors[matchIndex % _pairColors.length],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Pair ${matchIndex + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                    cardBorderColor = _pairColors[matchIndex % _pairColors.length];
                    cardBgColor = cardBorderColor.withValues(alpha: 0.08);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () => _tapEnglishMatch(eng),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                                style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                              ),
                            ),
                            if (isMatched)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _pairColors[matchIndex % _pairColors.length],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Pair ${matchIndex + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
    final target = (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
        ? item.fitbAnswer!
        : item.englishWord;
    final hasFitbSentence = item.fitbSentence != null && item.fitbSentence!.trim().isNotEmpty;
    final rawSentence = hasFitbSentence ? item.fitbSentence! : item.exampleSentenceEnglish;

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
        if (_selectedOptionIndex >= 0 && _selectedOptionIndex < _options.length) {
          blankText = _options[_selectedOptionIndex];
        } else {
          blankText = '_______';
        }
        blankColor = const Color(0xFF3B82F6);
        blankBgColor = const Color(0xFFEFF6FF);
      }

      if (_checked) {
        if (_selectedOptionIndex >= 0 && _selectedOptionIndex < _options.length) {
          final selectedOption = _options[_selectedOptionIndex];
          String targetForColor = target;
          if (targetForColor.split(RegExp(r'\s+')).length > 2 || 
              targetForColor.contains('__') || 
              targetForColor.contains('.')) {
            targetForColor = item.englishWord;
          }
          final isCorrect = selectedOption.toLowerCase() == targetForColor.toLowerCase();
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
        final isCorrect = typedText.toLowerCase() == targetForColor.toLowerCase();
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
                      style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        color: blankColor == const Color(0xFF94A3B8) ? const Color(0xFF64748B) : blankColor,
                      ),
                    ),
                  ),
                  if (parts.length > 1)
                    Text(
                      parts[1],
                      style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    ),
                ],
              ),
              if (item.exampleSentenceCebuano != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🇵🇭 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: CebuanoTextHighlighter(
                        text: item.exampleSentenceCebuano!,
                        highlightWord: item.cebuanoMeaning,
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                      ),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
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
                  backgroundColor: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Text(item.englishWord, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  if (_flashcardFlipped) ...[
                    CebuanoTextHighlighter(
                      text: item.cebuanoMeaning,
                      highlightWord: item.cebuanoMeaning,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.45),
                    ),
                    const SizedBox(height: 8),
                    Text(item.exampleSentenceEnglish, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
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

  Widget _buildRearrangement(PracticeItemModel item) {
    // English prompt intentionally hidden for this activity; show Bisaya only.
    final bisayaGuide = (item.exampleSentenceCebuano?.trim().isNotEmpty ?? false)
      ? item.exampleSentenceCebuano!.trim()
      : item.cebuanoMeaning.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bisayaGuide.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('🇵🇭 ', style: TextStyle(fontSize: 18)),
                    Text(
                      item.activityFormat == ActivityFormat.wordScramble
                          ? LocalizationService.translate(pref, 'word_guide')
                          : LocalizationService.translate(pref, 'sentence_guide'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                CebuanoTextHighlighter(
                  text: bisayaGuide,
                  highlightWord: item.cebuanoMeaning,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0C4A6E), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
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
              Text(
                item.activityFormat == ActivityFormat.wordScramble ? 'Assembled Word' : 'Assembled Sentence',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _assembledTokens.isEmpty
                      ? [Text(item.activityFormat == ActivityFormat.wordScramble ? 'Tap letters below to build the word' : 'Tap words below to build the sentence', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14))]
                      : _assembledTokens.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final token = entry.value;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _assembledTokens.removeAt(idx);
                                _scrambledTokens.add(token);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                token,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
          'Available Words',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scrambledTokens.map((token) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _scrambledTokens.remove(token);
                  _assembledTokens.add(token);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Text(
                  token,
                  style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListeningTyping(PracticeItemModel item) {
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
              Text(
                item.cebuanoMeaning.isNotEmpty 
                    ? 'Type the English word for:'
                    : 'Listen and type what you hear',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (item.cebuanoMeaning.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    item.cebuanoMeaning,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF06A6FF)),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextField(
                controller: _typingController,
                onChanged: (_) {
                  if (mounted) setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Type the English word',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF06A6FF), width: 2)),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _ttsService.speak(_getListeningTypingAudioText(item)),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Hear it'),
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
      ],
    );
  }

  // Bottom action bar (Check answers / Feedback banners)
  Widget _buildBottomPanel(ThemeData theme, String? pref) {
    final item = _practiceQueue[_currentIndex];
    // Compute a contextual correct answer string for feedback display
    String correctAnswerText() {
      if (item.activityFormat == ActivityFormat.rearrangement) {
        final tokens = item.sentenceArrangementTokens ?? item.exampleSentenceEnglish.split(RegExp(r'\s+'));
        return tokens.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).join(' ').trim();
      }
      if (item.activityFormat == ActivityFormat.listeningTyping) {
        final fitb = item.fitbAnswer?.trim() ?? '';
        if (fitb.isNotEmpty && fitb.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).length == 1) return fitb;
        return item.englishWord;
      }
      if (item.activityFormat == ActivityFormat.trueOrFalse) {
        return item.fitbAnswer ?? 'True';
      }
      if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
        List<String> incorrectExpectedPairs = [];
        if (item.matchingSet != null && item.matchingSet!.isNotEmpty) {
          for (var pair in item.matchingSet!) {
            final expectedCeb = (pair['cebuanoMeaning'] ?? pair['cebuano'] ?? '').toString();
            final expectedEng = (pair['englishWord'] ?? pair['english'] ?? '').toString();
            bool isMatchedCorrectly = _currentMatches.entries.any((e) => 
              e.key.toLowerCase() == expectedCeb.toLowerCase() && 
              e.value.toLowerCase() == expectedEng.toLowerCase()
            );
            if (!isMatchedCorrectly) {
              incorrectExpectedPairs.add('$expectedCeb = $expectedEng');
            }
          }
        } else {
          bool isMatchedCorrectly = _currentMatches.entries.any((e) => 
            e.key.toLowerCase() == item.cebuanoMeaning.toLowerCase() && 
            e.value.toLowerCase() == item.englishWord.toLowerCase()
          );
          if (!isMatchedCorrectly) {
            incorrectExpectedPairs.add('${item.cebuanoMeaning} = ${item.englishWord}');
          }
        }
        
        if (incorrectExpectedPairs.isNotEmpty) {
          return incorrectExpectedPairs.join(', ');
        }
        return 'All pairs correctly matched';
      }
      return item.englishWord;
    }

    String? getLearnerSentenceRestatement() {
      String learnerAns = '';
      if (item.activityFormat == ActivityFormat.multipleChoice ||
          (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isNotEmpty) ||
          item.activityFormat == ActivityFormat.imageMatching) {
        if (_selectedOptionIndex >= 0 && _selectedOptionIndex < _options.length) {
          learnerAns = _options[_selectedOptionIndex];
        }
      } else if (item.activityFormat == ActivityFormat.listeningTyping ||
                 (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isEmpty)) {
        learnerAns = _typingController.text.trim();
      } else if (item.activityFormat == ActivityFormat.rearrangement) {
        return _assembledTokens.join(' ');
      }

      if (item.activityFormat == ActivityFormat.fillInTheBlank) {
        final rawSentence = item.fitbSentence ?? item.sentenceCompletionSentence ?? item.exampleSentenceEnglish;
        if (rawSentence.isNotEmpty) {
          final blankPlaceholderRegex = RegExp(
            r'\{BLANK\}|\[BLANK\]|<BLANK>|\(BLANK\)|\{blank\}|\[blank\]|<blank>|\(blank\)|\(\.\.\.\)|\[\.\.\.\]|\.\.\.|_{1,}|-{2,}|\[_\]',
            caseSensitive: false,
          );
          final filledAns = learnerAns.isNotEmpty ? learnerAns : '___';
          if (rawSentence.contains(blankPlaceholderRegex)) {
            return rawSentence.replaceFirst(blankPlaceholderRegex, filledAns);
          }
          return '$rawSentence (Answer: $filledAns)';
        }
      }
      return null;
    }

    String? getCorrectSentenceRestatement() {
      if (item.activityFormat == ActivityFormat.rearrangement) {
        final tokens = item.sentenceArrangementTokens ?? item.exampleSentenceEnglish.split(RegExp(r'\s+'));
        return tokens.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).join(' ').trim();
      }
      if (item.activityFormat == ActivityFormat.fillInTheBlank) {
        final rawSentence = item.fitbSentence ?? item.sentenceCompletionSentence ?? item.exampleSentenceEnglish;
        final correctAns = (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
            ? item.fitbAnswer!
            : item.englishWord;
        if (rawSentence.isNotEmpty) {
          final blankPlaceholderRegex = RegExp(
            r'\{BLANK\}|\[BLANK\]|<BLANK>|\(BLANK\)|\{blank\}|\[blank\]|<blank>|\(blank\)|\(\.\.\.\)|\[\.\.\.\]|\.\.\.|_{1,}|-{2,}|\[_\]',
            caseSensitive: false,
          );
          if (rawSentence.contains(blankPlaceholderRegex)) {
            return rawSentence.replaceFirst(blankPlaceholderRegex, correctAns);
          }
          final wordRegex = RegExp(r'\b' + RegExp.escape(correctAns) + r'\b', caseSensitive: false);
          if (rawSentence.contains(wordRegex)) {
            return rawSentence;
          }
          return '$rawSentence (Answer: $correctAns)';
        }
      }
      return null;
    }
    
    // Determine button enabling
    bool isActionEnabled = false;
    if (_submittingAnswer || _checked) {
      isActionEnabled = false;
    } else if (item.activityFormat == ActivityFormat.trueOrFalse) {
      isActionEnabled = _selectedOptionIndex == 0 || _selectedOptionIndex == 1;
    } else if (item.activityFormat == ActivityFormat.multipleChoice ||
        (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isNotEmpty) ||
        item.activityFormat == ActivityFormat.imageMatching ||
        item.activityFormat == ActivityFormat.imageLabeling) {
      isActionEnabled = _selectedOptionIndex != -1 && _selectedOptionIndex < _options.length;
    } else if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
      isActionEnabled = _matchingCebuanoList.isNotEmpty && _currentMatches.length == _matchingCebuanoList.length;
    } else if (item.activityFormat == ActivityFormat.listeningTyping ||
               (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isEmpty)) {
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
                onPressed: (isActionEnabled && !_submittingAnswer && !_checked) ? _checkAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6), // Indigo/Blue
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
                      _isAnswerCorrect
                          ? (((_wordWrongAttempts[item.wordId] ?? 0) > 0)
                              ? 'Correct (+5 pts)'
                              : (item.activityFormat == ActivityFormat.rearrangement
                                  ? 'Correct (+15 pts)'
                                  : 'Correct (+10 pts)'))
                          : 'Incorrect (0 pts)',
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
                          ] else if (!_isAnswerCorrect && correctSentence == null) ...[
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
            child: Text(
              LocalizationService.translate(pref, 'continue'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Session Summary Widget (UC-2.1 Metrics and UC-2.2 Reinforcement results)
  Widget _buildSummaryScreen(ThemeData theme, String? pref) {
    final masteredCount = _words.where((word) => (_wordWrongAttempts[word.wordId] ?? 0) == 0).length;
    final needsReviewWords = _words.where((word) => (_wordWrongAttempts[word.wordId] ?? 0) > 0).map((w) => w.englishWord).toList();

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
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
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
                      child: Text(
                        '🏆',
                        style: TextStyle(fontSize: 80),
                      ),
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
                    _buildStatRow('Total Words Practiced', '${_words.length} words'),
                    const Divider(height: 24),
                    _buildStatRow('Words Mastered', '$masteredCount / ${_words.length}', isBold: true),
                    if (needsReviewWords.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildStatRow('Still Needs Review', needsReviewWords.join(', ')),
                    ],
                  ],
                ),
              ),

              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Continue to Sentence Building (Module 3) for this session with loading screen
                  context.push(
                    '/loading',
                    extra: {
                      'duration': 13000,
                      'redirectPath': '/session/${widget.sessionId}/sentence-building',
                      'lessonId': widget.lessonId,
                      'categoryId': widget.categoryId,
                      'lessonTitle': widget.lessonTitle,
                      'allWords': widget.allWords,
                      'isSandbox': widget.isSandbox,
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
        content: const Text('Your progress will be saved. You can continue from where you left off when you return.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await _saveCurrentState();
              await LocalStorageService.saveModuleProgressSnapshot(
                widget.sessionId,
                {
                  'module': 2,
                  'wordDifficulties': _wordDifficulties,
                  'lessonId': widget.lessonId,
                  'sessionId': widget.sessionId,
                  'savedAt': DateTime.now().toIso8601String(),
                },
              );
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              final provider = Provider.of<LessonProvider>(context, listen: false);
              provider.recordPartialModuleTime(widget.sessionId, 2, _computeActiveSeconds(), lessonId: widget.lessonId);
              // ignore: use_build_context_synchronously
              Navigator.of(ctx).pop();
              // ignore: use_build_context_synchronously
              context.go('/home');
            },
            child: const Text('EXIT', style: TextStyle(color: Colors.redAccent)),
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
}
