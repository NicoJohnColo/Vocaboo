class WordProgressModel {
  final String progressId;
  final String sessionId;
  final String wordId;
  final String pathway; // 'FULL', 'ACCELERATED'
  final int stepCompleted; // 0 to 4
  final String status; // 'INTRODUCED', 'NEEDS_PRONUNCIATION_REVIEW', etc.
  final String? completedAt;

  WordProgressModel({
    required this.progressId,
    required this.sessionId,
    required this.wordId,
    required this.pathway,
    required this.stepCompleted,
    required this.status,
    this.completedAt,
  });

  factory WordProgressModel.fromJson(Map<String, dynamic> json) {
    return WordProgressModel(
      progressId: json['progressId'] ?? '',
      sessionId: json['sessionId'] ?? '',
      wordId: json['wordId'] ?? '',
      pathway: json['pathway'] ?? 'FULL',
      stepCompleted: json['stepCompleted'] ?? 0,
      status: json['status'] ?? 'INTRODUCED',
      completedAt: json['completedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progressId': progressId,
      'sessionId': sessionId,
      'wordId': wordId,
      'pathway': pathway,
      'stepCompleted': stepCompleted,
      'status': status,
      'completedAt': completedAt,
    };
  }
}
