class PronunciationMatcher {
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool matchesTranscript(String transcript, String targetWord) {
    final normalizedTranscript = normalize(transcript);
    final normalizedTarget = normalize(targetWord);

    if (normalizedTranscript.isEmpty || normalizedTarget.isEmpty) {
      return false;
    }

    if (normalizedTranscript.contains(normalizedTarget)) {
      return true;
    }

    final longestCommonSubstringRatio =
        longestCommonSubstring(normalizedTranscript, normalizedTarget) /
            (normalizedTarget.isNotEmpty ? normalizedTarget.length : 1);
    if (longestCommonSubstringRatio >= 0.80) {
      return true;
    }

    return normalizedSimilarity(normalizedTranscript, normalizedTarget) >= 0.80;
  }

  static double normalizedSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final longest = a.length > b.length ? a.length : b.length;
    if (longest == 0) return 0.0;
    final distance = levenshteinDistance(a, b);
    return 1.0 - (distance / longest);
  }

  static int levenshteinDistance(String a, String b) {
    final rows = a.length + 1;
    final cols = b.length + 1;
    final matrix = List.generate(rows, (_) => List<int>.filled(cols, 0));

    for (var i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final deletion = matrix[i - 1][j] + 1;
        final insertion = matrix[i][j - 1] + 1;
        final substitution = matrix[i - 1][j - 1] + cost;

        matrix[i][j] = deletion < insertion
            ? (deletion < substitution ? deletion : substitution)
            : (insertion < substitution ? insertion : substitution);
      }
    }

    return matrix[rows - 1][cols - 1];
  }

  static int longestCommonSubstring(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;

    final rows = a.length;
    final cols = b.length;
    List<int> previousRow = List<int>.filled(cols + 1, 0);
    int maxLength = 0;

    for (var i = 1; i <= rows; i++) {
      final currentRow = List<int>.filled(cols + 1, 0);
      for (var j = 1; j <= cols; j++) {
        if (a[i - 1] == b[j - 1]) {
          currentRow[j] = previousRow[j - 1] + 1;
          if (currentRow[j] > maxLength) {
            maxLength = currentRow[j];
          }
        }
      }
      previousRow = currentRow;
    }

    return maxLength;
  }
}