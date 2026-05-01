import 'package:flutter/material.dart';

import '../../../../models/sensor_history_record.dart';
import '../../../../widgets/common/metric_chip.dart';

class RecordItem extends StatelessWidget {
  const RecordItem({
    super.key,
    required this.record,
    required this.isLast,
  });

  final SensorHistoryRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, isLast ? 16 : 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 5),
                Text(
                  _formatDateTime(record.recordedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                MetricTag(
                  value: record.temperature,
                  unit: '°C',
                  color: Colors.orangeAccent,
                ),
                const SizedBox(width: 4),
                MetricTag(
                  value: record.humidity,
                  unit: '%',
                  color: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                MiniChip(
                  label: '光照',
                  value: record.illumination,
                  unit: 'lux',
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                MiniChip(
                  label: '土壤',
                  value: record.effectiveSoilMoisture,
                  unit: '%',
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                MiniChip(
                  label: 'CO₂',
                  value: record.co2,
                  unit: 'ppm',
                  color: Colors.purpleAccent,
                ),
                const SizedBox(width: 8),
                MiniChip(
                  label: 'pH',
                  value: record.phValue,
                  unit: '',
                  color: Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final datePart =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return '$datePart ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
