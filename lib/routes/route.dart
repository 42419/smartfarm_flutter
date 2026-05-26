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
import '../pages/automation/automation_page.dart';

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
  final base = ThemeData(
    colorSchemeSeed: Colors.greenAccent,
    brightness: brightness,
    useMaterial3: true,
  );

  if (brightness == Brightness.light) {
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF2F3F5),
      colorScheme: base.colorScheme.copyWith(
        surfaceTint: Colors.transparent,
        surface: Colors.white,
        surfaceContainerLow: Colors.white,
        surfaceContainerHigh: const Color(0xFFF0F3F5),
        surfaceContainerHighest: const Color(0xFFE8ECF0),
        outlineVariant: const Color(0xFFE2E5EA),
      ),
    );
  }

  // Dark theme — override auto-generated M3 surfaces for better contrast
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF101216),
    colorScheme: base.colorScheme.copyWith(
      surfaceTint: Colors.transparent,
      surface: const Color(0xFF1A1D27),
      surfaceContainerLow: const Color(0xFF1E212F),
      surfaceContainerHigh: const Color(0xFF282B3A),
      surfaceContainerHighest: const Color(0xFF323548),
      outlineVariant: const Color(0xFF2F3245),
    ),
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
    '/automation': (context) => const AutomationPage(),
  };
}
