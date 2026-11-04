import 'package:flutter/material.dart';

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String fileUrl;
  final DateTime submittedAt;
  final int? score;
  final int? maxScore;
  final String? feedback;
  final String status;

  Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.fileUrl,
    required this.submittedAt,
    this.score,
    this.maxScore,
    this.feedback,
    this.status = 'submitted',
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      studentEmail: json['student_email'] as String,
      fileUrl: json['file_url'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      score: json['score'] as int?,
      maxScore: json['max_score'] as int?,
      feedback: json['feedback'] as String?,
      status: json['status'] as String? ?? 'submitted',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'student_id': studentId,
      'student_name': studentName,
      'student_email': studentEmail,
      'file_url': fileUrl,
      'submitted_at': submittedAt.toIso8601String(),
      'score': score,
      'max_score': maxScore,
      'feedback': feedback,
      'status': status,
    };
  }

  String get statusDisplay => status.toUpperCase();

  @override
  String toString() => 'Submission(id: $id, student: $studentName, score: $score)';
}
