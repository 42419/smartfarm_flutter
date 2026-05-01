import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../models/sensor_trend_point.dart';
import '../sensor_history/sensor_history_page.dart';
import '../../services/device_manager.dart';
import '../../services/sensor_history_service.dart';
import '../../widgets/common/metric_selector.dart';
import 'widgets/data_card.dart';
import 'widgets/trend_section.dart';

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

  final List<MetricOption> _metrics = const [
    MetricOption(label: '温度', color: Colors.orangeAccent, column: 'temperature'),
    MetricOption(label: '湿度', color: Colors.blueAccent, column: 'humidity'),
    MetricOption(label: '土壤湿度', color: Colors.green, column: 'soil_moisture'),
    MetricOption(label: '光照', color: Colors.amber, column: 'illumination'),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    DeviceManager.instance.addListener(_onDeviceUpdate);
    _loadTrendData(forceRefresh: true);
  }

  @override
  void dispose() {
    DeviceManager.instance.removeListener(_onDeviceUpdate);
    super.dispose();
  }

  void _onDeviceUpdate() {
    if (mounted) setState(() {});
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

  Future<void> _loadTrendData({bool forceRefresh = false}) async {
    setState(() => _isTrendLoading = true);

    final points = await SensorHistoryService.instance.fetchTrend(
      greenhouse: Config.supabaseGreenhouse,
      metric: _metrics[_selectedMetricIndex].column,
      range: _selectedRange,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

    setState(() {
      _trendPoints = points;
      _isTrendLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dm = DeviceManager.instance;
    final currentTemp = dm.temperature;
    final currentHumidity = dm.humidity;
    final currentIllumination = dm.illumination;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('数据监测',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('实时数据',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                DataCard(
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
                DataCard(
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
                DataCard(
                  icon: Icons.eco_outlined,
                  iconColor: Colors.green,
                  val: _calcSoilMoisture(currentTemp, currentHumidity),
                  unit: '%',
                  label: '土壤湿度',
                  range: '25% ~ 70%',
                  status:
                      _soilMoistureStatus(currentTemp, currentHumidity),
                  statusColor: _soilMoistureStatusColor(
                      currentTemp, currentHumidity),
                  valColor: Colors.black87,
                ),
                DataCard(
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
            TrendSection(
              metrics: _metrics,
              selectedMetricIndex: _selectedMetricIndex,
              selectedTimeIndex: _selectedTimeIndex,
              isLoading: _isTrendLoading,
              trendPoints: _trendPoints,
              onMetricChanged: (i) {
                setState(() => _selectedMetricIndex = i);
                _loadTrendData();
              },
              onTimeChanged: (i) {
                setState(() => _selectedTimeIndex = i);
                _loadTrendData();
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const SensorHistoryPage(),
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
                label: const Text('查看历史数据',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
    if (t == null || h == null) return '--';
    final result =
        (75 - (t - 22) * 2 + (h - 60) * 0.5).clamp(10.0, 95.0);
    return result.toStringAsFixed(1);
  }

  String _soilMoistureStatus(String tempStr, String humStr) {
    final v = double.tryParse(_calcSoilMoisture(tempStr, humStr));
    if (v == null) return '未知';
    if (v < 25) return '过低';
    if (v < 40) return '偏低';
    if (v <= 70) return '正常';
    return '偏高';
  }

  Color _soilMoistureStatusColor(String tempStr, String humStr) {
    switch (_soilMoistureStatus(tempStr, humStr)) {
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
}
