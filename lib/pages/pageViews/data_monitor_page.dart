import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/device_manager.dart';

class DataMonitorPage extends StatefulWidget {
  const DataMonitorPage({super.key});

  @override
  State<DataMonitorPage> createState() => _DataMonitorPageState();
}

class _DataMonitorPageState extends State<DataMonitorPage> {
  int _selectedTimeIndex = 0; // 0: 24小时, 1: 7天, 2: 30天
  int _selectedMetricIndex = 0; // 0: 温度, 1: 湿度, 2: 土壤湿度, 3: 光照

  final List<String> _timeLabels = ['24小时', '7天', '30天'];
  final List<Map<String, dynamic>> _metrics = [
    {'label': '温度', 'color': Colors.orangeAccent},
    {'label': '湿度', 'color': Colors.blueAccent},
    {'label': '土壤湿度', 'color': Colors.green},
    {'label': '光照', 'color': Colors.amber},
  ];

  @override
  void initState() {
    super.initState();
    DeviceManager.instance.addListener(_onDeviceUpdate);
  }

  @override
  void dispose() {
    DeviceManager.instance.removeListener(_onDeviceUpdate);
    super.dispose();
  }

  void _onDeviceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final deviceManager = DeviceManager.instance;
    String _currentTemp = deviceManager.temperature;
    String _currentHumidity = deviceManager.humidity;
    String _currentIllumination = deviceManager.illumination;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '数据监测',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEBF3FF),
                foregroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                '导出报表',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部的三个筛选下拉框
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterDropdown('东郊农场'),
                _buildFilterDropdown('全部大棚'),
                _buildFilterDropdown('全部指标'),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              '实时数据',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // 实时数据网格
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
                  val: _currentTemp,
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
                  val: _currentHumidity,
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
                  val: '18',
                  unit: '%',
                  label: '土壤湿度',
                  range: '25% ~ 60%',
                  status: '偏低',
                  statusColor: Colors.redAccent,
                  valColor: Colors.redAccent,
                ),
                _buildDataCard(
                  icon: Icons.wb_sunny_outlined,
                  iconColor: Colors.yellow.shade700,
                  val: _currentIllumination,
                  unit: '',
                  label: '光照强度(lux)',
                  range: '1000 ~ 8000',
                  status: '正常',
                  statusColor: Colors.green,
                  valColor: Colors.black87,
                ),
                _buildDataCard(
                  icon: Icons.cloud_outlined,
                  iconColor: Colors.purpleAccent,
                  val: '820',
                  unit: '',
                  label: 'CO2浓度(ppm)',
                  range: '400 ~ 1500',
                  status: '正常',
                  statusColor: Colors.green,
                  valColor: Colors.black87,
                ),
                _buildDataCard(
                  icon: Icons.science_outlined,
                  iconColor: Colors.indigoAccent,
                  val: '6.8',
                  unit: '',
                  label: '土壤pH值',
                  range: '5.5 ~ 7.5',
                  status: '正常',
                  statusColor: Colors.green,
                  valColor: Colors.black87,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 趋势图区域包裹在一个卡片里
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
                  // 图表顶部区域：标题和时间范围切换
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
                            bool isSelected = _selectedTimeIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTimeIndex = index;
                                });
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

                  // 图表主体
                  SizedBox(height: 220, child: _buildLineChart()),

                  const SizedBox(height: 24),

                  // 图表底部区域：指标切换
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_metrics.length, (index) {
                        bool isSelected = _selectedMetricIndex == index;
                        Color metricColor = _metrics[index]['color'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMetricIndex = index;
                            });
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
                                  _metrics[index]['label'],
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 下拉筛选组件
  Widget _buildFilterDropdown(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  // 实时数据卡片
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

  // 构建平滑优美的曲线图
  Widget _buildLineChart() {
    Color lineColor = _metrics[_selectedMetricIndex]['color'];
    List<FlSpot> spots = _generateMockData();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          // 去除强制为1的水平网格线间隔，让其根据数据跨度自动计算，避免数据跨度大时(如光照上千的值)渲染成百上千条网格线导致严重卡顿
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
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _getTimeLabel(value.toInt()),
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
        // 给Y轴留白一些空间，看起来更好看
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
            // 隐藏数据小圆点，让曲线更高级
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
            // 这里提供的是默认的悬浮小提示气泡，可以自定义底色
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

  // 根据当前选择的时间与指标模拟生成数据
  List<FlSpot> _generateMockData() {
    double baseValue = _selectedMetricIndex == 0
        ? 25.0
        : _selectedMetricIndex == 1
        ? 65.0
        : _selectedMetricIndex == 2
        ? 20.0
        : 3200.0;
    double volatility = _selectedMetricIndex == 3
        ? 600
        : (_selectedMetricIndex == 1 ? 15.0 : 5.0);
    int pointsCount = _selectedTimeIndex == 0
        ? 7
        : _selectedTimeIndex == 1
        ? 7
        : 6;

    List<FlSpot> spots = [];
    for (int i = 0; i < pointsCount; i++) {
      // 创建具有一定周期的平滑抛物线
      double sineWave =
          (i % 2 == 0 ? 1 : -0.5) *
          volatility *
          ((_selectedTimeIndex + 1) * 0.3);
      double pointValue = baseValue + sineWave + (i * 0.5);
      spots.add(FlSpot(i.toDouble(), pointValue));
    }
    return spots;
  }

  String _getTimeLabel(int xValue) {
    if (_selectedTimeIndex == 0) {
      List<String> labels = [
        '00:00',
        '04:00',
        '08:00',
        '12:00',
        '16:00',
        '20:00',
        '24:00',
      ];
      if (xValue >= 0 && xValue < labels.length) return labels[xValue];
    } else if (_selectedTimeIndex == 1) {
      List<String> labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      if (xValue >= 0 && xValue < labels.length) return labels[xValue];
    } else {
      List<String> labels = ['1号', '6号', '12号', '18号', '24号', '30号'];
      if (xValue >= 0 && xValue < labels.length) return labels[xValue];
    }
    return '';
  }
}
