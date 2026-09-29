/// Decisions for the post photo and video viewer.
abstract final class GalleryViewer {
  /// Distance a vertical drag must travel before the viewer closes.
  static const double dismissDistance = 140;

  /// Release speed that closes the viewer even on a short drag.
  static const double dismissVelocity = 900;

  /// Media the grid is showing. On the web that list is photos only, and the
  /// gallery must open this same list so the tapped index still matches.
  static List<Map<String, dynamic>> visibleMedia(
    List<Map<String, dynamic>> media, {
    required bool imagesOnly,
  }) {
    if (!imagesOnly) return media;
    return [
      for (final entry in media)
        if (entry['type'] == 'img') entry,
    ];
  }

  /// Sideways paging and swipe-to-close stay available for video, and for a
  /// photo that is still fit to the screen. A zoomed photo keeps the gesture.
  static bool allowsPagingAndDismiss({
    required bool isPhoto,
    required bool photoIsFit,
  }) {
    if (!isPhoto) return true;
    return photoIsFit;
  }

  static bool shouldDismissDrag({
    required double offset,
    required double velocity,
  }) {
    return offset.abs() >= dismissDistance || velocity.abs() >= dismissVelocity;
  }

  /// `0:05`, `1:05`, or `1:02:03` when the clip is an hour or longer.
  static String formatPlaybackTime(Duration duration) {
    final clamped = duration.isNegative ? Duration.zero : duration;
    final hours = clamped.inHours;
    final minutes = clamped.inMinutes.remainder(60);
    final seconds = clamped.inSeconds.remainder(60);
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final mm = minutes.toString().padLeft(2, '0');
      return '$hours:$mm:$ss';
    }
    return '$minutes:$ss';
  }
}
