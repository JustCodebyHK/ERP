class ParentAssignmentSummary {
  final int id;
  final String title;
  final String subject;
  final DateTime dueAt;
  final String status;
  final int? score;
  final int? maxScore;

  ParentAssignmentSummary({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueAt,
    required this.status,
    this.score,
    this.maxScore,
  });

  factory ParentAssignmentSummary.fromJson(Map<String, dynamic> json) {
    return ParentAssignmentSummary(
      id: json['id'] as int,
      title: json['title'] as String,
      subject: json['subject'] as String,
      dueAt: DateTime.parse(json['due_at'] as String),
      status: json['status'] as String,
      score: json['score'] as int?,
      maxScore: json['max_score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'due_at': dueAt.toIso8601String(),
      'status': status,
      'score': score,
      'max_score': maxScore,
    };
  }

  double? get percentage => maxScore != null && maxScore! > 0 && score != null
      ? (score! / maxScore!) * 100
      : null;

  @override
  String toString() => 'ParentAssignmentSummary(id: $id, title: $title, status: $status)';
}
