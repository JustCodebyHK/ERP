import 'package:flutter/material.dart';

import '../widgets/app_theme.dart';

/// Announcement model from API
class Announcement {
  final String id;
  final String? batchId;
  final String type;
  final String title;
  final String body;
  final String publishedBy;
  final DateTime publishedAt;
  final bool isActive;
  final String? batchName;

  Announcement({
    required this.id,
    this.batchId,
    required this.type,
    required this.title,
    required this.body,
    required this.publishedBy,
    required this.publishedAt,
    required this.isActive,
    this.batchName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        batchId: json['batch_id'] as String?,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        publishedBy: json['published_by'] as String,
        publishedAt: DateTime.parse(json['published_at'] as String),
        isActive: json['is_active'] as bool? ?? true,
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
  bool get isGlobal => batchId == null;
}