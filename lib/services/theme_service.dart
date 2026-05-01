import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();

  static final ThemeService instance = ThemeService._();

  static const _key = 'app_theme_mode';

  final ValueNotifier<ThemeMode> modeNotifier = ValueNotifier(ThemeMode.system);

  ThemeMode get mode => modeNotifier.value;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? 'system';
    modeNotifier.value = _parse(raw);
  }

  Future<void> setMode(ThemeMode mode) async {
    modeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _serialize(mode));
  }

  String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _parse(String raw) {
    if (raw == 'light') return ThemeMode.light;
    if (raw == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }
}
