import 'package:flutter/material.dart';

class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({super.key});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['全部', '灌溉设备', '通风设备', '补光设备', '水肥设备'];

  // 模拟设备状态数据
  bool pump1 = false;
  bool pump2 = true;
  bool fan1 = true;
  bool window3 = true;
  bool light2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          '设备控制',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEBF3FF),
                foregroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                '批量控制',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 标签栏
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  bool isSelected = _selectedTabIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(_tabs[index]),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                      },
                      selectedColor: Colors.blueAccent,
                      backgroundColor: const Color(0xFFF0F2F5),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: false,
                      side: BorderSide.none,
                    ),
                  );
                }),
              ),
            ),
          ),

          // 设备列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: 20,
              ),
              children: [
                if (_selectedTabIndex == 0 || _selectedTabIndex == 1) ...[
                  _buildSectionHeader(
                    '灌溉设备',
                    Icons.water_drop_outlined,
                    Colors.blueAccent,
                  ),
                  _buildDeviceCard(
                    title: '灌溉泵 #001',
                    location: '1号大棚',
                    runtimeDay: '28',
                    statusTextOn: '运行中',
                    statusTextOff: '已关闭',
                    attributes: [
                      {'label': '流量', 'value': pump1 ? '120 L/min' : '0 L/min'},
                      {'label': '压力', 'value': pump1 ? '0.32 Mpa' : '0 Mpa'},
                    ],
                    isOn: pump1,
                    onChanged: (val) => setState(() => pump1 = val),
                    icons: [Icons.access_time, Icons.monitor],
                  ),
                  const SizedBox(height: 12),
                  _buildDeviceCard(
                    title: '灌溉泵 #002',
                    location: '2号大棚',
                    runtimeDay: '32',
                    statusTextOn: '运行中',
                    statusTextOff: '已关闭',
                    attributes: [
                      {'label': '流量', 'value': pump2 ? '120 L/min' : '0 L/min'},
                      {'label': '压力', 'value': pump2 ? '0.32 Mpa' : '0 Mpa'},
                    ],
                    isOn: pump2,
                    onChanged: (val) => setState(() => pump2 = val),
                    icons: [Icons.access_time, Icons.monitor],
                  ),
                  const SizedBox(height: 24),
                ],

                if (_selectedTabIndex == 0 || _selectedTabIndex == 2) ...[
                  _buildSectionHeader('通风设备', Icons.air, Colors.green),
                  _buildDeviceCard(
                    title: '轴流风机 #001',
                    location: '1号大棚',
                    runtimeDay: '45',
                    statusTextOn: '运行中',
                    statusTextOff: '已关闭',
                    attributes: [
                      {'label': '风速', 'value': fan1 ? '2 级' : '0 级'},
                      {'label': '当前温度', 'value': '26.8℃'},
                    ],
                    isOn: fan1,
                    onChanged: (val) => setState(() => fan1 = val),
                    icons: [Icons.access_time, Icons.monitor],
                  ),
                  const SizedBox(height: 12),
                  _buildDeviceCard(
                    title: '电动天窗 #003',
                    location: '3号大棚',
                    runtimeDay: '18',
                    statusTextOn: '部分开启',
                    statusTextOff: '已关闭',
                    attributes: [
                      {'label': '开度', 'value': window3 ? '45%' : '0%'},
                      {'label': '当前温度', 'value': '29.2℃'},
                    ],
                    isOn: window3,
                    onChanged: (val) => setState(() => window3 = val),
                    icons: [Icons.access_time, Icons.tune],
                  ),
                  const SizedBox(height: 24),
                ],

                if (_selectedTabIndex == 0 || _selectedTabIndex == 3) ...[
                  _buildSectionHeader(
                    '补光设备',
                    Icons.wb_sunny_outlined,
                    Colors.orangeAccent,
                  ),
                  _buildDeviceCard(
                    title: 'LED补光灯 #002',
                    location: '2号大棚',
                    runtimeDay: '22',
                    statusTextOn: '运行中',
                    statusTextOff: '已关闭',
                    attributes: [
                      {'label': '亮度', 'value': light2 ? '75%' : '0%'},
                      {'label': '环境光照', 'value': '3200 lux'},
                    ],
                    isOn: light2,
                    onChanged: (val) => setState(() => light2 = val),
                    icons: [Icons.access_time],
                  ),
                  const SizedBox(height: 20),
                ],

                if (_selectedTabIndex == 4) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                      child: Text(
                        '暂无相关设备',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required String title,
    required String location,
    required String runtimeDay,
    String statusTextOn = '运行中',
    String statusTextOff = '已关闭',
    required List<Map<String, String>> attributes,
    required bool isOn,
    required ValueChanged<bool> onChanged,
    required List<IconData> icons,
  }) {
    String statusText = isOn ? statusTextOn : statusTextOff;
    Color statusColor = isOn
        ? (statusTextOn == '部分开启' ? Colors.orangeAccent : Colors.green)
        : Colors.grey;
    Color statusBgColor = isOn
        ? (statusTextOn == '部分开启'
              ? const Color(0xFFFFF8E1)
              : const Color(0xFFE8F5E9))
        : const Color(0xFFF0F2F5);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$location · 已运行 $runtimeDay天',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // attributes
              Expanded(
                child: Row(
                  children: attributes.map((attr) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attr['label']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            attr['value']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              // action icons
              Row(
                children: icons.map((icon) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(icon, size: 16, color: Colors.grey.shade600),
                  );
                }).toList(),
              ),
              // switch
              Switch(
                value: isOn,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.green,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
