import 'package:flutter/material.dart';

class ComponentDetail {
  final String label;
  final double score;
  final double weight;
  final String unit;
  final Map<String, dynamic>? details;

  ComponentDetail({
    required this.label,
    required this.score,
    required this.weight,
    required this.unit,
    this.details,
  });

  factory ComponentDetail.fromJson(Map<String, dynamic> json) {
    return ComponentDetail(
      label: json['label'] as String,
      score: (json['score'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      unit: json['unit'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'score': score,
      'weight': weight,
      'unit': unit,
      'details': details,
    };
  }

  double get percentage => weight > 0 ? (score / weight) * 100 : 0.0;

  @override
  String toString() => 'ComponentDetail(label: $label, score: $score/$weight $unit)';
}
