class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String content;
  final String type;
  final DateTime createdAt;
  final String? senderName;
  final String? senderRole;
  final int readCount;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.senderName,
    this.senderRole,
    this.readCount = 0,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: json['sender_name'] as String?,
      senderRole: json['sender_role'] as String?,
      readCount: json['read_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'sender_name': senderName,
      'sender_role': senderRole,
      'read_count': readCount,
    };
  }

  GroupMessage copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? content,
    String? type,
    DateTime? createdAt,
    String? senderName,
    String? senderRole,
    int? readCount,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      readCount: readCount ?? this.readCount,
    );
  }

  @override
  String toString() =>
      'GroupMessage(id: $id, senderId: $senderId, content: $content, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
