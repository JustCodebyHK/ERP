class AttendanceDetail {
  final String date;
  final String status;
  final String? subject;

  AttendanceDetail({
    required this.date,
    required this.status,
    this.subject,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceDetail(
      date: json['date'] as String,
      status: json['status'] as String,
      subject: json['subject'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'status': status,
      'subject': subject,
    };
  }

  @override
  String toString() => 'AttendanceDetail(date: $date, status: $status)';
}
