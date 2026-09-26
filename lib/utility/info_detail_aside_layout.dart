import 'image_orientation.dart';

/// When a testimonial should pin its lead photo beside the story.
///
/// Wide windows with a portrait or square lead image use a left rail. Landscape
/// photos and narrow windows keep the stacked banner. Until the lead image has
/// been measured, a wide window still uses the rail so the hero lands on the
/// photo (testimonial cards are 3:4).
abstract final class InfoDetailAsideLayout {
  static const double columnGap = 32;
  static const double outerPadding = 24;
  static const double minRailWidth = 280;
  static const double maxRailWidth = 420;
  static const double railFraction = 0.36;
  static const double minReadingWidth = 420;

  static double get minWidth => minRailWidth + columnGap + minReadingWidth;

  static double railWidthFor(final double availableWidth) {
    return (availableWidth * railFraction).clamp(minRailWidth, maxRailWidth);
  }

  static bool pinLeadImage({
    required final bool enabled,
    required final double availableWidth,
    required final bool hasLeadImage,
    required final bool orientationKnown,
    required final ImageOrientation? leadOrientation,
  }) {
    if (!enabled || !hasLeadImage) {
      return false;
    }
    if (availableWidth < minWidth) {
      return false;
    }
    if (!orientationKnown) {
      return true;
    }
    return leadOrientation == ImageOrientation.portrait ||
        leadOrientation == ImageOrientation.square;
  }
}
