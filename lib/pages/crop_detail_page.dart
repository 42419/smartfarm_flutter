import 'package:flutter/material.dart';

import '../models/crop.dart';

class CropDetailPage extends StatelessWidget {
  const CropDetailPage({super.key, required this.crop, required this.greenhouseIndex});

  final Crop crop;
  final int greenhouseIndex;

  @override
  Widget build(BuildContext context) {
    final info = _getHealthInfo(crop.health);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${greenhouseIndex + 1}号大棚 - ${crop.cropName}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, info),
            const SizedBox(height: 16),
            _buildBasicInfo(),
            const SizedBox(height: 16),
            _buildGrowthInfo(info),
            const SizedBox(height: 16),
            _buildEnvironmentAnalysis(info),
            const SizedBox(height: 16),
            _buildTasks(),
            const SizedBox(height: 16),
            _buildRecommendations(info),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _DetailHealthInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (crop.cropImg != null && crop.cropImg!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                crop.cropImg!,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  width: 120,
                  color: info.mainColor.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.eco,
                    size: 48,
                    color: info.mainColor,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            crop.cropName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: info.mainColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: info.mainColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              crop.health ?? '状态未知',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: info.mainColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return _sectionCard(
      '基本信息',
      Column(
        children: [
          _buildInfoRow('种植日期', _formatDate(crop.plantDate)),
          _buildDivider(),
          _buildInfoRow('预计收获', _formatDate(crop.harvestDate)),
          _buildDivider(),
          _buildInfoRow('种植面积', '${crop.area.toStringAsFixed(1)} 亩'),
          _buildDivider(),
          _buildInfoRow('植株高度', crop.height ?? '--'),
          _buildDivider(),
          _buildInfoRow('叶片光强', crop.leafCount ?? '--'),
        ],
      ),
    );
  }

  Widget _buildGrowthInfo(_DetailHealthInfo info) {
    final progress = crop.total > 0 ? crop.current / crop.total : 0.0;
    final daysFromPlant = crop.plantDate != null
        ? _daysBetween(crop.plantDate!, _todayStr())
        : 0;
    final totalDays = crop.plantDate != null && crop.harvestDate != null
        ? _daysBetween(crop.plantDate!, crop.harvestDate!)
        : 0;

    return _sectionCard(
      '生长进度',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('当前进度', style: TextStyle(fontSize: 14, color: Colors.black87)),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: info.mainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(info.mainColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressLabel('已种植', '$daysFromPlant 天'),
              _buildProgressLabel(
                '总周期',
                totalDays > 0 ? '$totalDays 天' : '--',
              ),
              _buildProgressLabel('预计产量', crop.yieldText ?? '--'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLabel(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildEnvironmentAnalysis(_DetailHealthInfo info) {
    final items = [
      _EnvItem('土壤养分', crop.environmentAnalysis1 ?? 0, Icons.water_drop),
      _EnvItem('温度适宜', crop.environmentAnalysis2 ?? 0, Icons.thermostat),
      _EnvItem('光照条件', crop.environmentAnalysis3 ?? 0, Icons.wb_sunny),
      _EnvItem('CO₂浓度', crop.environmentAnalysis4 ?? 0, Icons.co2),
      _EnvItem('生态健康', crop.environmentAnalysis5 ?? 0, Icons.eco),
    ];

    return _sectionCard(
      '环境分析',
      Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final color = item.score >= 85
              ? Colors.green
              : item.score >= 75
                  ? Colors.orangeAccent
                  : Colors.redAccent;
          return Padding(
            padding: EdgeInsets.only(top: i > 0 ? 12 : 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                Text(
                  '${item.score}分',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: info.mainColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTasks() {
    final tasks = <_TaskItem>[];
    if (crop.taskTime1 != null && crop.taskTime1!.isNotEmpty) {
      tasks.add(_TaskItem(Icons.task_alt, '任务一', crop.taskTime1!));
    }
    if (crop.taskTime2 != null && crop.taskTime2!.isNotEmpty) {
      tasks.add(_TaskItem(Icons.pending_actions, '任务二', crop.taskTime2!));
    }
    if (tasks.isEmpty) {
      return const SizedBox();
    }

    return _sectionCard(
      '待办任务',
      Row(
        children: tasks.map((t) {
          return Expanded(
            child: Column(
              children: [
                Icon(t.icon, color: Colors.blueAccent, size: 28),
                const SizedBox(height: 6),
                Text(t.label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  t.time,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendations(_DetailHealthInfo info) {
    final items = <_RecItem>[];
    if (crop.desc1 != null && crop.desc1!.isNotEmpty) {
      items.add(_RecItem(
        icon: Icons.warning_amber_rounded,
        color: Colors.orangeAccent,
        title: crop.desc1!,
        content: crop.recommendation1 ?? '',
      ));
    }
    if (crop.desc2 != null && crop.desc2!.isNotEmpty) {
      items.add(_RecItem(
        icon: Icons.bug_report_outlined,
        color: Colors.redAccent.shade200,
        title: crop.desc2!,
        content: crop.recommendation2 ?? '',
      ));
    }
    if (items.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '问题与建议',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: item.color, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, color: item.color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '建议: ${item.content}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return '--';
    }
    return dateStr;
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int _daysBetween(String from, String to) {
    final a = DateTime.tryParse(from);
    final b = DateTime.tryParse(to);
    if (a == null || b == null) {
      return 0;
    }
    return b.difference(a).inDays.abs();
  }

  _DetailHealthInfo _getHealthInfo(String? health) {
    final h = (health ?? '').trim();
    if (h.contains('异常') || h.contains('偏高') || h.contains('偏低') || h.contains('危险') || h.contains('差')) {
      return _DetailHealthInfo(const Color(0xFFFFF4F4), Colors.redAccent);
    }
    if (h.contains('一般') || h.contains('注意') || h.contains('接近') || h.contains('警告')) {
      return _DetailHealthInfo(const Color(0xFFFFFDE7), Colors.orangeAccent);
    }
    return _DetailHealthInfo(const Color(0xFFF4FFF6), Colors.green);
  }
}

class _DetailHealthInfo {
  final Color bgColor;
  final Color mainColor;
  const _DetailHealthInfo(this.bgColor, this.mainColor);
}

class _EnvItem {
  final String label;
  final int score;
  final IconData icon;
  const _EnvItem(this.label, this.score, this.icon);
}

class _TaskItem {
  final IconData icon;
  final String label;
  final String time;
  const _TaskItem(this.icon, this.label, this.time);
}

class _RecItem {
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  const _RecItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
  });
}
