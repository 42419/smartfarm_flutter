import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _hasUnhandledAlerts = false;
  bool _weatherRefreshing = false;

  static const _cacheKey = 'env_avg_cache';
  static const _dismissedAlertKey = 'dismissed_alert_ids';
  static const _baseAlertIds = ['alert_1', 'alert_2', 'alert_3'];

  @override
  void initState() {
    super.initState();
    _loadCrops();
    _loadCachedEnvData();
    _loadEnvAverages();
    _loadAlertBadge();
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

  Future<void> _loadAlertBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dismissedAlertKey);
    if (raw == null) {
      if (mounted) setState(() => _hasUnhandledAlerts = true);
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final dismissed = list.cast<String>().toSet();
      final hasUnhandled =
          _baseAlertIds.any((id) => !dismissed.contains(id));
      if (mounted) setState(() => _hasUnhandledAlerts = hasUnhandled);
    } catch (_) {
      if (mounted) setState(() => _hasUnhandledAlerts = true);
    }
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AuthService.instance.currentUser?.farm.isNotEmpty == true
                  ? AuthService.instance.currentUser!.farm
                  : '东郊农场',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none,
                    color: Colors.black87),
                if (_hasUnhandledAlerts)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AlertCenterPage(),
                ),
              );
              _loadAlertBadge();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    '在线设备',
                    '42',
                    '全部在线',
                    Icons.developer_board,
                    Colors.blue,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    '告警设备',
                    '3',
                    '需紧急处理',
                    Icons.warning_amber_rounded,
                    Colors.redAccent,
                    Colors.redAccent,
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
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_formatTimeAgo(),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  const Divider(height: 20, color: Colors.black12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('农场区域视图',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const LegendItem(
                        color: Color(0xFF1565C0), label: '优秀'),
                    const SizedBox(width: 8),
                    const LegendItem(color: Colors.green, label: '良好'),
                    const SizedBox(width: 8),
                    const LegendItem(color: Colors.amber, label: '告警'),
                    const SizedBox(width: 8),
                    const LegendItem(
                        color: Colors.redAccent, label: '异常'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _crops.isEmpty
                      ? const Center(child: Text('暂无大棚数据'))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: _crops.length,
                          itemBuilder: (context, index) {
                            final crop = _crops[index];
                            final info = getHealthInfo(crop.health);
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < _crops.length - 1 ? 10 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CropDetailPage(
                                            crop: crop,
                                            greenhouseIndex: index,
                                          ),
                                    ),
                                  );
                                },
                                child: GreenhouseCard(
                                  title:
                                      '${index + 1}号大棚 - ${crop.cropName}',
                                  subtitle: crop.health ?? '状态未知',
                                  bgColor: info.bgColor,
                                  mainColor: info.mainColor,
                                  icons: relevantIcons(crop),
                                  crop: crop,
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13)),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isAlert ? Colors.redAccent : Colors.black87,
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
