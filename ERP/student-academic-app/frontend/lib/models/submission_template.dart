class SubmissionTemplate {
  final int id;
  final String type;
  final String title;
  final int version;
  final int fileSize;
  final String fileUrl;
  final DateTime createdAt;
  final bool isCurrent;

  SubmissionTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.version,
    required this.fileSize,
    required this.fileUrl,
    required this.createdAt,
    this.isCurrent = false,
  });

  factory SubmissionTemplate.fromJson(Map<String, dynamic> json) {
    return SubmissionTemplate(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      version: json['version'] as int,
      fileSize: json['file_size'] as int,
      fileUrl: json['file_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isCurrent: json['is_current'] as bool? ?? false,
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
    };
  }

  SubmissionTemplate copyWith({int? version, bool? isCurrent}) {
    return SubmissionTemplate(
      id: id,
      type: type,
      title: title,
      version: version ?? this.version,
      fileSize: fileSize,
      fileUrl: fileUrl,
      createdAt: createdAt,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  String get typeLabel => type.replaceAll('_', ' ').toUpperCase();
  String get icon {
    switch (type) {
      case 'front_page': return 'description';
      case 'index_page': return 'list_alt';
      case 'certificate': return 'verified';
      default: return 'attach_file';
    }
  }
  String get formattedSize => (fileSize / (1024 * 1024)).toStringAsFixed(2);

  @override
  String toString() => 'SubmissionTemplate(id: $id, type: $type, version: $version)';
}

import 'package:flutter/material.dart';
