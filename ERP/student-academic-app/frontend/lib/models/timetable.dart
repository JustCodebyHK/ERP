class TimetableEntry {
  final int id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final int subjectId;
  final String? room;
  final String? subjectName;
  final String? subjectCode;
  final String? batchName;

  TimetableEntry({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.subjectId,
    this.room,
    this.subjectName,
    this.subjectCode,
    this.batchName,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'] as int,
      dayOfWeek: json['day_of_week'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      durationMinutes: json['duration_minutes'] as int,
      subjectId: json['subject_id'] as int,
      room: json['room'] as String?,
      subjectName: json['subject_name'] as String?,
      subjectCode: json['subject_code'] as String?,
      batchName: json['batch_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'subject_id': subjectId,
      'room': room,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'batch_name': batchName,
    };
  }

  static List<String> get days => ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  String get timeRange => '$startTime - $endTime';
  String? get displayRoom => room ?? 'TBA';

  TimetableEntry copyWith({String? startTime, String? endTime, String? room}) {
    return TimetableEntry(
      id: id,
      dayOfWeek: dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes,
      subjectId: subjectId,
      room: room ?? this.room,
    );
  }

  @override
  String toString() => 'TimetableEntry(id: $id, day: $dayOfWeek, $startTime-$endTime)';
}
