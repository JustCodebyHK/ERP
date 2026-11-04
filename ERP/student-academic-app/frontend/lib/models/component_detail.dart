class ComponentDetail {
  final String label;
  final double value;
  final double maxValue;
  final String unit;
  final List<Map<String, dynamic>> items;

  ComponentDetail({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.unit,
    this.items = const [],
  });

  factory ComponentDetail.fromJson(Map<String, dynamic> json) {
    return ComponentDetail(
      label: json['label'] as String,
      value: (json['value'] as num).toDouble(),
      maxValue: (json['max_value'] as num).toDouble(),
      unit: json['unit'] as String,
      items: (json['items'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'max_value': maxValue,
      'unit': unit,
      'items': items,
    };
  }

  double get percentage => maxValue > 0 ? (value / maxValue) * 100 : 0.0;

  @override
  String toString() => 'ComponentDetail(label: $label, value: $value/$maxValue $unit)';
}
