import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../models/sensor_history_record.dart';
import '../../../../widgets/common/line_chart_widget.dart';
import '../../../../widgets/common/metric_selector.dart';

class TrendChartSection extends StatelessWidget {
  const TrendChartSection({
    super.key,
    required this.metrics,
    required this.selectedMetricIndex,
    required this.records,
    required this.onMetricChanged,
  });

  final List<MetricOption> metrics;
  final int selectedMetricIndex;
  final List<SensorHistoryRecord> records;
  final ValueChanged<int> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metrics[selectedMetricIndex].label}趋势图',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                MetricSelector(
                  metrics: metrics,
                  selectedIndex: selectedMetricIndex,
                  onSelected: onMetricChanged,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildChart(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '详细数据列表',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildChart() {
    final metric = metrics[selectedMetricIndex];
    final lineColor = metric.color;
    final column = metric.column;

    final reversedRecords = records.reversed.toList();
    final spots = <FlSpot>[];

    for (int i = 0; i < reversedRecords.length; i++) {
      final record = reversedRecords[i];
      final double? value = switch (column) {
        'temperature' => record.temperature,
        'humidity' => record.humidity,
        'soil_moisture' => record.effectiveSoilMoisture,
        'illumination' => record.illumination,
        _ => null,
      };

      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    final minYRange = switch (column) {
      'illumination' => 500.0,
      'temperature' => 8.0,
      _ => 20.0, // humidity / soil_moisture
    };

    return LineChartWidget(
      spots: spots,
      lineColor: lineColor,
      showDots: true,
      minYRange: minYRange,
      bottomTitleBuilder: (value, meta) {
        final index = value.toInt();
        if (index >= 0 && index < reversedRecords.length) {
          final dt = reversedRecords[index].recordedAt;
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
