import 'package:flutter/material.dart';
import 'package:smart_farm_flutter/pages/pageViews/alert_center_page.dart';
import 'package:smart_farm_flutter/pages/sensor_history_page.dart';
import 'package:smart_farm_flutter/services/app_feedback.dart';

import '../pages/login_page.dart';
import '../pages/main_page.dart';

Widget getRootWidget() {
  return MaterialApp(
    initialRoute: '/login',
    routes: getRootRoutes(),
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: appScaffoldMessengerKey,
    theme: ThemeData(colorSchemeSeed: Colors.greenAccent),
  );
}

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    '/main': (context) => MainPage(), // 主页
    '/login': (context) => LoginPage(), // 登录页
    '/alert': (context) => AlertCenterPage(), // 预警中心
    '/sensor-history': (context) => const SensorHistoryPage(), // 历史数据查询
  };
}
