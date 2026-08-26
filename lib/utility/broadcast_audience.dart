import 'notification_topics.dart';

/// Resolves which FCM topics a post broadcast should hit.
///
/// Broadcasts use location umbrella topics only (e.g. `Belfast`, `Portadown`,
/// `north-coast`). See `docs/post-tags-notification-streams.md`.
abstract final class BroadcastAudience {
  /// Whether [topics] already includes the Belfast umbrella topic.
  static bool includesBelfastUmbrella(Iterable<String> topics) =>
      topics.contains(NotificationTopics.belfastUmbrella);

  /// Whether [topics] includes the umbrella for [locationName].
  static bool includesLocationUmbrella({
    required Iterable<String> topics,
    required String locationName,
  }) =>
      topics.contains(NotificationTopics.locationUmbrella(locationName));

  /// Location-only FCM audience for a post broadcast.
  static List<String> resolveFromPost({
    required String location,
    required bool includeLocationUmbrella,
  }) {
    if (!includeLocationUmbrella) return [];
    return [NotificationTopics.locationUmbrella(location)];
  }

  /// Human-readable audience list for confirmations and UI.
  static String describe(Iterable<String> topics) {
    final list = topics.toList();
    if (list.isEmpty) return 'No topics selected';
    return list.map(NotificationTopics.labelFor).join(', ');
  }
}
