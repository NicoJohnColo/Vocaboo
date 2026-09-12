import 'package:flutter/material.dart';
import 'mastery_result_screen.dart';

class CumulativeReviewSummaryScreen extends StatelessWidget {
  final String sessionId;
  final int correct;
  final int total;
  final double? score;
  final String? lessonId;
  final String? categoryId;
  final String? lessonTitle;
  final List<Map<String, dynamic>> allWords;
  final List<Map<String, dynamic>> wordBreakdown;
  final bool isSandbox;

  const CumulativeReviewSummaryScreen({
    super.key,
    required this.sessionId,
    required this.correct,
    required this.total,
    this.score,
    this.lessonId,
    this.categoryId,
    this.lessonTitle,
    this.allWords = const [],
    this.wordBreakdown = const [],
    this.isSandbox = false,
  });

  @override
  Widget build(BuildContext context) {
    final missedWordIds = wordBreakdown
        .where((w) => ((w['wrongAttempts'] as int?) ?? 0) > 0)
        .map((w) => (w['wordId'] ?? w['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();

    return MasteryResultScreen(
      sessionId: sessionId,
      categoryId: categoryId ?? '',
      isSandbox: isSandbox,
      totalItems: total > 0 ? total : (allWords.isNotEmpty ? allWords.length : wordBreakdown.length),
      masteredCount: correct > 0 ? correct : (total - missedWordIds.length),
      missedWordIds: missedWordIds,
      allWords: allWords,
      masteryScore: score,
      wordBreakdown: wordBreakdown,
    );
  }
}
