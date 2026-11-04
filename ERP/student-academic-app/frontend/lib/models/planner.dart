class PlannerEvent {
  final int id;
  final String title;
  final String eventType;
  final DateTime scheduledAt;
  final bool isCompleted;

  PlannerEvent({
    required this.id,
    required this.title,
    required this.eventType,
    required this.scheduledAt,
    this.isCompleted = false,
  });

  factory PlannerEvent.fromJson(Map<String, dynamic> json) {
    return PlannerEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      eventType: json['event_type'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'event_type': eventType,
      'scheduled_at': scheduledAt.toIso8601String(),
      'is_completed': isCompleted,
    };
  }

  PlannerEvent copyWith({bool? isCompleted}) {
    return PlannerEvent(
      id: id,
      title: title,
      eventType: eventType,
      scheduledAt: scheduledAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() => 'PlannerEvent(id: $id, title: $title, type: $eventType)';
}
