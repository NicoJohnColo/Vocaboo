class LearnerActivityStatsModel {
  final String learnerId;
  final int currentStreak;
  final int longestStreak;
  final int totalActiveDays;
  final Set<String> activeDates;

  const LearnerActivityStatsModel({
    required this.learnerId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalActiveDays,
    required this.activeDates,
  });

  factory LearnerActivityStatsModel.fromJson(Map<String, dynamic> json) {
    final rawDates = json['activeDates'];
    final Set<String> dates = {};
    if (rawDates is List) {
      for (final item in rawDates) {
        if (item != null) {
          dates.add(item.toString());
        }
      }
    }
    return LearnerActivityStatsModel(
      learnerId: (json['learnerId'] ?? '').toString(),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      totalActiveDays: (json['totalActiveDays'] as num?)?.toInt() ?? dates.length,
      activeDates: dates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learnerId': learnerId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalActiveDays': totalActiveDays,
      'activeDates': activeDates.toList(),
    };
  }
}
