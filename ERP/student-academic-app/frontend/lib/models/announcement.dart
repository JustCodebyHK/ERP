import 'package:flutter/material.dart';

class Announcement {
  final int id;
  final String title;
  final String body;
  final String createdBy;
  final DateTime createdAt;
  final DateTime publishedAt;
  final bool isRead;
  final String priority;
  final String type;
  final Color? color;
  final IconData? icon;
  final bool isGlobal;
  final String? batchName;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdBy,
    required this.createdAt,
    required this.publishedAt,
    this.isRead = false,
    this.priority = 'normal',
    this.type = 'info',
    this.color,
    this.icon,
    this.isGlobal = false,
    this.batchName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: DateTime.parse(json['published_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'normal',
      type: json['type'] as String? ?? 'info',
      color: json['color'] != null ? Color(int.parse(json['color'].toString().replaceAll('0x', '0xff'))) : null,
      icon: null,
      isGlobal: json['is_global'] as bool? ?? false,
      batchName: json['batch_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'published_at': publishedAt.toIso8601String(),
      'is_read': isRead,
      'priority': priority,
      'type': type,
      'color': color?.value,
      'is_global': isGlobal,
      'batch_name': batchName,
    };
  }

  bool get isHighPriority => priority == 'high';
  String get typeLabel => type.toUpperCase();

  Announcement copyWith({bool? isRead, String? priority, String? type}) {
    return Announcement(
      id: id,
      title: title,
      body: body,
      createdBy: createdBy,
      createdAt: createdAt,
      publishedAt: publishedAt,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      color: color,
      icon: icon,
      isGlobal: isGlobal,
      batchName: batchName,
    );
  }

  @override
  String toString() => 'Announcement(id: $id, title: $title, priority: $priority)';
}
