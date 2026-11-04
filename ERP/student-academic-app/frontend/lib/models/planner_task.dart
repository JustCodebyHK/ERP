import 'package:flutter/material.dart';

class PlannerTask {
  final String id;
  final String? timetableEntryId;
  final String title;
  final String? description;
  final int priority;
  final DateTime dueAt;
  final DateTime scheduledFor;
  final bool isCompleted;
  final bool hasTimetableLink;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? subjectCode;
  final String? status;

  PlannerTask({
    required this.id,
    this.timetableEntryId,
    required this.title,
    this.description,
    required this.priority,
    required this.dueAt,
    required this.scheduledFor,
    this.isCompleted = false,
    this.hasTimetableLink = false,
    this.startTime,
    this.endTime,
    this.subjectCode,
    this.status,
  });

  factory PlannerTask.fromJson(Map<String, dynamic> json) {
    return PlannerTask(
      id: json['id'] as String,
      timetableEntryId: json['timetable_entry_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] as int,
      dueAt: DateTime.parse(json['due_at'] as String),
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      hasTimetableLink: json['has_timetable_link'] as bool? ?? false,
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time'] as String) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      subjectCode: json['subject_code'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timetable_entry_id': timetableEntryId,
      'title': title,
      'description': description,
      'priority': priority,
      'due_at': dueAt.toIso8601String(),
      'scheduled_for': scheduledFor.toIso8601String(),
      'is_completed': isCompleted,
      'has_timetable_link': hasTimetableLink,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'subject_code': subjectCode,
      'status': status,
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueAt) && !isCompleted;

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

  String get statusDisplay => status?.toUpperCase() ?? 'PENDING';

  PlannerTask copyWith({
    String? id,
    String? timetableEntryId,
    String? title,
    String? description,
    int? priority,
    DateTime? dueAt,
    DateTime? scheduledFor,
    bool? isCompleted,
    bool? hasTimetableLink,
    DateTime? startTime,
    DateTime? endTime,
    String? subjectCode,
    String? status,
  }) {
    return PlannerTask(
      id: id ?? this.id,
      timetableEntryId: timetableEntryId ?? this.timetableEntryId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueAt: dueAt ?? this.dueAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isCompleted: isCompleted ?? this.isCompleted,
      hasTimetableLink: hasTimetableLink ?? this.hasTimetableLink,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subjectCode: subjectCode ?? this.subjectCode,
      status: status ?? this.status,
    );
  }

  @override
  String toString() => 'PlannerTask(id: $id, title: $title, priority: $priority)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlannerTask && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
