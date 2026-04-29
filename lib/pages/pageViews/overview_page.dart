import 'package:flutter/material.dart';
import 'alert_center_page.dart';
import '../../models/crop.dart';
import '../../services/crop_service.dart';
import '../crop_detail_page.dart';

class _HealthInfo {
  final Color bgColor;
  final Color mainColor;
  const _HealthInfo(this.bgColor, this.mainColor);
}

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with AutomaticKeepAliveClientMixin {
  List<Crop> _crops = const [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    final crops = await CropService.instance.fetchCrops();
    if (!mounted) {
      return;
    }
    setState(() {
      _crops = crops;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _crops.isEmpty
                      ? const Center(child: Text('暂无大棚数据'))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: _crops.length,
                          itemBuilder: (context, index) {
                            final crop = _crops[index];
                            final info = _getHealthInfo(crop.health);
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < _crops.length - 1 ? 10 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CropDetailPage(
                                        crop: crop,
                                        greenhouseIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: _buildGreenhouseCard(
                                  '${index + 1}号大棚 - ${crop.cropName}',
                                  crop.health ?? '状态未知',
                                  info.bgColor,
                                  info.mainColor,
                                  _relevantIcons(crop),
                                  crop: crop,
                                ),
                              ),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  _HealthInfo _getHealthInfo(String? health) {
    final h = (health ?? '').trim();
    if (h.contains('异常') || h.contains('偏高') || h.contains('偏低') || h.contains('危险') || h.contains('差')) {
      return _HealthInfo(const Color(0xFFFFF4F4), Colors.redAccent);
    }
    if (h.contains('一般') || h.contains('注意') || h.contains('接近') || h.contains('警告')) {
      return _HealthInfo(const Color(0xFFFFFDE7), Colors.orangeAccent);
    }
    return _HealthInfo(const Color(0xFFF4FFF6), Colors.green);
  }

  List<IconData> _relevantIcons(Crop crop) {
    final icons = <IconData>[];
    final env1 = crop.environmentAnalysis1 ?? 0;
    final env2 = crop.environmentAnalysis2 ?? 0;
    final env3 = crop.environmentAnalysis3 ?? 0;
    final env4 = crop.environmentAnalysis4 ?? 0;
    final env5 = crop.environmentAnalysis5 ?? 0;

    if (env1 < 80) {
      icons.add(Icons.water_drop);
    }
    if (env2 < 80) {
      icons.add(Icons.thermostat);
    }
    if (env3 < 80) {
      icons.add(Icons.wb_sunny);
    }
    if (env4 < 80) {
      icons.add(Icons.co2);
    }
    if (env5 < 80) {
      icons.add(Icons.eco);
    }
    if (icons.isEmpty) {
      icons.add(Icons.check_circle);
    }
    return icons;
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
    List<IconData> icons, {
    Crop? crop,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
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
                if (crop != null) ...[
                  const SizedBox(height: 6),
                  _buildCropInfoRow(crop),
                ],
              ],
            ),
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

  Widget _buildCropInfoRow(Crop crop) {
    if (crop.summary != null && crop.summary!.isNotEmpty) {
      return Text(
        crop.summary!,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final items = <String>[];
    if (crop.plantDate != null && crop.plantDate!.isNotEmpty) {
      items.add('种植:${crop.plantDate}');
    }
    if (crop.harvestDate != null && crop.harvestDate!.isNotEmpty) {
      items.add('收获:${crop.harvestDate}');
    }
    if (crop.yieldText != null && crop.yieldText!.isNotEmpty) {
      items.add('产量:${crop.yieldText}');
    }
    if (crop.total > 0) {
      items.add('生长:${((crop.current / crop.total) * 100).toStringAsFixed(0)}%');
    }
    if (items.isEmpty) {
      return const SizedBox();
    }
    return Text(
      items.join('  '),
      style: const TextStyle(fontSize: 11, color: Colors.black54),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
