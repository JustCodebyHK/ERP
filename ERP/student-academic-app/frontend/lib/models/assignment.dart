class Assignment {
  final int id;
  final String title;
  final String description;
  final int subjectId;
  final DateTime dueDate;
  final String status;
  final String? fileUrl;
  final int? maxScore;
  final int? obtainedScore;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.dueDate,
    this.status = 'pending',
    this.fileUrl,
    this.maxScore,
    this.obtainedScore,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      subjectId: json['subject_id'] as int,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String? ?? 'pending',
      fileUrl: json['file_url'] as String?,
      maxScore: json['max_score'] as int?,
      obtainedScore: json['obtained_score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'file_url': fileUrl,
      'max_score': maxScore,
      'obtained_score': obtainedScore,
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != 'submitted';
  double? get percentage => maxScore != null && maxScore! > 0 && obtainedScore != null
      ? (obtainedScore! / maxScore!) * 100
      : null;

  Assignment copyWith({String? status, String? fileUrl, int? maxScore, int? obtainedScore}) {
    return Assignment(
      id: id,
      title: title,
      description: description,
      subjectId: subjectId,
      dueDate: dueDate,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      maxScore: maxScore ?? this.maxScore,
      obtainedScore: obtainedScore ?? this.obtainedScore,
    );
  }

  @override
  String toString() => 'Assignment(id: $id, title: $title, status: $status)';
}
