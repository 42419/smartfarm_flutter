import 'package:flutter/material.dart';

import 'monitor/data_monitor_page.dart';
import 'devices/device_control_page.dart';
import 'home/overview_page.dart';
import 'profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static final GlobalKey<MainPageState> globalKey = GlobalKey<MainPageState>();

  static void switchToTab(int index) {
    globalKey.currentState?._switchToTab(index);
  }

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  void _switchToTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  void _onAiTap() {
    Navigator.pushNamed(context, '/ai-chat');
  }

  final List<Widget> _pages = const [
    OverviewPage(),
    DeviceControlPage(),
    DataMonitorPage(),
    ProfilePage(),
  ];

  static const _tabs = [
    (Icons.grid_view_outlined, Icons.grid_view_rounded, '总览'),
    (Icons.settings_outlined, Icons.settings_rounded, '设备控制'),
    (Icons.show_chart_outlined, Icons.show_chart_rounded, '数据监测'),
    (Icons.person_outline, Icons.person_rounded, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < _tabs.length; i++) ...[
                      Expanded(child: _buildTab(context, i, colorScheme)),
                      if (i == 1) const SizedBox(width: 56),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: _onAiTap,
              child: Container(
                width: 63,
                height: 63,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surface,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  "assets/img/ai.png",
                  width: 50,
                  height: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, ColorScheme colorScheme) {
    final isSelected = _currentIndex == index;
    final (icon, selectedIcon, label) = _tabs[index];

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: isSelected
            ? BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 26,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
