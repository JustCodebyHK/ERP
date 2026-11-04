class AttendanceSummary {
  final String name;
  final String code;
  final int attended;
  final int totalLectures;

  AttendanceSummary({
    required this.name,
    required this.code,
    required this.attended,
    required this.totalLectures,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      name: json['name'] as String,
      code: json['code'] as String,
      attended: json['attended'] as int,
      totalLectures: json['total_lectures'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'attended': attended,
      'total_lectures': totalLectures,
    };
  }

  double get percentage => totalLectures > 0 ? (attended / totalLectures) * 100 : 0.0;

  @override
  String toString() => 'AttendanceSummary(name: $name, percentage: $percentage%)';
}
