import 'package:flutter/material.dart';
import '../../services/app_feedback.dart';
import '../../services/device_manager.dart';
import 'widgets/device_card.dart';

class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({super.key});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage>
    with AutomaticKeepAliveClientMixin {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['全部', '灌溉设备', '通风设备', '补光设备', '水肥设备'];

  @override
  bool get wantKeepAlive => true;

  bool pump1 = false;
  bool pump2 = true;
  bool window3 = true;

  @override
  void initState() {
    super.initState();
    DeviceManager.instance.addListener(_onDeviceUpdate);
  }

  @override
  void dispose() {
    DeviceManager.instance.removeListener(_onDeviceUpdate);
    super.dispose();
  }

  void _onDeviceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dm = DeviceManager.instance;
    bool fan1 = dm.motorStatus;
    bool light2 = dm.lightStatus;
    final currentTemp =
        dm.temperature == '--' ? '--℃' : '${dm.temperature}℃';
    final currentIllumination =
        dm.illumination == '--' ? '-- lux' : '${dm.illumination} lux';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('设备控制',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 12),
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
                        setState(() => _selectedTabIndex = index);
                      },
                      selectedColor: Colors.blueAccent,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: QuickOpButton(
                    title: '一键灌溉',
                    icon: Icons.water_drop,
                    color: Colors.blueAccent,
                    onTap: () {
                      final anyOff = !pump1 || !pump2;
                      setState(() {
                        pump1 = anyOff;
                        pump2 = anyOff;
                      });
                      showAppToast(anyOff ? '灌溉泵已全部开启' : '灌溉泵已全部关闭');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickOpButton(
                    title: '一键通风',
                    icon: Icons.air,
                    color: Colors.green,
                    onTap: () {
                      final target = !fan1;
                      dm.controlDevice(
                          'motor_control', target ? 'ON' : 'OFF');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: QuickOpButton(
                    title: '一键补光',
                    icon: Icons.wb_sunny,
                    color: Colors.orangeAccent,
                    onTap: () {
                      final target = !light2;
                      dm.controlDevice(
                          'light_control', target ? 'ON' : 'OFF');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 10, bottom: 20),
              children: [
                if (_selectedTabIndex == 0 || _selectedTabIndex == 1) ...[
                  const SectionHeader(
                    title: '灌溉设备',
                    icon: Icons.water_drop_outlined,
                    color: Colors.blueAccent,
                  ),
                  DeviceCard(
                    title: '灌溉泵 #001',
                    location: '1号大棚',
                    runtimeDay: '28',
                    attributes: [
                      {'label': '流量',
                       'value': pump1 ? '120 L/min' : '0 L/min'},
                      {'label': '压力',
                       'value': pump1 ? '0.32 Mpa' : '0 Mpa'},
                    ],
                    isOn: pump1,
                    onChanged: (val) => setState(() => pump1 = val),
                    icons: [Icons.access_time, Icons.monitor],
                  ),
                  const SizedBox(height: 12),
                  DeviceCard(
                    title: '灌溉泵 #002',
                    location: '2号大棚',
                    runtimeDay: '32',
                    attributes: [
                      {'label': '流量',
                       'value': pump2 ? '120 L/min' : '0 L/min'},
                      {'label': '压力',
                       'value': pump2 ? '0.32 Mpa' : '0 Mpa'},
                    ],
                    isOn: pump2,
                    onChanged: (val) => setState(() => pump2 = val),
                    icons: [Icons.access_time, Icons.monitor],
                  ),
                  const SizedBox(height: 24),
                ],
                if (_selectedTabIndex == 0 || _selectedTabIndex == 2) ...[
                  const SectionHeader(
                    title: '通风设备',
                    icon: Icons.air,
                    color: Colors.green,
                  ),
                  DeviceCard(
                    title: '轴流风机 #001',
                    location: '1号大棚',
                    runtimeDay: '45',
                    attributes: [
                      {'label': '风速', 'value': fan1 ? '2 级' : '0 级'},
                      {'label': '当前温度', 'value': currentTemp},
                    ],
                    isOn: fan1,
                    onChanged: (val) {
                      dm.controlDevice(
                          'motor_control', val ? 'ON' : 'OFF');
                    },
                    icons: [Icons.access_time, Icons.monitor],
                  ),
                  const SizedBox(height: 12),
                  DeviceCard(
                    title: '电动天窗 #003',
                    location: '3号大棚',
                    runtimeDay: '18',
                    statusTextOn: '部分开启',
                    attributes: [
                      {'label': '开度',
                       'value': window3 ? '45%' : '0%'},
                      {'label': '当前温度', 'value': currentTemp},
                    ],
                    isOn: window3,
                    onChanged: (val) => setState(() => window3 = val),
                    icons: [Icons.access_time, Icons.tune],
                  ),
                  const SizedBox(height: 24),
                ],
                if (_selectedTabIndex == 0 || _selectedTabIndex == 3) ...[
                  const SectionHeader(
                    title: '补光设备',
                    icon: Icons.wb_sunny_outlined,
                    color: Colors.orangeAccent,
                  ),
                  DeviceCard(
                    title: 'LED补光灯 #001',
                    location: '1号大棚',
                    runtimeDay: '22',
                    attributes: [
                      {'label': '亮度',
                       'value': light2 ? '75%' : '0%'},
                      {'label': '环境光照', 'value': currentIllumination},
                    ],
                    isOn: light2,
                    onChanged: (val) {
                      dm.controlDevice(
                          'light_control', val ? 'ON' : 'OFF');
                    },
                    icons: [Icons.access_time],
                  ),
                  const SizedBox(height: 20),
                ],
                if (_selectedTabIndex == 4) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                      child: Text('暂无相关设备',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
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
}
