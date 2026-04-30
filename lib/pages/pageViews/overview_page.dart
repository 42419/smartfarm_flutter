import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_center_page.dart';
import '../../models/crop.dart';
import '../../services/auth_service.dart';
import '../../config/config.dart';
import '../../services/crop_service.dart';
import '../../services/sensor_history_service.dart';
import '../../services/weather_service.dart';
import '../crop_detail_page.dart';

class _HealthInfo {
  final Color bgColor;
  final Color mainColor;

  const _HealthInfo(this.bgColor, this.mainColor);
}

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
    } catch (_) {
      // ignore corrupt cache
    }
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
      final hasUnhandled = _baseAlertIds.any((id) => !dismissed.contains(id));
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
    if (!mounted) {
      return;
    }
    setState(() {
      _crops = crops;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // 淡灰色背景
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
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, color: Colors.black87),
                if (_hasUnhandledAlerts)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
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
            // 顶部的设备状态卡片
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

            // 环境数据
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '环境数据',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatTimeAgo(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCompactEnvItem(
                        Icons.thermostat,
                        Colors.orangeAccent,
                        _avgTemperature != null
                            ? '${_avgTemperature!.toStringAsFixed(1)}°'
                            : '--',
                        '温度',
                      ),
                      _buildCompactEnvItem(
                        Icons.water_drop_outlined,
                        Colors.blueAccent,
                        _avgHumidity != null
                            ? '${_avgHumidity!.toStringAsFixed(0)}%'
                            : '--',
                        '湿度',
                      ),
                      _buildCompactEnvItem(
                        Icons.wb_sunny_outlined,
                        Colors.yellow.shade700,
                        _avgIllumination != null
                            ? '${_avgIllumination!.toStringAsFixed(0)} Lux'
                            : '--',
                        '光照',
                      ),
                      _buildCompactEnvItem(
                        Icons.eco_outlined,
                        Colors.green,
                        _avgSoilMoisture != null
                            ? '${_avgSoilMoisture!.toStringAsFixed(0)}%'
                            : '--',
                        '土壤',
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Colors.black12),
                  _buildWeatherCard(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 农场区域视图
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '农场区域视图',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    _buildLegendItem(const Color(0xFF1565C0), '优秀'),
                    const SizedBox(width: 8),
                    _buildLegendItem(Colors.green, '良好'),
                    const SizedBox(width: 8),
                    _buildLegendItem(Colors.amber, '告警'),
                    const SizedBox(width: 8),
                    _buildLegendItem(Colors.redAccent, '异常'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 大棚卡片列表，设置为固定高度并支持独立滑动
            SizedBox(
              height: 250, // 根据需要调整高度
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
                        final info = _getHealthInfo(crop.health);
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < _crops.length - 1 ? 10 : 0,
                          ),
                          child: GestureDetector(
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
                            child: _buildGreenhouseCard(
                              '${index + 1}号大棚 - ${crop.cropName}',
                              crop.health ?? '状态未知',
                              info.bgColor,
                              info.mainColor,
                              _relevantIcons(crop),
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

  _HealthInfo _getHealthInfo(String? health) {
    final h = (health ?? '').trim();
    if (h.contains('优秀')) {
      return _HealthInfo(const Color(0xFFE8F5FF), const Color(0xFF1565C0));
    }
    if (h.contains('异常') ||
        h.contains('偏高') ||
        h.contains('偏低') ||
        h.contains('危险') ||
        h.contains('差')) {
      return _HealthInfo(const Color(0xFFFFF4F4), Colors.redAccent);
    }
    if (h.contains('一般') ||
        h.contains('注意') ||
        h.contains('接近') ||
        h.contains('警告')) {
      return _HealthInfo(const Color(0xFFFFFDE7), Colors.orangeAccent);
    }
    return _HealthInfo(const Color(0xFFF4FFF6), Colors.green);
  }

  List<IconData> _relevantIcons(Crop crop) {
    final icons = <IconData>[];
    final env1 = crop.environmentAnalysis1 ?? 0;
    final env2 = crop.environmentAnalysis2 ?? 0;
    final env3 = crop.environmentAnalysis3 ?? 0;
    final env4 = crop.environmentAnalysis4 ?? 0;
    final env5 = crop.environmentAnalysis5 ?? 0;

    if (env1 < 80) {
      icons.add(Icons.water_drop);
    }
    if (env2 < 80) {
      icons.add(Icons.thermostat);
    }
    if (env3 < 80) {
      icons.add(Icons.wb_sunny);
    }
    if (env4 < 80) {
      icons.add(Icons.co2);
    }
    if (env5 < 80) {
      icons.add(Icons.eco);
    }
    if (icons.isEmpty) {
      icons.add(Icons.check_circle);
    }
    return icons;
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
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
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
          Text(subText, style: TextStyle(color: subTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCompactEnvItem(
    IconData icon,
    Color iconColor,
    String value,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWeatherCard() {
    final w = WeatherService.instance;
    return GestureDetector(
      onTap: () async {
        setState(() => _weatherRefreshing = true);
        await WeatherService.instance.fetch();
        if (mounted) {
          setState(() {
            _weatherRefreshing = false;
            _envUpdateTime = DateTime.now();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _weatherRefreshing ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  w.city,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _weatherRefreshing
                      ? SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: w.accentColor,
                          ),
                        )
                      : Icon(
                          w.weatherIcon(),
                          key: ValueKey(w.weatherText),
                          size: 44,
                          color: w.accentColor,
                        ),
                ),
                const SizedBox(width: 10),
                Text(
                  w.weatherTemp,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  w.weatherText,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.air, size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          w.weatherWind,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          w.weatherHumidity,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGreenhouseCard(
    String title,
    String subtitle,
    Color bgColor,
    Color mainColor,
    List<IconData> icons, {
    Crop? crop,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: mainColor.withValues(alpha: 0.8),
                  ),
                ),
                if (crop != null) ...[
                  const SizedBox(height: 6),
                  _buildCropInfoRow(crop),
                ],
              ],
            ),
          ),
          Row(
            children: icons.map((icon) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: mainColor, size: 16),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCropInfoRow(Crop crop) {
    if (crop.summary != null && crop.summary!.isNotEmpty) {
      return Text(
        crop.summary!,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final items = <String>[];
    if (crop.plantDate != null && crop.plantDate!.isNotEmpty) {
      items.add('种植:${crop.plantDate}');
    }
    if (crop.harvestDate != null && crop.harvestDate!.isNotEmpty) {
      items.add('收获:${crop.harvestDate}');
    }
    if (crop.yieldText != null && crop.yieldText!.isNotEmpty) {
      items.add('产量:${crop.yieldText}');
    }
    if (crop.total > 0) {
      items.add(
        '生长:${((crop.current / crop.total) * 100).toStringAsFixed(0)}%',
      );
    }
    if (items.isEmpty) {
      return const SizedBox();
    }
    return Text(
      items.join('  '),
      style: const TextStyle(fontSize: 11, color: Colors.black54),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
