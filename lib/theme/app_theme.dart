import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Use these ONLY where Theme.of(context) is not available.
  // Prefer Theme.of(context).colorScheme in build methods.
  static const Color primary = Color(0xFF2B3245);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color surfaceContainer = Color(0xFFF0F2F5);
  static const Color surfaceInput = Color(0xFFF8F9FB);

  static const Color accent = Colors.blueAccent;

  static const Color temp = Colors.orangeAccent;
  static const Color humidity = Colors.blueAccent;
  static const Color soil = Colors.green;
  static const Color light = Colors.amber;
  static const Color co2 = Colors.purpleAccent;

  static const Color success = Colors.green;
  static const Color warning = Colors.amber;
  static const Color error = Colors.redAccent;
  static const Color info = Color(0xFF34495E);

  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textHint = Colors.grey;

  static const Color divider = Colors.black12;
}

class AppTheme {
  AppTheme._();

  static Color scaffoldBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color onSurfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color surfaceContainerHighest(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color outlineVariant(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color dividerColor(BuildContext context) =>
      Theme.of(context).dividerColor;
}
