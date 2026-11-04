class GrowthIndex {
  final double overall;
  final Map<String, ComponentDetail> components;

  GrowthIndex({
    required this.overall,
    required this.components,
  });

  factory GrowthIndex.fromJson(Map<String, dynamic> json) {
    return GrowthIndex(
      overall: (json['overall'] as num).toDouble(),
      components: (json['components'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, ComponentDetail.fromJson(value))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'components': components.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  @override
  String toString() => 'GrowthIndex(overall: $overall)';
}
