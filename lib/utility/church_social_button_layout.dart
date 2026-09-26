/// How social buttons share the width of a church hub card.
///
/// One link is a full-width button. Several links share a row when each
/// button stays wide enough for its label, and wrap onto more rows when
/// they do not. Column count steps down when that avoids a single leftover
/// button. A short last row still stretches across the card.
abstract final class ChurchSocialButtonLayout {
  static const double gap = 8;

  /// Icon, label, and the tonal button's horizontal padding.
  static const double minButtonWidth = 148;

  /// Keeps a wide card from becoming one row of tiny buttons.
  static const int maxColumns = 3;

  static int columns({
    required final int count,
    required final double maxWidth,
  }) {
    if (count <= 1) return 1;
    final fitted = _fittedColumns(maxWidth);
    if (count <= fitted) return count;
    if (fitted > 2 && count % fitted == 1) {
      final narrower = fitted - 1;
      if (count % narrower != 1) return narrower;
    }
    return fitted;
  }

  static int _fittedColumns(final double maxWidth) {
    if (maxWidth <= 0) return 1;
    var columns = maxColumns;
    while (columns > 1) {
      final needed = columns * minButtonWidth + gap * (columns - 1);
      if (needed <= maxWidth) return columns;
      columns--;
    }
    return 1;
  }
}
