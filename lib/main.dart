import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/auth_service.dart';
import 'services/automation_service.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'routes/route.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();
  await AuthService.instance.init();
  await ThemeService.instance.init();

  AutomationService.instance.loadRules();
  AutomationService.instance.startEngine();

  final hasSession = Supabase.instance.client.auth.currentSession != null;

  runApp(getRootWidget(initialRoute: hasSession ? '/main' : '/login'));
}
