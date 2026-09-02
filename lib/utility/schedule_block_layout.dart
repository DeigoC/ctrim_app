/// Decides how much a schedule timeline block can show at a given height.
///
/// A block's height is its duration, so it cannot grow to fit its content —
/// the content has to be chosen to fit the block. Keeping that arithmetic here
/// (rather than as thresholds sprinkled through the widget) means it can be
/// swept in a test, which is how a two-pixel overflow got shipped once.
library;

/// Where a block has room to show who is assigned.
enum ScheduleBlockAvatars {
  /// No users, or no room at all.
  none,

  /// On the same line as the title.
  inline,

  /// Pinned to the bottom edge, below the time.
  bottom,
}

class ScheduleBlockLayout {
  const ScheduleBlockLayout._({
    required this.stacked,
    required this.twoLineTitle,
    required this.avatars,
    required this.requiredHeight,
  });

  /// False when the block shows time, title and avatars on a single line.
  final bool stacked;
  final bool twoLineTitle;
  final ScheduleBlockAvatars avatars;

  /// What the chosen content occupies. Always `<=` the height asked for.
  final double requiredHeight;

  /// Text is pinned rather than scaled: the canvas is sized by clock time and
  /// cannot absorb a larger font. The role detail sheet scales normally.
  static const double maxTextScale = 1;

  static const double tightPadding = 1;
  static const double stackedPadding = 6;

  /// Rendered line heights for `labelLarge` and `labelSmall`.
  static const double titleLine = 20 * maxTextScale;
  static const double timeLine = 16 * maxTextScale;

  static const double compactAvatar = 18;
  static const double inlineAvatar = 22;
  static const double bottomAvatar = 28;

  /// Breathing room so rounding never tips a block into an overflow.
  static const double slack = 2;

  static const double _titleRowWithAvatar =
      titleLine > inlineAvatar ? titleLine : inlineAvatar;
  static const double _compactRow =
      titleLine > compactAvatar ? titleLine : compactAvatar;

  /// Smallest block that can show anything at all.
  static const double compactHeight = 2 * tightPadding + _compactRow;

  /// Below this a block stays on one line; at or above it, content stacks.
  static const double stackedHeight =
      2 * stackedPadding + _titleRowWithAvatar + timeLine + slack;

  static const double bottomAvatarHeight =
      2 * stackedPadding + titleLine + timeLine + bottomAvatar + slack;

  static const double twoLineHeight =
      2 * stackedPadding + 2 * titleLine + timeLine + slack;

  static const double twoLineWithBottomAvatarHeight =
      2 * stackedPadding + 2 * titleLine + timeLine + bottomAvatar + slack;

  static ScheduleBlockLayout forHeight(
    final double height, {
    required final bool hasUsers,
  }) {
    if (height < stackedHeight) {
      final avatars =
          hasUsers ? ScheduleBlockAvatars.inline : ScheduleBlockAvatars.none;
      return ScheduleBlockLayout._(
        stacked: false,
        twoLineTitle: false,
        avatars: avatars,
        requiredHeight: 2 * tightPadding + _compactRow,
      );
    }

    // Decided first, and independently of the avatars: a taller block must
    // never show less text than a shorter one.
    final twoLine = height >= twoLineHeight;

    // Avatars only move to the bottom edge once that fits alongside the title
    // the block has already earned; until then they ride on the title row.
    final bottom = hasUsers &&
        height >=
            (twoLine ? twoLineWithBottomAvatarHeight : bottomAvatarHeight);

    final titleRow = twoLine
        ? 2 * titleLine
        : hasUsers && !bottom
            ? _titleRowWithAvatar
            : titleLine;

    return ScheduleBlockLayout._(
      stacked: true,
      twoLineTitle: twoLine,
      avatars: bottom
          ? ScheduleBlockAvatars.bottom
          : hasUsers
              ? ScheduleBlockAvatars.inline
              : ScheduleBlockAvatars.none,
      requiredHeight: 2 * stackedPadding +
          titleRow +
          timeLine +
          (bottom ? bottomAvatar : 0),
    );
  }
}
