class DailyGoalModel {
  final String id;
  final String learnerId;
  final String goalDate;
  final int targetCount;
  final int currentProgress;
  final bool isCompleted;

  DailyGoalModel({
    required this.id,
    required this.learnerId,
    required this.goalDate,
    required this.targetCount,
    required this.currentProgress,
    required this.isCompleted,
  });

  factory DailyGoalModel.fromJson(Map<String, dynamic> json) {
    return DailyGoalModel(
      id: json['id'] ?? '',
      learnerId: json['learnerId'] ?? '',
      goalDate: json['goalDate'] ?? '',
      targetCount: json['targetCount'] ?? 10,
      currentProgress: json['currentProgress'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
