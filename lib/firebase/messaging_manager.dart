import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingManager {
  static final FirebaseMessaging _instance = FirebaseMessaging.instance;
  static const String _ctrimBelfast = 'ctrim-belfast';
  static const String _vapidKey =
      'BA_LUkYRR60mG5nEYSRe4B260xxJFVSYRjxqDksn7DT8u0MvvVUZM6hln9W4acuiY7sbBjLQ3170UJFqiC0J7MI';

  Future<String?> requestPermissionAndToken() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // For web, we need the VAPID key
        final String? token = await _instance.getToken(
          vapidKey: kIsWeb ? _vapidKey : null,
        );
        debugPrint('FCM Token generated: $token');
        return token;
      } else {
        debugPrint('User declined or has not accepted permission');
        return null;
      }
    } catch (e) {
      debugPrint('Error requesting permission and token: $e');
      return null;
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _instance.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      debugPrint('FCM Token retrieved: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  /// Subscribe to the main CTRIM Belfast topic
  /// Note: Topic subscriptions are not supported on web, tokens must be managed server-side
  Future<void> subscribeToCTRIMBelfast() async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions are not supported on web. Use token-based notifications instead.');
      return;
    }
    try {
      await _instance.subscribeToTopic(_ctrimBelfast);
      debugPrint('Subscribed to topic: $_ctrimBelfast');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from the main CTRIM Belfast topic
  Future<void> unsubscribeFromCTRIMBelfast() async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions are not supported on web.');
      return;
    }
    try {
      await _instance.unsubscribeFromTopic(_ctrimBelfast);
      debugPrint('Unsubscribed from topic: $_ctrimBelfast');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe to a custom topic
  Future<void> subscribeToTopic(final String topic) async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions are not supported on web. Use token-based notifications instead.');
      return;
    }
    try {
      await _instance.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a custom topic
  Future<void> unsubscribeFromTopic(final String topic) async {
    if (kIsWeb) {
      debugPrint('Topic subscriptions are not supported on web.');
      return;
    }
    try {
      await _instance.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Listen for token refresh (important for maintaining valid tokens)
  void onTokenRefresh(Function(String) callback) {
    _instance.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      callback(newToken);
    });
  }
}
