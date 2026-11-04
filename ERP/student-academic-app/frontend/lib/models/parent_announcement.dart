import 'package:flutter/material.dart';

class ParentAnnouncement {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime publishedAt;
  final Color? color;
  final IconData? icon;
  final String? batchName;

  ParentAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.publishedAt,
    this.color,
    this.icon,
    this.batchName,
  });

  factory ParentAnnouncement.fromJson(Map<String, dynamic> json) {
    return ParentAnnouncement(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      color: json['color'] != null ? Color(int.parse(json['color'].toString().replaceAll('0x', '0xff'))) : null,
      icon: null,
      batchName: json['batch_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'published_at': publishedAt.toIso8601String(),
      'color': color?.value,
      'batch_name': batchName,
    };
  }

  String get typeLabel => type.toUpperCase();

  @override
  String toString() => 'ParentAnnouncement(id: $id, title: $title, type: $type)';
}
