import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/app_feedback.dart';
import '../../services/device_manager.dart';
import '../../widgets/common/stat_card.dart';
import '../main_page.dart';
import 'models/alert_data.dart';
import 'widgets/alert_card.dart';
import 'widgets/dismissible_alert.dart';

class AlertCenterPage extends StatefulWidget {
  const AlertCenterPage({super.key});

  @override
  State<AlertCenterPage> createState() => _AlertCenterPageState();
}

class _AlertCenterPageState extends State<AlertCenterPage> {
  int _selectedFilterIndex = 0;
  final Set<String> _dismissedIds = {};
  final List<AlertData> _generatedAlerts = [];
  Timer? _generateTimer;
  final _random = Random();

  static const String _dismissedKey = 'dismissed_alert_ids';

  static final List<AlertData> _baseAlerts = [
    AlertData(
      id: 'alert_1',
      borderColorKey: 'red',
      tagText: '紧急',
      title: '土壤湿度过低',
      time: DateTime(2026, 4, 30, 10, 23),
      content: '1号大棚 土壤湿度当前值18%，低于阈值25%，请及时灌溉',
      primaryActionText: '一键灌溉',
      primaryActionIcon: Icons.water_drop_outlined,
      primaryActionColor: Colors.blueAccent,
    ),
    AlertData(
      id: 'alert_2',
      borderColorKey: 'amber',
      tagText: '警告',
      title: '温度接近阈值',
      time: DateTime(2026, 4, 30, 9, 15),
      content: '3号大棚 当前温度29.2℃，接近阈值30℃，建议开启通风',
      primaryActionText: '开启通风',
      primaryActionIcon: Icons.air,
      primaryActionColor: const Color(0xFF2ECC71),
    ),
    AlertData(
      id: 'alert_3',
      borderColorKey: 'orange',
      tagText: '离线',
      title: '设备离线',
      time: DateTime(2026, 4, 30, 8, 42),
      content: '4号大棚 土壤湿度传感器已离线30分钟，请检查设备连接',
      primaryActionText: '查看设备',
      primaryActionIcon: Icons.settings_outlined,
      primaryActionColor: const Color(0xFF34495E),
    ),
  ];

