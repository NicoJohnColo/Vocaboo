import 'package:flutter/material.dart';
import '../services/tts_service.dart';

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
    if (widget.confusablePairs.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Confusable Words Distinction",
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Text(
            'No confusable pair was available for this lesson.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
        title: const Text(
          "Confusable Words Distinction",
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: LinearProgressIndicator(
                value: widget.confusablePairs.isNotEmpty ? ((_currentIndex + 1) / widget.confusablePairs.length) : 0,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                minHeight: 8,
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
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
                              border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
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
                                ElevatedButton.icon(
                                  onPressed: () => _ttsService.speak(wordAEnglish),
                                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                                  label: const Text("Listen"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
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
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                            ),
                            child: Column(
                              children: [
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
                                ElevatedButton.icon(
                                  onPressed: () => _ttsService.speak(wordBEnglish),
                                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                                  label: const Text("Listen"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      "Contrastive Exercise",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                              'Bisaya: $sentenceACebuano',
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
                              'Bisaya: $sentenceBCebuano',
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
                  ? ElevatedButton(
                      onPressed: () => _handleContinue(pair),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isCorrectA && isCorrectB) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        (isCorrectA && isCorrectB) ? "CONTINUE" : "TRY AGAIN",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: (_selectedForA != null && _selectedForB != null)
                          ? () => _checkAnswers(pair)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "SUBMIT ANSWERS",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          side: BorderSide(
            color: isSelected ? const Color(0xFF06A6FF) : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF06A6FF) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
