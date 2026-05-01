class SensorTrendPoint {
  const SensorTrendPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }

  factory SensorTrendPoint.fromJson(Map<String, dynamic> json) {
    return SensorTrendPoint(
      label: json['label']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}
