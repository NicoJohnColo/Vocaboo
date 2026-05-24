import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/scoring_service.dart';

void main() {
  group('ScoringService', () {
    test('computes lesson percentage correctly', () {
      expect(ScoringService.computeLessonScore(8, 10), 80.0);
      expect(ScoringService.computeLessonScore(0, 0), 0.0);
    });

    test('averages lesson scores for combined lesson score', () {
      expect(ScoringService.computeCombinedLessonScore(90.0, 70.0), 80.0);
    });

    test('computes final weighted score using 60/40 split', () {
      expect(ScoringService.computeFinalScore(90.0, 50.0), 74.0);
    });

    test('computes final weighted score from two lesson scores and review score', () {
      expect(ScoringService.computeFinalScoreFromLessons(80.0, 100.0, 50.0), 74.0);
    });

    test('applies the default passing threshold of 70', () {
      expect(ScoringService.isPassing(70.0), isTrue);
      expect(ScoringService.isPassing(69.9), isFalse);
    });
  });
}
