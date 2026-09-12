
import '../constants/app_avatars.dart';

class LearnerProfileModel {
  final String learnerId;
  final String? userId;
  final String displayName;
  final int age;
  final String pin; // stored raw temporarily during registration, normally verified
  final String languagePreference;
  final String? gradeLevel; // 'GRADE_4', 'GRADE_5', 'GRADE_6'
  final bool onboardingComplete;
  final String avatar;
  final String createdAt;

  LearnerProfileModel({
    required this.learnerId,
    this.userId,
    required this.displayName,
    required this.age,
    required this.pin,
    required this.languagePreference,
    this.gradeLevel,
    this.onboardingComplete = false,
    this.avatar = 'prof1.jpg',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'learner_id': learnerId,
      'user_id': userId,
      'display_name': displayName,
      'age': age,
      'language_preference': languagePreference,
      'grade_level': gradeLevel,
      'gradeLevel': gradeLevel,
      'onboarding_complete': onboardingComplete ? 1 : 0,
      'avatar': avatar,
      'created_at': createdAt,
    };
  }

  factory LearnerProfileModel.fromMap(Map<String, dynamic> map) {
    return LearnerProfileModel(
      learnerId: map['learner_id'] ?? map['learnerId'] ?? '',
      userId: map['user_id'] ?? map['userId'],
      displayName: map['display_name'] ?? map['displayName'] ?? '',
      age: map['age'] ?? 0,
      pin: '', // PIN is never persisted back from the server response
      languagePreference: map['language_preference'] ?? map['languagePreference'] ?? 'CEBUANO_TO_ENGLISH',
      gradeLevel: map['grade_level'] ?? map['gradeLevel'] ?? 'GRADE_4',
      onboardingComplete: (map['onboarding_complete'] ?? map['onboardingComplete'] ?? 0) == 1 || map['onboarding_complete'] == true || map['onboardingComplete'] == true,
      avatar: AppAvatars.normalize(map['avatar'], seed: (map['display_name'] ?? map['learner_id'])?.toString()),
      createdAt: map['created_at'] ?? map['createdAt'] ?? '',
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
      'pin': pin,
      'languagePreference': languagePreference,
      'language_preference': languagePreference,
      'gradeLevel': gradeLevel,
      'grade_level': gradeLevel,
      'onboardingComplete': onboardingComplete,
      'onboarding_complete': onboardingComplete,
      'avatar': avatar,
      'createdAt': createdAt,
    };
  }
}
