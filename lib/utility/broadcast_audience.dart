import 'notification_topics.dart';

/// Resolves which FCM topics a post broadcast should hit.
abstract final class BroadcastAudience {
  /// Whether [topics] already includes the Belfast umbrella topic.
  static bool includesBelfastUmbrella(Iterable<String> topics) =>
      topics.contains(NotificationTopics.belfastUmbrella);

  /// Post topics with Belfast umbrella added or stripped per [includeBelfastUmbrella].
  ///
  /// Non-Belfast topics from [postTopics] are always kept (deduped, order preserved).
  static List<String> resolve({
    required Iterable<String> postTopics,
    required bool includeBelfastUmbrella,
  }) {
    final seen = <String>{};
    final result = <String>[];

    for (final topic in postTopics) {
      if (topic == NotificationTopics.belfastUmbrella) continue;
      if (seen.add(topic)) result.add(topic);
    }

    if (includeBelfastUmbrella) {
      result.add(NotificationTopics.belfastUmbrella);
    }

    return result;
  }

  /// Human-readable audience list for confirmations and UI.
  static String describe(Iterable<String> topics) {
    final list = topics.toList();
    if (list.isEmpty) return 'No topics selected';
    return list.map(NotificationTopics.labelFor).join(', ');
  }
}
