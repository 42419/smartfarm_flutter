import 'package:flutter/material.dart';

class MetricTag extends StatelessWidget {
  const MetricTag({
    super.key,
    required this.value,
    this.unit = '',
    required this.color,
  });

  final double? value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = value != null ? '${value!.toStringAsFixed(1)}$unit' : '--';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class MiniChip extends StatelessWidget {
  const MiniChip({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    required this.color,
  });

  final String label;
  final double? value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = value != null ? '${value!.toStringAsFixed(1)}$unit' : '--';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label $text',
          style: TextStyle(fontSize: 11, color: color),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
