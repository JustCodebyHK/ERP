import 'package:flutter/material.dart';

class SubmissionTemplate {
  final String id;
  final String type;
  final String title;
  final int version;
  final int fileSize;
  final String fileUrl;
  final DateTime createdAt;
  final bool isCurrent;
  final String? originalName;

  SubmissionTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.version,
    required this.fileSize,
    required this.fileUrl,
    required this.createdAt,
    this.isCurrent = false,
    this.originalName,
  });

  factory SubmissionTemplate.fromJson(Map<String, dynamic> json) {
    return SubmissionTemplate(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      version: json['version'] as int,
      fileSize: json['file_size'] as int,
      fileUrl: json['file_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isCurrent: json['is_current'] as bool? ?? false,
      originalName: json['original_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'version': version,
      'file_size': fileSize,
      'file_url': fileUrl,
      'created_at': createdAt.toIso8601String(),
      'is_current': isCurrent,
      'original_name': originalName,
    };
  }

  SubmissionTemplate copyWith({String? id, String? type, String? title, int? version,
    int? fileSize, String? fileUrl, DateTime? createdAt, bool? isCurrent, String? originalName}) {
    return SubmissionTemplate(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      version: version ?? this.version,
      fileSize: fileSize ?? this.fileSize,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
      isCurrent: isCurrent ?? this.isCurrent,
      originalName: originalName ?? this.originalName,
    );
  }

  String get typeLabel => type.replaceAll('_', ' ').toUpperCase();
  IconData get icon {
    switch (type) {
      case 'front_page': return const IconData(0xe147, fontFamily: 'MaterialIcons');
      case 'index_page': return const IconData(0xe376, fontFamily: 'MaterialIcons');
      case 'certificate': return const IconData(0xe8f2, fontFamily: 'MaterialIcons');
      default: return const IconData(0xe2c2, fontFamily: 'MaterialIcons');
    }
  }
  String get formattedSize => (fileSize / (1024 * 1024)).toStringAsFixed(2);

  @override
  String toString() => 'SubmissionTemplate(id: $id, type: $type, version: $version)';
}
