class AttendanceSummary {
  final String date;
  final String status;

  AttendanceSummary({
    required this.date,
    required this.status,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      date: json['date'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'status': status,
    };
  }

  @override
  String toString() => 'AttendanceSummary(date: $date, status: $status)';
}