  static const _templates = [
    {
      'tag': '警告',
      'colorKey': 'amber',
      'title': '土壤湿度过低',
      'body': '{}号大棚 土壤湿度当前值{}%，低于阈值25%，请及时灌溉',
      'action': '一键灌溉',
      'icon': Icons.water_drop_outlined,
      'actionColor': Colors.blueAccent,
    },
    {
      'tag': '警告',
      'colorKey': 'amber',
      'title': '温度偏高',
      'body': '{}号大棚 当前温度{}℃，接近阈值30℃，建议开启通风',
      'action': '开启通风',
      'icon': Icons.air,
      'actionColor': Color(0xFF2ECC71),
    },
    {
      'tag': '紧急',
      'colorKey': 'red',
      'title': '湿度过低',
      'body': '{}号大棚 空气湿度降至{}%，低于阈值45%，请检查加湿设备',
      'action': '查看设备',
      'icon': Icons.settings_outlined,
      'actionColor': Color(0xFF34495E),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDismissed();
    _scheduleNextGenerate();
  }

  @override
  void dispose() {
    _generateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool('alert_migrated_v2') ?? false;
    if (!migrated) {
      final raw = prefs.getString(_dismissedKey);
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          final ids = list.cast<String>().toSet();
          final allBaseDismissed = ids.contains('alert_1') &&
              ids.contains('alert_2') &&
              ids.contains('alert_3');
          if (allBaseDismissed) {
            ids.removeAll({'alert_1', 'alert_2', 'alert_3'});
          }
          _dismissedIds.addAll(ids);
          await prefs.setString(
              _dismissedKey, jsonEncode(_dismissedIds.toList()));
        } catch (_) {}
      }
      await prefs.setBool('alert_migrated_v2', true);
    } else {
      final raw = prefs.getString(_dismissedKey);
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          _dismissedIds.addAll(list.cast<String>());
        } catch (_) {}
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _dismissAlert(String id) async {
    _dismissedIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _dismissedKey, jsonEncode(_dismissedIds.toList()));
    _generatedAlerts.removeWhere((a) => a.id == id);
    if (mounted) setState(() {});
  }

  void _scheduleNextGenerate() {
    final delay = Duration(seconds: 60 + _random.nextInt(120));
    _generateTimer = Timer(delay, () {
      if (!mounted) return;
      _generateRandomAlert();
      _scheduleNextGenerate();
    });
  }

  void _generateRandomAlert() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final template = _templates[_random.nextInt(_templates.length)];
    final greenHouseNum = _random.nextInt(4) + 1;
    final title = template['title'] as String;
    final value = title == '温度偏高'
        ? (28.5 + _random.nextDouble() * 3.0).toStringAsFixed(1)
        : (title == '湿度过低'
            ? (35 + _random.nextInt(10)).toString()
            : (14 + _random.nextInt(8)).toString());

    final minuteOffset = max(0, now.difference(todayStart).inMinutes - 1);
    final randomMinute =
        minuteOffset > 0 ? _random.nextInt(minuteOffset) : 0;
    final alertTime = todayStart.add(Duration(minutes: randomMinute));

    final id = 'gen_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _generatedAlerts.insert(
        0,
        AlertData(
          id: id,
          borderColorKey: template['colorKey'] as String,
          tagText: template['tag'] as String,
          title: title,
          time: alertTime,
          content: (template['body'] as String)
              .replaceFirst('{}', greenHouseNum.toString())
              .replaceFirst('{}', value),
          primaryActionText: template['action'] as String,
          primaryActionIcon: template['icon'] as IconData,
          primaryActionColor: template['actionColor'] as Color,
          isGenerated: true,
        ),
      );
    });
  }

  void _handleIrrigation() {
    DeviceManager.instance.toggleAllIrrigation(true);
    showAppToast('灌溉泵已全部开启');
  }

  void _handleVentilation() {
    DeviceManager.instance.controlDevice('motor_control', 'ON');
    showAppToast('通风设备已开启');
  }

  void _handleViewDevice() {
    MainPage.switchToTab(1);
    Navigator.of(context).pop();
  }

  Color _borderColor(String key) {
    switch (key) {
      case 'red':
        return Colors.redAccent;
      case 'amber':
        return Colors.amber.shade600;
      case 'orange':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _tagColor(String key) {
    switch (key) {
      case 'red':
        return Colors.redAccent;
      case 'amber':
        return Colors.amber.shade700;
      case 'orange':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _tagBgColor(String key) {
    switch (key) {
      case 'red':
        return const Color(0xFFFFF0F0);
      case 'amber':
        return const Color(0xFFFFFDE7);
      case 'orange':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFF5F7FA);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final ts = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    if (time.isAfter(today) || time.isAtSameMomentAs(today)) {
      return ts;
    }
    if (time.isAfter(yesterday) || time.isAtSameMomentAs(yesterday)) {
      return '昨天 $ts';
    }
    return '${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} $ts';
  }

  String _dateGroupLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (time.isAfter(today) || time.isAtSameMomentAs(today)) return '今天';
    if (time.isAfter(yesterday) || time.isAtSameMomentAs(yesterday)) return '昨天';
    return '更早';
  }

  int get _unhandledCount {
    int count = 0;
    for (final a in _baseAlerts) {
      if (!_dismissedIds.contains(a.id)) count++;
    }
    count += _generatedAlerts.length;
    return count;
  }

  int get _handledCount {
    int count = 0;
    for (final a in _baseAlerts) {
      if (_dismissedIds.contains(a.id)) count++;
    }
    for (final id in _dismissedIds) {
      if (id.startsWith('gen_')) count++;
    }
    return count + 2;
  }

  int get _totalCount => _unhandledCount + _handledCount;

  VoidCallback? _getAction(AlertData alert) {
    if (alert.primaryActionText == '一键灌溉') return _handleIrrigation;
    if (alert.primaryActionText == '开启通风') return _handleVentilation;
    if (alert.primaryActionText == '查看设备') return _handleViewDevice;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final activeAlerts = <AlertData>[
      ..._generatedAlerts,
      for (final a in _baseAlerts)
        if (!_dismissedIds.contains(a.id)) a,
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.arrow_back_ios,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(width: 8),
            const Text(
              '告警中心',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              for (final a in _generatedAlerts.toList()) {
                _dismissAlert(a.id);
              }
            },
            child: Text(
              '全部已读',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CompactStatCard(
                  label: '今日告警',
                  value: '$_totalCount',
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 10),
                CompactStatCard(
                  label: '未处理',
                  value: '$_unhandledCount',
                  color: Colors.orangeAccent,
                ),
                const SizedBox(width: 10),
                CompactStatCard(
                  label: '已处理',
                  value: '$_handledCount',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildFilterChip('全部', 0),
                const SizedBox(width: 8),
                _buildFilterChip('未处理', 1),
                const SizedBox(width: 8),
                _buildFilterChip('已处理', 2),
              ],
            ),
            const SizedBox(height: 20),
            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
              Builder(builder: (context) {
                final today = activeAlerts
                    .where((a) => _dateGroupLabel(a.time) == '今天')
                    .toList();
                final yesterday = activeAlerts
                    .where((a) => _dateGroupLabel(a.time) == '昨天')
                    .toList();
                final earlier = activeAlerts
                    .where((a) => _dateGroupLabel(a.time) == '更早')
                    .toList();

                final groups = <MapEntry<String, List<AlertData>>>[
                  if (today.isNotEmpty) MapEntry('今天', today),
                  if (yesterday.isNotEmpty) MapEntry('昨天', yesterday),
                  if (earlier.isNotEmpty) MapEntry('更早', earlier),
                ];

                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        '暂无未处理告警',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in groups) ...[
                      Text(
                        group.key,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...group.value.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DismissibleAlert(
                              alertId: a.id,
                              onDismissed: () => _dismissAlert(a.id),
                              child: ActiveAlertCard(
                                alert: a,
                                borderColor:
                                    _borderColor(a.borderColorKey),
                                tagColor: _tagColor(a.borderColorKey),
                                tagBgColor: _tagBgColor(a.borderColorKey),
                                time: _formatTime(a.time),
                                onPrimaryAction: _getAction(a),
                                onIgnore: () => _dismissAlert(a.id),
                              ),
                            ),
                          )),
                      const SizedBox(height: 24),
                    ],
                  ],
                );
              }),
            ],
            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
              Text(
                '昨天',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              HandledAlertCard(
                tagText: '已处理',
                title: '空气湿度过低',
                time: '昨天 16:38',
                content: '2号大棚 空气湿度一度降至42%，已开启加湿设备',
                handledText: '已开启通风换气，当前CO₂浓度已恢复至820ppm',
              ),
              const SizedBox(height: 12),
              HandledAlertCard(
                tagText: '已处理',
                title: 'CO2浓度偏高',
                time: '昨天 14:22',
                content: '1号大棚 CO₂浓度一度升至880ppm，已开启通风设备',
                handledText: '已开启通风换气，当前CO₂浓度已恢复至820ppm',
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final selected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2B3245)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
