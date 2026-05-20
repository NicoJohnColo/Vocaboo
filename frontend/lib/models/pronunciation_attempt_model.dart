class PronunciationAttemptModel {
  final String attemptId;
  final bool isCorrect;
  final String? transcribedText;
  final String? phoneticTarget;
  final String? phonologicalTip;
  final int attemptNumber;
  final bool isInconclusive;

  PronunciationAttemptModel({
    required this.attemptId,
    required this.isCorrect,
    this.transcribedText,
    this.phoneticTarget,
    this.phonologicalTip,
    required this.attemptNumber,
    required this.isInconclusive,
  });

  factory PronunciationAttemptModel.fromJson(Map<String, dynamic> json) {
    return PronunciationAttemptModel(
      attemptId: json['attemptId'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      transcribedText: json['transcribedText'],
      phoneticTarget: json['phoneticTarget'],
      phonologicalTip: json['phonologicalTip'],
      attemptNumber: json['attemptNumber'] ?? 1,
      isInconclusive: json['isInconclusive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attemptId': attemptId,
      'isCorrect': isCorrect,
      'transcribedText': transcribedText,
      'phoneticTarget': phoneticTarget,
      'phonologicalTip': phonologicalTip,
      'attemptNumber': attemptNumber,
      'isInconclusive': isInconclusive,
    };
  }
}
