import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/responsive.dart';
import '../../models/crop.dart';
import '../../services/auth_service.dart';
import '../../config/config.dart';
import '../../services/crop_service.dart';
import '../../services/sensor_history_service.dart';
import '../../services/weather_service.dart';
import '../alerts/alert_center_page.dart';
import '../crop_detail/crop_detail_page.dart';
import 'widgets/env_data_section.dart';
import 'widgets/greenhouse_card.dart';
import 'widgets/weather_card.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  List<Crop> _crops = const [];
  bool _loading = true;

  double? _avgTemperature;
  double? _avgHumidity;
  double? _avgIllumination;
  double? _avgSoilMoisture;
  DateTime? _envUpdateTime;
  Timer? _refreshTimer;
  bool _weatherRefreshing = false;

  static const _cacheKey = 'env_avg_cache';

  @override
  void initState() {
    super.initState();
    _loadCrops();
    _loadCachedEnvData();
    _loadEnvAverages();
    WeatherService.instance.loadCached().then((_) {
      if (mounted) setState(() {});
    });
    WeatherService.instance.fetch().then((_) {
      if (mounted) setState(() => _envUpdateTime = DateTime.now());
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadEnvAverages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedEnvData() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null || !mounted) return;

    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      setState(() {
        _avgTemperature = (json['temp'] as num?)?.toDouble();
        _avgHumidity = (json['hum'] as num?)?.toDouble();
        _avgIllumination = (json['illu'] as num?)?.toDouble();
        _avgSoilMoisture = (json['soil'] as num?)?.toDouble();
        _envUpdateTime = json['time'] != null
            ? DateTime.tryParse(json['time'])
            : null;
      });
    } catch (_) {}
  }

  Future<void> _saveEnvCache() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'temp': _avgTemperature,
      'hum': _avgHumidity,
      'illu': _avgIllumination,
      'soil': _avgSoilMoisture,
      'time': _envUpdateTime?.toIso8601String(),
    });
    await prefs.setString(_cacheKey, json);
  }

  Future<void> _loadEnvAverages() async {
    final greenhouse = Config.supabaseGreenhouse;

    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));
    final records = await SensorHistoryService.instance.fetchRecords(
      greenhouse: greenhouse,
      startDate: start,
      endDate: now,
      limit: 10000,
      forceRefresh: true,
    );

    if (records.isEmpty) return;

    final tempVals = <double>[];
    final humVals = <double>[];
    final illuVals = <double>[];
    final soilVals = <double>[];

    for (final r in records) {
      if (r.temperature != null) tempVals.add(r.temperature!);
      if (r.humidity != null) humVals.add(r.humidity!);
      if (r.illumination != null) illuVals.add(r.illumination!);
      soilVals.add(r.effectiveSoilMoisture);
    }

    if (!mounted) return;

    setState(() {
      _avgTemperature = tempVals.isNotEmpty
          ? tempVals.reduce((a, b) => a + b) / tempVals.length
          : _avgTemperature;
      _avgHumidity = humVals.isNotEmpty
          ? humVals.reduce((a, b) => a + b) / humVals.length
          : _avgHumidity;
      _avgIllumination = illuVals.isNotEmpty
          ? illuVals.reduce((a, b) => a + b) / illuVals.length
          : _avgIllumination;
      _avgSoilMoisture = soilVals.isNotEmpty
          ? soilVals.reduce((a, b) => a + b) / soilVals.length
          : _avgSoilMoisture;
      _envUpdateTime = DateTime.now();
    });

    _saveEnvCache();
  }

  String _formatTimeAgo() {
    if (_envUpdateTime == null) return '';
    final diff = DateTime.now().difference(_envUpdateTime!);
    if (diff.inSeconds < 60) return '更新于 几秒前';
    if (diff.inMinutes < 60) return '更新于 ${diff.inMinutes}分钟前';
    return '更新于 ${diff.inHours}小时前';
  }

  Future<void> _loadCrops() async {
    final crops = await CropService.instance.fetchCrops();
    if (!mounted) return;
    setState(() {
      _crops = crops;
      _loading = false;
    });
  }

  Future<void> _refreshWeather() async {
    setState(() => _weatherRefreshing = true);
    await WeatherService.instance.fetch();
    if (mounted) {
      setState(() {
        _weatherRefreshing = false;
        _envUpdateTime = DateTime.now();
      });
    }
  }

  String get _temperatureText => _avgTemperature != null
      ? '${_avgTemperature!.toStringAsFixed(1)}°'
      : '--';

  String get _humidityText =>
      _avgHumidity != null ? '${_avgHumidity!.toStringAsFixed(0)}%' : '--';

  String get _illuminationText => _avgIllumination != null
      ? '${_avgIllumination!.toStringAsFixed(0)} Lux'
      : '--';

  String get _soilMoistureText => _avgSoilMoisture != null
      ? '${_avgSoilMoisture!.toStringAsFixed(0)}%'
      : '--';

  @override
  Widget build(BuildContext context) {
    final w = WeatherService.instance;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AuthService.instance.currentUser?.farm.isNotEmpty == true
                  ? AuthService.instance.currentUser!.farm
                  : '东郊农场',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AlertCenterPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Builder(
        builder: (context) {
          final isDesktop = Responsive.isDesktop(context);
          final isLarge = Responsive.isLargeScreen(context);

          return SingleChildScrollView(
            padding: isDesktop
                ? const EdgeInsets.all(24.0)
                : const EdgeInsets.all(16.0),
            child: isDesktop
                ? _buildDesktopContent(context, w)
                : isLarge
                    ? _buildLandscapeContent(context, w)
                    : _buildPortraitContent(context, w),
          );
        },
      ),
    );
  }

  Widget _buildLandscapeContent(BuildContext context, WeatherService w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                '在线设备', '42', '全部在线',
                Icons.developer_board, Colors.blue, Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatusCard(
                '告警设备', '3', '需紧急处理',
                Icons.warning_amber_rounded, Colors.redAccent, Colors.redAccent,
                isAlert: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text('环境数据',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Text(_formatTimeAgo(),
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: EnvDataSection(
                  temperature: _temperatureText,
                  humidity: _humidityText,
                  illumination: _illuminationText,
                  soilMoisture: _soilMoistureText,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: WeatherCard(
                  city: w.city,
                  weatherText: w.weatherText,
                  weatherIcon: w.weatherIcon(),
                  weatherTemp: w.weatherTemp,
                  weatherWind: w.weatherWind,
                  weatherHumidity: w.weatherHumidity,
                  accentColor: w.accentColor,
                  isRefreshing: _weatherRefreshing,
                  onRefresh: _refreshWeather,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildFarmSection(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDesktopContent(BuildContext context, WeatherService w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDesktopStatsRow(context),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text('环境数据',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Text(_formatTimeAgo(),
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: EnvDataSection(
                  temperature: _temperatureText,
                  humidity: _humidityText,
                  illumination: _illuminationText,
                  soilMoisture: _soilMoistureText,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: WeatherCard(
                  city: w.city,
                  weatherText: w.weatherText,
                  weatherIcon: w.weatherIcon(),
                  weatherTemp: w.weatherTemp,
                  weatherWind: w.weatherWind,
                  weatherHumidity: w.weatherHumidity,
                  accentColor: w.accentColor,
                  isRefreshing: _weatherRefreshing,
                  onRefresh: _refreshWeather,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildFarmSection(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDesktopStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            '在线设备', '42', '全部在线',
            Icons.developer_board, Colors.blue, Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            '告警设备', '3', '需紧急处理',
            Icons.warning_amber_rounded, Colors.redAccent, Colors.redAccent,
            isAlert: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            '大棚总数', '${_crops.length}', '${_crops.where((c) => c.health != null && (c.health!.contains('优秀') || c.health!.contains('良好'))).length}个健康',
            Icons.agriculture, const Color(0xFF1565C0), Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            '环境状态', '正常', _avgTemperature != null ? '均温${_avgTemperature!.toStringAsFixed(1)}°' : '--',
            Icons.eco, Colors.green, Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitContent(BuildContext context, WeatherService w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                '在线设备', '42', '全部在线',
                Icons.developer_board, Colors.blue, Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                '告警设备', '3', '需紧急处理',
                Icons.warning_amber_rounded, Colors.redAccent, Colors.redAccent,
                isAlert: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('环境数据',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_formatTimeAgo(),
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              EnvDataSection(
                temperature: _temperatureText,
                humidity: _humidityText,
                illumination: _illuminationText,
                soilMoisture: _soilMoistureText,
              ),
              Divider(
                  height: 20,
                  color: Theme.of(context).colorScheme.outlineVariant),
              WeatherCard(
                city: w.city,
                weatherText: w.weatherText,
                weatherIcon: w.weatherIcon(),
                weatherTemp: w.weatherTemp,
                weatherWind: w.weatherWind,
                weatherHumidity: w.weatherHumidity,
                accentColor: w.accentColor,
                isRefreshing: _weatherRefreshing,
                onRefresh: _refreshWeather,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildFarmSection(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFarmSection(BuildContext context) {
    final isLarge = Responsive.isLargeScreen(context);
    final isDesktop = Responsive.isDesktop(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('农场区域视图',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const LegendItem(color: Color(0xFF1565C0), label: '优秀'),
                const SizedBox(width: 8),
                const LegendItem(color: Colors.green, label: '良好'),
                const SizedBox(width: 8),
                const LegendItem(color: Colors.amber, label: '告警'),
                const SizedBox(width: 8),
                const LegendItem(color: Colors.redAccent, label: '异常'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : _crops.isEmpty
                ? const Center(child: Text('暂无大棚数据'))
                : isDesktop
                    ? _buildCropGrid(context)
                    : SizedBox(
                        height: isLarge ? 400 : 250,
                        child: _buildCropList(context),
                      ),
      ],
    );
  }

  Widget _buildCropList(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _crops.length,
      itemBuilder: (context, index) {
        final crop = _crops[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _crops.length - 1 ? 10 : 0,
          ),
          child: _buildCropItem(context, crop, index),
        );
      },
    );
  }

  Widget _buildCropGrid(BuildContext context) {
    final crossAxisCount = _crops.length <= 2 ? _crops.length : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: _crops.first.cropImg != null ? 3.0 : 4.5,
      ),
      itemCount: _crops.length,
      itemBuilder: (context, index) {
        final crop = _crops[index];
        return _buildCropItem(context, crop, index);
      },
    );
  }

  Widget _buildCropItem(BuildContext context, Crop crop, int index) {
    final info = getHealthInfo(context, crop.health);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CropDetailPage(
              crop: crop,
              greenhouseIndex: index,
            ),
          ),
        );
      },
      child: GreenhouseCard(
        title: '${index + 1}号大棚 - ${crop.cropName}',
        subtitle: crop.health ?? '状态未知',
        bgColor: info.bgColor,
        mainColor: info.mainColor,
        icons: relevantIcons(crop),
        crop: crop,
      ),
    );
  }

  Widget _buildStatusCard(
    String title,
    String value,
    String subText,
    IconData icon,
    Color iconColor,
    Color subTextColor, {
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13)),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isAlert ? Colors.redAccent : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(subText,
              style: TextStyle(color: subTextColor, fontSize: 12)),
        ],
      ),
    );
  }
}
