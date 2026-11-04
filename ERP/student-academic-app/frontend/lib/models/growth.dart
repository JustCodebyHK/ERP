class GrowthRecord {
  final int id;
  final int studentId;
  final String metricType;
  final double value;
  final String unit;
  final DateTime recordedAt;

  GrowthRecord({
    required this.id,
    required this.studentId,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  factory GrowthRecord.fromJson(Map<String, dynamic> json) {
    return GrowthRecord(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      metricType: json['metric_type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'metric_type': metricType,
      'value': value,
      'unit': unit,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  GrowthRecord copyWith({double? value, String? unit}) {
    return GrowthRecord(
      id: id,
      studentId: studentId,
      metricType: metricType,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      recordedAt: recordedAt,
    );
  }

  @override
  String toString() => 'GrowthRecord(id: , metric: , value:  )';
}
