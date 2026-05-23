// cumulative_mixed_review_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
 
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/mascot_visual.dart';
import 'mastery_result_screen.dart';

class CumulativeMixedReviewScreen extends StatefulWidget {
  final String sessionId;
  final List<Map<String, dynamic>> allWords;
  final String categoryId;
  final bool isSandbox;
  final List<String>? priorityWordIds;
  const CumulativeMixedReviewScreen({super.key, required this.sessionId, this.allWords = const [], required this.categoryId, this.isSandbox = false, this.priorityWordIds});

  @override
  State<CumulativeMixedReviewScreen> createState() => _CumulativeMixedReviewScreenState();
}

class _CumulativeMixedReviewScreenState extends State<CumulativeMixedReviewScreen> {
  List<dynamic> _reviewItems = [];
  bool _loading = true;
  final Map<String, bool> _results = {};
  Map<String, dynamic>? _pendingSavedState;
  bool _showResumePrompt = false;

  // Working queue with activityFormat assigned
  final List<Map<String, dynamic>> _queue = [];
  int _currentIndex = 0;
  double? _weightedScore;
  String? _selectedMatchingWord;
  List<String> _matchingOptions = [];

  Map<String, dynamic>? get _currentItem => _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  MascotType _mascotForFormat(String fmt) {
    switch (fmt) {
      case 'FILL_IN_THE_BLANK':
        return MascotType.sippy;
      case 'MATCHING':
        return MascotType.toti;
      default:
        return MascotType.bibo;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReviewItems();
  }

  void _prepareCurrentActivityState() {
    _selectedMatchingWord = null;
    _matchingOptions = [];

    final item = _currentItem;
    if (item == null) return;

    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();
    if (fmt == 'MATCHING') {
      _matchingOptions = _buildMatchingOptions(item);
    }
  }

  List<String> _buildMatchingOptions(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString().trim();
    if (correct.isEmpty) return const [];

    final matchingSet = (item['matchingSet'] as List<dynamic>?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const [];

    final candidateWords = <String>{};
    if (matchingSet.isNotEmpty) {
      for (final entry in matchingSet) {
        final word = (entry['englishWord'] ?? '').toString().trim();
        if (word.isNotEmpty && word != correct) {
          candidateWords.add(word);
        }
      }
    } else {
      for (final entry in _reviewItems) {
        final word = (entry['word'] ?? '').toString().trim();
        if (word.isNotEmpty && word != correct) {
          candidateWords.add(word);
        }
      }
    }

    final distractors = candidateWords.toList();
    distractors.shuffle(Random('${item['wordId'] ?? correct}'.hashCode));

    final options = <String>[correct, ...distractors.take(3)];
    options.shuffle(Random('${item['wordId'] ?? correct}_bank'.hashCode));
    return options;
  }

  @override
  void dispose() {
    if (!_loading && _queue.isNotEmpty) {
      LocalStorageService.saveCumulativeReviewState(widget.sessionId, {
        'reviewItems': _reviewItems,
        'queue': _queue,
        'currentIndex': _currentIndex,
        'results': _results,
        'weightedScore': _weightedScore,
      });
    }
    super.dispose();
  }

  Future<void> _fetchReviewItems() async {
    final savedState = await LocalStorageService.getCumulativeReviewState(widget.sessionId);
    if (savedState != null) {
      // Prompt user to resume or start fresh instead of auto-restoring
      setState(() {
        _pendingSavedState = Map<String, dynamic>.from(savedState);
        _showResumePrompt = true;
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    final lessons = Provider.of<LessonProvider>(context, listen: false);
    final items = widget.isSandbox
        ? widget.allWords
        : widget.categoryId.isNotEmpty
            ? await lessons.loadCategoryActivity(widget.categoryId)
            : widget.allWords;
    final list = items.map((e) {
      final item = Map<String, dynamic>.from(e);
      return <String, dynamic>{
        'wordId': item['wordId'] ?? item['id'] ?? item['vocabularyId'] ?? '',
        'word': item['word'] ?? item['englishWord'] ?? '',
        'definition': item['definition'] ?? item['cebuanoMeaning'] ?? item['cebuanoDefinition'] ?? '',
        'example': item['example'] ?? item['exampleSentenceEnglish'] ?? item['englishSentence'] ?? '',
        'mcDistractor1': item['mcDistractor1'],
        'mcDistractor2': item['mcDistractor2'],
        'mcDistractor3': item['mcDistractor3'],
        'fitbSentence': item['fitbSentence'],
        'fitbAnswer': item['fitbAnswer'],
        'matchingSet': item['matchingSet'],
      };
    }).toList();

    // Ensure every item has a wordId and englishWord
    list.removeWhere((it) => ((it['wordId'] ?? it['vocabularyId'] ?? '')).toString().isEmpty);

    // Build queue ensuring each word appears at least once
    final rnd = Random();
    _queue.clear();
    for (final it in list) {
      final formats = ['MULTIPLE_CHOICE', 'FILL_IN_THE_BLANK', 'MATCHING'];
      final fmt = formats[rnd.nextInt(formats.length)];
      _queue.add({...it, 'activityFormat': fmt});
    }

    // If retry priority provided, append duplicates of those words
    if (widget.priorityWordIds != null && widget.priorityWordIds!.isNotEmpty) {
      final prioritySet = widget.priorityWordIds!.toSet();
      final prioritized = list.where((it) => prioritySet.contains((it['wordId'] ?? '').toString())).toList();
      for (final it in prioritized) {
        final fmt = ['MULTIPLE_CHOICE', 'FILL_IN_THE_BLANK', 'MATCHING'][rnd.nextInt(3)];
        _queue.add({...it, 'activityFormat': fmt});
      }
    }

    _queue.shuffle();

    setState(() {
      _reviewItems = list;
      _loading = false;
      _currentIndex = 0;
      // Do not compute final weighted score yet; will compute on finish using prior-module data.
      _weightedScore = null;
      _prepareCurrentActivityState();
    });

    // Save initial state
    LocalStorageService.saveCumulativeReviewState(widget.sessionId, {
      'reviewItems': _reviewItems,
      'queue': _queue,
      'currentIndex': _currentIndex,
      'results': _results,
      'weightedScore': _weightedScore,
    });
  }

  void _resumeSavedState() {
    if (_pendingSavedState == null) return;
    setState(() {
      final saved = _pendingSavedState!;
      _reviewItems = List<dynamic>.from(saved['reviewItems'] as List<dynamic>? ?? const []);
      _queue
        ..clear()
        ..addAll((saved['queue'] as List<dynamic>? ?? const []).whereType<Map>().map((item) => Map<String, dynamic>.from(item)));
      _currentIndex = saved['currentIndex'] as int? ?? 0;
      _results
        ..clear()
        ..addAll((saved['results'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as bool)) ?? {});
      _weightedScore = (saved['weightedScore'] as num?)?.toDouble();
      _pendingSavedState = null;
      _showResumePrompt = false;
      _prepareCurrentActivityState();
    });
  }

  Future<void> _startFresh() async {
    // Clear saved state and rebuild queue from source
    await LocalStorageService.clearCumulativeReviewState(widget.sessionId);
    setState(() {
      _pendingSavedState = null;
      _showResumePrompt = false;
      _loading = true;
    });
    // Re-run fetch to build a fresh queue
    await _fetchReviewItems();
  }

  void _playAudio(String text) {
    TTSService.speak(text);
  }

  void _recordAnswer(String wordId, bool correct) {
    _results[wordId] = correct;
    // When incorrect, enqueue reinforcement with a different activity format
    if (!correct) {
      final rnd = Random();
      final fmt = ['MULTIPLE_CHOICE', 'FILL_IN_THE_BLANK', 'MATCHING'][rnd.nextInt(3)];
      final original = _reviewItems.firstWhere((it) => ((it['wordId'] ?? '').toString()) == wordId, orElse: () => null);
      if (original != null) {
        _queue.add({...original, 'activityFormat': fmt});
      }
    }
  }

  void _nextItem() {
    setState(() {
      _currentIndex++;
      _prepareCurrentActivityState();
    });
    if (_currentIndex >= _queue.length) {
      _finishReview();
    }
  }

  Future<void> _finishReview() async {
    final lessons = Provider.of<LessonProvider>(context, listen: false);
    final module4Percent = _queue.isEmpty ? 0.0 : (_results.values.where((v) => v).length / _queue.length) * 100.0;

    // Try to load prior session summary (Modules 1-3) to compute weighted mastery.
    final prevSummary = await LocalStorageService.getSessionSummary(widget.sessionId);
    final prevMastery = prevSummary?.overallMasteryPercentage ?? 0.0;

    // Weighting: Modules 1-3 = 60%, Module 4 = 30% (final mastery expressed as percent)
    final weighted = (prevMastery * 0.60) + (module4Percent * 0.30);
    _weightedScore = weighted;

    final result = widget.isSandbox
        ? await lessons.completeSandbox(widget.sessionId)
        : await lessons.completeCategoryReview(
            sessionId: widget.sessionId,
            categoryId: widget.categoryId,
            score: _weightedScore ?? module4Percent,
          );

    int total = _queue.length;
    int mastered = _results.values.where((v) => v).length;
    List<String> missed = _queue
        .where((it) => !_results.containsKey((it['wordId'] ?? '').toString()) || _results[(it['wordId'] ?? '').toString()] == false)
        .map((it) => (it['wordId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();

    if (result != null) {
      total = result['totalItems'] as int? ?? total;
      mastered = result['masteredCount'] as int? ?? (result['correctCount'] as int? ?? mastered);
      _weightedScore = (result['score'] as num?)?.toDouble() ?? module4Percent;
      final backendMissed = result['missedWordIds'] ?? result['wordsToReview'] ?? result['missedWords'];
      if (backendMissed is List) {
        missed = backendMissed.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
    }

    await LocalStorageService.clearCumulativeReviewState(widget.sessionId);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => MasteryResultScreen(
        sessionId: widget.sessionId,
        categoryId: widget.categoryId,
        isSandbox: widget.isSandbox,
        totalItems: total,
        masteredCount: mastered,
        missedWordIds: missed,
        allWords: widget.allWords,
        masteryScore: _weightedScore,
      ),
    ));
  }

  Widget _buildCurrentActivity() {
    if (_currentIndex >= _queue.length) return const SizedBox.shrink();
    final item = _queue[_currentIndex];
    final fmt = (item['activityFormat'] ?? 'MULTIPLE_CHOICE').toString();
    switch (fmt) {
      case 'FILL_IN_THE_BLANK':
        return _buildFillInBlank(item);
      case 'MATCHING':
        return _buildMatching(item);
      default:
        return _buildMultipleChoice(item);
    }
  }

  Widget _buildMultipleChoice(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final definition = (item['definition'] ?? '').toString();
    final provided = [
      item['mcDistractor1'],
      item['mcDistractor2'],
      item['mcDistractor3'],
    ].whereType<String>().where((value) => value.isNotEmpty).toList();

    final options = <String>[correct];
    if (provided.isNotEmpty) {
      options.addAll(provided.take(3));
    } else {
      final other = _reviewItems.map((e) => e['word']?.toString() ?? '').where((w) => w.isNotEmpty && w != correct).toList();
      other.shuffle();
      for (var i = 0; i < min(3, other.length); i++) {
        options.add(other[i]);
      }
    }
    options.shuffle();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
                  child: Center(child: MascotVisual(type: _mascotForFormat((item['activityFormat'] ?? '').toString()), size: 44)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose the correct English word',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.7),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        correct,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                definition,
                style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.45),
              ),
            ),
            const SizedBox(height: 18),
            ...options.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final isCorrect = opt == correct;
                      _recordAnswer((item['wordId'] ?? '').toString(), isCorrect);
                      _nextItem();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(const Color(0xFFEFF6FF)),
                    ),
                    child: Text(
                      opt,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                )),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _playAudio(correct),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Hear word'),
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
    );
  }

  Widget _buildFillInBlank(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final sentence = (item['fitbSentence'] ?? item['example'] ?? '').toString();
    final answer = (item['fitbAnswer'] ?? correct).toString();
    final controller = TextEditingController();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fill in the missing word',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              sentence.isEmpty ? 'Type the word:' : sentence.replaceAll(answer, '_____'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.45),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Answer',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF06A6FF), width: 2)),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final answer = controller.text.trim();
                final isCorrect = answer.toLowerCase() == (item['fitbAnswer'] ?? correct).toString().toLowerCase();
                _recordAnswer((item['wordId'] ?? '').toString(), isCorrect);
                _nextItem();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06A6FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _playAudio(correct),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Hear word'),
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
    );
  }

  Widget _buildMatching(Map<String, dynamic> item) {
    final correct = (item['word'] ?? '').toString();
    final prompt = (item['definition'] ?? '').toString();
    final choices = _matchingOptions.isNotEmpty ? _matchingOptions : _buildMatchingOptions(item);
    final selectedWord = _selectedMatchingWord;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Drag or tap the matching word',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              prompt.isEmpty ? 'Choose the English word that matches the Cebuano meaning' : prompt,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.45),
            ),
            const SizedBox(height: 18),
            DragTarget<String>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) {
                setState(() {
                  _selectedMatchingWord = details.data;
                });
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isHovering ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHovering ? const Color(0xFF06A6FF) : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'DROP HERE',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        selectedWord ?? 'Drop or tap a word',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: selectedWord == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'WORD BANK',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 12,
              children: choices.map((choice) {
                final isSelected = choice == selectedWord;
                return Draggable<String>(
                  data: choice,
                  feedback: Material(
                    color: Colors.transparent,
                    child: ActionChip(
                      label: Text(
                        choice,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF334155)),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF06A6FF), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: ActionChip(
                      label: Text(
                        choice,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF334155)),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  child: ActionChip(
                    label: Text(
                      choice,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF334155)),
                    ),
                    backgroundColor: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    side: BorderSide(color: isSelected ? const Color(0xFF06A6FF) : const Color(0xFFCBD5E1), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.black.withValues(alpha: 0.04),
                    elevation: 2,
                    onPressed: () {
                      setState(() {
                        _selectedMatchingWord = choice;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: selectedWord == null
                  ? null
                  : () {
                      final isCorrect = selectedWord == correct;
                      _recordAnswer((item['wordId'] ?? '').toString(), isCorrect);
                      _nextItem();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06A6FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('CHECK', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _playAudio(correct),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Hear word'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final pref = Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;

    // If there is a saved session waiting to be resumed, show prompt UI
    if (_showResumePrompt && _pendingSavedState != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text('Cumulative Review'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Resume your previous Module 4 review?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      const Text('You have an in-progress review. Resume where you left off or start a fresh review.'),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: _startFresh,
                            child: const Text('Start Fresh'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _resumeSavedState,
                            child: const Text('Resume'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          LocalizationService.translate(pref, 'cumulative_review'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF06A6FF)))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF0FDF4), Color(0xFFFFFFFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0xFFB7E4C7), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.08),
                            blurRadius: 18,
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
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEFFAF1), Color(0xFFD1FAE5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.10),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: MascotVisual(
                                    type: _currentItem == null ? MascotType.starry : _mascotForFormat((_currentItem?['activityFormat'] ?? '').toString()),
                                    size: 58,
                                    isCelebrating: _currentIndex > 0 && _currentIndex == _queue.length - 1,
                                  ),
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
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: const Color(0xFFBBF7D0)),
                                      ),
                                      child: const Text(
                                        'MODULE 4',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: 1.0),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Mastery Review',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _currentItem == null ? 'Preparing your review...' : 'Keep going. Missed words return later in the same session.',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569), height: 1.45),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.autorenew_rounded, size: 16, color: Color(0xFF059669)),
                              const SizedBox(width: 6),
                              Text(
                                _showResumePrompt ? 'Resume available' : 'Persistent session state',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Review progress',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF059669).withValues(alpha: 0.9)),
                        ),
                        Text(
                          _queue.isEmpty ? '0%' : '${((_currentIndex + 1) / _queue.length * 100).round()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _queue.isEmpty ? 0 : (_currentIndex + 1) / _queue.length,
                          minHeight: 12,
                          backgroundColor: const Color(0x00FFFFFF),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0, bottom: 24.0),
                          child: _buildCurrentActivity(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Removed unused _goBackWithAnimation helper to satisfy analyzer.

  // _buildResumeRoute removed — navigation now uses direct pushes to MasteryResultScreen where needed.
}
