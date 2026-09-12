/// Model for a learner's performance within a single classroom.
/// This is parallel to (but independent from) the global LearnerMastery stats.
class ClassPerformanceModel {
  final String classId;
  final String className;
  final String classCode;

  /// Total points earned while in this class context.
  final int classPoints;

  /// Overall accuracy (0–100) within this class context.
  final double classAccuracy;

  /// Derived mastery level: LEARNING / FAMILIAR / PROFICIENT / MASTERED
  final String classMasteryLevel;

  /// Number of sessions completed in this class context.
  final int classSessionsPlayed;

  /// Total questions answered in class context.
  final int classTotalQuestions;

  /// Total correct answers in class context.
  final int classCorrectAnswers;

  /// The learner's rank within this class leaderboard (null if not fetched).
  final int? classRank;

  ClassPerformanceModel({
    required this.classId,
    required this.className,
    required this.classCode,
    required this.classPoints,
    required this.classAccuracy,
    required this.classMasteryLevel,
    required this.classSessionsPlayed,
    required this.classTotalQuestions,
    required this.classCorrectAnswers,
    this.classRank,
  });

  factory ClassPerformanceModel.fromJson(Map<String, dynamic> json) {
    return ClassPerformanceModel(
      classId: json['classId']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      classCode: json['classCode']?.toString() ?? '',
      classPoints: (json['classPoints'] as num?)?.toInt() ?? 0,
      classAccuracy: (json['classAccuracy'] as num?)?.toDouble() ?? 0.0,
      classMasteryLevel: json['classMasteryLevel']?.toString() ?? 'LEARNING',
      classSessionsPlayed: (json['classSessionsPlayed'] as num?)?.toInt() ?? 0,
      classTotalQuestions: (json['classTotalQuestions'] as num?)?.toInt() ?? 0,
      classCorrectAnswers: (json['classCorrectAnswers'] as num?)?.toInt() ?? 0,
      classRank: (json['classRank'] as num?)?.toInt(),
    );
  }

  /// Returns a human-readable mastery label.
  String get masteryLabel {
    switch (classMasteryLevel.toUpperCase()) {
      case 'MASTERED':   return 'Mastered';
      case 'PROFICIENT': return 'Proficient';
      case 'FAMILIAR':   return 'Familiar';
      default:           return 'Learning';
    }
  }

  /// Returns accuracy as a percentage string like "82%".
  String get accuracyLabel => '${classAccuracy.toStringAsFixed(0)}%';

  /// Empty/zero placeholder (used before data loads).
  factory ClassPerformanceModel.empty(String classId) {
    return ClassPerformanceModel(
      classId: classId,
      className: '',
      classCode: '',
      classPoints: 0,
      classAccuracy: 0.0,
      classMasteryLevel: 'LEARNING',
      classSessionsPlayed: 0,
      classTotalQuestions: 0,
      classCorrectAnswers: 0,
    );
  }
}
