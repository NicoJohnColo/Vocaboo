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
  int _initialPassCorrectCount = 0;
  int _reinforcementPassCorrectCount = 0;

  // Session Completed State
  final bool _isCompleted = false;

  // Timer Variables
  Timer? _questionTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _words = widget.allWords.map((w) => VocabularyWordModel.fromJson(w)).toList();
    _initializeSession();
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _typingController.dispose();
    super.dispose();
  }

  final List<ReinforcementQueueItem> _reinforcementQueue = [];

  Future<void> _initializeSession() async {
    setState(() => _isLoading = true);
    
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
        _loadCurrentItemState();
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
        _practiceQueue = backendQuestions.map((q) {
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
              format = ActivityFormat.rearrangement;
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
                .map((e) => {
                      'englishWord': e['english'],
                      'cebuanoMeaning': e['cebuano'],
                    })
                .toList();
          }

          return PracticeItemModel(
            wordId: q['wordId'],
            englishWord: q['englishWord'] ?? '',
            cebuanoMeaning: q['cebuanoMeaning'] ?? '',
            exampleSentenceEnglish: q['questionText'] ?? '',
            exampleSentenceCebuano: q['cebuanoMeaning'],
            activityFormat: format,
            distractors: distractors,
            mcDistractor1: distractors.isNotEmpty ? distractors[0] : null,
            mcDistractor2: distractors.length > 1 ? distractors[1] : null,
            mcDistractor3: distractors.length > 2 ? distractors[2] : null,
            fitbSentence: q['questionText'],
            fitbAnswer: correctAnswer,
            matchingSet: matchingSet,
            sentenceArrangementTokens: scrambledTokens,
            imageAssetPath: q['imageAssetPath'],
            timeLimitSeconds: q['timeLimitSeconds'] as int?,
            difficultyLevel: q['difficultyLevel'] as String? ?? 'LEARNING',
          );
        }).toList();
      }
      
      _currentIndex = 0;
      _completedScreens = 0;
      _plannedScreens = _practiceQueue.length;
      if (_practiceQueue.isNotEmpty) {
        _loadCurrentItemState();
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
        _practiceQueue.add(_createPracticeItem(word, ActivityFormat.flashcardRecall));
        _practiceQueue.add(_createPracticeItem(word, ActivityFormat.multipleChoice));
        _practiceQueue.add(_createPracticeItem(word, ActivityFormat.fillInTheBlank));
      }
    } else {
      // Non-sandbox mode: fixed selection from the 4 core retrieval formats.
      final allowedFormats = [
        ActivityFormat.multipleChoice,
        ActivityFormat.fillInTheBlank,
        ActivityFormat.matching,
        ActivityFormat.listeningTyping,
      ];
      
      // Build queue sequentially per word: for each word, add two exercises back-to-back
      final random = Random();
      for (var index = 0; index < _words.length; index++) {
        final word = _words[index];

        var format1 = allowedFormats[random.nextInt(allowedFormats.length)];
        if (word.imageAssetPath != null && word.imageAssetPath!.isNotEmpty && random.nextDouble() < 0.3) {
          format1 = ActivityFormat.imageMatching;
        }
        _practiceQueue.add(_createPracticeItem(word, format1));

        // Second exercise: pick a random format ensuring it differs from the first format
        final remainingFormats = allowedFormats.where((f) => f != format1).toList();
        var format2 = remainingFormats[random.nextInt(remainingFormats.length)];
        _practiceQueue.add(_createPracticeItem(word, format2));
      }
    }
  }

  PracticeItemModel _createPracticeItem(VocabularyWordModel word, ActivityFormat format) {
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
      sentenceCompletionSentence: word.sentenceCompletionSentence,
      sentenceCompletionAnswer: word.sentenceCompletionAnswer,
      sentenceCompletionOption1: word.sentenceCompletionOption1,
      sentenceCompletionOption2: word.sentenceCompletionOption2,
      sentenceCompletionOption3: word.sentenceCompletionOption3,
      difficultyLevel: 'LEARNING',
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

  int _rearrangementTokenCount(VocabularyWordModel word) {
    final explicitTokens = word.sentenceArrangementTokens
        ?.map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
    if (explicitTokens != null && explicitTokens.isNotEmpty) {
      return explicitTokens.length;
    }

    final sentence = word.exampleSentenceEnglish.trim();
    if (sentence.isNotEmpty) {
      return sentence.split(RegExp(r'\s+')).where((token) => token.isNotEmpty).length;
    }

    return word.englishWord.trim().isEmpty ? 0 : 1;
  }

  List<Map<String, dynamic>> _resolveMatchingSet(PracticeItemModel targetItem) {
    final matchingSet = targetItem.matchingSet ?? const [];
    if (matchingSet.isNotEmpty) {
      return matchingSet;
    }

    final otherWords = _words.where((w) => w.wordId != targetItem.wordId).take(3).toList();
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

  double get _scorePoints {
    double score = 0.0;
    for (final word in _words) {
      if ((_wordWrongAttempts[word.wordId] ?? 0) == 0) {
        score += 1.0;
      }
    }
    return score;
  }

  void _loadCurrentItemState() {
    _questionTimer?.cancel();
    _secondsRemaining = 0;
    _checked = false;
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
        item.activityFormat == ActivityFormat.imageMatching) {
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
      
      if (_options.length < 4) {
        final fallbacks = ['apple', 'house', 'water', 'friend', 'school', 'book', 'tree', 'happy', 'run', 'big', 'cat', 'dog'];
        final needed = 4 - _options.length;
        final available = fallbacks.where((f) => !_options.contains(f)).toList()..shuffle();
        _options.addAll(available.take(needed));
      }
      
      _options.shuffle(Random(item.wordId.hashCode));
      debugPrint('MC options before render: $_options');
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
      
      if (_options.length < 4) {
        final fallbacks = ['apple', 'house', 'water', 'friend', 'school', 'book', 'tree', 'happy', 'run', 'big', 'cat', 'dog'];
        final needed = 4 - _options.length;
        final available = fallbacks.where((f) => !_options.contains(f)).toList()..shuffle();
        _options.addAll(available.take(needed));
      }
      
      _options.shuffle(Random(item.wordId.hashCode));
      debugPrint('FITB options before render: $_options');
    } else if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
      final matchingList = _resolveMatchingSet(item);
      _matchingCebuanoList = matchingList.map((entry) => (entry['cebuanoMeaning'] ?? '').toString()).where((value) => value.isNotEmpty).toList()..shuffle();
      _matchingEnglishList = matchingList.map((entry) => (entry['englishWord'] ?? '').toString()).where((value) => value.isNotEmpty).toList()..shuffle();
    } else if (item.activityFormat == ActivityFormat.rearrangement) {
      final tokens = item.sentenceArrangementTokens ?? [];
      if (tokens.isNotEmpty) {
        _scrambledTokens = List<String>.from(tokens)..shuffle(Random(item.wordId.hashCode));
      } else {
        final sentence = item.exampleSentenceEnglish.trim();
        _scrambledTokens = sentence.split(RegExp(r'\s+')).toList()..shuffle(Random(item.wordId.hashCode));
      }
      _assembledTokens = [];
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
        return 'Look at the image and choose the correct word.';
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
    }
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
    final item = _practiceQueue[_currentIndex];
    bool correct = false;
    String learnerAns = '';
    String correctAns = item.englishWord;

    if (item.activityFormat == ActivityFormat.multipleChoice ||
        (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isNotEmpty) ||
        item.activityFormat == ActivityFormat.imageMatching) {
      if (_selectedOptionIndex == -1) return;
      if (_selectedOptionIndex < 0 || _selectedOptionIndex >= _options.length) {
        debugPrint('Selected option index out of range ($_selectedOptionIndex) for options length ${_options.length}');
        return;
      }
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
      final lvl = item.difficultyLevel?.toUpperCase() ?? 'LEARNING';
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
        final cleanLearner = learnerAns.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
        final cleanCorrect = correctTarget.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
        correct = cleanLearner == cleanCorrect;
      } else {
        final cleanLearner = _cleanStringForCompare(learnerAns);
        final cleanCorrect = _cleanStringForCompare(correctTarget);
        correct = cleanLearner == cleanCorrect;
      }
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
      // Matching is correct if the target word is matched correctly AND all matching inputs are correct
      bool targetCorrect = _currentMatches[item.cebuanoMeaning] == item.englishWord;
      
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
        if (actualWordObj.englishWord.isNotEmpty && actualWordObj.englishWord != eng) {
          othersCorrect = false;
        }
      });

      correct = targetCorrect && othersCorrect;
      learnerAns = _currentMatches.toString();
      correctAns = 'All correct matches';
    } else if (item.activityFormat == ActivityFormat.flashcardRecall) {
      // Flashcard recall is always considered correct if the user flips and confirms
      correct = _flashcardFlipped;
      learnerAns = 'Flashcard flipped';
      correctAns = 'Flashcard confirmed';
    } else if (item.activityFormat == ActivityFormat.rearrangement) {
      final rawTargetTokens = item.sentenceArrangementTokens ?? item.exampleSentenceEnglish.split(RegExp(r'\s+'));
      final targetTokens = rawTargetTokens.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).toList();
      String normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final targetNormalized = targetTokens.map(normalize).where((t) => t.isNotEmpty).toList();
      final assembledNormalized = _assembledTokens.map(normalize).where((t) => t.isNotEmpty).toList();

      if (targetNormalized.isEmpty) {
        correct = false;
      } else if (targetNormalized.length == 1) {
        // One-word target: accept if assembled contains that word (robust to punctuation/capitalization)
        correct = assembledNormalized.any((tok) => tok == targetNormalized.first);
      } else {
        // Multi-word target: require exact normalized sentence match
        correct = assembledNormalized.join(' ') == targetNormalized.join(' ');
      }

      learnerAns = _assembledTokens.join(' ');
      correctAns = targetTokens.join(' ');
    }

    // Save practice result log
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
      await provider.submitRetrievalAnswer(
        widget.sessionId,
        item.wordId,
        correct,
      );
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
      final allowedFormats = [
        ActivityFormat.multipleChoice,
        ActivityFormat.fillInTheBlank,
        ActivityFormat.matching,
        ActivityFormat.listeningTyping,
        ActivityFormat.rearrangement,
      ];
      final remaining = allowedFormats.where((f) => f != item.activityFormat).toList();
      final nextFormat = remaining[Random().nextInt(remaining.length)];

      final wordModel = VocabularyWordModel(
        wordId: item.wordId,
        lessonId: widget.lessonId,
        englishWord: item.englishWord,
        cebuanoMeaning: item.cebuanoMeaning,
        exampleSentenceEnglish: item.exampleSentenceEnglish,
        exampleSentenceCebuano: item.exampleSentenceCebuano,
        gradeLevel: '',
        wordOrder: 0,
        isConfusablePairMember: false,
        imageAssetPath: item.imageAssetPath,
        mcDistractor1: item.mcDistractor1,
        mcDistractor2: item.mcDistractor2,
        mcDistractor3: item.mcDistractor3,
        fitbSentence: item.fitbSentence,
        fitbAnswer: item.fitbAnswer,
        matchingSet: item.matchingSet,
        sentenceArrangementTokens: item.sentenceArrangementTokens,
      );
      final failedItem = _createPracticeItem(wordModel, nextFormat);
      _practiceQueue.add(failedItem);
      _plannedScreens++;

      if (wasKnown && mounted) {
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
      await _completeModuleAndAdvance();
    } else {
      setState(() {
        _loadCurrentItemState();
      });
    }
  }

  Future<void> _completeModuleAndAdvance() async {
    // Strict guard: ensure all practice queue items are completed before advancing
    if (_currentIndex < _practiceQueue.length) {
      setState(() {
        _loadCurrentItemState();
      });
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
    try {
      await lessonProvider.persistModuleScore(
        widget.lessonId,
        widget.isSandbox ? null : 2,
        _initialPassCorrectCount,
        total,
        isSandbox: widget.isSandbox,
        sessionId: widget.sessionId,
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
    debugPrint('Navigating to Module 3...');
    context.go(
      '/session/${widget.sessionId}/sentence-building',
      extra: {
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
    // Calculate progress based on unique words completed
    final allWordIds = _words.map((w) => w.wordId).toSet();
    final remainingWordIds = _practiceQueue.sublist(_currentIndex).map((e) => e.wordId).toSet();
    final completedWordsCount = allWordIds.difference(remainingWordIds).length;
    final calculatedProgress = _words.isEmpty ? 0.0 : (completedWordsCount / _words.length);
    _maxProgress = max(_maxProgress, calculatedProgress);
    final progressVal = _progressOverride ?? _maxProgress;

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
              tween: Tween<double>(begin: 0.0, end: progressVal),
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
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
                '$completedWordsCount/${_words.length}',
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
      case ActivityFormat.matching:
      case ActivityFormat.translationMatching:
        return _buildMatching(item);
      case ActivityFormat.fillInTheBlank:
        return _buildFillInTheBlank(item);
      case ActivityFormat.listeningTyping:
        return _buildListeningTyping(item);
      case ActivityFormat.flashcardRecall:
        return _buildFlashcardRecall(item);
      case ActivityFormat.rearrangement:
        return _buildRearrangement(item);
    }
  }

  // 4. Image-to-Word Matching Widget
  Widget _buildImageMatching(PracticeItemModel item) {
    return ImageMatchingWidget(
      item: item,
      options: _options,
      selectedIndex: _selectedOptionIndex,
      onSelect: (idx) => _selectMcOption(idx),
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
              if (item.imageAssetPath != null && item.imageAssetPath!.isNotEmpty)
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
                          child: const Center(child: Icon(Icons.broken_image, color: Color(0xFF94A3B8))),
                        ),
                      ),
                    ),
                  ),
                ),
              Text(
                item.cebuanoMeaning,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
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
                              child: Text(
                                ceb,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

    // Split sentence: use explicit ___ marker first, then split on target word
    List<String> parts;
    if (rawSentence.contains('___')) {
      final split = rawSentence.split('___');
      parts = [split.first, split.skip(1).join('___')];
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
                Text(
                  item.exampleSentenceCebuano!,
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
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
                    Text(item.cebuanoMeaning, style: const TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.45)),
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
                const Text(
                  'Sentence Guide',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bisaya: $bisayaGuide',
                  style: const TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
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
              const Text(
                'Assembled Sentence',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: 60),
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
                      ? [const Text('Tap words below to build the sentence', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14))]
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
    final lvl = item.difficultyLevel?.toUpperCase() ?? 'LEARNING';
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              if (bisayaHint.isNotEmpty) ...[
                Text(
                  'Bisaya: $bisayaHint',
                  style: const TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF06A6FF), width: 2)),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _ttsService.speak(_getListeningTypingAudioText(item)),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Hear it again'),
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
        final sentence = item.fitbSentence ?? item.sentenceCompletionSentence ?? '';
        if (sentence.isNotEmpty) {
          final blankRegex = RegExp(r'_{2,}|-{2,}|\[_\]');
          if (sentence.contains(blankRegex)) {
            return sentence.replaceFirst(blankRegex, learnerAns.isEmpty ? '___' : learnerAns);
          }
          return '$sentence (Answer: $learnerAns)';
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
        final sentence = item.fitbSentence ?? item.sentenceCompletionSentence ?? '';
        final correctAns = (item.fitbAnswer != null && item.fitbAnswer!.trim().isNotEmpty)
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
        (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isNotEmpty) ||
        item.activityFormat == ActivityFormat.imageMatching) {
      isActionEnabled = _selectedOptionIndex != -1;
    } else if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
      isActionEnabled = _currentMatches.length == _matchingCebuanoList.length;
    } else if (item.activityFormat == ActivityFormat.listeningTyping ||
               (item.activityFormat == ActivityFormat.fillInTheBlank && _options.isEmpty)) {
      isActionEnabled = _typingController.text.trim().isNotEmpty;
    } else if (item.activityFormat == ActivityFormat.flashcardRecall) {
      isActionEnabled = _flashcardFlipped;
    } else if (item.activityFormat == ActivityFormat.rearrangement) {
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
                      _isAnswerCorrect ? 'Correct (+10 pts)' : 'Incorrect. Review and continue.',
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
            child: const Text(
              'CONTINUE',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
                  // Continue to Sentence Building (Module 3) for this session
                  context.go(
                    '/session/${widget.sessionId}/sentence-building',
                    extra: {
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
        content: const Text('Leaving now will discard your current session progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
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

  String _cleanStringForCompare(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.,!?;:]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
