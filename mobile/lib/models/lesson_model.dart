class LessonModel {
  final String lessonId;
  final String categoryId;
  final String lessonTitle;
  final String lessonDescription;
  final String gradeLevel;
  final int lessonOrder;
  final int totalWordCount;
  final int masteredWordCount;
  final String status; // 'LOCKED', 'UNLOCKED', 'COMPLETED'
  final double? masteryScore;
  final String? lessonType; // 'REGULAR', 'COMPOSITE_REVIEW'
  final List<String>? sourceLessonIds; // For composite review lessons
  final String? compositeReviewAfterLessonId; // Configurable node insertion position
  final String? contextParagraph;
  final String? module2Activities;
  final String? module3Activities;
  final String? module4Activities;
  final int? upgradeStreakRequired;
  final int? demotionThreshold;
  final int? reintroductionThreshold;
  final int? module3UpgradeStreakRequired;
  final int? module3DemotionThreshold;
  final int? streakCelebrationThreshold;
  final String? classId;
  final String? className;
  final Map<String, int> posTotalWordCounts;
  final Map<String, int> posMasteredWordCounts;

  LessonModel({
    required this.lessonId,
    required this.categoryId,
    required this.lessonTitle,
    required this.lessonDescription,
    required this.gradeLevel,
    required this.lessonOrder,
    required this.totalWordCount,
    this.masteredWordCount = 0,
    required this.status,
    this.masteryScore,
    this.lessonType,
    this.sourceLessonIds,
    this.compositeReviewAfterLessonId,
    this.contextParagraph,
    this.module2Activities,
    this.module3Activities,
    this.module4Activities,
    this.upgradeStreakRequired,
    this.demotionThreshold,
    this.reintroductionThreshold,
    this.module3UpgradeStreakRequired,
    this.module3DemotionThreshold,
    this.streakCelebrationThreshold,
    this.classId,
    this.className,
    this.posTotalWordCounts = const {},
    this.posMasteredWordCounts = const {},
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
      masteredWordCount: json['masteredWordCount'] ?? 0,
      status: json['status'] ?? 'LOCKED',
      masteryScore: json['masteryScore'] != null ? (json['masteryScore'] as num).toDouble() : null,
      lessonType: json['lessonType'],
      sourceLessonIds: json['sourceLessonIds'] != null 
          ? List<String>.from(json['sourceLessonIds']) 
          : null,
      compositeReviewAfterLessonId: json['compositeReviewAfterLessonId'],
      contextParagraph: json['contextParagraph'],
      module2Activities: json['module2Activities'] ?? json['module2_activities'],
      module3Activities: json['module3Activities'] ?? json['module3_activities'],
      module4Activities: json['module4Activities'] ?? json['module4_activities'],
      upgradeStreakRequired: json['upgradeStreakRequired'] ?? json['upgrade_streak_required'],
      demotionThreshold: json['demotionThreshold'] ?? json['demotion_threshold'],
      reintroductionThreshold: json['reintroductionThreshold'] ?? json['reintroduction_threshold'],
      module3UpgradeStreakRequired: json['module3UpgradeStreakRequired'] ?? json['module3_upgrade_streak_required'],
      module3DemotionThreshold: json['module3DemotionThreshold'] ?? json['module3_demotion_threshold'],
      streakCelebrationThreshold: json['streakCelebrationThreshold'] ?? json['streak_celebration_threshold'],
      classId: json['classId'] ?? json['class_id'],
      className: json['className'] ?? json['class_name'],
      posTotalWordCounts: json['posTotalWordCounts'] != null
          ? (json['posTotalWordCounts'] as Map).map((k, v) => MapEntry(k.toString().toUpperCase(), (v as num).toInt()))
          : const {},
      posMasteredWordCounts: json['posMasteredWordCounts'] != null
          ? (json['posMasteredWordCounts'] as Map).map((k, v) => MapEntry(k.toString().toUpperCase(), (v as num).toInt()))
          : const {},
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
      'masteredWordCount': masteredWordCount,
      'status': status,
      'masteryScore': masteryScore,
      'lessonType': lessonType,
      'sourceLessonIds': sourceLessonIds,
      'compositeReviewAfterLessonId': compositeReviewAfterLessonId,
      'contextParagraph': contextParagraph,
      'module2Activities': module2Activities,
      'module3Activities': module3Activities,
      'module4Activities': module4Activities,
      'upgradeStreakRequired': upgradeStreakRequired,
      'demotionThreshold': demotionThreshold,
      'reintroductionThreshold': reintroductionThreshold,
      'module3UpgradeStreakRequired': module3UpgradeStreakRequired,
      'module3DemotionThreshold': module3DemotionThreshold,
      'streakCelebrationThreshold': streakCelebrationThreshold,
      'classId': classId,
      'className': className,
      'posTotalWordCounts': posTotalWordCounts,
      'posMasteredWordCounts': posMasteredWordCounts,
    };
  }

  bool get isLocked => status == 'LOCKED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isUnlocked => status == 'UNLOCKED';
  bool get isCompositeReview => lessonType == 'COMPOSITE_REVIEW';
}
