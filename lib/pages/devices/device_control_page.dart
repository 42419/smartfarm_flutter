import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
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

  bool _autoControlEnabled = false;
  bool _autoFan = true;
  bool _autoIrrigation = true;
  bool _autoLight = true;
  double _tempThreshold = 30.0;
  double _humidityThreshold = 50.0;
  double _lightThreshold = 500.0;

  CameraController? _cameraController;
  bool _isCameraActive = false;
  bool _isCameraLoading = false;
  Timer? _timeTimer;
  String _currentTime = '';
  final GlobalKey _cameraKey = GlobalKey();

  String _formatNow() {
    final now = DateTime.now();
    return '${now.year}年${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日 '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _currentTime = _formatNow();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = _formatNow());
    });
  }

  void _stopTimer() {
    _timeTimer?.cancel();
    _timeTimer = null;
  }

  @override
  void initState() {
    super.initState();
    DeviceManager.instance.addListener(_onDeviceUpdate);
  }

  @override
  void dispose() {
    _stopTimer();
    DeviceManager.instance.removeListener(_onDeviceUpdate);
    _disposeCamera();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (_isCameraLoading) return;
    setState(() => _isCameraLoading = true);

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          showAppToast('需要相机权限才能使用监控功能');
          setState(() => _isCameraLoading = false);
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          showAppToast('未检测到可用摄像头');
          setState(() => _isCameraLoading = false);
        }
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraActive = true;
          _isCameraLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        showAppToast('摄像头启动失败');
        setState(() => _isCameraLoading = false);
      }
    }
  }

  Future<void> _disposeCamera() async {
    _stopTimer();
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }
    _isCameraActive = false;
  }

  Future<void> _toggleCamera() async {
    if (_isCameraActive) {
      await _disposeCamera();
      if (mounted) setState(() {});
    } else {
      await _initCamera();
    }
  }

  Future<void> _goFullscreen() async {
    if (!_isCameraActive || _cameraController == null) return;
    final controller = _cameraController!;

    final renderBox =
        _cameraKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero);
    final size = renderBox?.size;

    if (offset == null || size == null) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _FullscreenCameraPage(controller: controller),
        ),
      );
      return;
    }

    await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FullscreenCameraPage(controller: controller),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          );
          final isReverse = animation.status == AnimationStatus.reverse;
          return AnimatedBuilder(
            animation: curved,
            builder: (context, child) {
              final t = curved.value;
              final screenSize = MediaQuery.of(context).size;
              return Stack(
                children: [
                  Positioned(
                    left: offset.dx * (1 - t),
                    top: offset.dy * (1 - t),
                    width: size.width + (screenSize.width - size.width) * t,
                    height:
                        size.height + (screenSize.height - size.height) * t,
                    child: Container(color: Colors.black),
                  ),
                  if (!isReverse)
                    Positioned(
                      left: offset.dx * (1 - t),
                      top: offset.dy * (1 - t),
                      width: size.width + (screenSize.width - size.width) * t,
                      height:
                          size.height + (screenSize.height - size.height) * t,
                      child: child!,
                    ),
                ],
              );
            },
            child: child,
          );
        },
      ),
    );
  }

  void _onDeviceUpdate() {
    if (mounted) {
      final dm = DeviceManager.instance;
      dm.silentMode = _autoControlEnabled;
      if (_autoControlEnabled) _runAutoControl();
      setState(() {});
    }
  }

  void _runAutoControl() {
    final dm = DeviceManager.instance;
    final temp = double.tryParse(dm.temperature);
    final humidity = double.tryParse(dm.humidity);
    final light = double.tryParse(dm.illumination);

    if (temp != null && _autoFan) {
      if (temp > _tempThreshold && !dm.motorStatus) {
        dm.controlDevice('motor_control', 'ON');
      } else if (temp <= _tempThreshold - 2 && dm.motorStatus) {
        dm.controlDevice('motor_control', 'OFF');
      }
    }

    if (light != null && _autoLight) {
      if (light < _lightThreshold && !dm.lightStatus) {
        dm.controlDevice('light_control', 'ON');
      } else if (light >= _lightThreshold + 100 && dm.lightStatus) {
        dm.controlDevice('light_control', 'OFF');
      }
    }

    if (humidity != null && _autoIrrigation) {
      final pumpOn = humidity < _humidityThreshold;
      if (pumpOn != pump1) {
        setState(() {
          pump1 = pumpOn;
          pump2 = pumpOn;
        });
        dm.toggleAllIrrigation(pumpOn);
      }
    }
  }

  void _showAutoControlSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.35,
              maxChildSize: 0.85,
              expand: false,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('自动控制',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                  Text(
                                      _autoControlEnabled
                                          ? '已开启，根据环境自动调节设备'
                                          : '已关闭',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _autoControlEnabled,
                              onChanged: (val) {
                                setSheetState(() {});
                                setState(() => _autoControlEnabled = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_autoControlEnabled) ...[
                        const SizedBox(height: 8),
                        _buildAutoRule(
                          context: ctx,
                          icon: Icons.thermostat,
                          label: '温度阈值',
                          subtitle: '高于阈值自动开启通风',
                          value: _tempThreshold,
                          unit: '℃',
                          min: 15,
                          max: 45,
                          enabled: _autoFan,
                          onToggle: (v) {
                            setSheetState(() {});
                            setState(() => _autoFan = v);
                          },
                          onChanged: (v) {
                            setSheetState(() {});
                            setState(() => _tempThreshold = v);
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildAutoRule(
                          context: ctx,
                          icon: Icons.water_drop,
                          label: '湿度阈值',
                          subtitle: '低于阈值自动开启灌溉',
                          value: _humidityThreshold,
                          unit: '%',
                          min: 20,
                          max: 90,
                          enabled: _autoIrrigation,
                          onToggle: (v) {
                            setSheetState(() {});
                            setState(() => _autoIrrigation = v);
                          },
                          onChanged: (v) {
                            setSheetState(() {});
                            setState(() => _humidityThreshold = v);
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildAutoRule(
                          context: ctx,
                          icon: Icons.wb_sunny,
                          label: '光照阈值',
                          subtitle: '低于阈值自动开启补光',
                          value: _lightThreshold,
                          unit: 'lux',
                          min: 100,
                          max: 2000,
                          enabled: _autoLight,
                          onToggle: (v) {
                            setSheetState(() {});
                            setState(() => _autoLight = v);
                          },
                          onChanged: (v) {
                            setSheetState(() {});
                            setState(() => _lightThreshold = v);
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAutoRule({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required double value,
    required String unit,
    required double min,
    required double max,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18,
                  color: enabled ? Colors.blueAccent : Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: enabled ? cs.onSurface : Colors.grey)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Text('${value.toInt()} $unit',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.blueAccent : Colors.grey)),
              Switch(
                value: enabled,
                onChanged: onToggle,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 2),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: enabled ? Colors.blueAccent : Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 1).toInt(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            icon: Icon(
              _autoControlEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              color: _autoControlEnabled ? Colors.blueAccent : null,
            ),
            tooltip: '自动控制',
            onPressed: _showAutoControlSheet,
          ),
        ],
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
          Stack(
            children: [
              GestureDetector(
                onTap: _isCameraActive ? null : _initCamera,
                child: Container(
                  key: _cameraKey,
                  width: double.infinity,
                  height: 230,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A2E),
                  ),
                  child: _isCameraActive && _cameraController != null
                      ? CameraPreview(_cameraController!)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                size: 56,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '视频监控',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '点击开启实时监控',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              if (_isCameraLoading)
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (_isCameraActive) ...[
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      onPressed: _toggleCamera,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currentTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                        onPressed: _goFullscreen,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
          const SizedBox(height: 12),
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

class _FullscreenCameraPage extends StatelessWidget {
  final CameraController controller;
  const _FullscreenCameraPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(controller)),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 22),
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
