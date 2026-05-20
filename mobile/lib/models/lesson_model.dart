class LessonModel {
  final String lessonId;
  final String categoryId;
  final String lessonTitle;
  final String lessonDescription;
  final String gradeLevel;
  final int lessonOrder;
  final int totalWordCount;
  final String status; // 'LOCKED', 'UNLOCKED', 'COMPLETED'
  final double? masteryScore;

  LessonModel({
    required this.lessonId,
    required this.categoryId,
    required this.lessonTitle,
    required this.lessonDescription,
    required this.gradeLevel,
    required this.lessonOrder,
    required this.totalWordCount,
    required this.status,
    this.masteryScore,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      lessonId: json['lessonId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      lessonTitle: json['lessonTitle'] ?? '',
      lessonDescription: json['lessonDescription'] ?? '',
      gradeLevel: json['gradeLevel'] ?? 'GRADE_4',
      lessonOrder: json['lessonOrder'] ?? 1,
      totalWordCount: json['totalWordCount'] ?? 0,
      status: json['status'] ?? 'LOCKED',
      masteryScore: json['masteryScore'] != null ? (json['masteryScore'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'categoryId': categoryId,
      'lessonTitle': lessonTitle,
      'lessonDescription': lessonDescription,
      'gradeLevel': gradeLevel,
      'lessonOrder': lessonOrder,
      'totalWordCount': totalWordCount,
      'status': status,
      'masteryScore': masteryScore,
    };
  }

  bool get isLocked => status == 'LOCKED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isUnlocked => status == 'UNLOCKED';
}
