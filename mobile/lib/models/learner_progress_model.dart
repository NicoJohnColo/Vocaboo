class LearnerProgressModel {
  final String learnerId;
  final int totalSessionsPlayed;
  final int totalCorrectAnswers;
  final int totalQuestionsAnswered;
  final double overallAccuracy;
  final int wordsMasteredCount;
  final int totalPoints;
  final int pointsThisWeek;
  final String masteryLevel; // 'LEARNING', 'FAMILIAR', 'PROFICIENT', 'MASTERED'

  LearnerProgressModel({
    required this.learnerId,
    required this.totalSessionsPlayed,
    required this.totalCorrectAnswers,
    required this.totalQuestionsAnswered,
    required this.overallAccuracy,
    required this.wordsMasteredCount,
    required this.totalPoints,
    required this.pointsThisWeek,
    required this.masteryLevel,
  });

  factory LearnerProgressModel.fromJson(Map<String, dynamic> json) {
    return LearnerProgressModel(
      learnerId: json['learnerId'] ?? '',
      totalSessionsPlayed: json['totalSessionsPlayed'] ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] ?? 0,
      totalQuestionsAnswered: json['totalQuestionsAnswered'] ?? 0,
      overallAccuracy: (json['overallAccuracy'] as num?)?.toDouble() ?? 0.0,
      wordsMasteredCount: json['wordsMasteredCount'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      pointsThisWeek: json['pointsThisWeek'] ?? 0,
      masteryLevel: json['masteryLevel'] ?? 'LEARNING',
    );
  }
}
