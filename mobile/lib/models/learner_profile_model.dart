
class LearnerProfileModel {
  final String learnerId;
  final String displayName;
  final int age;
  final String pin; // stored raw temporarily during registration, normally verified
  final String languagePreference;
  final bool onboardingComplete;
  final String createdAt;

  LearnerProfileModel({
    required this.learnerId,
    required this.displayName,
    required this.age,
    required this.pin,
    required this.languagePreference,
    this.onboardingComplete = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'learner_id': learnerId,
      'display_name': displayName,
      'age': age,
      'language_preference': languagePreference,
      'onboarding_complete': onboardingComplete ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory LearnerProfileModel.fromMap(Map<String, dynamic> map) {
    return LearnerProfileModel(
      learnerId: map['learner_id'] ?? '',
      displayName: map['display_name'] ?? '',
      age: map['age'] ?? 0,
      pin: '', // PIN is never persisted back from the server response
      languagePreference: map['language_preference'] ?? 'CEBUANO_TO_ENGLISH',
      onboardingComplete: (map['onboarding_complete'] ?? 0) == 1,
      createdAt: map['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learnerId': learnerId,
      'displayName': displayName,
      'age': age,
      'pin': pin,
      'languagePreference': languagePreference,
      'onboardingComplete': onboardingComplete,
      'createdAt': createdAt,
    };
  }
}
