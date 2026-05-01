import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

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

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textHint,
  );

  static const TextStyle metricValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle metricLabel = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}

class AppDecorations {
  AppDecorations._();

  static BoxDecoration card({
    Color color = AppColors.surface,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  static BoxDecoration chipDeclared(Color bgColor, Color borderColor) {
    return BoxDecoration(
      color: bgColor,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(20),
    );
  }

  static RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
}
