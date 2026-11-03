import 'package:flutter/material.dart';

/// Submission Kit template model from API
class SubmissionTemplate {
  final String id;
  final String type; // 'front_page', 'index_page', 'certificate'
  final String title;
  final String filePath;
  final String originalName;
  final String? mimeType;
  final int sizeBytes;
  final int version;
  final bool isCurrent;
  final String uploadedBy;
  final DateTime createdAt;

  SubmissionTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.filePath,
    required this.originalName,
    this.mimeType,
    required this.sizeBytes,
    required this.version,
    required this.isCurrent,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory SubmissionTemplate.fromJson(Map<String, dynamic> json) => SubmissionTemplate(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        filePath: json['file_path'] as String,
        originalName: json['original_name'] as String,
        mimeType: json['mime_type'] as String?,
        sizeBytes: _parseSizeBytes(json['size_bytes']),
        version: json['version'] as int,
        isCurrent: json['is_current'] as bool? ?? false,
        uploadedBy: json['uploaded_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  static int _parseSizeBytes(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static const Map<String, IconData> typeIcons = {
    'front_page': Icons.description,
    'index_page': Icons.list_alt,
    'certificate': Icons.card_membership,
  };

  static const Map<String, String> typeLabels = {
    'front_page': 'Front Page',
    'index_page': 'Index Page',
    'certificate': 'Certificate',
  };

  String get typeLabel => typeLabels[type] ?? type;
  IconData get icon => typeIcons[type] ?? Icons.insert_drive_file;

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}