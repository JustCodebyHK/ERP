import 'package:flutter/material.dart';

class AttendanceDetail {
  final String date;
  final String status;
  final String? subject;
  final int attended;
  final int total;
  final String name;

  AttendanceDetail({
    required this.date,
    required this.status,
    this.subject,
    required this.attended,
    required this.total,
    required this.name,
  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceDetail(
      date: json['date'] as String,
      status: json['status'] as String,
      subject: json['subject'] as String?,
      attended: (json['attended'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'status': status,
      'subject': subject,
      'attended': attended,
      'total': total,
      'name': name,
    };
  }

  double get percentage => total > 0 ? (attended / total) * 100 : 0.0;

  String get percentageDisplay => '${percentage.toStringAsFixed(1)}%';

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  String toString() => 'AttendanceDetail(date: $date, status: $status)';
}
