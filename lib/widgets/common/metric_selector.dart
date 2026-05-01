import 'package:flutter/material.dart';

class MetricSelector extends StatelessWidget {
  const MetricSelector({
    super.key,
    required this.metrics,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<MetricOption> metrics;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(metrics.length, (index) {
          final isSelected = selectedIndex == index;
          final metric = metrics[index];
          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? metric.color.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? metric.color.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: metric.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    metric.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? metric.color : Colors.black54,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class MetricOption {
  final String label;
  final Color color;
  final String column;

  const MetricOption({
    required this.label,
    required this.color,
    required this.column,
  });
}
