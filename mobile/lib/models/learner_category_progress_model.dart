class LearnerCategoryProgressModel {
  final String categoryId;
  final String categoryName;
  final int totalLessons;
  final int completedLessons;
  final double categoryAccuracy;

  LearnerCategoryProgressModel({
    required this.categoryId,
    required this.categoryName,
    required this.totalLessons,
    required this.completedLessons,
    required this.categoryAccuracy,
  });

  factory LearnerCategoryProgressModel.fromJson(Map<String, dynamic> json) {
    return LearnerCategoryProgressModel(
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      totalLessons: json['totalLessons'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      categoryAccuracy: (json['categoryAccuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
