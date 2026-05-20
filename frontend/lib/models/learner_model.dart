class LearnerModel {
  final String learnerId;
  final String displayName;
  final int age;
  final String languagePreference; // 'CEBUANO_TO_ENGLISH', 'FULL_ENGLISH', 'CEBUANO_ENGLISH_MIXED'
  final bool onboardingComplete;

  LearnerModel({
    required this.learnerId,
    required this.displayName,
    required this.age,
    required this.languagePreference,
    required this.onboardingComplete,
  });

  factory LearnerModel.fromJson(Map<String, dynamic> json) {
    return LearnerModel(
      learnerId: json['learnerId'] ?? '',
      displayName: json['displayName'] ?? '',
      age: json['age'] ?? 9,
      languagePreference: json['languagePreference'] ?? 'CEBUANO_TO_ENGLISH',
      onboardingComplete: json['onboardingComplete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learnerId': learnerId,
      'displayName': displayName,
      'age': age,
      'languagePreference': languagePreference,
      'onboardingComplete': onboardingComplete,
    };
  }
}
