class LearnerLessonProgressModel {
  final String lessonId;
  final String lessonTitle;
  final String categoryId;
  final String categoryName;
  final double accuracyRate;
  final int starsEarned;
  final int totalAttempts;
  final String? completedAt;
  final String status; // 'COMPLETED', 'UNLOCKED', 'LOCKED'
  final String? classId;
  final String? className;

  LearnerLessonProgressModel({
    required this.lessonId,
    required this.lessonTitle,
    required this.categoryId,
    required this.categoryName,
    required this.accuracyRate,
    required this.starsEarned,
    required this.totalAttempts,
    this.completedAt,
    required this.status,
    this.classId,
    this.className,
  });

  factory LearnerLessonProgressModel.fromJson(Map<String, dynamic> json) {
    return LearnerLessonProgressModel(
      lessonId: json['lessonId'] ?? '',
      lessonTitle: json['lessonTitle'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      accuracyRate: (json['accuracyRate'] as num?)?.toDouble() ?? 0.0,
      starsEarned: json['starsEarned'] ?? 0,
      totalAttempts: json['totalAttempts'] ?? 0,
      completedAt: json['completedAt'],
      status: json['status'] ?? 'UNLOCKED',
      classId: json['classId'],
      className: json['className'],
    );
  }
}
