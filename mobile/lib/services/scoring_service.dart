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
}
