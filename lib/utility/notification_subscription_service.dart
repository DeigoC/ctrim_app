import '../firebase/messaging_manager.dart';
import 'app_shared_preferences.dart';
import 'notification_debug.dart';
import 'notification_topics.dart';

/// Outcome of aligning topic subscriptions with local prefs.
class NotificationReconcileResult {
  const NotificationReconcileResult({
    this.attempted = 0,
    this.succeeded = 0,
    this.failed = 0,
  });

  final int attempted;
  final int succeeded;
  final int failed;
}

/// Keeps FCM / Firestore web topic subscriptions aligned with local prefs.
class NotificationSubscriptionService {
  final MessagingManager _messagingManager = MessagingManager();

  /// Location umbrella topics the user opted into via prefs.
  static List<String> topicsFromPrefs(
    AppSharedPreferences prefs, {
    Iterable<String> locationNames = const ['Belfast'],
  }) {
    final topics = <String>[];
    final seen = <String>{};

    for (final location in locationNames) {
      final umbrella = NotificationTopics.locationUmbrella(location);
      final umbrellaOn = umbrella == NotificationTopics.belfastUmbrella
          ? prefs.subscribedToBelfast
          : prefs.isSubscribedToTopic(umbrella);
      if (umbrellaOn && seen.add(umbrella)) {
        topics.add(umbrella);
      }
    }

    return topics;
  }

  /// Location umbrellas + bookmark topics the user should be subscribed to.
  static List<String> allSubscribedTopics(
    AppSharedPreferences prefs, {
    Iterable<String> locationNames = const ['Belfast'],
  }) {
    final topics = topicsFromPrefs(
      prefs,
      locationNames: locationNames,
    ).toList();
    for (final postId in prefs.bookmarkedPosts) {
      topics.add(NotificationTopics.postTopic(postId));
    }
    return topics;
  }

  /// Re-subscribe to every topic implied by prefs and bookmarks.
  Future<NotificationReconcileResult> reconcile({
    required AppSharedPreferences prefs,
    String? webAuthId,
    Iterable<String> locationNames = const ['Belfast'],
  }) async {
    final topics = allSubscribedTopics(
      prefs,
      locationNames: locationNames,
    );
    var succeeded = 0;
    var failed = 0;

    for (final topic in topics) {
      final ok =
          await _messagingManager.subscribeToTopic(topic, authId: webAuthId);
      if (ok) {
        succeeded++;
      } else {
        failed++;
        NotificationDebug.warn('reconcile: failed to subscribe to $topic');
      }
    }

    return NotificationReconcileResult(
      attempted: topics.length,
      succeeded: succeeded,
      failed: failed,
    );
  }

  /// After a web FCM token refresh, move topic memberships to the new token.
  Future<void> migrateWebTopicsAfterTokenRefresh({
    required String oldToken,
    required String newToken,
    required AppSharedPreferences prefs,
    Iterable<String> locationNames = const ['Belfast'],
  }) async {
    if (oldToken.isEmpty || oldToken == newToken) return;

    await _messagingManager.migrateWebTopicToken(
      oldToken: oldToken,
      newToken: newToken,
      topics: allSubscribedTopics(
        prefs,
        locationNames: locationNames,
      ),
    );
  }
}
