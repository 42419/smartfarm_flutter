import 'package:flutter/material.dart';

import '../pages/alerts/alert_center_page.dart';
import '../pages/sensor_history/sensor_history_page.dart';
import '../services/app_feedback.dart';
import '../services/theme_service.dart';

import '../pages/login_page.dart';
import '../pages/main_page.dart';
import '../pages/register_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/edit_profile_page.dart';
import '../pages/ai_chat/ai_chat_page.dart';

Widget getRootWidget({String initialRoute = '/login'}) {
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: ThemeService.instance.modeNotifier,
    builder: (context, themeMode, _) {
      return MaterialApp(
        initialRoute: initialRoute,
        routes: getRootRoutes(),
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        themeMode: themeMode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
      );
    },
  );
}

ThemeData _buildTheme(Brightness brightness) {
  return ThemeData(
    colorSchemeSeed: Colors.greenAccent,
    brightness: brightness,
    useMaterial3: true,
  );
}

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    '/main': (context) => MainPage(key: MainPage.globalKey),
    '/login': (context) => LoginPage(),
    '/alert': (context) => AlertCenterPage(),
    '/sensor-history': (context) => const SensorHistoryPage(),
    '/register': (context) => const RegisterPage(),
    '/forgot-password': (context) => const ForgotPasswordPage(),
    '/edit-profile': (context) => const EditProfilePage(),
    '/ai-chat': (context) => const AiChatPage(),
  };
}
