import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      temperature: _readDoubleValue(json['temperature']),
      humidity: _readDoubleValue(json['humidity']),
      illumination: _readDoubleValue(json['illumination']),
      soilMoisture: _readDoubleValue(json['soilMoisture']),
      co2: _readDoubleValue(json['co2']),
      phValue: _readDoubleValue(json['phValue']),
    );
  }
}

enum TrendRange { last24Hours, last7Days, last30Days }

class SensorHistoryService {
  static const _minRecordInterval = Duration(minutes: 1);
  static const _trendCacheTtl = Duration(minutes: 2);
  static const _recordsCacheTtl = Duration(minutes: 2);
  static const _availableDatesCacheTtl = Duration(minutes: 10);

  SensorHistoryService._();

  static final SensorHistoryService instance = SensorHistoryService._();

  DateTime? _lastRecordedAt;
  final Map<String, _HistoryCacheEntry> _memoryCache = {};

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
    bool forceRefresh = false,
  }) async {
    final cacheKey = _trendCacheKey(greenhouse, metric, range);
    if (!forceRefresh) {
      final cached = await _readCache<List<SensorTrendPoint>>(
        cacheKey,
        _decodeTrendPoints,
      );
      if (cached != null) {
        if (cached.isStale(_trendCacheTtl)) {
          unawaited(
            _refreshTrendCache(
              cacheKey: cacheKey,
              greenhouse: greenhouse,
              metric: metric,
              range: range,
            ),
          );
        }
        return cached.value;
      }
    }

    return _refreshTrendCache(
      cacheKey: cacheKey,
      greenhouse: greenhouse,
      metric: metric,
      range: range,
    );
  }

  Future<List<SensorHistoryRecord>> fetchRecords({
    required String greenhouse,
    DateTime? startDate,
    DateTime? endDate,
    bool descending = true,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _recordsCacheKey(
      greenhouse: greenhouse,
      startDate: startDate,
      endDate: endDate,
      descending: descending,
      limit: limit,
    );
    if (!forceRefresh) {
      final cached = await _readCache<List<SensorHistoryRecord>>(
        cacheKey,
        _decodeHistoryRecords,
      );
      if (cached != null) {
        if (cached.isStale(_recordsCacheTtl)) {
          unawaited(
            _refreshRecordsCache(
              cacheKey: cacheKey,
              greenhouse: greenhouse,
              startDate: startDate,
              endDate: endDate,
              descending: descending,
              limit: limit,
            ),
          );
        }
        return cached.value;
      }
    }

    return _refreshRecordsCache(
      cacheKey: cacheKey,
      greenhouse: greenhouse,
      startDate: startDate,
      endDate: endDate,
      descending: descending,
      limit: limit,
    );
  }

  Future<Set<DateTime>> fetchAvailableDates({
    required String greenhouse,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _availableDatesCacheKey(greenhouse);
    if (!forceRefresh) {
      final cached = await _readCache<Set<DateTime>>(
        cacheKey,
        _decodeDateSet,
      );
      if (cached != null) {
        if (cached.isStale(_availableDatesCacheTtl)) {
          unawaited(
            _refreshAvailableDatesCache(
              cacheKey: cacheKey,
              greenhouse: greenhouse,
            ),
          );
        }
        return cached.value;
      }
    }

    return _refreshAvailableDatesCache(
      cacheKey: cacheKey,
      greenhouse: greenhouse,
    );
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
        return time.hour.toString().padLeft(2, '0');
      case TrendRange.last7Days:
        const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
        return labels[time.weekday - 1];
      case TrendRange.last30Days:
        return '${time.day}号';
    }
  }

  Future<List<SensorTrendPoint>> _refreshTrendCache({
    required String cacheKey,
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

      final points = buckets.entries
          .map(
            (entry) => SensorTrendPoint(
              label: entry.key,
              value: entry.value.reduce((a, b) => a + b) / entry.value.length,
            ),
          )
          .toList();
      await _writeCache(cacheKey, points.map((e) => e.toJson()).toList());
      return points;
    } catch (error) {
      debugPrint('Supabase fetchTrend failed: $error');
      final cached = await _readCache<List<SensorTrendPoint>>(
        cacheKey,
        _decodeTrendPoints,
      );
      return cached?.value ?? const [];
    }
  }

  Future<List<SensorHistoryRecord>> _refreshRecordsCache({
    required String cacheKey,
    required String greenhouse,
    DateTime? startDate,
    DateTime? endDate,
    required bool descending,
    required int limit,
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
      final records = rows.map((row) {
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
      await _writeCache(
        cacheKey,
        records.map((e) => e.toJson()).toList(),
      );
      return records;
    } catch (error) {
      debugPrint('Supabase fetchRecords failed: $error');
      final cached = await _readCache<List<SensorHistoryRecord>>(
        cacheKey,
        _decodeHistoryRecords,
      );
      return cached?.value ?? const [];
    }
  }

  Future<Set<DateTime>> _refreshAvailableDatesCache({
    required String cacheKey,
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
      await _writeCache(
        cacheKey,
        dates.map((date) => date.toIso8601String()).toList(),
      );
      return dates;
    } catch (error) {
      debugPrint('fetchAvailableDates failed: $error');
      final cached = await _readCache<Set<DateTime>>(
        cacheKey,
        _decodeDateSet,
      );
      return cached?.value ?? {};
    }
  }

  Future<_CachedValue<T>?> _readCache<T>(
    String key,
    T Function(Object? payload) decoder,
  ) async {
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null) {
      return _CachedValue(
        value: decoder(memoryEntry.payload),
        savedAt: memoryEntry.savedAt,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt =
          DateTime.tryParse(decoded['savedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final payload = decoded['payload'];
      final entry = _HistoryCacheEntry(savedAt: savedAt, payload: payload);
      _memoryCache[key] = entry;
      return _CachedValue(
        value: decoder(payload),
        savedAt: savedAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, Object payload) async {
    final entry = _HistoryCacheEntry(
      savedAt: DateTime.now(),
      payload: payload,
    );
    _memoryCache[key] = entry;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'savedAt': entry.savedAt.toIso8601String(),
        'payload': payload,
      }),
    );
  }

  List<SensorTrendPoint> _decodeTrendPoints(Object? payload) {
    final items = (payload as List<dynamic>? ?? const []);
    return items
        .map((item) => SensorTrendPoint.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  List<SensorHistoryRecord> _decodeHistoryRecords(Object? payload) {
    final items = (payload as List<dynamic>? ?? const []);
    return items
        .map((item) => SensorHistoryRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Set<DateTime> _decodeDateSet(Object? payload) {
    final items = (payload as List<dynamic>? ?? const []);
    return items
        .map(
          (item) => DateTime.tryParse(item.toString())?.toLocal(),
        )
        .whereType<DateTime>()
        .map((dt) => DateTime(dt.year, dt.month, dt.day))
        .toSet();
  }

  String _trendCacheKey(String greenhouse, String metric, TrendRange range) {
    return 'sensor_history_trend_${jsonEncode({
      'greenhouse': greenhouse,
      'metric': metric,
      'range': range.name,
    })}';
  }

  String _recordsCacheKey({
    required String greenhouse,
    DateTime? startDate,
    DateTime? endDate,
    required bool descending,
    required int limit,
  }) {
    return 'sensor_history_records_${jsonEncode({
      'greenhouse': greenhouse,
      'startDate': startDate?.toUtc().toIso8601String(),
      'endDate': endDate?.toUtc().toIso8601String(),
      'descending': descending,
      'limit': limit,
    })}';
  }

  String _availableDatesCacheKey(String greenhouse) {
    return 'sensor_history_dates_${jsonEncode({
      'greenhouse': greenhouse,
    })}';
  }
}

class _HistoryCacheEntry {
  const _HistoryCacheEntry({
    required this.savedAt,
    required this.payload,
  });

  final DateTime savedAt;
  final Object payload;
}

class _CachedValue<T> {
  const _CachedValue({
    required this.value,
    required this.savedAt,
  });

  final T value;
  final DateTime savedAt;

  bool isStale(Duration ttl) {
    return DateTime.now().difference(savedAt) > ttl;
  }
}

double? _readDoubleValue(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is num) {
    return raw.toDouble();
  }
  return double.tryParse(raw.toString());
}
