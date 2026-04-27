import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../pages/main_page.dart';

Widget getRootWidget() {
  return MaterialApp(
    initialRoute: '/login',
    routes: getRootRoutes(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.greenAccent),
  );
}

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    '/main': (context) => MainPage(), // 主页路由
    '/login': (context) => LoginPage(), // 登录路由
  };
}
