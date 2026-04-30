import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../models/sensor_trend_point.dart';
import '../sensor_history_page.dart';
import '../../services/device_manager.dart';
import '../../services/sensor_history_service.dart';

class DataMonitorPage extends StatefulWidget {
  const DataMonitorPage({super.key});

  @override
  State<DataMonitorPage> createState() => _DataMonitorPageState();
}

class _DataMonitorPageState extends State<DataMonitorPage>
    with AutomaticKeepAliveClientMixin {
  int _selectedTimeIndex = 0;
  int _selectedMetricIndex = 0;
  bool _isTrendLoading = false;
  List<SensorTrendPoint> _trendPoints = const [];

  final List<String> _timeLabels = ['24小时', '7天', '30天'];
  final List<Map<String, dynamic>> _metrics = [
    {'label': '温度', 'color': Colors.orangeAccent, 'column': 'temperature'},
    {'label': '湿度', 'color': Colors.blueAccent, 'column': 'humidity'},
    {'label': '土壤湿度', 'color': Colors.green, 'column': 'soil_moisture'},
    {'label': '光照', 'color': Colors.amber, 'column': 'illumination'},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    DeviceManager.instance.addListener(_onDeviceUpdate);
    _loadTrendData();
  }

  @override
  void dispose() {
    DeviceManager.instance.removeListener(_onDeviceUpdate);
    super.dispose();
  }

  void _onDeviceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  TrendRange get _selectedRange {
    switch (_selectedTimeIndex) {
      case 0:
        return TrendRange.last24Hours;
      case 1:
        return TrendRange.last7Days;
      case 2:
        return TrendRange.last30Days;
      default:
        return TrendRange.last24Hours;
    }
  }

  Future<void> _loadTrendData() async {
    setState(() {
      _isTrendLoading = true;
    });

    final points = await SensorHistoryService.instance.fetchTrend(
      greenhouse: Config.supabaseGreenhouse,
      metric: _metrics[_selectedMetricIndex]['column'] as String,
      range: _selectedRange,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _trendPoints = points;
      _isTrendLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final deviceManager = DeviceManager.instance;
    final currentTemp = deviceManager.temperature;
    final currentHumidity = deviceManager.humidity;
    final currentIllumination = deviceManager.illumination;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '数据监测',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '实时数据',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDataCard(
                  icon: Icons.thermostat,
                  iconColor: Colors.orangeAccent,
                  val: currentTemp,
                  unit: '°C',
                  label: '温度',
                  range: '15°C ~ 30°C',
                  status: '正常',
                  statusColor: Colors.green,
                  valColor: Colors.black87,
                ),
                _buildDataCard(
                  icon: Icons.water_drop_outlined,
                  iconColor: Colors.blueAccent,
                  val: currentHumidity,
                  unit: '%',
                  label: '空气湿度',
                  range: '40% ~ 80%',
                  status: '正常',
                  statusColor: Colors.green,
                  valColor: Colors.black87,
                ),
                _buildDataCard(
                  icon: Icons.eco_outlined,
                  iconColor: Colors.green,
                  val: _calcSoilMoisture(currentTemp, currentHumidity),
                  unit: '%',
                  label: '土壤湿度',
                  range: '25% ~ 70%',
                  status: _soilMoistureStatus(currentTemp, currentHumidity),
                  statusColor:
                      _soilMoistureStatusColor(currentTemp, currentHumidity),
                  valColor: Colors.black87,
                ),
                _buildDataCard(
                  icon: Icons.wb_sunny_outlined,
                  iconColor: Colors.yellow.shade700,
                  val: currentIllumination,
                  unit: '',
                  label: '光照强度(lux)',
                  range: '1000 ~ 8000',
                  status: '正常',
                  statusColor: Colors.green,
                  valColor: Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        '${_metrics[_selectedMetricIndex]['label']}趋势',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          children: List.generate(_timeLabels.length, (index) {
                            final isSelected = _selectedTimeIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTimeIndex = index;
                                });
                                _loadTrendData();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: isSelected
                                    ? BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
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
                                        : Colors.grey,
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
                    child: _isTrendLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildLineChart(),
                  ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_metrics.length, (index) {
                        final isSelected = _selectedMetricIndex == index;
                        final metricColor = _metrics[index]['color'] as Color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMetricIndex = index;
                            });
                            _loadTrendData();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? metricColor.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? metricColor.withValues(alpha: 0.3)
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: metricColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _metrics[index]['label'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? metricColor
                                        : Colors.black54,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SensorHistoryPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2B3245),
                  side: const BorderSide(color: Color(0xFF2B3245)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.history),
                label: const Text(
                  '查看历史数据',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _calcSoilMoisture(String tempStr, String humStr) {
    final t = double.tryParse(tempStr);
    final h = double.tryParse(humStr);
    if (t == null || h == null) {
      return '--';
    }
    final result = (75 - (t - 22) * 2 + (h - 60) * 0.5).clamp(10.0, 95.0);
    return result.toStringAsFixed(1);
  }

  String _soilMoistureStatus(String tempStr, String humStr) {
    final v = double.tryParse(_calcSoilMoisture(tempStr, humStr));
    if (v == null) {
      return '未知';
    }
    if (v < 25) {
      return '过低';
    }
    if (v < 40) {
      return '偏低';
    }
    if (v <= 70) {
      return '正常';
    }
    return '偏高';
  }

  Color _soilMoistureStatusColor(String tempStr, String humStr) {
    final status = _soilMoistureStatus(tempStr, humStr);
    switch (status) {
      case '正常':
        return Colors.green;
      case '偏低':
        return Colors.orangeAccent;
      case '过高':
      case '过低':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDataCard({
    required IconData icon,
    required Color iconColor,
    required String val,
    required String unit,
    required String label,
    required String range,
    required String status,
    required Color statusColor,
    required Color valColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    val,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: valColor,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: valColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          Text(
            '阈值范围: $range',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final lineColor = _metrics[_selectedMetricIndex]['color'] as Color;
    final points = _trendPoints.isNotEmpty ? _trendPoints : _generateMockData();
    final spots = List.generate(
      points.length,
      (index) => FlSpot(index.toDouble(), points[index].value),
    );

    return LineChart(
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
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final label = index >= 0 && index < points.length
                    ? points[index].label
                    : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY:
            spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) -
            (_selectedMetricIndex == 3 ? 200 : 2),
        maxY:
            spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) +
            (_selectedMetricIndex == 3 ? 200 : 2),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
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
                      ),
                    ),
                  )
                  .toList();
            },
          ),
        ),
      ),
    );
  }

  List<SensorTrendPoint> _generateMockData() {
    final baseValue = _selectedMetricIndex == 0
        ? 25.0
        : _selectedMetricIndex == 1
        ? 65.0
        : _selectedMetricIndex == 2
        ? 20.0
        : 3200.0;
    final volatility = _selectedMetricIndex == 3
        ? 600.0
        : (_selectedMetricIndex == 1 ? 15.0 : 5.0);
    final pointsCount = _selectedTimeIndex == 0
        ? 7
        : _selectedTimeIndex == 1
        ? 7
        : 6;

    final points = <SensorTrendPoint>[];
    for (int i = 0; i < pointsCount; i++) {
      final sineWave =
          (i % 2 == 0 ? 1 : -0.5) * volatility * ((_selectedTimeIndex + 1) * 0.3);
      final pointValue = baseValue + sineWave + (i * 0.5);
      points.add(
        SensorTrendPoint(
          label: _getTimeLabel(i),
          value: pointValue,
        ),
      );
    }
    return points;
  }

  String _getTimeLabel(int xValue) {
    if (_selectedTimeIndex == 0) {
      const labels = [
        '00:00',
        '04:00',
        '08:00',
        '12:00',
        '16:00',
        '20:00',
        '24:00',
      ];
      if (xValue >= 0 && xValue < labels.length) {
        return labels[xValue];
      }
    } else if (_selectedTimeIndex == 1) {
      const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      if (xValue >= 0 && xValue < labels.length) {
        return labels[xValue];
      }
    } else {
      const labels = ['1号', '6号', '12号', '18号', '24号', '30号'];
      if (xValue >= 0 && xValue < labels.length) {
        return labels[xValue];
      }
    }
    return '';
  }
}
