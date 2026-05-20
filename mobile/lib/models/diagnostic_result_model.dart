class DiagnosticResultModel {
  final String sessionId;
  final String lessonId;
  final List<String> knownWordIds;
  final List<String> unknownWordIds;

  DiagnosticResultModel({
    required this.sessionId,
    required this.lessonId,
    required this.knownWordIds,
    required this.unknownWordIds,
  });

  factory DiagnosticResultModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticResultModel(
      sessionId: json['sessionId'] ?? '',
      lessonId: json['lessonId'] ?? '',
      knownWordIds: List<String>.from(json['knownWordIds'] ?? []),
      unknownWordIds: List<String>.from(json['unknownWordIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'lessonId': lessonId,
      'knownWordIds': knownWordIds,
      'unknownWordIds': unknownWordIds,
    };
  }
}
