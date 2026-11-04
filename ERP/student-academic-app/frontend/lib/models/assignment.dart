class Assignment {
  final String id;
  final String title;
  final String description;
  final String subjectId;
  final DateTime dueAt;
  final String status;
  final String? fileUrl;
  final int? maxScore;
  final int? obtainedScore;
  final int? received;
  final int? totalSubmissions;
  final String? subjectCode;
  final String? subjectName;
  final int? score;

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
    this.subjectCode,
    this.subjectName,
    this.score,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      subjectId: json['subject_id'] as String,
      dueAt: DateTime.parse(json['due_at'] as String),
      status: json['status'] as String? ?? 'pending',
      fileUrl: json['file_url'] as String?,
      maxScore: json['max_score'] as int?,
      obtainedScore: json['obtained_score'] as int?,
      received: json['received'] as int?,
      totalSubmissions: json['total_submissions'] as int?,
      subjectCode: json['subject_code'] as String?,
      subjectName: json['subject_name'] as String?,
      score: json['score'] as int?,
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
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'score': score,
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueAt) && status != 'submitted';
  bool get isLate => DateTime.now().isAfter(dueAt) && status != 'submitted';
  bool get isSubmitted => status == 'submitted';
  bool get isGraded => obtainedScore != null;
  bool get isPending => status == 'pending';
  bool get isDueToday => DateTime.now().difference(dueAt).inDays.abs() <= 1 && status != 'submitted';
  String get statusDisplay => status.toUpperCase();

  double? get percentage => maxScore != null && maxScore! > 0 && obtainedScore != null
      ? (obtainedScore! / maxScore!) * 100
      : null;

  Assignment copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    DateTime? dueAt,
    String? status,
    String? fileUrl,
    int? maxScore,
    int? obtainedScore,
    int? received,
    int? totalSubmissions,
    String? subjectCode,
    String? subjectName,
    int? score,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      maxScore: maxScore ?? this.maxScore,
      obtainedScore: obtainedScore ?? this.obtainedScore,
      received: received ?? this.received,
      totalSubmissions: totalSubmissions ?? this.totalSubmissions,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      score: score ?? this.score,
    );
  }

  @override
  String toString() => 'Assignment(id: $id, title: $title, status: $status)';
}
