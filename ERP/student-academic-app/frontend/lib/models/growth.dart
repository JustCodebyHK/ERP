import 'package:flutter/material.dart';

import '../widgets/app_theme.dart';

/// Growth Index models

class GrowthIndex {
  final int? growthIndex;
  final Map<String, double> weights;
  final Map<String, dynamic> components;

  GrowthIndex({
    required this.growthIndex,
    required this.weights,
    required this.components,
  });

  factory GrowthIndex.fromJson(Map<String, dynamic> json) => GrowthIndex(
        growthIndex: json['growthIndex'] as int?,
        weights: Map<String, double>.from(json['weights'] ?? {}),
        components: Map<String, dynamic>.from(json['components'] ?? {}),
      );

  // Convenience getters
  int? get attendanceScore => components['attendance']?['score'] as int?;
  int? get marksScore => components['marks']?['score'] as int?;
  int? get assignmentsScore => components['assignments']?['score'] as int?;
}

class ComponentDetail {
  final int? score;
  final double weight;
  final List<dynamic> details;

  ComponentDetail({
    required this.score,
    required this.weight,
    required this.details,
  });

  factory ComponentDetail.fromJson(Map<String, dynamic> json) => ComponentDetail(
        score: json['score'] as int?,
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        details: json['details'] as List? ?? [],
      );

  String get scoreDisplay => score != null ? '$score%' : 'N/A';
  String get weightDisplay => '${(weight * 100).toInt()}%';
}

class AttendanceDetail {
  final String subject;
  final String name;
  final int attended;
  final int total;
  final double percentage;

  AttendanceDetail({
    required this.subject,
    required this.name,
    required this.attended,
    required this.total,
    required this.percentage,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) => AttendanceDetail(
        subject: json['subject'] as String,
        name: json['name'] as String,
        attended: (json['attended'] as num).toInt(),
        total: (json['total'] as num).toInt(),
        percentage: (json['percentage'] as num).toDouble(),
      );

  String get percentageDisplay => '${percentage.toStringAsFixed(1)}%';
  Color get statusColor {
    if (percentage >= 90) return AppTheme.tertiary;
    if (percentage >= 75) return AppTheme.secondary;
    return AppTheme.error;
  }
}

class MarkDetail {
  final String subject;
  final String name;
  final String type;
  final String title;
  final int score;
  final int maxScore;
  final double percentage;

  MarkDetail({
    required this.subject,
    required this.name,
    required this.type,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.percentage,
  });

  factory MarkDetail.fromJson(Map<String, dynamic> json) => MarkDetail(
        subject: json['subject'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        score: (json['score'] as num).toInt(),
        maxScore: (json['maxScore'] as num).toInt(),
        percentage: (json['percentage'] as num).toDouble(),
      );

  bool get passed => percentage >= 60;
}