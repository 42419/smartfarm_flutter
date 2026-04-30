import 'package:flutter/material.dart';
import 'package:smart_farm_flutter/services/supabase_service.dart';
import 'package:smart_farm_flutter/routes/route.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseService.initialize();
  
  runApp(getRootWidget());
}
