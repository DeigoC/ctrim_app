import '../models/post_tag.dart';
import 'notification_topics.dart';

/// Resolves which FCM topics a post broadcast should hit.
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

  /// Builds stream topics from location + notifiable post tags.
  ///
  /// When no notifiable tags resolve, falls back to [legacyTopics] (minus any
  /// location umbrella) so older posts keep working.
  static List<String> topicsFromTags({
    required String location,
    required Iterable<String> tagIDs,
    required List<PostTag> allTags,
    Iterable<String> legacyTopics = const [],
  }) {
    final tagMap = {for (final tag in allTags) tag.id: tag};
    final seen = <String>{};
    final result = <String>[];

    for (final id in tagIDs) {
      final tag = tagMap[id];
      if (tag == null || !tag.isNotifiable) continue;
      final topic = NotificationTopics.streamTopic(
        locationName: location,
        streamKind: tag.streamKind!,
      );
      if (topic.isEmpty) continue;
      if (seen.add(topic)) result.add(topic);
    }

    if (result.isNotEmpty) return result;

    final umbrella = NotificationTopics.locationUmbrella(location);
    for (final topic in legacyTopics) {
      if (topic == umbrella || topic == NotificationTopics.belfastUmbrella) continue;
      if (seen.add(topic)) result.add(topic);
    }
    return result;
  }

  /// Post topics with location umbrella added or stripped.
  ///
  /// Prefer [resolveForLocation]. This Belfast-named API remains for call sites
  /// that only deal with Belfast umbrellas.
  static List<String> resolve({
    required Iterable<String> postTopics,
    required bool includeBelfastUmbrella,
  }) {
    return resolveForLocation(
      postTopics: postTopics,
      locationName: 'Belfast',
      includeLocationUmbrella: includeBelfastUmbrella,
    );
  }

  /// Post topics with [locationName] umbrella added or stripped.
  ///
  /// Non-umbrella topics from [postTopics] are always kept (deduped, order preserved).
  static List<String> resolveForLocation({
    required Iterable<String> postTopics,
    required String locationName,
    required bool includeLocationUmbrella,
  }) {
    final umbrella = NotificationTopics.locationUmbrella(locationName);
    final seen = <String>{};
    final result = <String>[];

    for (final topic in postTopics) {
      if (topic == umbrella) continue;
      // Also strip Belfast umbrella when resolving a non-Belfast location so a
      // mis-copied legacy topic does not leak into another city's audience.
      if (topic == NotificationTopics.belfastUmbrella && umbrella != NotificationTopics.belfastUmbrella) {
        continue;
      }
      if (seen.add(topic)) result.add(topic);
    }

    if (includeLocationUmbrella) {
      result.add(umbrella);
    }

    return result;
  }

  /// Full audience for a post: derived streams (+ optional umbrella).
  static List<String> resolveFromPost({
    required String location,
    required Iterable<String> tagIDs,
    required List<PostTag> allTags,
    required bool includeLocationUmbrella,
    Iterable<String> legacyTopics = const [],
  }) {
    final streams = topicsFromTags(
      location: location,
      tagIDs: tagIDs,
      allTags: allTags,
      legacyTopics: legacyTopics,
    );
    return resolveForLocation(
      postTopics: streams,
      locationName: location,
      includeLocationUmbrella: includeLocationUmbrella,
    );
  }

  /// Human-readable audience list for confirmations and UI.
  static String describe(Iterable<String> topics) {
    final list = topics.toList();
    if (list.isEmpty) return 'No topics selected';
    return list.map(NotificationTopics.labelFor).join(', ');
  }
}
