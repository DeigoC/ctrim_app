import 'package:flutter/material.dart';

/// Breakpoints aligned with ctrim_app (information_home + events pages).
enum GutterStyle {
  /// width / 5 (~20% each side) — bulletin-style lists
  wide,

  /// width / 6 (~16.7%) — personal / welcome screens
  medium,

  /// width / 7 (~14.3%) — standard detail and form pages
  standard,
}

abstract final class ResponsiveLayout {
  static const double compact = 600;
  static const double wideGutter = 768;
  static const double tablet = 900;
  static const double desktop = 1200;

  static const double loginMaxWidth = 500;
  static const double chordMaxWidth = 900;
  static const double dialogAvatarMaxRadius = 120;

  static bool isCompact(double width) => width < compact;

  static bool isWideScreen(double width) => width >= tablet;

  static double horizontalGutter(
    double width, {
    GutterStyle style = GutterStyle.standard,
    double narrowPadding = 0,
  }) {
    if (width < wideGutter) return narrowPadding;

    return switch (style) {
      GutterStyle.wide => width / 5,
      GutterStyle.medium => width / 6,
      GutterStyle.standard => width / 7,
    };
  }

  static double maxContentWidth(double width) {
    if (width >= desktop) return 1400;
    if (width >= tablet) return 1000;
    return width;
  }

  static int crossAxisCount(double width, {int max = 3}) {
    if (width >= desktop) return max;
    if (width >= tablet) return max > 2 ? 2 : max;
    return 1;
  }

  static int statisticsCrossAxisCount(double width) {
    if (width >= desktop) return 4;
    if (width >= tablet) return 3;
    return 2;
  }

  static double dialogAvatarRadius(double screenWidth, {double fraction = 0.25}) {
    return (screenWidth * fraction).clamp(48.0, dialogAvatarMaxRadius);
  }

  static double dialogAvatarRadiusFromHeight(double screenHeight, {double fraction = 0.25}) {
    return (screenHeight * fraction).clamp(48.0, dialogAvatarMaxRadius);
  }

  static double horizontalGutterOf(BuildContext context, {GutterStyle style = GutterStyle.standard, double narrowPadding = 0}) {
    return horizontalGutter(MediaQuery.sizeOf(context).width, style: style, narrowPadding: narrowPadding);
  }
}
