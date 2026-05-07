import 'package:flutter/widgets.dart';

class Responsive {
  static const double largeScreenBreakpoint = 600;
  static const double contentMaxWidth = 700;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeScreenBreakpoint;

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 4;
    if (w >= 600) return 3;
    return 2;
  }
}
