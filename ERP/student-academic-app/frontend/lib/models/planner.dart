import 'package:flutter/material.dart';

import '../widgets/app_theme.dart';

/// Planner Task model
class PlannerTask {
  final String id;
  final String studentId;
  final String title;
  final String? description;
  final String status; // pending, in_progress, completed, deferred, cancelled
  final int priority; // 1=low, 2=medium, 3=high
  final DateTime? dueAt;
  final DateTime scheduledFor;
  final String? timetableEntryId;
  final String? subjectId;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? startTime;
  final String? endTime;
  final String? subjectCode;
  final String? subjectName;

  PlannerTask({
    required this.id,
    required this.studentId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueAt,
    required this.scheduledFor,
    this.timetableEntryId,
    this.subjectId,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.startTime,
    this.endTime,
    this.subjectCode,
    this.subjectName,
  });

  factory PlannerTask.fromJson(Map<String, dynamic> json) => PlannerTask(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        status: json['status'] as String,
        priority: (json['priority'] as num).toInt(),
        dueAt: json['due_at'] != null ? DateTime.parse(json['due_at'] as String) : null,
        scheduledFor: DateTime.parse(json['scheduled_for'] as String),
        timetableEntryId: json['timetable_entry_id'] as String?,
        subjectId: json['subject_id'] as String?,
        completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        startTime: json['start_time'] as String?,
        endTime: json['end_time'] as String?,
        subjectCode: json['subject_code'] as String?,
        subjectName: json['subject_name'] as String?,
      );

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isDeferred => status == 'deferred';
  bool get isOverdue => dueAt != null && dueAt!.isBefore(DateTime.now()) && !isCompleted;

  String get statusDisplay {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'deferred':
        return 'Deferred';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 3:
        return AppTheme.error;
      case 2:
        return AppTheme.secondary;
      default:
        return AppTheme.tertiary;
    }
  }

  bool get hasTimetableLink => timetableEntryId != null;
}

/// Daily Digest model
class DailyDigest {
  final String date;
  final List<PlannerTask> tasks;
  final List<ClassEntry> classes;
  final List<AssignmentSummary> overdueAssignments;
  final List<AssignmentSummary> upcomingAssignments;
  final DigestStats stats;

  DailyDigest({
    required this.date,
    required this.tasks,
    required this.classes,
    required this.overdueAssignments,
    required this.upcomingAssignments,
    required this.stats,
  });

  factory DailyDigest.fromJson(Map<String, dynamic> json) => DailyDigest(
        date: json['date'] as String,
        tasks: (json['tasks'] as List).map((e) => PlannerTask.fromJson(e)).toList(),
        classes: (json['classes'] as List).map((e) => ClassEntry.fromJson(e)).toList(),
        overdueAssignments: (json['overdue_assignments'] as List).map((e) => AssignmentSummary.fromJson(e)).toList(),
        upcomingAssignments: (json['upcoming_assignments'] as List).map((e) => AssignmentSummary.fromJson(e)).toList(),
        stats: DigestStats.fromJson(json['stats']),
      );
}

class ClassEntry {
  final String id;
  final String batchId;
  final String subjectId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String? teacherId;
  final String? batchName;
  final String? subjectCode;
  final String? subjectName;

  ClassEntry({
    required this.id,
    required this.batchId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacherId,
    this.batchName,
    this.subjectCode,
    this.subjectName,
  });

  factory ClassEntry.fromJson(Map<String, dynamic> json) => ClassEntry(
        id: json['id'] as String,
        batchId: json['batch_id'] as String,
        subjectId: json['subject_id'] as String,
        dayOfWeek: json['day_of_week'] as int,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        room: json['room'] as String?,
        teacherId: json['teacher_id'] as String?,
        batchName: json['batch_name'] as String?,
        subjectCode: json['subject_code'] as String?,
        subjectName: json['subject_name'] as String?,
      );

  static const List<String> days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  String get dayName => days[dayOfWeek];
  String get timeRange => '$startTime - $endTime';
}

class AssignmentSummary {
  final String id;
  final String title;
  final DateTime dueAt;
  final int maxScore;
  final String? status;
  final DateTime? submittedAt;
  final int? score;
  final String? subjectCode;
  final String? subjectName;

  AssignmentSummary({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.maxScore,
    this.status,
    this.submittedAt,
    this.score,
    this.subjectCode,
    this.subjectName,
  });

  factory AssignmentSummary.fromJson(Map<String, dynamic> json) => AssignmentSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        dueAt: DateTime.parse(json['due_at'] as String),
        maxScore: (json['max_score'] as num).toInt(),
        status: json['status'] as String?,
        submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String) : null,
        score: (json['score'] as num?)?.toInt(),
        subjectCode: json['subject_code'] as String?,
        subjectName: json['subject_name'] as String?,
      );

  String get statusDisplay {
    if (status == 'graded') return 'Graded: $score/$maxScore';
    if (status == 'submitted') return 'Submitted';
    if (status == 'late') return 'Late';
    return 'Pending';
  }
}

class DigestStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueAssignments;

  DigestStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueAssignments,
  });

  factory DigestStats.fromJson(Map<String, dynamic> json) => DigestStats(
        totalTasks: (json['total_tasks'] as num).toInt(),
        completedTasks: (json['completed_tasks'] as num).toInt(),
        pendingTasks: (json['pending_tasks'] as num).toInt(),
        overdueAssignments: (json['overdue_assignments'] as num).toInt(),
      );
}