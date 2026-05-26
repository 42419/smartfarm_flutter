import 'package:flutter/material.dart';

class DeviceSuppliesPage extends StatelessWidget {
  const DeviceSuppliesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          '设备耗材',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(context),
          const SizedBox(height: 16),
          _buildSupplyItem(
            context: context,
            name: '滴灌带 φ16mm',
            spec: '100米/卷',
            stock: '库存 28 卷',
            icon: Icons.water,
            status: '充足',
            statusColor: Colors.green,
          ),
          _buildSupplyItem(
            context: context,
            name: '湿度传感器探头',
            spec: 'SM-2801B',
            stock: '库存 5 个',
            icon: Icons.dew_point,
            status: '偏低',
            statusColor: Colors.orangeAccent,
          ),
          _buildSupplyItem(
            context: context,
            name: 'CO₂ 传感器模组',
            spec: 'MH-Z19C',
            stock: '库存 12 个',
            icon: Icons.co2_outlined,
            status: '充足',
            statusColor: Colors.green,
          ),
          _buildSupplyItem(
            context: context,
            name: 'LED 补光灯管',
            spec: 'T8 1.2m 18W',
            stock: '库存 3 根',
            icon: Icons.lightbulb_outline_rounded,
            status: '紧张',
            statusColor: Colors.redAccent,
          ),
          _buildSupplyItem(
            context: context,
            name: 'pH 校准液套装',
            spec: 'pH 4.0 / 7.0 / 10.0',
            stock: '库存 8 套',
            icon: Icons.policy_outlined,
            status: '充足',
            statusColor: Colors.green,
          ),
          _buildSupplyItem(
            context: context,
            name: '水泵密封圈套件',
            spec: 'DN25 氟橡胶',
            stock: '库存 0 套',
            icon: Icons.water_damage_outlined,
            status: '缺货',
            statusColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '耗材概览',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat(context, '总品类', '6', Colors.blueAccent),
              _buildStat(context, '充足', '3', Colors.green),
              _buildStat(context, '预警', '2', Colors.orangeAccent),
              _buildStat(context, '缺货', '1', Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '建议尽快补充 LED 补光灯管和湿度传感器探头',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildSupplyItem({
    required BuildContext context,
    required String name,
    required String spec,
    required String stock,
    required IconData icon,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                size: 24, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(spec,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(stock,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
