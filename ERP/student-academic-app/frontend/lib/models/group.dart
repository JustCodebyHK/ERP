import 'package:flutter/material.dart';

import '../widgets/app_theme.dart';

/// Group/Channel model from API
class Group {
  final String id;
  final String name;
  final String? description;
  final String type; // 'group' or 'channel'
  final String? avatarUrl;
  final String inviteCode;
  final bool isPublic;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? batchName;
  final String? role; // for membership
  final DateTime? mutedUntil;
  final int? memberCount;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.avatarUrl,
    required this.inviteCode,
    required this.isPublic,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.batchName,
    this.role,
    this.mutedUntil,
    this.memberCount,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        type: json['type'] as String,
        avatarUrl: json['avatar_url'] as String?,
        inviteCode: json['invite_code'] as String,
        isPublic: json['is_active'] as bool? ?? json['is_public'] as bool? ?? true,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        batchName: json['batch_name'] as String?,
        role: json['role'] as String?,
        mutedUntil: json['muted_until'] != null
            ? DateTime.parse(json['muted_until'] as String)
            : null,
        memberCount: (json['member_count'] as num?)?.toInt(),
      );

  String get typeLabel => type == 'channel' ? 'Channel' : 'Group';

  Color get typeColor =>
      type == 'channel' ? AppTheme.tertiary : AppTheme.primary;

  String get memberCountDisplay {
    if (memberCount == null) return '';
    return '$memberCount member${memberCount! > 1 ? 's' : ''}';
  }
}

/// Group message model from API
class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String content;
  final String type; // text, image, file, alert, notification, system
  final String? replyTo;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final String? senderName;
  final String? senderRole;
  final int readCount;
  final String? startTime;
  final String? endTime;
  final String? subjectCode;
  final String? subjectName;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    required this.type,
    this.replyTo,
    this.editedAt,
    this.deletedAt,
    required this.createdAt,
    this.senderName,
    this.senderRole,
    this.readCount = 0,
    this.startTime,
    this.endTime,
    this.subjectCode,
    this.subjectName,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) => GroupMessage(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        type: json['type'] as String,
        replyTo: json['reply_to'] as String?,
        editedAt: json['edited_at'] != null
            ? DateTime.parse(json['edited_at'] as String)
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        senderName: json['sender_name'] as String?,
        senderRole: json['sender_role'] as String?,
        readCount: (json['read_count'] as num?)?.toInt() ?? 0,
        startTime: json['start_time'] as String?,
        endTime: json['end_time'] as String?,
        subjectCode: json['subject_code'] as String?,
        subjectName: json['subject_name'] as String?,
      );

  bool get isOwn => false; // Will be set by the UI based on current user

  String get timeRange {
    if (startTime == null || endTime == null) return '';
    return '$startTime - $endTime';
  }
}