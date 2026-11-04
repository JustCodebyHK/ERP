class Announcement {
  final int id;
  final String title;
  final String content;
  final String createdBy;
  final DateTime createdAt;
  final bool isRead;
  final String priority;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.createdAt,
    this.isRead = false,
    this.priority = 'normal',
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'priority': priority,
    };
  }

  bool get isHighPriority => priority == 'high';

  Announcement copyWith({bool? isRead, String? priority}) {
    return Announcement(
      id: id,
      title: title,
      content: content,
      createdBy: createdBy,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
    );
  }

  @override
  String toString() => 'Announcement(id: $id, title: $title, priority: $priority)';
}
