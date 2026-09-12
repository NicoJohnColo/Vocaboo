import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import '../core/motion/motion.dart';

class ConfusableWordsDistinctionScreen extends StatefulWidget {
  final String sessionId;
  final String lessonId;
  final List<Map<String, dynamic>> confusablePairs;

  const ConfusableWordsDistinctionScreen({
    super.key,
    required this.sessionId,
    required this.lessonId,
    required this.confusablePairs,
  });

  @override
  State<ConfusableWordsDistinctionScreen> createState() => _ConfusableWordsDistinctionScreenState();
}

class _ConfusableWordsDistinctionScreenState extends State<ConfusableWordsDistinctionScreen> {
  final TtsService _ttsService = TtsService();

  int _currentIndex = 0;
  bool _isChecked = false;
  Map<String, bool> _results = {}; // pairId -> isMastered

  // Question selection states
  String? _selectedForA; // Selected word for Blank A (contrastiveSentenceA)
  String? _selectedForB; // Selected word for Blank B (contrastiveSentenceB)

  @override
  void initState() {
    super.initState();
    _results = {for (var pair in widget.confusablePairs) pair['pairId'] as String: true};
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.initialize();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _checkAnswers(Map<String, dynamic> pair) {
    final wordA = pair['wordA']['englishWord'] as String;
    final wordB = pair['wordB']['englishWord'] as String;

    final isCorrectA = _selectedForA?.toLowerCase() == wordA.toLowerCase();
    final isCorrectB = _selectedForB?.toLowerCase() == wordB.toLowerCase();

    setState(() {
      _isChecked = true;
      if (!isCorrectA || !isCorrectB) {
        _results[pair['pairId'] as String] = false; // Mark as NEEDS_REVIEW
      }
    });
  }

  void _handleContinue(Map<String, dynamic> pair) {
    final wordA = pair['wordA']['englishWord'] as String;
    final wordB = pair['wordB']['englishWord'] as String;

    final isCorrectA = _selectedForA?.toLowerCase() == wordA.toLowerCase();
    final isCorrectB = _selectedForB?.toLowerCase() == wordB.toLowerCase();

    if (isCorrectA && isCorrectB) {
      if (_currentIndex + 1 < widget.confusablePairs.length) {
        setState(() {
          _currentIndex++;
          _isChecked = false;
          _selectedForA = null;
          _selectedForB = null;
        });
      } else {
        // All completed, pop back to SentenceBuildingScreen with results
        Navigator.of(context).pop(_results);
      }
    } else {
      // User must try again
      setState(() {
        _isChecked = false;
        _selectedForA = null;
        _selectedForB = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    if (widget.confusablePairs.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            "Confusable Words Distinction",
            style: AppTypography.baloo2(fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Text(
            'No confusable pair was available for this lesson.',
            style: AppTypography.nunito(fontSize: 14, color: const Color(0xFF64748B)),
          ),
        ),
      );
    }

    final pair = widget.confusablePairs[_currentIndex];

    final wordA = pair['wordA'] as Map<String, dynamic>;
    final wordB = pair['wordB'] as Map<String, dynamic>;

    final wordAEnglish = wordA['englishWord'] as String;
    final wordACebuano = wordA['cebuanoMeaning'] as String;
    final wordBEnglish = wordB['englishWord'] as String;
    final wordBCebuano = wordB['cebuanoMeaning'] as String;

    final sentenceA = pair['contrastiveSentenceA'] as String;
    final sentenceB = pair['contrastiveSentenceB'] as String;
    final sentenceACebuano = (pair['contrastiveSentenceACebuano'] ?? wordA['exampleSentenceCebuano'] ?? '') as String;
    final sentenceBCebuano = (pair['contrastiveSentenceBCebuano'] ?? wordB['exampleSentenceCebuano'] ?? '') as String;

    // Create sentence frames with blank
    final sentenceAFrame = sentenceA.replaceAll(
      RegExp('\b${RegExp.escape(wordAEnglish)}\b', caseSensitive: false),
      '________',
    );
    final sentenceBFrame = sentenceB.replaceAll(
      RegExp('\b${RegExp.escape(wordBEnglish)}\b', caseSensitive: false),
      '________',
    );

    final isCorrectA = _selectedForA?.toLowerCase() == wordAEnglish.toLowerCase();
    final isCorrectB = _selectedForB?.toLowerCase() == wordBEnglish.toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
          onPressed: () => Navigator.of(context).pop(_results),
        ),
        title: Text(
          'Confusable Words (${_currentIndex + 1}/${widget.confusablePairs.length})',
          style: AppTypography.baloo2(
            color: const Color(0xFF06A6FF),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: App3DProgressBar(
                value: widget.confusablePairs.isNotEmpty
                    ? ((_currentIndex + 1) / widget.confusablePairs.length)
                    : 0,
                height: 20.0,
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                key: ValueKey('confusable_${pair['pairId']}_$_currentIndex'),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "These words look or sound similar, but have different meanings. Compare them:",
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Side-by-side comparative cards
                    Row(
                      children: [
                        // Word A Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF0EA5E9), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  wordAEnglish,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0369A1)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Cebuano: $wordACebuano",
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                App3DButton(
                                  onPressed: () => _ttsService.speak(wordAEnglish),
                                  icon: Icons.volume_up_rounded,
                                  text: LocalizationService.translate(pref, 'listen'),
                                  customBaseColor: const Color(0xFF0EA5E9),
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

                        // Word B Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
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
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Cebuano: $wordBCebuano",
                                  style: const TextStyle(fontSize: 13, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                App3DButton(
                                  onPressed: () => _ttsService.speak(wordBEnglish),
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
                    const SizedBox(height: 32),

                    Text(
                      LocalizationService.translate(pref, 'contrastive_exercise'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 16),

                    // Contrastive Blank 1
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            sentenceAFrame,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          if (sentenceACebuano.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                             Text(
                               'Cebuano: $sentenceACebuano',
                               style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontStyle: FontStyle.italic),
                             ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildChoiceButton(wordAEnglish, _selectedForA == wordAEnglish, () {
                                if (_isChecked) return;
                                setState(() => _selectedForA = wordAEnglish);
                              }),
                              const SizedBox(width: 12),
                              _buildChoiceButton(wordBEnglish, _selectedForA == wordBEnglish, () {
                                if (_isChecked) return;
                                setState(() => _selectedForA = wordBEnglish);
                              }),
                            ],
                          ),
                          if (_isChecked && !isCorrectA)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Incorrect. The correct sentence is: \"$sentenceA\"",
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contrastive Blank 2
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            sentenceBFrame,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          if (sentenceBCebuano.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                             Text(
                               'Cebuano: $sentenceBCebuano',
                               style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontStyle: FontStyle.italic),
                             ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildChoiceButton(wordAEnglish, _selectedForB == wordAEnglish, () {
                                if (_isChecked) return;
                                setState(() => _selectedForB = wordAEnglish);
                              }),
                              const SizedBox(width: 12),
                              _buildChoiceButton(wordBEnglish, _selectedForB == wordBEnglish, () {
                                if (_isChecked) return;
                                setState(() => _selectedForB = wordBEnglish);
                              }),
                            ],
                          ),
                          if (_isChecked && !isCorrectB)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Incorrect. The correct sentence is: \"$sentenceB\"",
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit / Continue footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
              ),
              child: _isChecked
                  ? App3DButton(
                      onPressed: () => _handleContinue(pair),
                      variant: (isCorrectA && isCorrectB) ? App3DButtonVariant.success : App3DButtonVariant.danger,
                      height: 54,
                      depth: 5.0,
                      isFullWidth: true,
                      text: (isCorrectA && isCorrectB)
                          ? LocalizationService.translate(pref, 'continue').toUpperCase()
                          : LocalizationService.translate(pref, 'try_again'),
                    )
                  : App3DButton(
                      onPressed: (_selectedForA != null && _selectedForB != null)
                          ? () => _checkAnswers(pair)
                          : null,
                      variant: App3DButtonVariant.warning,
                      height: 54,
                      depth: 5.0,
                      isFullWidth: true,
                      text: LocalizationService.translate(pref, 'submit_answers'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: App3DChoiceTile(
        text: text,
        state: isSelected ? App3DChoiceState.selected : App3DChoiceState.idle,
        onTap: onTap,
        depth: 3.5,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }
}
