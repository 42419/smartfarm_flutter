import 'package:flutter/material.dart';

import '../../../../models/crop.dart';

class LegendItem extends StatelessWidget {
  const LegendItem({
    super.key,
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class GreenhouseCard extends StatelessWidget {
  const GreenhouseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.mainColor,
    required this.icons,
    this.crop,
  });

  final String title;
  final String subtitle;
  final Color bgColor;
  final Color mainColor;
  final List<IconData> icons;
  final Crop? crop;

  @override
  Widget build(BuildContext context) {
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
                  _buildCropInfoRow(context, crop!),
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

  Widget _buildCropInfoRow(BuildContext context, Crop crop) {
    if (crop.summary != null && crop.summary!.isNotEmpty) {
      return Text(
        crop.summary!,
        style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    if (items.isEmpty) return const SizedBox();
    return Text(
      items.join('  '),
      style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class HealthInfo {
  final Color bgColor;
  final Color mainColor;
  const HealthInfo(this.bgColor, this.mainColor);
}

HealthInfo getHealthInfo(BuildContext context, String? health) {
  final h = (health ?? '').trim();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (h.contains('优秀')) {
    return HealthInfo(
      isDark ? const Color(0xFF1565C0).withValues(alpha: 0.16) : const Color(0xFFE8F5FF),
      const Color(0xFF1565C0),
    );
  }
  if (h.contains('异常') ||
      h.contains('偏高') ||
      h.contains('偏低') ||
      h.contains('危险') ||
      h.contains('差')) {
    return HealthInfo(
      isDark ? Colors.redAccent.withValues(alpha: 0.16) : const Color(0xFFFFF4F4),
      Colors.redAccent,
    );
  }
  if (h.contains('一般') ||
      h.contains('注意') ||
      h.contains('接近') ||
      h.contains('警告')) {
    return HealthInfo(
      isDark ? Colors.orangeAccent.withValues(alpha: 0.16) : const Color(0xFFFFFDE7),
      Colors.orangeAccent,
    );
  }
  return HealthInfo(
    isDark ? Colors.green.withValues(alpha: 0.16) : const Color(0xFFF4FFF6),
    Colors.green,
  );
}

List<IconData> relevantIcons(Crop crop) {
  final icons = <IconData>[];
  final env1 = crop.environmentAnalysis1 ?? 0;
  final env2 = crop.environmentAnalysis2 ?? 0;
  final env3 = crop.environmentAnalysis3 ?? 0;
  final env4 = crop.environmentAnalysis4 ?? 0;
  final env5 = crop.environmentAnalysis5 ?? 0;

  if (env1 < 80) icons.add(Icons.water_drop);
  if (env2 < 80) icons.add(Icons.thermostat);
  if (env3 < 80) icons.add(Icons.wb_sunny);
  if (env4 < 80) icons.add(Icons.co2);
  if (env5 < 80) icons.add(Icons.eco);
  if (icons.isEmpty) icons.add(Icons.check_circle);
  return icons;
}
