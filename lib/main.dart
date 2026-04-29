import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:smart_farm_flutter/services/supabase_service.dart';
import 'package:smart_farm_flutter/routes/route.dart';

Future<void> main(List<String> args) async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await SupabaseService.initialize();
  
  runApp(getRootWidget());
  FlutterNativeSplash.remove();
}
