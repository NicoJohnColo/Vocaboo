import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../models/vocabulary_word_model.dart';
import '../widgets/mascot_bubble.dart';
import '../services/local_storage_service.dart';
import '../services/scoring_service.dart';
import '../services/tts_service.dart';
import '../widgets/image_matching_widget.dart';

class ActivePracticeScreen extends StatefulWidget {
  final String sessionId;
  final String lessonId;
  final String categoryId;
  final List<String> knownWordIds;
  final List<String> unknownWordIds;
  final List<Map<String, dynamic>> allWords;
  final bool isSandbox;

  const ActivePracticeScreen({
    super.key,
    required this.sessionId,
    required this.lessonId,
    required this.categoryId,
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

  // Reinforcement Mode Variables
  bool _isReinforcementMode = false;
  List<ReinforcementQueueItem> _reinforcementQueue = [];
  int _initialPassCorrectCount = 0;
  int _reinforcementPassCorrectCount = 0;
  // How many reinforcement duplicates to add for denser reinforcement
  static const int _reinforcementDuplicates = 2; // adds 2 copies

  // Session Completed State
  final bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _words = widget.allWords.map((w) => VocabularyWordModel.fromJson(w)).toList();
    _initializeSession();
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    setState(() => _isLoading = true);
    
    // Check if there is an existing saved session state
    final savedState = await LocalStorageService.getPracticeSessionState(widget.sessionId);
    final savedQueue = await LocalStorageService.getReinforcementQueue(widget.sessionId);
    
    _reinforcementQueue = savedQueue;

    if (savedState != null) {
      _practiceQueue = savedState['queue'] as List<PracticeItemModel>;
      _currentIndex = savedState['currentIndex'] as int;
      
      // If index is out of bounds, check if we need to transition to reinforcement
      if (_currentIndex >= _practiceQueue.length) {
        await _transitionToReinforcementOrComplete();
      } else {
        _loadCurrentItemState();
      }
    } else {
      // Build new session queue
      _buildPracticeQueue();
      _currentIndex = 0;
      if (_practiceQueue.isNotEmpty) {
        _loadCurrentItemState();
      }
      await _saveCurrentState();
    }

    setState(() => _isLoading = false);
  }

  void _buildPracticeQueue() {
    _practiceQueue.clear();
    final random = Random();
    final requiredFormats = [
      ActivityFormat.multipleChoice,
      ActivityFormat.listeningTyping,
      ActivityFormat.fillInTheBlank,
      ActivityFormat.imageMatching,
      ActivityFormat.translationMatching,
      ActivityFormat.flashcardRecall,
    ];
    final allFormats = ActivityFormat.values.toList();
    final shuffledWords = List<VocabularyWordModel>.from(_words)..shuffle(random);

    for (final format in requiredFormats) {
      if (shuffledWords.isEmpty) {
        break;
      }
      final word = shuffledWords[_practiceQueue.length % shuffledWords.length];
      _practiceQueue.add(_createPracticeItem(word, format));
    }

    for (final word in shuffledWords) {
      final format = allFormats[random.nextInt(allFormats.length)];
      _practiceQueue.add(_createPracticeItem(word, format));
    }

    _practiceQueue.shuffle(random);
  }

  PracticeItemModel _createPracticeItem(VocabularyWordModel word, ActivityFormat format) {
    var resolvedFormat = format;
    if (resolvedFormat == ActivityFormat.imageMatching && (word.imageAssetPath == null || word.imageAssetPath!.isEmpty)) {
      resolvedFormat = ActivityFormat.multipleChoice;
    }

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
    );
  }

  List<String> _resolveDistractors(VocabularyWordModel targetWord) {
    final provided = [
      targetWord.mcDistractor1,
      targetWord.mcDistractor2,
      targetWord.mcDistractor3,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

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

  void _loadCurrentItemState() {
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
        item.activityFormat == ActivityFormat.fillInTheBlank ||
        item.activityFormat == ActivityFormat.imageMatching) {
      final distractors = item.distractors.isNotEmpty ? item.distractors : _resolveDistractors(_words.firstWhere((w) => w.wordId == item.wordId));
      _options = [item.englishWord, ...distractors];
      _options.shuffle(Random(item.wordId.hashCode)); // consistent shuffle for this word
    } else if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
      final matchingList = _resolveMatchingSet(item);
      _matchingCebuanoList = matchingList.map((entry) => (entry['cebuanoMeaning'] ?? '').toString()).where((value) => value.isNotEmpty).toList()..shuffle();
      _matchingEnglishList = matchingList.map((entry) => (entry['englishWord'] ?? '').toString()).where((value) => value.isNotEmpty).toList()..shuffle();
    }

    // Passive TTS speak target English word
    _ttsService.speak(item.englishWord);
  }

