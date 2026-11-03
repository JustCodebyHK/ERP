import 'package:flutter/material.dart';

import '../widgets/app_theme.dart';

/// Parent-Child link model
class Child {
  final String id;
  final String name;
  final String email;
  final String relationship;
  final DateTime createdAt;

  Child({
    required this.id,
    required this.name,
    required this.email,
    required this.relationship,
    required this.createdAt,
  });

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        relationship: json['relationship'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Attendance summary per subject
class AttendanceSummary {
  final String code;
  final String name;
  final int totalLectures;
  final int attended;
  final double percentage;

  AttendanceSummary({
    required this.code,
    required this.name,
    required this.totalLectures,
    required this.attended,
    required this.percentage,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) => AttendanceSummary(
        code: json['code'] as String,
        name: json['name'] as String,
        totalLectures: (json['total_lectures'] as num).toInt(),
        attended: (json['attended'] as num).toInt(),
        percentage: (json['percentage'] as num).toDouble(),
      );
}

/// Mark record
class Mark {
  final String id;
  final String code;
  final String name;
  final String type;
  final String title;
  final int score;
  final int maxScore;
  final DateTime createdAt;
  final double percentage;

  Mark({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.createdAt,
    required this.percentage,
  });

  factory Mark.fromJson(Map<String, dynamic> json) => Mark(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        score: (json['score'] as num).toInt(),
        maxScore: (json['max_score'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
        percentage: (json['percentage'] as num).toDouble(),
      );
}

/// Assignment summary for parent
class ParentAssignmentSummary {
  final String id;
  final String title;
  final DateTime dueAt;
  final int maxScore;
  final String? status;
  final DateTime? submittedAt;
  final int? score;
  final DateTime? gradedAt;
  final String subjectCode;
  final String subjectName;

  ParentAssignmentSummary({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.maxScore,
    this.status,
    this.submittedAt,
    this.score,
    this.gradedAt,
    required this.subjectCode,
    required this.subjectName,
  });

  factory ParentAssignmentSummary.fromJson(Map<String, dynamic> json) => ParentAssignmentSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        dueAt: DateTime.parse(json['due_at'] as String),
        maxScore: (json['max_score'] as num).toInt(),
        status: json['status'] as String?,
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : null,
        score: (json['score'] as num?)?.toInt(),
        gradedAt: json['graded_at'] != null
            ? DateTime.parse(json['graded_at'] as String)
            : null,
        subjectCode: json['subject_code'] as String,
        subjectName: json['subject_name'] as String,
      );

  String get statusDisplay {
    if (status == 'graded') return 'Graded: $score/$maxScore';
    if (status == 'submitted') return 'Submitted';
    if (status == 'late') return 'Late';
    if (status == 'pending') {
      final now = DateTime.now();
      if (dueAt.isBefore(now)) return 'Overdue';
      if (dueAt.year == now.year && dueAt.month == now.month && dueAt.day == now.day) return 'Due Today';
      return 'Pending';
    }
    return status ?? 'Unknown';
  }

  bool get isGraded => status == 'graded';
  bool get isSubmitted => status == 'submitted';
  bool get isLate => status == 'late';
  bool get isPending => status == 'pending' || status == null;
  bool get isOverdue => isPending && dueAt.isBefore(DateTime.now());
}

/// Announcement for parent
class ParentAnnouncement {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime publishedAt;
  final String? batchName;

  ParentAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.publishedAt,
    this.batchName,
  });

  factory ParentAnnouncement.fromJson(Map<String, dynamic> json) => ParentAnnouncement(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        publishedAt: DateTime.parse(json['published_at'] as String),
        batchName: json['batch_name'] as String?,
      );

  static const Map<String, IconData> typeIcons = {
    'holiday': Icons.celebration,
    'exam': Icons.quiz,
    'deadline': Icons.schedule,
    'general': Icons.info,
    'alert': Icons.warning_amber,
  };

  static const Map<String, Color> typeColors = {
    'holiday': AppTheme.tertiary,
    'exam': AppTheme.primary,
    'deadline': AppTheme.secondary,
    'general': AppTheme.onSurfaceVariant,
    'alert': AppTheme.error,
  };

  IconData get icon => typeIcons[type] ?? Icons.announcement;
  Color get color => typeColors[type] ?? AppTheme.onSurfaceVariant;
  String get typeLabel => type[0].toUpperCase() + type.substring(1);
}