import 'package:flutter/material.dart';

class AlertCenterPage extends StatefulWidget {
  const AlertCenterPage({super.key});

  @override
  State<AlertCenterPage> createState() => _AlertCenterPageState();
}

class _AlertCenterPageState extends State<AlertCenterPage> {
  int _selectedFilterIndex = 0; // 0: 全部, 1: 未处理, 2: 已处理

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 整个页面底层是白色
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.arrow_back_ios, color: Colors.black87),
            // 保持和图一致的左侧返回（虽然是tab，但图上有）
            SizedBox(width: 8),
            Text(
              '告警中心',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        // 我们自己画了返回按钮占位
        titleSpacing: 16,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF0F2F5),
                foregroundColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                '全部已读',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部三个统计卡片
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '今日告警',
                    '8',
                    const Color(0xFFFFF4F4),
                    Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '未处理',
                    '3',
                    const Color(0xFFFFF8EC),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '已处理',
                    '5',
                    const Color(0xFFF0FFF0),
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // 分段控制器选项卡 (全部 / 未处理 / 已处理)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildSegmentButton(0, '全部'),
                  _buildSegmentButton(1, '未处理'),
                  _buildSegmentButton(2, '已处理'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 列表部分
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FB), // 列表区域稍微带灰底色
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  if (_selectedFilterIndex == 0 ||
                      _selectedFilterIndex == 1) ...[
                    const Text(
                      '今天',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildActiveAlertCard(
                      borderColor: Colors.redAccent,
                      tagText: '紧急',
                      tagColor: Colors.redAccent,
                      tagBgColor: const Color(0xFFFFF0F0),
                      title: '土壤湿度过低',
                      time: '10:23',
                      content: '1号大棚 土壤湿度当前值18%，低于阈值25%，请及时灌溉',
                      primaryActionText: '一键灌溉',
                      primaryActionIcon: Icons.water_drop_outlined,
                      primaryActionColor: Colors.blueAccent,
                    ),
                    const SizedBox(height: 12),

                    _buildActiveAlertCard(
                      borderColor: Colors.amber.shade600,
                      tagText: '警告',
                      tagColor: Colors.amber.shade700,
                      tagBgColor: const Color(0xFFFFFDE7),
                      title: '温度接近阈值',
                      time: '09:15',
                      content: '3号大棚 当前温度29.2℃，接近阈值30℃，建议开启通风',
                      primaryActionText: '开启通风',
                      primaryActionIcon: Icons.air,
                      primaryActionColor: const Color(0xFF2ECC71),
                    ),
                    const SizedBox(height: 12),

                    _buildActiveAlertCard(
                      borderColor: Colors.orange.shade700,
                      tagText: '离线',
                      tagColor: Colors.orange.shade700,
                      tagBgColor: const Color(0xFFFFF3E0),
                      title: '设备离线',
                      time: '08:42',
                      content: '4号大棚 土壤湿度传感器已离线30分钟，请检查设备连接',
                      primaryActionText: '查看设备',
                      primaryActionIcon: Icons.settings_outlined,
                      primaryActionColor: const Color(0xFF34495E),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_selectedFilterIndex == 0 ||
                      _selectedFilterIndex == 2) ...[
                    const Text(
                      '昨天',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildHandledAlertCard(
                      title: '空气湿度过低',
                      time: '昨天 16:38',
                      content: '2号大棚 空气湿度当前值38%，低于阈值40%',
                      handledText: '已开启雾化加湿，当前湿度已恢复至65%',
                    ),
                    const SizedBox(height: 12),

                    _buildHandledAlertCard(
                      title: 'CO₂浓度偏高',
                      time: '昨天 14:22',
                      content: '3号大棚 CO₂浓度1620ppm，高于阈值1500ppm',
                      handledText: '已开启通风换气，当前CO₂浓度已恢复至820ppm',
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color bgColor,
    Color valColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: valColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String title) {
    bool isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // 活跃告警卡片（红框/黄框/橙框等）
  Widget _buildActiveAlertCard({
    required Color borderColor,
    required String tagText,
    required Color tagColor,
    required Color tagBgColor,
    required String title,
    required String time,
    required String content,
    required String primaryActionText,
    required IconData primaryActionIcon,
    required Color primaryActionColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tagBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tagText,
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // 小红点
                ],
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(primaryActionIcon, size: 16, color: Colors.white),
                  label: Text(
                    primaryActionText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryActionColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F7FA),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '忽略',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 已处理告警卡片（灰框）
  Widget _buildHandledAlertCard({
    required String title,
    required String time,
    required String content,
    required String handledText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '已处理',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.check, color: Colors.green, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  handledText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