  Future<void> _saveCurrentState() async {
    await LocalStorageService.savePracticeSessionState(widget.sessionId, _practiceQueue, _currentIndex);
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
    }
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
        item.activityFormat == ActivityFormat.fillInTheBlank ||
        item.activityFormat == ActivityFormat.imageMatching) {
      if (_selectedOptionIndex == -1) return;
      learnerAns = _options[_selectedOptionIndex];
      correct = (learnerAns == item.englishWord);
    } else if (item.activityFormat == ActivityFormat.listeningTyping) {
      learnerAns = _typingController.text.trim();
      final correctTarget = (item.fitbAnswer ?? item.englishWord).trim();
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
    }

    // Save practice result log
    final result = PracticeEvaluationResult(
      wordId: item.wordId,
      activityFormat: item.activityFormat,
      learnerResponse: learnerAns,
      correctAnswer: correctAns,
      isCorrect: correct,
      evaluatedAt: DateTime.now(),
      isReinforcementAttempt: _isReinforcementMode ? 1 : 0,
    );
    await LocalStorageService.saveEvaluationResult(widget.sessionId, result);

    if (correct) {
      if (_isReinforcementMode) {
        _reinforcementPassCorrectCount++;
      } else {
        _initialPassCorrectCount++;
      }
    }

    setState(() {
      _checked = true;
      _isAnswerCorrect = correct;
      _showFeedback = true;
    });

    // Speak correct English word upon answer checking for reinforcement
    _ttsService.speak(item.englishWord);
  }

  Future<void> _advanceNext() async {
    final item = _practiceQueue[_currentIndex];
    final wasKnown = widget.knownWordIds.contains(item.wordId);

    if (!_isAnswerCorrect) {
      // Keep missed words in the same session and reintroduce them later.
      // This preserves the active-recall flow instead of ejecting the learner back to Module 1.
      final provider = Provider.of<LessonProvider>(context, listen: false);
      if (wasKnown) {
        await provider.updateWordProgress(widget.sessionId, item.wordId, 'FULL', 0, 'NEEDS_PRONUNCIATION_REVIEW');
      }

      final currentFormat = item.activityFormat;
      final alternateFormat = ActivityFormat.values.firstWhere((f) => f != currentFormat);

      // Add multiple duplicates to increase reinforcement density
      for (var i = 0; i < _reinforcementDuplicates; i++) {
        _reinforcementQueue.add(
          ReinforcementQueueItem(
            wordId: item.wordId,
            assignedFormat: alternateFormat,
            status: ReinforcementStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
      }
      await LocalStorageService.saveReinforcementQueue(widget.sessionId, _reinforcementQueue);

      if (wasKnown && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.englishWord}" will be reviewed again in this session.'),
            backgroundColor: const Color(0xFFF59E0B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Correct answer!
      if (_isReinforcementMode) {
        // Update item in reinforcement queue status to COMPLETE
        final indexInR = _reinforcementQueue.indexWhere((q) => q.wordId == item.wordId && q.status == ReinforcementStatus.pending);
        if (indexInR != -1) {
          _reinforcementQueue[indexInR] = ReinforcementQueueItem(
            wordId: item.wordId,
            assignedFormat: _reinforcementQueue[indexInR].assignedFormat,
            status: ReinforcementStatus.reinforcedComplete,
            createdAt: _reinforcementQueue[indexInR].createdAt,
          );
          await LocalStorageService.saveReinforcementQueue(widget.sessionId, _reinforcementQueue);
        }
      }
    }

    // Increment current index
    _currentIndex++;
    await _saveCurrentState();

    if (_currentIndex >= _practiceQueue.length) {
      await _transitionToReinforcementOrComplete();
    } else {
      setState(() {
        _loadCurrentItemState();
      });
    }
  }

  Future<void> _transitionToReinforcementOrComplete() async {
    // Filter pending items from reinforcement queue
    final pendingReinforcements = _reinforcementQueue
        .where((item) => item.status == ReinforcementStatus.pending)
        .toList();

    if (pendingReinforcements.isNotEmpty) {
      // Re-build practice queue with pending reinforcement items
      final random = Random();
      _practiceQueue = pendingReinforcements.map((rItem) {
        final originalWord = _words.firstWhere((w) => w.wordId == rItem.wordId);
        return PracticeItemModel(
          wordId: originalWord.wordId,
          englishWord: originalWord.englishWord,
          cebuanoMeaning: originalWord.cebuanoMeaning,
          exampleSentenceEnglish: originalWord.exampleSentenceEnglish,
          exampleSentenceCebuano: originalWord.exampleSentenceCebuano,
          activityFormat: rItem.assignedFormat,
            imageAssetPath: originalWord.imageAssetPath,
          distractors: _resolveDistractors(originalWord),
          mcDistractor1: originalWord.mcDistractor1,
          mcDistractor2: originalWord.mcDistractor2,
          mcDistractor3: originalWord.mcDistractor3,
          fitbSentence: originalWord.fitbSentence,
          fitbAnswer: originalWord.fitbAnswer,
          matchingSet: originalWord.matchingSet,
          sentenceArrangementTokens: originalWord.sentenceArrangementTokens,
          sentenceCompletionSentence: originalWord.sentenceCompletionSentence,
          sentenceCompletionAnswer: originalWord.sentenceCompletionAnswer,
          sentenceCompletionOption1: originalWord.sentenceCompletionOption1,
          sentenceCompletionOption2: originalWord.sentenceCompletionOption2,
          sentenceCompletionOption3: originalWord.sentenceCompletionOption3,
        );
      }).toList()..shuffle(random);

      _currentIndex = 0;
      _isReinforcementMode = true;
      _loadCurrentItemState();
      await _saveCurrentState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Starting Reinforcement Phase for failed practice words!'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
      }
    } else {
      await _completeModuleAndAdvance();
    }
  }

  Future<void> _completeModuleAndAdvance() async {
    final total = _words.length;
    final moduleScore = ScoringService.computeLessonScore(_initialPassCorrectCount, total);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await lessonProvider.persistModuleScore(widget.lessonId, 2, _initialPassCorrectCount, total);

    final summary = SessionSummaryModel(
      sessionId: widget.sessionId,
      learnerId: authProvider.learner?.learnerId ?? 'anonymous',
      lessonId: widget.lessonId,
      totalWordsPracticed: total,
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

    if (!mounted) return;
    context.go(
      '/session/${widget.sessionId}/sentence-building',
      extra: {
        'lessonId': widget.lessonId,
        'categoryId': widget.categoryId,
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

    final item = _practiceQueue[_currentIndex];
    final progressVal = _practiceQueue.isNotEmpty
        ? (_currentIndex / _practiceQueue.length)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 10,
            child: LinearProgressIndicator(
              value: progressVal,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)), // Yellow progress
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                '${_currentIndex + 1}/${_practiceQueue.length}',
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
                      speechText: _getInstructionText(item.activityFormat),
                      isSad: _checked && !_isAnswerCorrect,
                      isCelebrating: _checked && _isAnswerCorrect,
                    ),
                    const SizedBox(height: 24),
                    
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
        // Cebuano word prompt card
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
    // Generate the sentence with target english word blanked out
    final target = item.englishWord;
    final sentence = item.exampleSentenceEnglish;
    final regExp = RegExp(target, caseSensitive: false);
    
    final parts = sentence.split(regExp);

    String blankText = '_______';
    Color blankColor = const Color(0xFF94A3B8);
    Color blankBgColor = const Color(0xFFF1F5F9);

    if (_selectedOptionIndex != -1) {
      blankText = _options[_selectedOptionIndex];
      blankColor = const Color(0xFF3B82F6);
      blankBgColor = const Color(0xFFEFF6FF);
    }

    if (_checked) {
      final isCorrect = (_options[_selectedOptionIndex] == target);
      if (isCorrect) {
        blankColor = const Color(0xFF22C55E);
        blankBgColor = const Color(0xFFF0FDF4);
      } else {
        blankColor = const Color(0xFFEF4444);
        blankBgColor = const Color(0xFFFEF2F2);
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
        // Options List
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

  Widget _buildListeningTyping(PracticeItemModel item) {
    final prompt = (item.fitbSentence ?? item.exampleSentenceEnglish).trim();
    final answer = (item.fitbAnswer ?? item.englishWord).trim();

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
              Text(
                prompt,
                style: const TextStyle(fontSize: 18, height: 1.45, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
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
                onPressed: () => _ttsService.speak(answer),
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
    
    // Determine button enabling
    bool isActionEnabled = false;
    if (item.activityFormat == ActivityFormat.multipleChoice ||
        item.activityFormat == ActivityFormat.fillInTheBlank ||
        item.activityFormat == ActivityFormat.imageMatching) {
      isActionEnabled = _selectedOptionIndex != -1;
    } else if (item.activityFormat == ActivityFormat.matching || item.activityFormat == ActivityFormat.translationMatching) {
      isActionEnabled = _currentMatches.length == _matchingCebuanoList.length;
    } else if (item.activityFormat == ActivityFormat.listeningTyping) {
      isActionEnabled = _typingController.text.trim().isNotEmpty;
    } else if (item.activityFormat == ActivityFormat.flashcardRecall) {
      isActionEnabled = _flashcardFlipped;
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
                      _isAnswerCorrect ? 'Nice!' : 'Incorrect',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (!_isAnswerCorrect) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Correct answer: ${item.englishWord}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
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
    final double correctPercentage = _words.isNotEmpty
        ? (_initialPassCorrectCount / _words.length) * 100
        : 0.0;

    final double overallMastery = _words.isNotEmpty
        ? ((_words.length - _reinforcementQueue.where((item) => item.status != ReinforcementStatus.reinforcedComplete).length) / _words.length) * 100.0
        : 0.0;

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
                    _buildStatRow('Total Words Practiced', '${_words.length}'),
                    const Divider(height: 24),
                    _buildStatRow('Initial Correct (First Pass)', '$_initialPassCorrectCount / ${_words.length} (${correctPercentage.toStringAsFixed(0)}%)'),
                    const Divider(height: 24),
                    _buildStatRow('Reinforced Pass Correct', '$_reinforcementPassCorrectCount'),
                    const Divider(height: 24),
                    _buildStatRow('Overall Mastery Score', '${overallMastery.toStringAsFixed(0)}%', isBold: true),
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
                child: const Text(
                  'CONTINUE TO MODULE 3',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
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
}
