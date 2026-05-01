import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.iconSize = 48,
  });

  final String message;
  final IconData? icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: iconSize,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.35),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
