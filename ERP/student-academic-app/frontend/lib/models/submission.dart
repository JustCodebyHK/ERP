class Submission {
  final int id;
  final int assignmentId;
  final int studentId;
  final String studentName;
  final String fileUrl;
  final DateTime submittedAt;
  final int? score;
  final String? feedback;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.fileUrl,
    required this.submittedAt,
    this.score,
    this.feedback,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as int,
      assignmentId: json['assignment_id'] as int,
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String,
      fileUrl: json['file_url'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      score: json['score'] as int?,
      feedback: json['feedback'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'student_id': studentId,
      'student_name': studentName,
      'file_url': fileUrl,
      'submitted_at': submittedAt.toIso8601String(),
      'score': score,
      'feedback': feedback,
    };
  }

  @override
  String toString() => 'Submission(id: $id, student: $studentName, score: $score)';
}
