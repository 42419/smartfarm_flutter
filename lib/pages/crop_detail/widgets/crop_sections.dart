import 'package:flutter/material.dart';
import '../../../models/crop.dart';

class DetailHealthInfo {
  final Color bgColor;
  final Color mainColor;
  const DetailHealthInfo(this.bgColor, this.mainColor);
}

DetailHealthInfo getDetailHealthInfo(String? health) {
  final h = (health ?? '').trim();
  if (h.contains('异常') ||
      h.contains('偏高') ||
      h.contains('偏低') ||
      h.contains('危险') ||
      h.contains('差')) {
    return const DetailHealthInfo(Color(0xFFFFF4F4), Colors.redAccent);
  }
  if (h.contains('一般') ||
      h.contains('注意') ||
      h.contains('接近') ||
      h.contains('警告')) {
    return const DetailHealthInfo(Color(0xFFFFFDE7), Colors.orangeAccent);
  }
  return const DetailHealthInfo(Color(0xFFF4FFF6), Colors.green);
}

class CropHeader extends StatelessWidget {
  const CropHeader({super.key, required this.crop, required this.info});

  final Crop crop;
  final DetailHealthInfo info;

  @override
  Widget build(BuildContext context) {
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
                  child:
                      Icon(Icons.eco, size: 48, color: info.mainColor),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(crop.cropName,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: info.mainColor)),
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
                  color: info.mainColor),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

int daysBetween(String from, String to) {
  final a = DateTime.tryParse(from);
  final b = DateTime.tryParse(to);
  if (a == null || b == null) return 0;
  return b.difference(a).inDays.abs();
}

class GrowthSection extends StatelessWidget {
  const GrowthSection({super.key, required this.crop, required this.info});

  final Crop crop;
  final DetailHealthInfo info;

  @override
  Widget build(BuildContext context) {
    final progress = crop.total > 0 ? crop.current / crop.total : 0.0;
    final daysFromPlant = crop.plantDate != null
        ? daysBetween(crop.plantDate!, _todayStr())
        : 0;
    final totalDays = crop.plantDate != null && crop.harvestDate != null
        ? daysBetween(crop.plantDate!, crop.harvestDate!)
        : 0;

    return SectionCard(
      title: '生长进度',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('当前进度',
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: info.mainColor),
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
                  '总周期', totalDays > 0 ? '$totalDays 天' : '--'),
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
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class EnvItem {
  final String label;
  final int score;
  final IconData icon;
  const EnvItem(this.label, this.score, this.icon);
}

class EnvironmentSection extends StatelessWidget {
  const EnvironmentSection(
      {super.key, required this.crop, required this.info});

  final Crop crop;
  final DetailHealthInfo info;

  @override
  Widget build(BuildContext context) {
    final items = [
      EnvItem('土壤养分', crop.environmentAnalysis1 ?? 0, Icons.water_drop),
      EnvItem('温度适宜', crop.environmentAnalysis2 ?? 0, Icons.thermostat),
      EnvItem('光照条件', crop.environmentAnalysis3 ?? 0, Icons.wb_sunny),
      EnvItem('CO₂浓度', crop.environmentAnalysis4 ?? 0, Icons.co2),
      EnvItem('生态健康', crop.environmentAnalysis5 ?? 0, Icons.eco),
    ];

    return SectionCard(
      title: '环境分析',
      child: Column(
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
                  child: Text(item.label,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black87)),
                ),
                Text('${item.score}分',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: info.mainColor)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TaskItem {
  final IconData icon;
  final String label;
  final String time;
  const TaskItem(this.icon, this.label, this.time);
}

class TasksSection extends StatelessWidget {
  const TasksSection({super.key, required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final tasks = <TaskItem>[];
    if (crop.taskTime1 != null && crop.taskTime1!.isNotEmpty) {
      tasks.add(TaskItem(Icons.task_alt, '任务一', crop.taskTime1!));
    }
    if (crop.taskTime2 != null && crop.taskTime2!.isNotEmpty) {
      tasks.add(
          TaskItem(Icons.pending_actions, '任务二', crop.taskTime2!));
    }
    if (tasks.isEmpty) return const SizedBox();

    return SectionCard(
      title: '待办任务',
      child: Row(
        children: tasks.map((t) {
          return Expanded(
            child: Column(
              children: [
                Icon(t.icon, color: Colors.blueAccent, size: 28),
                const SizedBox(height: 6),
                Text(t.label,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(t.time,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class RecItem {
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  const RecItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
  });
}

class RecommendationsSection extends StatelessWidget {
  const RecommendationsSection({super.key, required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final items = <RecItem>[];
    if (crop.desc1 != null && crop.desc1!.isNotEmpty) {
      items.add(RecItem(
        icon: Icons.warning_amber_rounded,
        color: Colors.orangeAccent,
        title: crop.desc1!,
        content: crop.recommendation1 ?? '',
      ));
    }
    if (crop.desc2 != null && crop.desc2!.isNotEmpty) {
      items.add(RecItem(
        icon: Icons.bug_report_outlined,
        color: Colors.redAccent.shade200,
        title: crop.desc2!,
        content: crop.recommendation2 ?? '',
      ));
    }
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('问题与建议',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 12),
        ...items.map((item) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: item.color, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, color: item.color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: item.color)),
                    ),
                  ],
                ),
                if (item.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('建议: ${item.content}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.5)),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
