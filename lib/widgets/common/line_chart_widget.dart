import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartWidget extends StatelessWidget {
  const LineChartWidget({
    super.key,
    required this.spots,
    required this.lineColor,
    this.showDots = false,
    this.height = 200,
    this.yPadding = 0,
    this.bottomTitleBuilder,
  });

  final List<FlSpot> spots;
  final Color lineColor;
  final bool showDots;
  final double height;
  final double yPadding;
  final Widget Function(double value, TitleMeta meta)? bottomTitleBuilder;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('暂无数据')),
      );
    }

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1 + yPadding;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.15),
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (spots.length > 1)
                    ? ((spots.length - 1) / 5).ceil().toDouble()
                    : 1,
                getTitlesWidget: bottomTitleBuilder ??
                    (value, meta) => const SizedBox(),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: showDots && spots.length <= 20,
                getDotPainter: (spot, xPercentage, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: lineColor,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: 0.4),
                    lineColor.withValues(alpha: 0.01),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map(
                      (spot) => LineTooltipItem(
                        spot.y.toStringAsFixed(1),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
