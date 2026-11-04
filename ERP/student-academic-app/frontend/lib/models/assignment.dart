class Assignment {
  final int id;
  final String title;
  final String description;
  final int subjectId;
  final DateTime dueAt;
  final String status;
  final String? fileUrl;
  final int? maxScore;
  final int? obtainedScore;
  final int? received;
  final int? totalSubmissions;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.dueAt,
    this.status = 'pending',
    this.fileUrl,
    this.maxScore,
    this.obtainedScore,
    this.received,
    this.totalSubmissions,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      subjectId: json['subject_id'] as int,
      dueAt: DateTime.parse(json['due_at'] as String),
      status: json['status'] as String? ?? 'pending',
      fileUrl: json['file_url'] as String?,
      maxScore: json['max_score'] as int?,
      obtainedScore: json['obtained_score'] as int?,
      received: json['received'] as int?,
      totalSubmissions: json['total_submissions'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject_id': subjectId,
      'due_at': dueAt.toIso8601String(),
      'status': status,
      'file_url': fileUrl,
      'max_score': maxScore,
      'obtained_score': obtainedScore,
      'received': received,
      'total_submissions': totalSubmissions,
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueAt) && status != 'submitted';
  double? get percentage => maxScore != null && maxScore! > 0 && obtainedScore != null
      ? (obtainedScore! / maxScore!) * 100
      : null;

  Assignment copyWith({String? status, String? fileUrl, int? maxScore, int? obtainedScore, int? received, int? totalSubmissions}) {
    return Assignment(
      id: id,
      title: title,
      description: description,
      subjectId: subjectId,
      dueAt: dueAt,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      maxScore: maxScore ?? this.maxScore,
      obtainedScore: obtainedScore ?? this.obtainedScore,
      received: received ?? this.received,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
    );
  }

  @override
  String toString() => 'Assignment(id: $id, title: $title, status: $status)';
}
