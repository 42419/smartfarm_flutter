import 'package:flutter/foundation.dart';

import '../models/sensor_trend_point.dart';
import 'supabase_service.dart';

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
    if (soilMoisture != null) {
      return soilMoisture!;
    }
    if (temperature != null && humidity != null) {
      final estimated = 75 - (temperature! - 22) * 2 + (humidity! - 60) * 0.5;
      return estimated.clamp(10.0, 95.0);
    }
    return 60;
  }
}

enum TrendRange { last24Hours, last7Days, last30Days }

class SensorHistoryService {
  static const _minRecordInterval = Duration(minutes: 1);

  SensorHistoryService._();

  static final SensorHistoryService instance = SensorHistoryService._();

  DateTime? _lastRecordedAt;

  Future<void> recordReading({
    required String greenhouse,
    double? temperature,
    double? humidity,
    double? illumination,
    double? soilMoisture,
    double? co2,
    double? phValue,
  }) async {
    final client = SupabaseService.maybeClient;
    if (client == null) {
      return;
    }

    final now = DateTime.now();
    if (_shouldSkipRecord(now)) {
      return;
    }

    try {
      await client.from('sensor_readings').insert({
        'greenhouse': greenhouse,
        'temperature': temperature,
        'humidity': humidity,
        'illumination': illumination,
        'soil_moisture': soilMoisture,
        'co2': co2,
        'ph_value': phValue,
        'recorded_at': now.toUtc().toIso8601String(),
      });
      _lastRecordedAt = now;
    } catch (error) {
      debugPrint('Supabase recordReading failed: $error');
    }
  }

  Future<List<SensorTrendPoint>> fetchTrend({
    required String greenhouse,
    required String metric,
    required TrendRange range,
  }) async {
    final client = SupabaseService.maybeClient;
    if (client == null) {
      return const [];
    }

    final now = DateTime.now().toUtc();
    final start = switch (range) {
      TrendRange.last24Hours => now.subtract(const Duration(hours: 24)),
      TrendRange.last7Days => now.subtract(const Duration(days: 7)),
      TrendRange.last30Days => now.subtract(const Duration(days: 30)),
    };

    try {
      final rows = await client
          .from('sensor_readings')
          .select('recorded_at, $metric')
          .eq('greenhouse', greenhouse)
          .gte('recorded_at', start.toIso8601String())
          .order('recorded_at', ascending: true);

      final buckets = <String, List<double>>{};
      for (final row in rows) {
        final value = _readDouble(row[metric]);
        final recordedAt = DateTime.tryParse(
          row['recorded_at']?.toString() ?? '',
        );
        if (value == null || recordedAt == null) {
          continue;
        }

        final label = _bucketLabel(recordedAt.toLocal(), range);
        buckets.putIfAbsent(label, () => <double>[]).add(value);
      }

      return buckets.entries
          .map(
            (entry) => SensorTrendPoint(
              label: entry.key,
              value: entry.value.reduce((a, b) => a + b) / entry.value.length,
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('Supabase fetchTrend failed: $error');
      return const [];
    }
  }

  Future<List<SensorHistoryRecord>> fetchRecords({
    required String greenhouse,
    DateTime? startDate,
    DateTime? endDate,
    bool descending = true,
    int limit = 100,
  }) async {
    final client = SupabaseService.maybeClient;
    if (client == null) {
      return const [];
    }

    try {
      var query = client
          .from('sensor_readings')
          .select(
            'recorded_at, temperature, humidity, illumination, soil_moisture, co2, ph_value',
          )
          .eq('greenhouse', greenhouse);

      if (startDate != null) {
        query = query.gte('recorded_at', startDate.toUtc().toIso8601String());
      }
      if (endDate != null) {
        final inclusiveEnd = endDate
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        query = query.lte(
          'recorded_at',
          inclusiveEnd.toUtc().toIso8601String(),
        );
      }
      final finalQuery = query
          .order('recorded_at', ascending: !descending)
          .limit(limit);

      final rows = await finalQuery;
      return rows.map((row) {
        final recordedAt =
            DateTime.tryParse(
              row['recorded_at']?.toString() ?? '',
            )?.toLocal() ??
            DateTime.now();
        return SensorHistoryRecord(
          recordedAt: recordedAt,
          temperature: _readDouble(row['temperature']),
          humidity: _readDouble(row['humidity']),
          illumination: _readDouble(row['illumination']),
          soilMoisture: _readDouble(row['soil_moisture']),
          co2: _readDouble(row['co2']),
          phValue: _readDouble(row['ph_value']),
        );
      }).toList();
    } catch (error) {
      debugPrint('Supabase fetchRecords failed: $error');
      return const [];
    }
  }

  Future<Set<DateTime>> fetchAvailableDates({
    required String greenhouse,
  }) async {
    final client = SupabaseService.maybeClient;
    if (client == null) {
      return {};
    }

    try {
      final rows = await client
          .from('sensor_readings')
          .select('recorded_at')
          .eq('greenhouse', greenhouse);

      final dates = <DateTime>{};
      for (final row in rows) {
        final dateStr = row['recorded_at']?.toString();
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr)?.toLocal();
          if (dt != null) {
            dates.add(DateTime(dt.year, dt.month, dt.day));
          }
        }
      }
      return dates;
    } catch (error) {
      debugPrint('fetchAvailableDates failed: $error');
      return {};
    }
  }

  bool _shouldSkipRecord(DateTime now) {
    if (_lastRecordedAt == null) {
      return false;
    }

    final elapsed = now.difference(_lastRecordedAt!);
    return elapsed < _minRecordInterval;
  }

  double? _readDouble(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw.toString());
  }

  String _bucketLabel(DateTime time, TrendRange range) {
    switch (range) {
      case TrendRange.last24Hours:
        return '${time.hour.toString().padLeft(2, '0')}:00';
      case TrendRange.last7Days:
        const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
        return labels[time.weekday - 1];
      case TrendRange.last30Days:
        return '${time.day}号';
    }
  }
}
