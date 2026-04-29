import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/config.dart';

class SupabaseService {
  static bool _initialized = false;

  static bool get isConfigured =>
      Config.supabaseUrl.isNotEmpty && Config.supabaseAnonKey.isNotEmpty;

  static SupabaseClient? get maybeClient =>
      _initialized ? Supabase.instance.client : null;

  static Future<void> initialize() async {
    if (_initialized || !isConfigured) {
      return;
    }

    try {
      await Supabase.initialize(
        url: Config.supabaseUrl,
        anonKey: Config.supabaseAnonKey,
      );
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Supabase initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
