import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/app_feedback.dart';
import '../../services/device_manager.dart';
import '../../utils/responsive.dart';

class DeviceControlPage extends StatefulWidget {
  const DeviceControlPage({super.key});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  bool pump1 = false;
  bool pump2 = true;

  bool _autoControlEnabled = false;
  bool _autoFan = true;
  bool _autoIrrigation = true;
  bool _autoLight = true;
  double _tempThreshold = 30.0;
  double _humidityThreshold = 50.0;
  double _lightThreshold = 500.0;

  late AnimationController _windAnimController;
  late Animation<double> _windAnim;
  late AnimationController _flow1AnimController;
  late Animation<double> _flow1Anim;
  late AnimationController _flow2AnimController;
  late Animation<double> _flow2Anim;
  late AnimationController _recAnimController;

  void _syncAnimations() {
    final dm = DeviceManager.instance;
    if (dm.motorStatus) {
      if (!_windAnimController.isAnimating && !_windAnimController.isCompleted) {
        _windAnimController.forward();
      }
    } else {
      if (!_windAnimController.isAnimating && !_windAnimController.isDismissed) {
        _windAnimController.reverse();
      }
    }
    if (pump1) {
      if (!_flow1AnimController.isAnimating && !_flow1AnimController.isCompleted) {
        _flow1AnimController.forward();
      }
    } else {
      if (!_flow1AnimController.isAnimating && !_flow1AnimController.isDismissed) {
        _flow1AnimController.reverse();
      }
    }
    if (pump2) {
      if (!_flow2AnimController.isAnimating && !_flow2AnimController.isCompleted) {
        _flow2AnimController.forward();
      }
    } else {
      if (!_flow2AnimController.isAnimating && !_flow2AnimController.isDismissed) {
        _flow2AnimController.reverse();
      }
    }
  }

  VideoPlayerController? _videoController;
  double _videoAspectRatio = 16 / 9;
  bool _isVideoActive = false;
  bool _isVideoLoading = false;
  bool _isVideoToggling = false;
  Timer? _timeTimer;
  String _currentTime = '';

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
    final dm = DeviceManager.instance;
    DeviceManager.instance.addListener(_onDeviceUpdate);

