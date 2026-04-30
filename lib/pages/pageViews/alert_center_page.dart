import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/app_feedback.dart';
import '../../services/device_manager.dart';
import '../main_page.dart';

class _AlertData {
  final String id;
  final String borderColorKey;
  final String tagText;
  final String title;
  final DateTime time;
  final String content;
  final String primaryActionText;
  final IconData primaryActionIcon;
  final Color primaryActionColor;
  final bool isGenerated;

  _AlertData({
    required this.id,
    required this.borderColorKey,
    required this.tagText,
    required this.title,
    required this.time,
    required this.content,
    required this.primaryActionText,
    required this.primaryActionIcon,
    required this.primaryActionColor,
    this.isGenerated = false,
  });
}

class AlertCenterPage extends StatefulWidget {
  const AlertCenterPage({super.key});

  @override
  State<AlertCenterPage> createState() => _AlertCenterPageState();
}

class _AlertCenterPageState extends State<AlertCenterPage> {
  int _selectedFilterIndex = 0;
  final Set<String> _dismissedIds = {};
  final List<_AlertData> _generatedAlerts = [];
  Timer? _generateTimer;
  final _random = Random();

  static const String _dismissedKey = 'dismissed_alert_ids';

  static final List<_AlertData> _baseAlerts = [
    _AlertData(
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
    _AlertData(
      id: 'alert_2',
      borderColorKey: 'amber',
      tagText: '警告',
      title: '温度接近阈值',
      time: DateTime(2026, 4, 30, 9, 15),
      content: '3号大棚 当前温度29.2℃，接近阈值30℃，建议开启通风',
      primaryActionText: '开启通风',
      primaryActionIcon: Icons.air,
      primaryActionColor: Color(0xFF2ECC71),
    ),
    _AlertData(
      id: 'alert_3',
      borderColorKey: 'orange',
      tagText: '离线',
      title: '设备离线',
      time: DateTime(2026, 4, 30, 8, 42),
      content: '4号大棚 土壤湿度传感器已离线30分钟，请检查设备连接',
      primaryActionText: '查看设备',
      primaryActionIcon: Icons.settings_outlined,
      primaryActionColor: Color(0xFF34495E),
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
          final allBaseDismissed =
              ids.contains('alert_1') && ids.contains('alert_2') && ids.contains('alert_3');
          if (allBaseDismissed) {
            ids.removeAll({'alert_1', 'alert_2', 'alert_3'});
          }
          _dismissedIds.addAll(ids);
          await prefs.setString(_dismissedKey, jsonEncode(_dismissedIds.toList()));
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
    await prefs.setString(_dismissedKey, jsonEncode(_dismissedIds.toList()));
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
    final value = template['title'] == '温度偏高'
        ? (28.5 + _random.nextDouble() * 3.0).toStringAsFixed(1)
        : (template['title'] == '湿度过低'
            ? (35 + _random.nextInt(10)).toString()
            : (14 + _random.nextInt(8)).toString());

    final minuteOffset = max(0, now.difference(todayStart).inMinutes - 1);
    final randomMinute = minuteOffset > 0 ? _random.nextInt(minuteOffset) : 0;
    final alertTime = todayStart.add(Duration(minutes: randomMinute));

    final id = 'gen_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _generatedAlerts.insert(
        0,
        _AlertData(
          id: id,
          borderColorKey: template['colorKey'] as String,
          tagText: template['tag'] as String,
          title: template['title'] as String,
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
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    final activeAlerts = <_AlertData>[
      ..._generatedAlerts,
      for (final a in _baseAlerts)
        if (!_dismissedIds.contains(a.id)) a,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            ),
            const SizedBox(width: 8),
            const Text(
              '告警中心',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              for (final a in _generatedAlerts.toList()) {
                _dismissAlert(a.id);
              }
            },
            child: const Text(
              '全部已读',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatCard('今日告警', '$_totalCount', Colors.redAccent),
                const SizedBox(width: 10),
                _buildStatCard(
                  '未处理',
                  '$_unhandledCount',
                  Colors.orangeAccent,
                ),
                const SizedBox(width: 10),
                _buildStatCard('已处理', '$_handledCount', Colors.green),
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
              const Text(
                '今天',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...activeAlerts.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DismissibleAlert(
                      alertId: a.id,
                      onDismissed: () => _dismissAlert(a.id),
                      child: _buildActiveAlertCard(
                        borderColor: _borderColor(a.borderColorKey),
                        tagText: a.tagText,
                        tagColor: _tagColor(a.borderColorKey),
                        tagBgColor: _tagBgColor(a.borderColorKey),
                        title: a.title,
                        time: _formatTime(a.time),
                        content: a.content,
                        primaryActionText: a.primaryActionText,
                        primaryActionIcon: a.primaryActionIcon,
                        primaryActionColor: a.primaryActionColor,
                        onPrimaryAction: a.primaryActionText == '一键灌溉'
                            ? _handleIrrigation
                            : a.primaryActionText == '开启通风'
                                ? _handleVentilation
                                : _handleViewDevice,
                        onIgnore: () => _dismissAlert(a.id),
                      ),
                    ),
                  )),
              if (activeAlerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '暂无未处理告警',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
            if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
              const Text(
                '昨天',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildHandledAlertCard(
                tagText: '已处理',
                title: '空气湿度过低',
                time: '昨天 16:38',
                content: '2号大棚 空气湿度一度降至42%，已开启加湿设备',
                handledText: '已开启通风换气，当前CO₂浓度已恢复至820ppm',
              ),
              const SizedBox(height: 12),
              _buildHandledAlertCard(
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

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2B3245) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveAlertCard({
    required Color borderColor,
    required String tagText,
    required Color tagColor,
    required Color tagBgColor,
    required String title,
    required String time,
    required String content,
    required String primaryActionText,
    required IconData primaryActionIcon,
    required Color primaryActionColor,
    VoidCallback? onPrimaryAction,
    VoidCallback? onIgnore,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tagText,
                      style: TextStyle(
                        fontSize: 10,
                        color: tagColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onPrimaryAction,
                  icon: Icon(primaryActionIcon, size: 16, color: Colors.white),
                  label: Text(
                    primaryActionText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: onIgnore,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F7FA),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '忽略',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHandledAlertCard({
    required String tagText,
    required String title,
    required String time,
    required String content,
    required String handledText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tagText,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  handledText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DismissibleAlert extends StatelessWidget {
  final String alertId;
  final VoidCallback onDismissed;
  final Widget child;

  const _DismissibleAlert({
    required this.alertId,
    required this.onDismissed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alertId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return true;
      },
      dismissThresholds: const {DismissDirection.endToStart: 0.3},
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            SizedBox(width: 4),
            Text(
              '忽略',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: child,
    );
  }
}
