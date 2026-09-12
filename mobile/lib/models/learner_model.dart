import '../constants/app_avatars.dart';

class LearnerModel {
  final String learnerId;
  final String? userId;
  final String displayName;
  final int age;
  final String languagePreference; // 'CEBUANO_TO_ENGLISH', 'FULL_ENGLISH', 'CEBUANO_ENGLISH_MIXED'
  final String? gradeLevel; // 'GRADE_4', 'GRADE_5', 'GRADE_6'
  final bool onboardingComplete;
  final bool masteryApplyImmediately;
  final String posFocus; // 'ALL', 'NOUN', 'VERB', 'ADJECTIVE'
  final String avatar;
  final int totalPoints;
  final String masteryLevel;

  LearnerModel({
    required this.learnerId,
    this.userId,
    required this.displayName,
    required this.age,
    required this.languagePreference,
    this.gradeLevel,
    required this.onboardingComplete,
    required this.masteryApplyImmediately,
    this.posFocus = 'ALL',
    this.avatar = 'prof1.jpg',
    this.totalPoints = 0,
    this.masteryLevel = 'LEARNING',
  });

  factory LearnerModel.fromJson(Map<String, dynamic> json) {
    return LearnerModel(
      learnerId: json['learnerId'] ?? json['learner_id'] ?? '',
      userId: json['userId'] ?? json['user_id'],
      displayName: json['displayName'] ?? json['display_name'] ?? '',
      age: json['age'] ?? 9,
      languagePreference: json['languagePreference'] ?? json['language_preference'] ?? 'CEBUANO_TO_ENGLISH',
      gradeLevel: json['gradeLevel'] ?? json['grade_level'] ?? 'GRADE_4',
      onboardingComplete: json['onboardingComplete'] ?? json['onboarding_complete'] ?? false,
      masteryApplyImmediately: json['masteryApplyImmediately'] ?? json['mastery_apply_immediately'] ?? true,
      posFocus: json['posFocus'] ?? json['pos_focus'] ?? 'ALL',
      avatar: AppAvatars.normalize(json['avatar'], seed: (json['displayName'] ?? json['learnerId'])?.toString()),
      totalPoints: json['totalPoints'] ?? json['total_points'] ?? 0,
      masteryLevel: json['masteryLevel'] ?? json['mastery_level'] ?? 'LEARNING',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learnerId': learnerId,
      'learner_id': learnerId,
      'userId': userId,
      'user_id': userId,
      'displayName': displayName,
      'display_name': displayName,
      'age': age,
      'languagePreference': languagePreference,
      'language_preference': languagePreference,
      'gradeLevel': gradeLevel,
      'grade_level': gradeLevel,
      'onboardingComplete': onboardingComplete,
      'onboarding_complete': onboardingComplete,
      'masteryApplyImmediately': masteryApplyImmediately,
      'mastery_apply_immediately': masteryApplyImmediately,
      'posFocus': posFocus,
      'pos_focus': posFocus,
      'avatar': avatar,
      'totalPoints': totalPoints,
      'total_points': totalPoints,
      'masteryLevel': masteryLevel,
      'mastery_level': masteryLevel,
    };
  }

  LearnerModel copyWith({
    String? learnerId,
    String? userId,
    String? displayName,
    int? age,
    String? languagePreference,
    String? gradeLevel,
    bool? onboardingComplete,
    bool? masteryApplyImmediately,
    String? posFocus,
    String? avatar,
    int? totalPoints,
    String? masteryLevel,
  }) {
    return LearnerModel(
      learnerId: learnerId ?? this.learnerId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      languagePreference: languagePreference ?? this.languagePreference,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      masteryApplyImmediately: masteryApplyImmediately ?? this.masteryApplyImmediately,
      posFocus: posFocus ?? this.posFocus,
      avatar: avatar ?? this.avatar,
      totalPoints: totalPoints ?? this.totalPoints,
      masteryLevel: masteryLevel ?? this.masteryLevel,
    );
  }
}
