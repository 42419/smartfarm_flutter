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

  final List<Widget> _pages = const [
    OverviewPage(),
    DeviceControlPage(),
    DataMonitorPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: '总览',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设备控制',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: '数据监测',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
