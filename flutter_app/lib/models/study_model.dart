class GateTopicModel {
  final int id;
  final int subjectId;
  final String name;
  final String status;
  final int pyqCompleted;
  final double accuracyPct;

  GateTopicModel({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.status,
    this.pyqCompleted = 0,
    this.accuracyPct = 0.0,
  });

  GateTopicModel copyWith({
    int? id,
    int? subjectId,
    String? name,
    String? status,
    int? pyqCompleted,
    double? accuracyPct,
  }) {
    return GateTopicModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      status: status ?? this.status,
      pyqCompleted: pyqCompleted ?? this.pyqCompleted,
      accuracyPct: accuracyPct ?? this.accuracyPct,
    );
  }

  factory GateTopicModel.fromJson(Map<String, dynamic> json) {
    return GateTopicModel(
      id: json['id'] ?? 0,
      subjectId: json['subject_id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? 'Not Started',
      pyqCompleted: json['pyq_completed'] ?? 0,
      accuracyPct: (json['accuracy_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject_id': subjectId,
    'name': name,
    'status': status,
    'pyq_completed': pyqCompleted,
    'accuracy_pct': accuracyPct,
  };
}

class GateSubjectModel {
  final int id;
  final String code;
  final String name;
  final int orderIndex;
  final List<GateTopicModel> topics;

  GateSubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.orderIndex,
    required this.topics,
  });

  factory GateSubjectModel.fromJson(Map<String, dynamic> json) {
    var rawTopics = json['topics'] as List? ?? [];
    return GateSubjectModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      topics: rawTopics.map((t) => GateTopicModel.fromJson(t)).toList(),
    );
  }
}

class SemesterUnitModel {
  final int id;
  final int subjectId;
  final int unitNumber;
  final String title;
  final bool isCompleted;

  SemesterUnitModel({
    required this.id,
    required this.subjectId,
    required this.unitNumber,
    required this.title,
    required this.isCompleted,
  });

  SemesterUnitModel copyWith({
    int? id,
    int? subjectId,
    int? unitNumber,
    String? title,
    bool? isCompleted,
  }) {
    return SemesterUnitModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      unitNumber: unitNumber ?? this.unitNumber,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory SemesterUnitModel.fromJson(Map<String, dynamic> json) {
    return SemesterUnitModel(
      id: json['id'] ?? 0,
      subjectId: json['subject_id'] ?? 0,
      unitNumber: json['unit_number'] ?? 1,
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class SemesterSubjectModel {
  final int id;
  final String code;
  final String name;
  final String priority;
  final String difficulty;
  final List<SemesterUnitModel> units;

  SemesterSubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.priority,
    required this.difficulty,
    required this.units,
  });

  SemesterSubjectModel copyWith({
    int? id,
    String? code,
    String? name,
    String? priority,
    String? difficulty,
    List<SemesterUnitModel>? units,
  }) {
    return SemesterSubjectModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      priority: priority ?? this.priority,
      difficulty: difficulty ?? this.difficulty,
      units: units ?? this.units,
    );
  }

  factory SemesterSubjectModel.fromJson(Map<String, dynamic> json) {
    var rawUnits = json['units'] as List? ?? [];
    return SemesterSubjectModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      priority: json['priority'] ?? 'Medium',
      difficulty: json['difficulty'] ?? 'Medium',
      units: rawUnits.map((u) => SemesterUnitModel.fromJson(u)).toList(),
    );
  }
}
