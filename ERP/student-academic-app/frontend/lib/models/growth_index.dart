import 'component_detail.dart';

class GrowthIndex {
  final double growthIndex;
  final Map<String, ComponentDetail> components;

  GrowthIndex({
    required this.growthIndex,
    required this.components,
  });

  factory GrowthIndex.fromJson(Map<String, dynamic> json) {
    return GrowthIndex(
      growthIndex: (json['growth_index'] as num).toDouble(),
      components: (json['components'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, ComponentDetail.fromJson(value as Map<String, dynamic>))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'growth_index': growthIndex,
      'components': components.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  @override
  String toString() => 'GrowthIndex(index: $growthIndex)';
}
