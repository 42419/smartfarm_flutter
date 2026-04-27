import 'package:flutter/material.dart';
import 'alert_center_page.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // 淡灰色背景
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              '东郊农场',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, color: Colors.black87),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AlertCenterPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部的设备状态卡片
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    '在线设备',
                    '42',
                    '全部在线',
                    Icons.developer_board,
                    Colors.blue,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    '告警设备',
                    '3',
                    '需紧急处理',
                    Icons.warning_amber_rounded,
                    Colors.redAccent,
                    Colors.redAccent,
                    isAlert: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 环境平均数据
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '环境平均数据',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '更新于 1分钟前',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEnvItem(
                        Icons.thermostat,
                        Colors.orangeAccent,
                        '26°C',
                        '温度',
                      ),
                      _buildEnvItem(
                        Icons.water_drop_outlined,
                        Colors.blueAccent,
                        '68%',
                        '湿度',
                      ),
                      _buildEnvItem(
                        Icons.wb_sunny_outlined,
                        Colors.yellow.shade700,
                        '3200',
                        '光照(lux)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEnvItem(
                        Icons.eco_outlined,
                        Colors.green,
                        '18%',
                        '土壤湿度',
                        isAlert: true,
                      ),
                      _buildEnvItem(
                        Icons.cloud_outlined,
                        Colors.purpleAccent,
                        '820',
                        'CO2(ppm)',
                      ),
                      _buildEnvItem(
                        Icons.science_outlined,
                        Colors.blueGrey,
                        '6.8',
                        'pH值',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 农场区域视图
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '农场区域视图',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    _buildLegendItem(Colors.green, '正常'),
                    const SizedBox(width: 8),
                    _buildLegendItem(Colors.amber, '告警'),
                    const SizedBox(width: 8),
                    _buildLegendItem(Colors.redAccent, '异常'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 大棚卡片列表，设置为固定高度并支持独立滑动
            SizedBox(
              height: 250, // 根据需要调整高度
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _buildGreenhouseCard(
                    '1号大棚 - 番茄',
                    '土壤湿度偏低',
                    const Color(0xFFFFF4F4),
                    Colors.redAccent,
                    [Icons.water_drop, Icons.air],
                  ),
                  const SizedBox(height: 10),
                  _buildGreenhouseCard(
                    '2号大棚 - 黄瓜',
                    '所有参数正常',
                    const Color(0xFFF4FFF6),
                    Colors.green,
                    [Icons.water_drop, Icons.air, Icons.wb_sunny],
                  ),
                  const SizedBox(height: 10),
                  _buildGreenhouseCard(
                    '3号大棚 - 草莓',
                    '湿度接近阈值',
                    const Color(0xFFFFFDE7),
                    Colors.orangeAccent,
                    [Icons.water_drop, Icons.air],
                  ),
                  const SizedBox(height: 10),
                  _buildGreenhouseCard(
                    '4号大棚 - 辣椒',
                    '所有参数正常',
                    const Color(0xFFF4FFF6),
                    Colors.green,
                    [Icons.water_drop, Icons.wb_sunny],
                  ),
                  const SizedBox(height: 10),
                  _buildGreenhouseCard(
                    '5号大棚 - 西瓜',
                    '所有参数正常',
                    const Color(0xFFF4FFF6),
                    Colors.green,
                    [Icons.thermostat, Icons.air],
                  ),
                  const SizedBox(height: 10),
                  _buildGreenhouseCard(
                    '6号大棚 - 茄子',
                    '温度偏高',
                    const Color(0xFFFFF4F4),
                    Colors.redAccent,
                    [Icons.thermostat, Icons.air, Icons.water_drop],
                  ),
                  const SizedBox(height: 10),
                  _buildGreenhouseCard(
                    '7号大棚 - 南瓜',
                    '所有参数正常',
                    const Color(0xFFF4FFF6),
                    Colors.green,
                    [Icons.water_drop],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 快捷操作
            const Text(
              '快捷操作',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickOpButton(
                    '一键灌溉',
                    Icons.water_drop,
                    Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickOpButton('一键通风', Icons.air, Colors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickOpButton(
                    '一键补光',
                    Icons.wb_sunny,
                    Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    String title,
    String value,
    String subText,
    IconData icon,
    Color iconColor,
    Color subTextColor, {
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isAlert ? Colors.redAccent : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(subText, style: TextStyle(color: subTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEnvItem(
    IconData icon,
    Color iconColor,
    String value,
    String label, {
    bool isAlert = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isAlert ? Colors.redAccent : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isAlert ? Colors.redAccent : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGreenhouseCard(
    String title,
    String subtitle,
    Color bgColor,
    Color mainColor,
    List<IconData> icons,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: mainColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          Row(
            children: icons.map((icon) {
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: mainColor, size: 16),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOpButton(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
