import 'package:flutter/material.dart';

import 'pageViews/data_monitor_page.dart';
import 'pageViews/device_control_page.dart';
import 'pageViews/overview_page.dart';
import 'pageViews/profile_page.dart';

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
    (null, null, 'AI'),
    (Icons.show_chart_outlined, Icons.show_chart_rounded, '数据监测'),
    (Icons.person_outline, Icons.person_rounded, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 72 + bottomPadding,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              if (index == 2) {
                return Expanded(
                  child: GestureDetector(
                    onTap: _onAiTap,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                );
              }

              final isSelected = _currentIndex == (index > 2 ? index - 1 : index);
              final (icon, selectedIcon, label) = _tabs[index];

              return Expanded(
                child: InkWell(
                  onTap: () {
                    final targetIndex = index > 2 ? index - 1 : index;
                    setState(() => _currentIndex = targetIndex);
                  },
                  borderRadius: BorderRadius.circular(24),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? selectedIcon : icon,
                        size: 22,
                        color: isSelected ? colorScheme.primary : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? colorScheme.primary : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
