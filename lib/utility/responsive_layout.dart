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
  static const double dialogMaxWidth = 420;

  /// Checklist / review dialogs that need a bit more room than [dialogMaxWidth].
  static const double reviewDialogMaxWidth = 560;
  static const double dialogAvatarMaxRadius = 120;

  /// Desktop content column cap — also used for modal bottom sheets.
  static const double desktopContentMaxWidth = 1400;
  static const double tabletContentMaxWidth = 1000;

  static bool isCompact(double width) => width < compact;

  static bool isWideScreen(double width) => width >= tablet;

  /// Use **window** width, not a [LayoutBuilder] leftover after the nav rail
  /// or content gutters — those often sit under [tablet] on a wide window.
  static bool isWideScreenOf(BuildContext context) =>
      isWideScreen(MediaQuery.sizeOf(context).width);

  /// Card-grid columns from available [parentWidth], but at least 2 when the
  /// window is wide (so lists still pair beside the rail).
  static int cardCrossAxisCount(
    BuildContext context,
    double parentWidth, {
    int max = 3,
  }) {
    final count = crossAxisCount(parentWidth, max: max);
    if (isWideScreenOf(context) && count < 2) return 2;
    return count;
  }

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
    if (width >= desktop) return desktopContentMaxWidth;
    if (width >= tablet) return tabletContentMaxWidth;
    return width;
  }

  /// Caps modal bottom sheets to the same width as main content on wide screens.
  /// On phones this resolves to the full screen width (no visual change).
  static BoxConstraints bottomSheetConstraints(double width) =>
      BoxConstraints(maxWidth: maxContentWidth(width));

  static BoxConstraints bottomSheetConstraintsOf(BuildContext context) =>
      bottomSheetConstraints(MediaQuery.sizeOf(context).width);

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

  static double dialogAvatarRadius(double screenWidth,
      {double fraction = 0.25}) {
    return (screenWidth * fraction).clamp(48.0, dialogAvatarMaxRadius);
  }

  static double dialogAvatarRadiusFromHeight(double screenHeight,
      {double fraction = 0.25}) {
    return (screenHeight * fraction).clamp(48.0, dialogAvatarMaxRadius);
  }

  static double horizontalGutterOf(BuildContext context,
      {GutterStyle style = GutterStyle.standard, double narrowPadding = 0}) {
    return horizontalGutter(MediaQuery.sizeOf(context).width,
        style: style, narrowPadding: narrowPadding);
  }
}
