import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class PredictionAlert {
  final String id;
  final String title;
  final String content;
  final String severity;
  final DateTime createdAt;
  final String? actionText;
  final String? actionType;

  const PredictionAlert({
    required this.id,
    required this.title,
    required this.content,
    required this.severity,
    required this.createdAt,
    this.actionText,
    this.actionType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'severity': severity,
        'createdAt': createdAt.toIso8601String(),
        'actionText': actionText,
        'actionType': actionType,
      };

  factory PredictionAlert.fromJson(Map<String, dynamic> json) => PredictionAlert(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        severity: json['severity']?.toString() ?? 'info',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        actionText: json['actionText']?.toString(),
        actionType: json['actionType']?.toString(),
      );
}

class AlertPredictionService {
  AlertPredictionService._();

  static final AlertPredictionService instance = AlertPredictionService._();

  static const _persistKey = 'prediction_alerts';
  final List<PredictionAlert> _alerts = [];

  static const _thresholds = {
    'temperature': {'max': 32.0, 'min': 5.0, 'warnRising': 28.0, 'warnDropping': 10.0},
    'humidity': {'max': 85.0, 'min': 30.0, 'warnRising': 80.0, 'warnDropping': 35.0},
  };

  List<PredictionAlert> get alerts => List.unmodifiable(_alerts);
  List<PredictionAlert> get unreadAlerts =>
      _alerts.where((a) => a.severity != 'info').toList();

  Future<void> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_persistKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _alerts.clear();
      _alerts.addAll(
        list.map((e) => PredictionAlert.fromJson(e as Map<String, dynamic>)),
      );
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _persistKey,
      jsonEncode(_alerts.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<PredictionAlert>> analyzeAndPredict(
    List<Map<String, double?>> trendPoints,
  ) async {
    if (trendPoints.length < 3) return const [];

    final now = DateTime.now();
    final newAlerts = <PredictionAlert>[];

    _analyzeMetric(
      trendPoints: trendPoints,
      key: 'temperature',
      label: '温度',
      unit: '°C',
      maxThreshold: _thresholds['temperature']!['max']!,
      minThreshold: _thresholds['temperature']!['min']!,
      warnRising: _thresholds['temperature']!['warnRising']!,
      warnDropping: _thresholds['temperature']!['warnDropping']!,
      now: now,
    ).forEach(newAlerts.add);

    _analyzeMetric(
      trendPoints: trendPoints,
      key: 'humidity',
      label: '空气湿度',
      unit: '%',
      maxThreshold: _thresholds['humidity']!['max']!,
      minThreshold: _thresholds['humidity']!['min']!,
      warnRising: _thresholds['humidity']!['warnRising']!,
      warnDropping: _thresholds['humidity']!['warnDropping']!,
      now: now,
    ).forEach(newAlerts.add);

    return newAlerts;
  }

  List<PredictionAlert> _analyzeMetric({
    required List<Map<String, double?>> trendPoints,
    required String key,
    required String label,
    required String unit,
    required double maxThreshold,
    required double minThreshold,
    required double warnRising,
    required double warnDropping,
    required DateTime now,
  }) {
    final values = <(DateTime, double)>[];
    for (final p in trendPoints) {
      final v = p[key];
      final tsRaw = p['recorded_at'];
      DateTime? ts;
      if (tsRaw != null) {
        ts = DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt());
      }
      if (v != null && ts != null) {
        values.add((ts, v));
      }
    }
    if (values.length < 3) return const [];

    values.sort((a, b) => a.$1.compareTo(b.$1));

    final n = values.length;
    final recent = values.sublist(max(0, n - 6));
    final last = recent.last;

    final slope = _linearSlope(recent);

    final alerts = <PredictionAlert>[];

    if (last.$2 >= maxThreshold) {
      alerts.add(PredictionAlert(
        id: 'pred_${key}_high_${now.millisecondsSinceEpoch}',
        title: '$label 过高警报',
        content: '当前$label ${last.$2.toStringAsFixed(1)}$unit，超过安全阈值 $maxThreshold$unit。建议立即开启通风降温。',
        severity: 'critical',
        createdAt: now,
        actionText: '开启通风',
        actionType: 'ventilate',
      ));
    } else if (last.$2 >= warnRising && slope > 0) {
      final etaSeconds = _estimateTimeToThreshold(recent, maxThreshold);
      if (etaSeconds != null && etaSeconds < 3600 * 6) {
        final etaMin = (etaSeconds / 60).round();
        alerts.add(PredictionAlert(
          id: 'pred_${key}_rising_${now.millisecondsSinceEpoch}',
          title: '$label 持续上升',
          content: '$label 正以较快速度上升，当前${last.$2.toStringAsFixed(1)}$unit，预计约${etaMin}分钟后超过安全阈值$maxThreshold$unit。建议提前开启通风。',
          severity: 'warning',
          createdAt: now,
          actionText: '提前通风',
          actionType: 'ventilate',
        ));
      }
    }

    if (last.$2 <= minThreshold) {
      alerts.add(PredictionAlert(
        id: 'pred_${key}_low_${now.millisecondsSinceEpoch}',
        title: '$label 过低警报',
        content: '当前$label ${last.$2.toStringAsFixed(1)}$unit，低于安全阈值 $minThreshold$unit。注意防寒/加湿。',
        severity: 'warning',
        createdAt: now,
        actionText: null,
        actionType: null,
      ));
    } else if (last.$2 <= warnDropping && slope < 0) {
      final etaSeconds = _estimateTimeToThreshold(recent, minThreshold);
      if (etaSeconds != null && etaSeconds < 3600 * 6) {
        final etaMin = (etaSeconds / 60).round();
        alerts.add(PredictionAlert(
          id: 'pred_${key}_dropping_${now.millisecondsSinceEpoch}',
          title: '$label 持续下降',
          content: '$label 正以较快速度下降，当前${last.$2.toStringAsFixed(1)}$unit，预计约${etaMin}分钟后低于安全阈值$minThreshold$unit。',
          severity: 'warning',
          createdAt: now,
          actionText: null,
          actionType: null,
        ));
      }
    }

    return alerts;
  }

  static double _linearSlope(List<(DateTime, double)> points) {
    if (points.length < 2) return 0;
    final n = points.length;
    final t0 = points.first.$1.millisecondsSinceEpoch.toDouble();
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (final p in points) {
      final x = (p.$1.millisecondsSinceEpoch.toDouble() - t0) / 1000.0 / 60.0;
      final y = p.$2;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    final denom = n * sumX2 - sumX * sumX;
    return denom == 0 ? 0 : (n * sumXY - sumX * sumY) / denom;
  }

  static int? _estimateTimeToThreshold(
    List<(DateTime, double)> points,
    double threshold,
  ) {
    final slope = _linearSlope(points);
    if (slope.abs() < 0.001) return null;
    final last = points.last.$2;
    final delta = threshold - last;
    if (slope > 0 && delta <= 0) return 0;
    if (slope < 0 && delta >= 0) return 0;
    return (delta / slope * 60).round().clamp(0, 86400);
  }

  void addAlert(PredictionAlert alert) {
    _alerts.insert(0, alert);
    if (_alerts.length > 50) {
      _alerts.removeRange(50, _alerts.length);
    }
    _persist();
  }

  void clear() {
    _alerts.clear();
    _persist();
  }
}
