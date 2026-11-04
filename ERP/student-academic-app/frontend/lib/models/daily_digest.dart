import 'package:flutter/material.dart';
import 'planner_task.dart';

class DailyDigestStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueAssignments;

  DailyDigestStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueAssignments,
  });

  factory DailyDigestStats.fromJson(Map<String, dynamic> json) {
    return DailyDigestStats(
      totalTasks: json['total_tasks'] as int,
      completedTasks: json['completed_tasks'] as int,
      pendingTasks: json['pending_tasks'] as int,
      overdueAssignments: json['overdue_assignments'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'pending_tasks': pendingTasks,
      'overdue_assignments': overdueAssignments,
    };
  }
}

class DailyDigest {
  final String date;
  final DailyDigestStats stats;
  final List<PlannerTask> tasks;
  final List<PlannerTask> upcomingAssignments;
  final List<PlannerTask> overdueAssignments;
  final List<dynamic> classes;

  DailyDigest({
    required this.date,
    required this.stats,
    required this.tasks,
    required this.upcomingAssignments,
    required this.overdueAssignments,
    required this.classes,
  });

  factory DailyDigest.fromJson(Map<String, dynamic> json) {
    return DailyDigest(
      date: json['date'] as String,
      stats: DailyDigestStats.fromJson(json['stats'] as Map<String, dynamic>),
      tasks: (json['tasks'] as List?)
          ?.map((e) => PlannerTask.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      upcomingAssignments: (json['upcoming_assignments'] as List?)
          ?.map((e) => PlannerTask.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      overdueAssignments: (json['overdue_assignments'] as List?)
          ?.map((e) => PlannerTask.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      classes: (json['classes'] as List?) ?? <dynamic>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'stats': stats.toJson(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'upcoming_assignments': upcomingAssignments.map((t) => t.toJson()).toList(),
      'overdue_assignments': overdueAssignments.map((t) => t.toJson()).toList(),
      'classes': classes,
    };
  }

  @override
  String toString() => 'DailyDigest(date: $date, stats: $stats)';
}
