class SensorHistoryRecord {
  const SensorHistoryRecord({
    required this.recordedAt,
    this.temperature,
    this.humidity,
    this.illumination,
    this.soilMoisture,
    this.co2,
    this.phValue,
  });

  final DateTime recordedAt;
  final double? temperature;
  final double? humidity;
  final double? illumination;
  final double? soilMoisture;
  final double? co2;
  final double? phValue;

  double get effectiveSoilMoisture {
    if (soilMoisture != null) return soilMoisture!;
    if (temperature != null && humidity != null) {
      final estimated =
          75 - (temperature! - 22) * 2 + (humidity! - 60) * 0.5;
      return estimated.clamp(10.0, 95.0);
    }
    return 60;
  }

  Map<String, dynamic> toJson() {
    return {
      'recordedAt': recordedAt.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'illumination': illumination,
      'soilMoisture': soilMoisture,
      'co2': co2,
      'phValue': phValue,
    };
  }

  factory SensorHistoryRecord.fromJson(Map<String, dynamic> json) {
    return SensorHistoryRecord(
      recordedAt:
          DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
              DateTime.now(),
      temperature: _readDouble(json['temperature']),
      humidity: _readDouble(json['humidity']),
      illumination: _readDouble(json['illumination']),
      soilMoisture: _readDouble(json['soilMoisture']),
      co2: _readDouble(json['co2']),
      phValue: _readDouble(json['phValue']),
    );
  }

  static double? _readDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }
}
