import 'package:flutter/widgets.dart';

class Responsive {
  static const double largeScreenBreakpoint = 600;
  static const double desktopScreenBreakpoint = 1200;
  static const double contentMaxWidth = 1200;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeScreenBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopScreenBreakpoint;

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    if (w >= 600) return 2;
    return 2;
  }

  static Widget constrainedBody(BuildContext context, Widget child) {
    if (!isDesktop(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: contentMaxWidth),
        child: child,
      ),
    );
  }
}
