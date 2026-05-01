import 'package:flutter/material.dart';

class CompactEnvItem extends StatelessWidget {
  const CompactEnvItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class EnvDataSection extends StatelessWidget {
  const EnvDataSection({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.illumination,
    required this.soilMoisture,
  });

  final String temperature;
  final String humidity;
  final String illumination;
  final String soilMoisture;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CompactEnvItem(
            icon: Icons.thermostat,
            iconColor: Colors.orangeAccent,
            value: temperature,
            label: '温度',
          ),
          CompactEnvItem(
            icon: Icons.water_drop_outlined,
            iconColor: Colors.blueAccent,
            value: humidity,
            label: '湿度',
          ),
          CompactEnvItem(
            icon: Icons.wb_sunny_outlined,
            iconColor: Colors.yellow.shade700,
            value: illumination,
            label: '光照',
          ),
          CompactEnvItem(
            icon: Icons.eco_outlined,
            iconColor: Colors.green,
            value: soilMoisture,
            label: '土壤',
          ),
        ],
      ),
    );
  }
}
