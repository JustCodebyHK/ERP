/// Timetable entry model from API
class TimetableEntry {
  final String id;
  final String batchId;
  final String subjectId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? room;
  final String? teacherId;
  final DateTime createdAt;
  final String? batchName;
  final String? subjectCode;
  final String? subjectName;

  TimetableEntry({
    required this.id,
    required this.batchId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.teacherId,
    required this.createdAt,
    this.batchName,
    this.subjectCode,
    this.subjectName,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        id: json['id'] as String,
        batchId: json['batch_id'] as String,
        subjectId: json['subject_id'] as String,
        dayOfWeek: json['day_of_week'] as int,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        room: json['room'] as String?,
        teacherId: json['teacher_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        batchName: json['batch_name'] as String?,
        subjectCode: json['subject_code'] as String?,
        subjectName: json['subject_name'] as String?,
      );

  static const List<String> days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  String get dayName => days[dayOfWeek];

  String get timeRange => '$startTime - $endTime';

  String get displayRoom => room ?? 'TBA';
}