class RecentWordProgressModel {
  final String wordId;
  final String englishWord;
  final String cebuanoMeaning;
  final double accuracy;
  final String currentLevel; // 'LEARNING', 'FAMILIAR', 'PROFICIENT', 'MASTERED'
  final String? partOfSpeech;
  final String? lastPracticedAt;
  final int? totalAttempts;
  final int? correctCount;
  final int? incorrectCount;

  int get safeTotalAttempts => totalAttempts ?? 0;
  int get safeCorrectCount => correctCount ?? 0;
  int get safeIncorrectCount => incorrectCount ?? 0;

  RecentWordProgressModel({
    required this.wordId,
    required this.englishWord,
    required this.cebuanoMeaning,
    required this.accuracy,
    required this.currentLevel,
    this.partOfSpeech,
    this.lastPracticedAt,
    this.totalAttempts = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
  });

  factory RecentWordProgressModel.fromJson(Map<String, dynamic> json) {
    final total = json['totalAttempts'] as int? ?? 0;
    final correct = json['correctCount'] as int? ?? 0;
    final incorrect = json['incorrectCount'] as int? ?? (total > correct ? total - correct : 0);
    return RecentWordProgressModel(
      wordId: json['wordId'] ?? '',
      englishWord: json['englishWord'] ?? '',
      cebuanoMeaning: json['cebuanoMeaning'] ?? '',
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      currentLevel: json['currentLevel'] ?? 'LEARNING',
      partOfSpeech: json['partOfSpeech'],
      lastPracticedAt: json['lastPracticedAt'],
      totalAttempts: total,
      correctCount: correct,
      incorrectCount: incorrect,
    );
  }
}
