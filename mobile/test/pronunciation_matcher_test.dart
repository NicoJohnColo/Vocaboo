import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/pronunciation_matcher.dart';

void main() {
  group('PronunciationMatcher', () {
    test('matches exact transcript', () {
      expect(PronunciationMatcher.matchesTranscript('mother', 'mother'), isTrue);
    });

    test('matches transcript with punctuation and spacing', () {
      expect(PronunciationMatcher.matchesTranscript('  mo-ther!  ', 'mother'), isTrue);
    });

    test('rejects clearly different transcript', () {
      expect(PronunciationMatcher.matchesTranscript('banana', 'mother'), isFalse);
    });

    test('normalizes transcript text', () {
      expect(PronunciationMatcher.normalize('  Hello, World!  '), 'hello world');
    });
  });
}