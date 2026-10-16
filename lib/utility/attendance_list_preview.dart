/// How the People tab folds a long expected or attendance list.
abstract final class AttendanceListPreview {
  /// A phone folds the name list once this many people are in it.
  static const int phoneCollapseAt = 9;

  /// A wide window lists about twice as many names before folding.
  static const int wideCollapseAt = 18;

  /// Names kept visible in the folded overview. Wide shows twice as many.
  static const int phoneNamePreview = 3;
  static const int wideNamePreview = 6;

  static int collapseAt({required bool isWide}) =>
      isWide ? wideCollapseAt : phoneCollapseAt;

  static bool shouldCollapse({required int count, required bool isWide}) =>
      count >= collapseAt(isWide: isWide);

  static int namePreviewCount({required bool isWide}) =>
      isWide ? wideNamePreview : phoneNamePreview;

  /// Leading names for the folded line, and how many people that line leaves out.
  static AttendanceNamePreview names({
    required List<String> names,
    required bool isWide,
  }) {
    final preview = namePreviewCount(isWide: isWide);
    if (names.length <= preview) {
      return AttendanceNamePreview(shown: names, hidden: 0);
    }
    return AttendanceNamePreview(
      shown: names.sublist(0, preview),
      hidden: names.length - preview,
    );
  }
}

class AttendanceNamePreview {
  const AttendanceNamePreview({required this.shown, required this.hidden});

  final List<String> shown;
  final int hidden;
}