    _windAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
      value: dm.motorStatus ? 1.0 : 0.0,
    );
    _windAnim = CurvedAnimation(
      parent: _windAnimController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeOutCubic,
    );
    _windAnimController.addListener(() => setState(() {}));

    _flow1AnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
      value: pump1 ? 1.0 : 0.0,
    );
    _flow1Anim = CurvedAnimation(
      parent: _flow1AnimController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeOutCubic,
    );
    _flow1AnimController.addListener(() => setState(() {}));

    _flow2AnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
      value: pump2 ? 1.0 : 0.0,
    );
    _flow2Anim = CurvedAnimation(
      parent: _flow2AnimController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeOutCubic,
    );
    _flow2AnimController.addListener(() => setState(() {}));

    _recAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _recAnimController.addListener(() => setState(() {}));

    _videoController = VideoPlayerController.asset('assets/video/video.mp4');
    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() => _videoAspectRatio = _videoController!.value.aspectRatio);
      }
    });
  }

  @override
  void dispose() {
    _stopTimer();
    _windAnimController.dispose();
    _flow1AnimController.dispose();
    _flow2AnimController.dispose();
    _recAnimController.dispose();
    DeviceManager.instance.removeListener(_onDeviceUpdate);

    // 这里不能调 _disposeVideo()：它内部会 setState，销毁阶段调用会抛异常。
    // 直接同步摘除引用并释放，controller 的异步释放无需等待。
    final controller = _videoController;
    _videoController = null;
    _isVideoActive = false;
    controller?.dispose();

    super.dispose();
  }

  Future<void> _initVideo() async {
    if (_isVideoLoading) return;
    if (!mounted) return;
    setState(() => _isVideoLoading = true);

    try {
      // 用局部变量持有 controller：initialize() 期间页面可能被销毁，
      // 此时 _videoController 已被置空，继续用 ! 解包会抛异常。
      var controller = _videoController;
      if (controller == null) {
        controller = VideoPlayerController.asset('assets/video/video.mp4');
        _videoController = controller;
        await controller.initialize();
        _videoAspectRatio = controller.value.aspectRatio;
      }
      await controller.setLooping(true);
      await controller.play();

      if (!mounted) return;
      setState(() {
        _isVideoActive = true;
        _isVideoLoading = false;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      showAppToast('视频加载失败');
      setState(() => _isVideoLoading = false);
    }
  }

  Future<void> _disposeVideo() async {
    _stopTimer();
    // 先同步摘掉引用并翻转状态，再异步释放底层资源。
    // dispose() 一开始就会把 controller 标记为已释放，如果此时仍挂在字段上，
    // 每帧都会重建的 VideoPlayer 会拿到已释放的 controller 并抛
    // "A VideoPlayerController was used after being disposed"，表现为闪一帧红色错误块。
    final controller = _videoController;
    _videoController = null;
    _isVideoActive = false;
    if (mounted) setState(() {});

    if (controller != null) {
      try {
        await controller.pause();
      } catch (_) {
        // controller 可能已被释放，忽略
      }
      await controller.dispose();
    }
  }

  Future<void> _toggleVideo() async {
    // 挡住连点：两次并发 _disposeVideo 会在第二次解包时拿到 null
    if (_isVideoToggling) return;
    _isVideoToggling = true;
    try {
      if (_isVideoActive) {
        await _disposeVideo();
      } else {
        await _initVideo();
      }
    } finally {
      _isVideoToggling = false;
    }
  }

  void _onDeviceUpdate() {
    if (mounted) {
      final dm = DeviceManager.instance;
      dm.silentMode = _autoControlEnabled;
      if (_autoControlEnabled) _runAutoControl();
      _syncAnimations();
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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.30,
              maxChildSize: 0.80,
              expand: false,
              builder: (ctx, scrollController) {
                final dm = DeviceManager.instance;
                final cs = Theme.of(context).colorScheme;
                return Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _autoControlEnabled
                                      ? Colors.blueAccent.withValues(alpha: 0.12)
                                      : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 22,
                                  color: _autoControlEnabled
                                      ? Colors.blueAccent
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '自动控制',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _autoControlEnabled
                                          ? '根据环境数据自动调节设备'
                                          : '已关闭，需手动控制所有设备',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _autoControlEnabled,
                                onChanged: (val) {
                                  setSheetState(() {});
                                  setState(() => _autoControlEnabled = val);
                                },
                                activeThumbColor: Colors.white,
                                activeTrackColor: Colors.blueAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_autoControlEnabled) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '当前环境：${dm.temperature == '--' ? '--℃' : '${dm.temperature}℃'}   ${dm.humidity == '--' ? '--%' : '${dm.humidity}%'}   ${dm.illumination == '--' ? '-- lux' : '${dm.illumination} lux'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildAutoRule(
                          context: ctx,
                          icon: Icons.thermostat,
                          iconColor: Colors.orangeAccent,
                          label: '温度',
                          subtitle: '高于阈值自动开启通风',
                          value: _tempThreshold,
                          unit: '℃',
                          min: 15,
                          max: 45,
                          enabled: _autoFan,
                          currentValue: double.tryParse(dm.temperature),
                          onToggle: (v) {
                            setSheetState(() {});
                            setState(() => _autoFan = v);
                          },
                          onChanged: (v) {
                            setSheetState(() {});
                            setState(() => _tempThreshold = v);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildAutoRule(
                          context: ctx,
                          icon: Icons.water_drop,
                          iconColor: Colors.blueAccent,
                          label: '湿度',
                          subtitle: '低于阈值自动开启灌溉',
                          value: _humidityThreshold,
                          unit: '%',
                          min: 20,
                          max: 90,
                          enabled: _autoIrrigation,
                          currentValue: double.tryParse(dm.humidity),
                          onToggle: (v) {
                            setSheetState(() {});
                            setState(() => _autoIrrigation = v);
                          },
                          onChanged: (v) {
                            setSheetState(() {});
                            setState(() => _humidityThreshold = v);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildAutoRule(
                          context: ctx,
                          icon: Icons.wb_sunny,
                          iconColor: Colors.amber,
                          label: '光照',
                          subtitle: '低于阈值自动开启补光',
                          value: _lightThreshold,
                          unit: 'lux',
                          min: 100,
                          max: 2000,
                          enabled: _autoLight,
                          currentValue: double.tryParse(dm.illumination),
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
                      const SizedBox(height: 24),
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
    required Color iconColor,
    required String label,
    required String subtitle,
    required double value,
    required String unit,
    required double min,
    required double max,
    required bool enabled,
    double? currentValue,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: enabled
                        ? iconColor.withValues(alpha: 0.12)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: enabled ? iconColor : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: enabled ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${value.toInt()} $unit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: enabled ? iconColor : cs.onSurfaceVariant,
                      ),
                    ),
                    if (currentValue != null)
                      Text(
                        '当前 ${currentValue.toStringAsFixed(currentValue == currentValue.roundToDouble() ? 0 : 1)}$unit',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: Colors.white,
                  activeTrackColor: iconColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                activeTrackColor: enabled ? iconColor : Colors.grey,
                inactiveTrackColor: enabled
                    ? iconColor.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                overlayColor: iconColor.withValues(alpha: 0.12),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: ((max - min) / 2).toInt(),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dm = DeviceManager.instance;
    final isLarge = Responsive.isLargeScreen(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('设备控制',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            _buildOnlineBadge(dm),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _autoControlEnabled
                  ? Icons.auto_awesome
                  : Icons.auto_awesome_outlined,
              color: _autoControlEnabled ? Colors.blueAccent : null,
            ),
            tooltip: '自动控制',
            onPressed: _showAutoControlSheet,
          ),
        ],
      ),
      body: isDesktop
          ? _buildDesktopBody(context, dm)
          : isLarge
              ? _buildLandscapeBody(context, dm)
              : _buildMobileBody(context, dm),
    );
  }

  Widget _buildOnlineBadge(DeviceManager dm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dm.isDeviceOnline
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dm.isDeviceOnline ? Colors.green : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            dm.isDeviceOnline ? '在线' : '离线',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dm.isDeviceOnline ? Colors.green : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvStrip(BuildContext context, DeviceManager dm) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _envItem(Icons.thermostat, Colors.orangeAccent, dm.temperature, '°C'),
          _envDivider(cs),
          _envItem(Icons.water_drop_outlined, Colors.blueAccent, dm.humidity, '%'),
          _envDivider(cs),
          _envItem(Icons.wb_sunny_outlined, Colors.amber, dm.illumination, ' lux'),
        ],
      ),
    );
  }

  Widget _envItem(IconData icon, Color color, String value, String unit) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value == '--' ? '--' : '$value$unit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _envDivider(ColorScheme cs) {
    return Container(
      width: 1,
      height: 24,
      color: cs.outlineVariant,
    );
  }

  Widget _buildQuickActions(BuildContext context, DeviceManager dm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _quickBtn(
              context: context,
              icon: Icons.air,
              label: '一键通风',
              color: Colors.green,
              active: dm.motorStatus,
              onTap: () => dm.controlDevice(
                  'motor_control', dm.motorStatus ? 'OFF' : 'ON'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickBtn(
              context: context,
              icon: Icons.wb_sunny,
              label: '一键补光',
              color: Colors.orangeAccent,
              active: dm.lightStatus,
              onTap: () => dm.controlDevice(
                  'light_control', dm.lightStatus ? 'OFF' : 'ON'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _quickBtn(
              context: context,
              icon: Icons.water_drop,
              label: '一键灌溉',
              color: Colors.blueAccent,
              active: pump1,
              onTap: () {
                final anyOff = !pump1 || !pump2;
                setState(() {
                  pump1 = anyOff;
                  pump2 = anyOff;
                });
                dm.toggleAllIrrigation(anyOff);
                showAppToast(anyOff ? '灌溉泵已全部开启' : '灌溉泵已全部关闭');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    final bgColor = active ? color : color.withValues(alpha: 0.15);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: active ? Colors.white : color,
                size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopBody(BuildContext context, DeviceManager dm) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildEnvStrip(context, dm),
                  const SizedBox(height: 12),
                  _buildCameraArea(context),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, dm),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 10) / 2;
                final itemHeight = itemWidth / 1.05;
                final gridHeight = itemHeight * 2 + 10;
                return SizedBox(
                  height: gridHeight,
                  child: _buildDeviceGrid(context, dm),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 32;
    final height = width / _videoAspectRatio;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_isVideoActive && _videoController != null)
            Positioned.fill(
              child: VideoPlayer(_videoController!),
            )
          else ...[
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/img/bg.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _initVideo,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          Icons.videocam_rounded,
                          size: 28,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '点击开启实时监控',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (_isVideoLoading)
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (_isVideoActive) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _recAnimController,
                      builder: (_, child) => Opacity(
                        opacity: 0.3 + _recAnimController.value * 0.7,
                        child: child,
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('REC',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1)),
                    const Spacer(),
                    Text(_currentTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        )),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white, size: 18),
                  onPressed: _toggleVideo,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ],
      )
    );
  }

  Widget _buildLandscapeBody(BuildContext context, DeviceManager dm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEnvStrip(context, dm),
          const SizedBox(height: 12),
          _buildCameraArea(context),
          const SizedBox(height: 12),
          _buildQuickActions(context, dm),
          const SizedBox(height: 12),
          _buildDeviceGrid(context, dm),
        ],
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context, DeviceManager dm) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildEnvStrip(context, dm),
          _buildQuickActions(context, dm),
          _buildCameraArea(context),
          const SizedBox(height: 12),
          _buildDeviceGrid(context, dm),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDeviceGrid(BuildContext context, DeviceManager dm) {
    return GridView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      children: [
        _buildMiCard(
          context: context,
          icon: Icons.air,
          iconColor: Colors.green,
          title: '通风设备',
          subtitle: '',
          valueText: '${(_windAnim.value * 3).toStringAsFixed(1)} 级',
          valueLabel: '${dm.temperature}°C  ${dm.humidity}%',
          isOn: dm.motorStatus,
          onChanged: (v) =>
              dm.controlDevice('motor_control', v ? 'ON' : 'OFF'),
        ),
        _buildMiCard(
          context: context,
          icon: Icons.wb_sunny_outlined,
          iconColor: Colors.orangeAccent,
          title: '补光设备',
          subtitle: '',
          valueText: '${dm.illumination} lux',
          valueLabel: '光照',
          isOn: dm.lightStatus,
          onChanged: (v) =>
              dm.controlDevice('light_control', v ? 'ON' : 'OFF'),
        ),
        _buildMiCard(
          context: context,
          icon: Icons.water_drop_outlined,
          iconColor: Colors.blueAccent,
          title: '灌溉泵 1',
          subtitle: '',
          valueText: '${(_flow1Anim.value * 120).toInt()} L/min',
          valueLabel: '流量',
          isOn: pump1,
          onChanged: (v) {
            setState(() => pump1 = v);
            _syncAnimations();
          },
        ),
        _buildMiCard(
          context: context,
          icon: Icons.water_drop_outlined,
          iconColor: Colors.blueAccent,
          title: '灌溉泵 2',
          subtitle: '',
          valueText: '${(_flow2Anim.value * 120).toInt()} L/min',
          valueLabel: '流量',
          isOn: pump2,
          onChanged: (v) {
            setState(() => pump2 = v);
            _syncAnimations();
          },
        ),
      ],
    );
  }

  Widget _buildMiCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String valueText,
    required String valueLabel,
    required bool isOn,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!isOn),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valueText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        valueLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _PowerSwitch(
                  isOn: isOn,
                  activeColor: iconColor,
                  onToggle: () => onChanged(!isOn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PowerSwitch extends StatelessWidget {
  const _PowerSwitch({
    required this.isOn,
    required this.activeColor,
    required this.onToggle,
  });

  final bool isOn;
  final Color activeColor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final Color wellColor = isOn
        ? activeColor.withValues(alpha: 0.18)
        : Colors.grey.shade200;
    final Color iconColor = isOn ? activeColor : Colors.grey.shade500;
    final Color borderColor = isOn
        ? activeColor.withValues(alpha: 0.30)
        : Colors.grey.shade400;
    return GestureDetector(
      onTap: onToggle,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: wellColor,
                border: Border.all(color: borderColor, width: 1.5),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isOn
                      ? activeColor.withValues(alpha: 0.55)
                      : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.power_settings_new,
                size: 19,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
