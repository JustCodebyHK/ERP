class PlannerTask {
  final int id;
  final int? timetableEntryId;
  final String title;
  final String? description;
  final int priority;
  final DateTime scheduledFor;
  final bool isCompleted;

  PlannerTask({
    required this.id,
    this.timetableEntryId,
    required this.title,
    this.description,
    required this.priority,
    required this.scheduledFor,
    this.isCompleted = false,
  });

  factory PlannerTask.fromJson(Map<String, dynamic> json) {
    return PlannerTask(
      id: json['id'] as int,
      timetableEntryId: json['timetable_entry_id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as int,
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timetable_entry_id': timetableEntryId,
      'title': title,
      'description': description,
      'priority': priority,
      'scheduled_for': scheduledFor.toIso8601String(),
      'is_completed': isCompleted,
    };
  }

  String get priorityLabel {
    switch (priority) {
      case 1: return 'Low';
      case 2: return 'Medium';
      case 3: return 'High';
      default: return 'Normal';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 1: return const Color(0xFF4CAF50);
      case 2: return const Color(0xFFFFA726);
      case 3: return const Color(0xFFF44336);
      default: return const Color(0xFF9E9E9E);
    }
  }

  PlannerTask copyWith({
    int? id,
    int? timetableEntryId,
    String? title,
    String? description,
    int? priority,
    DateTime? scheduledFor,
    bool? isCompleted,
  }) {
    return PlannerTask(
      id: id ?? this.id,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() => 'PlannerTask(id: $id, title: $title, priority: $priority)';
}

import 'package:flutter/material.dart';
