import 'package:flutter/material.dart';

class FarmNetworkPage extends StatelessWidget {
  const FarmNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          '农场网络',
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
          _buildNetworkStatus(context),
          const SizedBox(height: 16),
          _buildWifiSection(context),
          const SizedBox(height: 16),
          _buildDeviceList(context),
        ],
      ),
    );
  }

  Widget _buildNetworkStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi, size: 36, color: Colors.green),
          ),
          const SizedBox(height: 12),
          Text(
            '网络状态良好',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNetStat(context, '下载', '86.4', 'Mbps'),
              Container(width: 1, height: 32, color: Theme.of(context).colorScheme.outlineVariant),
              _buildNetStat(context, '上传', '22.1', 'Mbps'),
              Container(width: 1, height: 32, color: Theme.of(context).colorScheme.outlineVariant),
              _buildNetStat(context, '延迟', '12', 'ms'),
              Container(width: 1, height: 32, color: Theme.of(context).colorScheme.outlineVariant),
              _buildNetStat(context, '在线设备', '42', '台'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetStat(BuildContext context, String label, String value, String unit) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(width: 2),
            Text(unit,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildWifiSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wi-Fi 网络',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildWifiItem(
            context: context,
            ssid: 'SmartFarm-5G',
            signal: 4,
            connected: true,
          ),
          const Divider(height: 6, color: Colors.transparent),
          _buildWifiItem(
            context: context,
            ssid: 'SmartFarm-2.4G',
            signal: 3,
            connected: false,
          ),
        ],
      ),
    );
  }

  Widget _buildWifiItem({
    required BuildContext context,
    required String ssid,
    required int signal,
    required bool connected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: connected
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.wifi,
              size: 22,
              color: connected ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ssid,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Row(
                  children: List.generate(4, (i) {
                    return Icon(
                      i < signal ? Icons.signal_cellular_alt : Icons.signal_cellular_alt,
                      size: 14,
                      color:                       i < signal ? Colors.green : Theme.of(context).colorScheme.outlineVariant,
                    );
                  }),
                ),
              ],
            ),
          ),
          if (connected)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('已连接',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '连接设备',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeviceItem(
            context: context,
            name: '中枢网关',
            ip: '192.168.1.100',
            mac: 'D4:5E:EC:A1:02:33',
            isOnline: true,
          ),
          _buildDeviceItem(
            context: context,
            name: '1号大棚控制器',
            ip: '192.168.1.101',
            mac: 'D4:5E:EC:A1:02:34',
            isOnline: true,
          ),
          _buildDeviceItem(
            context: context,
            name: '2号大棚控制器',
            ip: '192.168.1.102',
            mac: 'D4:5E:EC:A1:02:35',
            isOnline: true,
          ),
          _buildDeviceItem(
            context: context,
            name: '3号大棚控制器',
            ip: '192.168.1.103',
            mac: 'D4:5E:EC:A1:02:36',
            isOnline: false,
          ),
          _buildDeviceItem(
            context: context,
            name: '4号大棚控制器',
            ip: '192.168.1.104',
            mac: 'D4:5E:EC:A1:02:37',
            isOnline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem({
    required BuildContext context,
    required String name,
    required String ip,
    required String mac,
    required bool isOnline,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('$ip · $mac',
                    style: TextStyle(
                        fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(isOnline ? '在线' : '离线',
              style: TextStyle(
                  fontSize: 12, color: isOnline ? Colors.green : Colors.grey)),
        ],
      ),
    );
  }
}
