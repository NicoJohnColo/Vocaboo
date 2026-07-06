import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_word_model.dart';
import '../providers/lesson_provider.dart';

class LessonScoreScreen extends StatelessWidget {
  final String sessionId;
  final String lessonId;
  final String categoryId;
  final String lessonTitle;
  final List<VocabularyWordModel> allWords;
  final Map<String, bool> wordPronunciationCorrect; // wordId -> isCorrect
  final Map<String, int> wordPronunciationAttempts; // wordId -> attemptCount
  final Set<String> failedSentenceWordIds; // words that failed sentence activity
  final double overallScore; // kept for compatibility, not displayed
  final bool isSandbox;
  final int? masteredCount;           // new: from sentence_building_screen
  final List<String>? needsReviewWords; // new: list of word strings needing review

  const LessonScoreScreen({
    super.key,
    required this.sessionId,
    required this.lessonId,
    required this.categoryId,
    required this.lessonTitle,
    required this.allWords,
    required this.wordPronunciationCorrect,
    required this.wordPronunciationAttempts,
    required this.failedSentenceWordIds,
    required this.overallScore,
    this.isSandbox = false,
    this.masteredCount,
    this.needsReviewWords,
  });

  @override
  Widget build(BuildContext context) {
    // Derive mastered count: prefer passed value, otherwise compute locally
    // Pronunciation correctness is fully excluded from mastery logic
    final effectiveMastered = masteredCount ??
        allWords.where((w) => !failedSentenceWordIds.contains(w.wordId)).length;

    final effectiveNeedsReview = needsReviewWords ??
        allWords
          .where((w) => failedSentenceWordIds.contains(w.wordId))
          .map((w) => w.englishWord)
          .toList();

    final totalWords = allWords.length;
    final allMastered = effectiveMastered >= totalWords;

    debugPrint('LessonScoreScreen: mastered=$effectiveMastered/$totalWords needsReview=$effectiveNeedsReview');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lesson Complete',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Center(
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: allMastered ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                          boxShadow: [
                            BoxShadow(
                              color: (allMastered ? const Color(0xFF10B981) : const Color(0xFF06A6FF)).withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            allMastered ? '🌟' : '📘',
                            style: const TextStyle(fontSize: 72),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      lessonTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      allMastered
                          ? 'Great work! You have mastered all words in this lesson.'
                          : 'You have completed all modules. Keep practising the words below.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Mastery Count Card — no percentage
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Words Mastered',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$effectiveMastered',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: allMastered ? const Color(0xFF10B981) : const Color(0xFF06A6FF),
                                  ),
                                ),
                                TextSpan(
                                  text: ' / $totalWords',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Words Needing Review
                    if (effectiveNeedsReview.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.refresh_rounded, color: Color(0xFFEF4444), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Still Needs Practice',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: effectiveNeedsReview.map((word) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                                ),
                                child: Text(
                                  word,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Per-Word Breakdown
                    const Text(
                      'Word Breakdown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...allWords.asMap().entries.map((entry) {
                      final word = entry.value;
                      final failedSentence = failedSentenceWordIds.contains(word.wordId);
                      final attempts = wordPronunciationAttempts[word.wordId] ?? 0;
                      final correct = wordPronunciationCorrect[word.wordId] ?? false;

                      final mastered = !failedSentence;

                      final statusLabel = mastered ? 'Mastered' : 'Needs Review';
                      final statusColor = mastered ? const Color(0xFF10B981) : const Color(0xFFEF4444);
                      final statusBgColor = mastered ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                mastered ? Icons.check_rounded : Icons.refresh_rounded,
                                color: statusColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    word.englishWord,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    word.cebuanoMeaning,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  if (!isSandbox && attempts > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pronunciation: $attempts attempt${attempts == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!isSandbox)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor, width: 1),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Footer Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isSandbox || categoryId.isEmpty) {
                      debugPrint('Done button: navigating to home (sandbox or empty categoryId)');
                      context.go('/home');
                      return;
                    }

                    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
                    String categoryName = 'Lessons';
                    try {
                      final category = lessonProvider.categories.firstWhere((cat) => cat.categoryId == categoryId);
                      categoryName = category.categoryName;
                    } catch (_) {}

                    debugPrint('Done button: navigating to /category/$categoryId/lessons');
                    context.go(
                      '/category/$categoryId/lessons?name=${Uri.encodeComponent(categoryName)}',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
