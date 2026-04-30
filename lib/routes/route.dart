import 'package:flutter/material.dart';
import 'package:smart_farm_flutter/pages/pageViews/alert_center_page.dart';
import 'package:smart_farm_flutter/pages/sensor_history_page.dart';
import 'package:smart_farm_flutter/services/app_feedback.dart';

import '../pages/login_page.dart';
import '../pages/main_page.dart';
import '../pages/register_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/edit_profile_page.dart';

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
    '/main': (context) => MainPage(key: MainPage.globalKey), // 主页
    '/login': (context) => LoginPage(), // 登录页
    '/alert': (context) => AlertCenterPage(), // 预警中心
    '/sensor-history': (context) => const SensorHistoryPage(), // 历史数据查询
    '/register': (context) => const RegisterPage(), // 注册页
    '/forgot-password': (context) => const ForgotPasswordPage(), // 忘记密码页
    '/edit-profile': (context) => const EditProfilePage(), // 编辑资料页
  };
}
