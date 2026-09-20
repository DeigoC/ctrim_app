/// How many pastor tiles sit on one row of the church hub / pastors page.
abstract final class ChurchPastorListLayout {
  static const double gap = 8;
  static const double minTileWidth = 96;
  static const double avatarRadius = 28;

  /// One person is a single tile; a pair stays side by side; three or more
  /// use up to three columns when the card is wide enough, otherwise two.
  static int columns({
    required final int count,
    required final double maxWidth,
  }) {
    if (count <= 0) {
      return 0;
    }
    if (count == 1) {
      return 1;
    }
    if (count == 2) {
      return 2;
    }
    if (maxWidth <= 0) {
      return 2;
    }
    final threeWide = (maxWidth - gap * 2) / 3 >= minTileWidth;
    return threeWide ? 3 : 2;
  }

  static double tileWidth({
    required final int columns,
    required final double maxWidth,
  }) {
    if (columns <= 1) {
      return maxWidth;
    }
    return (maxWidth - gap * (columns - 1)) / columns;
  }
}
