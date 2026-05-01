import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: iconSize,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.35),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
