import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../models/sensor_trend_point.dart';
import '../../../../widgets/common/line_chart_widget.dart';
import '../../../../widgets/common/metric_selector.dart';

class TrendSection extends StatelessWidget {
  const TrendSection({
    super.key,
    required this.metrics,
    required this.selectedMetricIndex,
    required this.selectedTimeIndex,
    required this.isLoading,
    required this.trendPoints,
    required this.onMetricChanged,
    required this.onTimeChanged,
  });

  final List<MetricOption> metrics;
  final int selectedMetricIndex;
  final int selectedTimeIndex;
  final bool isLoading;
  final List<SensorTrendPoint> trendPoints;
  final ValueChanged<int> onMetricChanged;
  final ValueChanged<int> onTimeChanged;

  static const _timeLabels = ['24小时', '7天', '30天'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${metrics[selectedMetricIndex].label}趋势',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: List.generate(_timeLabels.length, (index) {
                    final isSelected = selectedTimeIndex == index;
                    return GestureDetector(
                      onTap: () => onTimeChanged(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: isSelected
                            ? BoxDecoration(
color: Theme.of(context).colorScheme.surfaceContainerLow,
                                borderRadius:
                                    BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ],
                              )
                            : null,
                        child: Text(
                          _timeLabels[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.blueAccent
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildChart(),
          ),
          const SizedBox(height: 24),
          MetricSelector(
            metrics: metrics,
            selectedIndex: selectedMetricIndex,
            onSelected: onMetricChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final lineColor = metrics[selectedMetricIndex].color;
    final points = trendPoints.isNotEmpty ? trendPoints : _generateMockData();
    final spots = List.generate(
      points.length,
      (index) => FlSpot(index.toDouble(), points[index].value),
    );

    return LineChartWidget(
      spots: spots,
      lineColor: lineColor,
      height: 220,
      minYRange: selectedMetricIndex == 3
          ? 500.0
          : (selectedMetricIndex == 0 ? 8.0 : 20.0),
      bottomTitleBuilder: (value, meta) {
        final index = value.toInt();
        final label = index >= 0 && index < points.length
            ? points[index].label
            : '';
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
        );
      },
    );
  }

  List<SensorTrendPoint> _generateMockData() {
    final baseValue = selectedMetricIndex == 0
        ? 25.0
        : selectedMetricIndex == 1
            ? 65.0
            : selectedMetricIndex == 2
                ? 20.0
                : 3200.0;
    final volatility = selectedMetricIndex == 3
        ? 600.0
        : (selectedMetricIndex == 1 ? 15.0 : 5.0);
    final pointsCount = selectedTimeIndex == 0
        ? 7
        : selectedTimeIndex == 1
            ? 7
            : 6;

    final points = <SensorTrendPoint>[];
    for (int i = 0; i < pointsCount; i++) {
      final sineWave = (i % 2 == 0 ? 1 : -0.5) *
          volatility *
          ((selectedTimeIndex + 1) * 0.3);
      final pointValue = baseValue + sineWave + (i * 0.5);
      points.add(SensorTrendPoint(
        label: _getTimeLabel(i),
        value: pointValue,
      ));
    }
    return points;
  }

  String _getTimeLabel(int xValue) {
    if (selectedTimeIndex == 0) {
      const labels = ['00', '04', '08', '12', '16', '20', '24'];
      if (xValue >= 0 && xValue < labels.length) return labels[xValue];
    } else if (selectedTimeIndex == 1) {
      const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      if (xValue >= 0 && xValue < labels.length) return labels[xValue];
    } else {
      const labels = ['1号', '6号', '12号', '18号', '24号', '30号'];
      if (xValue >= 0 && xValue < labels.length) return labels[xValue];
    }
    return '';
  }
}
