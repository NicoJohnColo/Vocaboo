/// ScoringService handles all score calculations across the app.
/// IMPORTANT POLICY: Microphone-based exercises must be fully excluded from all scoring calculations.
/// They must not contribute to the module score, the word mastery checklist, or the 60% composite input.
/// The scoring service must treat microphone exercises as non-scoring items and must never include 
/// their outcome — attempted or skipped — in any score formula.
class ScoringService {
  static const double lessonWeight = 0.6;
  static const double reviewWeight = 0.4;
  static const double passingThreshold = 70.0;

  /// Computes a percentage score from correct count and total items.
  static double computeLessonScore(int correct, int total) {
    if (total <= 0) return 0.0;
    return ((correct / total) * 100.0).clamp(0.0, 100.0);
  }

  /// Computes the combined lesson score as a simple average of two lesson scores.
  static double computeCombinedLessonScore(double score1, double score2) {
    return (score1 + score2) / 2.0;
  }

  /// Computes the final composite score based on the 60/40 weighted formula.
  static double computeFinalScore(double lessonScore, double cumulativeScore) {
    return (lessonWeight * lessonScore) + (reviewWeight * cumulativeScore);
  }

  /// Computes the final composite score from two lesson scores and one cumulative review score.
  static double computeFinalScoreFromLessons(double lesson1Score, double lesson2Score, double cumulativeScore) {
    final combinedLessonScore = computeCombinedLessonScore(lesson1Score, lesson2Score);
    return computeFinalScore(combinedLessonScore, cumulativeScore);
  }

  /// Checks if a final score meets or exceeds the passing threshold.
  static bool isPassing(double finalScore) {
    return finalScore >= passingThreshold;
  }

  /// Computes the word-level point value based on cumulative review wrong attempts.
  ///
  /// Revised non-negative scheme for Module 4 (2 attempts max):
  /// 0 wrong attempts => 1.00
  /// 1 wrong attempt  => 0.50
  /// 2+ wrong attempts => 0.25
  static double calculateWordScore(int wrongAttempts) {
    if (wrongAttempts <= 0) return 1.0;
    if (wrongAttempts == 1) return 0.5;
    return 0.25;
  }

  /// Computes the final cumulative review score based on the sum of all word scores.
  /// Clamped to [0.0, 100.0].
  static double calculateCumulativeScore(Map<String, int> wordWrongAttempts, List<String> wordIds) {
    if (wordIds.isEmpty) return 0.0;
    double sum = 0.0;
    for (final wordId in wordIds) {
      final wrong = wordWrongAttempts[wordId] ?? 0;
      sum += calculateWordScore(wrong);
    }
    return ((sum / wordIds.length) * 100.0).clamp(0.0, 100.0);
  }
}

