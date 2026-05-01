import 'package:flutter/material.dart';

class DismissibleAlert extends StatelessWidget {
  const DismissibleAlert({
    super.key,
    required this.alertId,
    required this.onDismissed,
    required this.child,
  });

  final String alertId;
  final VoidCallback onDismissed;
  final Widget child;

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
