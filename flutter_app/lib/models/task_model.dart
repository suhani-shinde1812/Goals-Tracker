class ScheduledTaskModel {
  final int id;
  final int userId;
  final String title;
  final String category;
  final String date;
  final String? scheduledTime;
  final int durationMinutes;
  final String priority;
  final bool isCompleted;
  final String? completedAt;
  final String? notes;

  ScheduledTaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.date,
    this.scheduledTime,
    required this.durationMinutes,
    required this.priority,
    required this.isCompleted,
    this.completedAt,
    this.notes,
  });

  factory ScheduledTaskModel.fromJson(Map<String, dynamic> json) {
    return ScheduledTaskModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 1,
      title: json['title'] as String,
      category: json['category'] as String? ?? 'General',
      date: json['date'] as String,
      scheduledTime: json['scheduled_time'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      priority: json['priority'] as String? ?? 'medium',
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'category': category,
    'date': date,
    'scheduled_time': scheduledTime,
    'duration_minutes': durationMinutes,
    'priority': priority,
    'is_completed': isCompleted,
    'completed_at': completedAt,
    'notes': notes,
  };

  ScheduledTaskModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? category,
    String? date,
    String? scheduledTime,
    int? durationMinutes,
    String? priority,
    bool? isCompleted,
    String? completedAt,
    String? notes,
  }) {
    return ScheduledTaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}
