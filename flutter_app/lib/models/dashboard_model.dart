class DashboardSummaryModel {
  final String welcomeMessage;
  final String todayDate;
  final double completionPercentage;
  final int totalTasksToday;
  final int completedTasksToday;
  final int pendingTasksToday;
  final int waterIntakeTodayMl;
  final int waterTargetMl;
  final double currentWeightKg;
  final double targetWeightKg;
  final bool workoutCompletedToday;
  final int gateTopicsCompleted;
  final int gateTotalTopics;
  final double semesterAvgCompletionPct;
  final int? daysSinceLastPeriod;
  final int recentBloatingLevel;

  DashboardSummaryModel({
    required this.welcomeMessage,
    required this.todayDate,
    required this.completionPercentage,
    required this.totalTasksToday,
    required this.completedTasksToday,
    required this.pendingTasksToday,
    required this.waterIntakeTodayMl,
    required this.waterTargetMl,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.workoutCompletedToday,
    required this.gateTopicsCompleted,
    required this.gateTotalTopics,
    required this.semesterAvgCompletionPct,
    this.daysSinceLastPeriod,
    required this.recentBloatingLevel,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      welcomeMessage: json['welcome_message'] as String? ?? 'Welcome!',
      todayDate: json['today_date'] as String,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      totalTasksToday: json['total_tasks_today'] as int? ?? 0,
      completedTasksToday: json['completed_tasks_today'] as int? ?? 0,
      pendingTasksToday: json['pending_tasks_today'] as int? ?? 0,
      waterIntakeTodayMl: json['water_intake_today_ml'] as int? ?? 0,
      waterTargetMl: json['water_target_ml'] as int? ?? 2200,
      currentWeightKg: (json['current_weight_kg'] as num?)?.toDouble() ?? 66.0,
      targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble() ?? 56.0,
      workoutCompletedToday: json['workout_completed_today'] as bool? ?? false,
      gateTopicsCompleted: json['gate_topics_completed'] as int? ?? 0,
      gateTotalTopics: json['gate_total_topics'] as int? ?? 0,
      semesterAvgCompletionPct: (json['semester_avg_completion_pct'] as num?)?.toDouble() ?? 0.0,
      daysSinceLastPeriod: json['days_since_last_period'] as int?,
      recentBloatingLevel: json['recent_bloating_level'] as int? ?? 0,
    );
  }
}
