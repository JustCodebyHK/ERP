class ParentAnnouncement {
  final int id;
  final String title;
  final String content;
  final String type;
  final DateTime publishedAt;

  ParentAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.publishedAt,
  });

  factory ParentAnnouncement.fromJson(Map<String, dynamic> json) {
    return ParentAnnouncement(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'published_at': publishedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'ParentAnnouncement(id: $id, title: $title, type: $type)';
}
