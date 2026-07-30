class RecentWordProgressModel {
  final String wordId;
  final String englishWord;
  final String cebuanoMeaning;
  final double accuracy;
  final String currentLevel; // 'LEARNING', 'FAMILIAR', 'PROFICIENT', 'MASTERED'
  final String? lastPracticedAt;

  RecentWordProgressModel({
    required this.wordId,
    required this.englishWord,
    required this.cebuanoMeaning,
    required this.accuracy,
    required this.currentLevel,
    this.lastPracticedAt,
  });

  factory RecentWordProgressModel.fromJson(Map<String, dynamic> json) {
    return RecentWordProgressModel(
      wordId: json['wordId'] ?? '',
      englishWord: json['englishWord'] ?? '',
      cebuanoMeaning: json['cebuanoMeaning'] ?? '',
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      currentLevel: json['currentLevel'] ?? 'LEARNING',
      lastPracticedAt: json['lastPracticedAt'],
    );
  }
}
