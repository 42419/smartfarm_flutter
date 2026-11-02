import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../models/sensor_trend_point.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../sensor_history/sensor_history_page.dart';
import '../../services/device_manager.dart';
import '../../services/sensor_history_service.dart';
import '../../widgets/common/metric_selector.dart';
import 'widgets/data_card.dart';
import 'widgets/trend_section.dart';

class _SelectOption {
  const _SelectOption({required this.label});

  final String label;
}

class DataMonitorPage extends StatefulWidget {
  const DataMonitorPage({super.key});

  @override
  State<DataMonitorPage> createState() => _DataMonitorPageState();
}

class _DataMonitorPageState extends State<DataMonitorPage>
    with AutomaticKeepAliveClientMixin {
  static const _eastFarmLabel = '东郊农场';
  static const _experimentGreenhouseLabel = '实验大棚';
  static const _simInterval = Duration(seconds: 3);

  int _selectedTimeIndex = 0;
  int _selectedMetricIndex = 0;
  bool _isTrendLoading = false;
  List<SensorTrendPoint> _trendPoints = const [];
  List<_SelectOption> _greenhouseOptions = const [
    _SelectOption(label: _experimentGreenhouseLabel),
  ];
  late final List<_SelectOption> _farmOptions;
  final List<_SelectOption> _indicatorOptions = const [
    _SelectOption(label: '全部指标'),
    _SelectOption(label: '温度指标'),
    _SelectOption(label: '湿度指标'),
    _SelectOption(label: '光照强度指标'),
  ];
  String _selectedFarmLabel = '';
  String _selectedGreenhouseLabel = _experimentGreenhouseLabel;
  String _selectedIndicatorLabel = '全部指标';

  Timer? _simTimer;
  double _simTemp = 30;
  double _simHumidity = 70;
  double _simSoilMoisture = 55;
  double _simIllumination = 4000;

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
    final currentFarm = AuthService.instance.currentUser?.farm.trim();
    final farmName = currentFarm != null && currentFarm.isNotEmpty
        ? currentFarm
        : '实验农场';
    _farmOptions = [
      _SelectOption(label: farmName),
      const _SelectOption(label: '东郊农场'),
    ];
    _selectedFarmLabel = _farmOptions.first.label;
    _greenhouseOptions = _greenhouseOptionsForFarm(_selectedFarmLabel);
    _regenerateSimulated();
    _simTimer = Timer.periodic(_simInterval, (_) {
      if (!_useRealData && mounted) setState(_regenerateSimulated);
    });
    DeviceManager.instance.addListener(_onDeviceUpdate);
    _loadTrendData(forceRefresh: true);
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    DeviceManager.instance.removeListener(_onDeviceUpdate);
    super.dispose();
  }

  void _onDeviceUpdate() {
    if (mounted) setState(() {});
  }

  List<_SelectOption> _greenhouseOptionsForFarm(String farmLabel) {
    if (farmLabel == _eastFarmLabel) {
      return List.generate(
        12,
        (index) => _SelectOption(label: '${index + 1}号大棚'),
      );
    }
    return const [
      _SelectOption(label: _experimentGreenhouseLabel),
    ];
  }

  bool get _useRealData =>
      _selectedFarmLabel != _eastFarmLabel &&
      _selectedGreenhouseLabel == _experimentGreenhouseLabel;

  static double _step(double current, double min, double max, double delta) {
    return (current + (Random().nextDouble() * 2 - 1) * delta)
        .clamp(min, max);
  }

  void _regenerateSimulated() {
    _simTemp = _step(_simTemp, 25, 35, 0.5);
    _simHumidity = _step(_simHumidity, 55, 85, 2);
    _simSoilMoisture = _step(_simSoilMoisture, 40, 70, 2);
    _simIllumination = _step(_simIllumination, 2000, 6000, 200);
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
    final isSimulated = !_useRealData;
    final currentTemp = isSimulated ? _simTemp.toStringAsFixed(1) : dm.temperature;
    final currentHumidity =
        isSimulated ? _simHumidity.toStringAsFixed(1) : dm.humidity;
    final currentIllumination =
        isSimulated ? _simIllumination.toStringAsFixed(0) : dm.illumination;
    final currentSoilMoisture = isSimulated
        ? _simSoilMoisture.toStringAsFixed(1)
        : _calcSoilMoisture(dm.temperature, dm.humidity);
    final isLarge = Responsive.isLargeScreen(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('数据监测',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: isLarge
          ? _buildLandscapeBody(context, currentTemp, currentHumidity,
              currentSoilMoisture, currentIllumination)
          : _buildPortraitBody(context, currentTemp, currentHumidity,
              currentSoilMoisture, currentIllumination),
    );
  }

  List<Widget> _buildDataCards(String currentTemp, String currentHumidity,
      String currentSoilMoisture, String currentIllumination) {
    final valColor = Theme.of(context).colorScheme.onSurface;
    return [
      DataCard(
        icon: Icons.thermostat,
        iconColor: Colors.orangeAccent,
        val: currentTemp,
        unit: '°C',
        label: '温度',
        range: '15°C ~ 30°C',
        status: '正常',
        statusColor: Colors.green,
        valColor: valColor,
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
        valColor: valColor,
      ),
      DataCard(
        icon: Icons.eco_outlined,
        iconColor: Colors.green,
        val: currentSoilMoisture,
        unit: '%',
        label: '土壤湿度',
        range: '25% ~ 70%',
        status: _soilMoistureStatus(currentSoilMoisture),
        statusColor: _soilMoistureStatusColor(currentSoilMoisture),
        valColor: valColor,
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
        valColor: valColor,
      ),
    ];
  }

  List<Widget> _filteredDataCards(String currentTemp, String currentHumidity,
      String currentSoilMoisture, String currentIllumination) {
    final cards = _buildDataCards(
        currentTemp, currentHumidity, currentSoilMoisture, currentIllumination);
    switch (_selectedIndicatorLabel) {
      case '温度指标':
        return [cards[0]];
      case '湿度指标':
        return [cards[1], cards[2]];
      case '光照强度指标':
        return [cards[3]];
      default:
        return cards;
    }
  }

  Widget _buildLandscapeBody(BuildContext context, String currentTemp,
      String currentHumidity, String currentSoilMoisture,
      String currentIllumination) {
    final cards = _filteredDataCards(
        currentTemp, currentHumidity, currentSoilMoisture, currentIllumination);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(context),
          const SizedBox(height: 20),
          Text('实时数据',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          if (cards.length == 1)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: cards.first,
              ),
            )
          else
            Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: cards[i]),
                ],
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
                foregroundColor: Theme.of(context).colorScheme.primary,
                side:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.history),
              label: const Text('查看历史数据',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPortraitBody(BuildContext context, String currentTemp,
      String currentHumidity, String currentSoilMoisture,
      String currentIllumination) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(context),
          const SizedBox(height: 20),
          Text('实时数据',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          _buildSensorGrid(
              currentTemp, currentHumidity, currentSoilMoisture, currentIllumination),
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
                    builder: (context) => const SensorHistoryPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side:
                    BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.history),
              label: const Text('查看历史数据',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSelectChip(
            context,
            value: _selectedFarmLabel,
            options: _farmOptions,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedFarmLabel = value;
                final options = _greenhouseOptionsForFarm(value);
                _greenhouseOptions = options;
                _selectedGreenhouseLabel = options.first.label;
                if (!_useRealData) _regenerateSimulated();
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSelectChip(
            context,
            value: _selectedGreenhouseLabel,
            options: _greenhouseOptions,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedGreenhouseLabel = value;
                if (!_useRealData) _regenerateSimulated();
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSelectChip(
            context,
            value: _selectedIndicatorLabel,
            options: _indicatorOptions,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedIndicatorLabel = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectChip(
    BuildContext context, {
    required String value,
    required List<_SelectOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: cs.onSurfaceVariant,
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          dropdownColor: cs.surface,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.label,
                  child: Text(
                    option.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  double _cardHeight(BuildContext context) {
    // 基准：竖屏两列布局的单卡片高度，单卡片放大时仅加宽、高度保持不变
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width - 32 - 12) / 2;
    return cardWidth / 1.05;
  }

  Widget _buildSensorGrid(String currentTemp, String currentHumidity,
      String currentSoilMoisture, String currentIllumination) {
    final cards = _filteredDataCards(
        currentTemp, currentHumidity, currentSoilMoisture, currentIllumination);
    final columnCount = cards.length == 1
        ? 1
        : cards.length == 2
            ? 2
            : Responsive.gridColumns(context);
    return GridView.count(
      crossAxisCount: columnCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      mainAxisExtent: _cardHeight(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
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

  String _soilMoistureStatus(String soilMoisture) {
    final v = double.tryParse(soilMoisture);
    if (v == null) return '未知';
    if (v < 25) return '过低';
    if (v < 40) return '偏低';
    if (v <= 70) return '正常';
    return '偏高';
  }

  Color _soilMoistureStatusColor(String soilMoisture) {
    switch (_soilMoistureStatus(soilMoisture)) {
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
