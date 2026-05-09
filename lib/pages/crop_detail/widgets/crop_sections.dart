import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/crop.dart';
import '../../../widgets/common/section_card.dart';

class DetailHealthInfo {
  final Color mainColor;
  const DetailHealthInfo(this.mainColor);
}

DetailHealthInfo getDetailHealthInfo(BuildContext context, String? health) {
  final h = (health ?? '').trim();
  if (h.contains('异常') || h.contains('偏高') || h.contains('偏低') ||
      h.contains('危险') || h.contains('差')) {
    return const DetailHealthInfo(Colors.redAccent);
  }
  if (h.contains('一般') || h.contains('注意') || h.contains('接近') ||
      h.contains('警告')) {
    return const DetailHealthInfo(Colors.orangeAccent);
  }
  return const DetailHealthInfo(Colors.green);
}

class CropHeader extends StatelessWidget {
  const CropHeader({super.key, required this.crop, required this.info});

  final Crop crop;
  final DetailHealthInfo info;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImage = crop.cropImg != null && crop.cropImg!.isNotEmpty;

    return SectionCard(
      title: '',
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // --- image / icon ---
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: crop.cropImg!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  height: 160,
                  color: info.mainColor.withValues(alpha: 0.05),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => _buildIconCircle(context),
              ),
            )
          else
            _buildIconCircle(context),
          const SizedBox(height: 16),
          // --- title ---
          Text(crop.cropName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // --- info chips ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // health chip
              if (crop.health != null && crop.health!.isNotEmpty)
                InputChip(
                  selected: true,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  avatar: Icon(Icons.favorite,
                      size: 16, color: info.mainColor),
                  label: Text(crop.health!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: info.mainColor)),
                  backgroundColor:
                      info.mainColor.withValues(alpha: 0.08),
                  side: BorderSide(color: info.mainColor.withValues(alpha: 0.3)),
                  shape: const StadiumBorder(),
                ),
              const SizedBox(width: 10),
              // area chip
              InputChip(
                selected: true,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                avatar: Icon(Icons.crop_square,
                    size: 16, color: cs.onSurfaceVariant),
                label: Text('${crop.area.toStringAsFixed(1)} 亩',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface)),
                backgroundColor: cs.surfaceContainerHigh,
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                shape: const StadiumBorder(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircle(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            info.mainColor.withValues(alpha: 0.12),
            info.mainColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.eco, size: 44, color: info.mainColor),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
          Text(value,
              style: TextStyle(fontSize: 14, color: cs.onSurface)),
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
    final cs = Theme.of(context).colorScheme;
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
        children: [
          // --- circular gauge ---
          Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(info.mainColor),
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: info.mainColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // --- stat row ---
          Row(
            children: [
              Expanded(
                child: _StatCell(
                    icon: Icons.calendar_today,
                    color: info.mainColor,
                    value: '$daysFromPlant',
                    label: '已种植(天)'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCell(
                    icon: Icons.timeline,
                    color: info.mainColor,
                    value: totalDays > 0 ? '$totalDays' : '--',
                    label: '总周期(天)'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCell(
                    icon: Icons.grass,
                    color: info.mainColor,
                    value: crop.yieldText ?? '--',
                    label: '预计产量'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
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
  const EnvironmentSection({super.key, required this.crop, required this.info});

  final Crop crop;
  final DetailHealthInfo info;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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

          return Column(
            children: [
              if (i > 0)
                Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.4)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.label,
                          style: TextStyle(
                              fontSize: 14, color: cs.onSurface)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.score} 分',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final cs = Theme.of(context).colorScheme;
    final tasks = <TaskItem>[];
    if (crop.taskTime1 != null && crop.taskTime1!.isNotEmpty) {
      tasks.add(TaskItem(Icons.task_alt, '任务一', crop.taskTime1!));
    }
    if (crop.taskTime2 != null && crop.taskTime2!.isNotEmpty) {
      tasks.add(TaskItem(Icons.pending_actions, '任务二', crop.taskTime2!));
    }
    if (tasks.isEmpty) return const SizedBox();

    return SectionCard(
      title: '待办任务',
      child: Row(
        children: tasks.map((t) {
          return Expanded(
            child: Container(
              margin:
                  EdgeInsets.only(right: t == tasks.last ? 0 : 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(t.icon,
                        color: Colors.blueAccent, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(t.label,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(t.time,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent)),
                ],
              ),
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
  final IconData badgeIcon;
  final String badgeLabel;
  const RecItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.content,
    required this.badgeIcon,
    required this.badgeLabel,
  });
}

class RecommendationsSection extends StatelessWidget {
  const RecommendationsSection({super.key, required this.crop});

  final Crop crop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <RecItem>[];
    if (crop.desc1 != null && crop.desc1!.isNotEmpty) {
      items.add(RecItem(
        icon: Icons.warning_amber_rounded,
        color: Colors.orangeAccent,
        title: crop.desc1!,
        content: crop.recommendation1 ?? '',
        badgeIcon: Icons.priority_high,
        badgeLabel: '需关注',
      ));
    }
    if (crop.desc2 != null && crop.desc2!.isNotEmpty) {
      items.add(RecItem(
        icon: Icons.bug_report_outlined,
        color: Colors.redAccent.shade200,
        title: crop.desc2!,
        content: crop.recommendation2 ?? '',
        badgeIcon: Icons.bug_report,
        badgeLabel: '病虫害',
      ));
    }
    if (items.isEmpty) return const SizedBox();

    return SectionCard(
      title: '问题与建议',
      child: Column(
        children: items.map((item) {
          return Container(
            width: double.infinity,
            margin: EdgeInsets.only(
                bottom: item == items.last ? 0 : 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // badge row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.badgeIcon,
                              size: 14, color: item.color),
                          const SizedBox(width: 4),
                          Text(item.badgeLabel,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: item.color)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(item.icon, size: 20, color: item.color),
                  ],
                ),
                const SizedBox(height: 12),
                // problem title
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if (item.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(item.content,
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                          height: 1.5)),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
