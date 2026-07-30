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

  /// Topics the user opted into via prefs (service toggles + Belfast umbrella).
  static List<String> topicsFromPrefs(AppSharedPreferences prefs) {
    final topics = <String>[];
    for (final topic in NotificationTopics.serviceTopics) {
      if (prefs.isSubscribedToTopic(topic)) {
        topics.add(topic);
      }
    }
    if (prefs.subscribedToBelfast) {
      topics.add(NotificationTopics.belfastUmbrella);
    }
    return topics;
  }

  /// Service + bookmark topics the user should be subscribed to.
  static List<String> allSubscribedTopics(AppSharedPreferences prefs) {
    final topics = topicsFromPrefs(prefs).toList();
    for (final postId in prefs.bookmarkedPosts) {
      topics.add(NotificationTopics.postTopic(postId));
    }
    return topics;
  }

  /// Re-subscribe to every topic implied by prefs and bookmarks.
  Future<NotificationReconcileResult> reconcile({
    required AppSharedPreferences prefs,
    String? webAuthId,
  }) async {
    final topics = allSubscribedTopics(prefs);
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
  }) async {
    if (oldToken.isEmpty || oldToken == newToken) return;

    await _messagingManager.migrateWebTopicToken(
      oldToken: oldToken,
      newToken: newToken,
      topics: allSubscribedTopics(prefs),
    );
  }
}
