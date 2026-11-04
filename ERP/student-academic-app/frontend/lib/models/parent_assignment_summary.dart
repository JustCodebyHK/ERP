import 'package:flutter/material.dart';

class ParentAssignmentSummary {
  final String id;
  final String title;
  final String subjectCode;
  final String subjectName;
  final DateTime dueAt;
  final String status;
  final int? score;
  final int? maxScore;

  ParentAssignmentSummary({
    required this.id,
    required this.title,
    required this.subjectCode,
    required this.subjectName,
    required this.dueAt,
    required this.status,
    this.score,
    this.maxScore,
  });

  factory ParentAssignmentSummary.fromJson(Map<String, dynamic> json) {
    return ParentAssignmentSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectCode: json['subject_code'] as String,
      subjectName: json['subject_name'] as String,
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
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'due_at': dueAt.toIso8601String(),
      'status': status,
      'score': score,
      'max_score': maxScore,
    };
  }

  bool get isGraded => score != null;
  bool get isSubmitted => status == 'submitted';
  bool get isOverdue => DateTime.now().isAfter(dueAt) && status != 'submitted';
  bool get isLate => DateTime.now().isAfter(dueAt) && status != 'submitted';
  String get statusDisplay => status.toUpperCase();

  double? get percentage => maxScore != null && maxScore! > 0 && score != null
      ? (score! / maxScore!) * 100
      : null;

  @override
  String toString() => 'ParentAssignmentSummary(id: $id, title: $title, status: $status)';
}
