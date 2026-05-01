import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.iconColor,
    this.subText,
    this.subTextColor,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final Color? iconColor;
  final String? subText;
  final Color? subTextColor;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveSubColor = subTextColor ?? color;
    final effectiveIconColor = iconColor ?? color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                Icon(icon, color: effectiveIconColor, size: 20),
              ],
            )
          else
            Text(label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isAlert ? Colors.redAccent : cs.onSurface,
            ),
          ),
          if (subText != null) ...[
            const SizedBox(height: 4),
            Text(subText!,
                style: TextStyle(color: effectiveSubColor, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class CompactStatCard extends StatelessWidget {
  const CompactStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            Text(label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
