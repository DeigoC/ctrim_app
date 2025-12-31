import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingManager {
  static final FirebaseMessaging _instance = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

        // Register token in Firestore if on web
        if (kIsWeb && token != null) {
          await _registerWebToken(token);
        }

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

      // Register token in Firestore if on web
      if (kIsWeb && token != null) {
        await _registerWebToken(token);
      }

      return token;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  /// Register web token in a centralized collection for efficient batch sending
  Future<void> _registerWebToken(String token) async {
    try {
      // Store in a map structure for O(1) lookups and efficient storage
      await _firestore.collection('notification_tokens').doc('web_tokens').set({
        'tokens': FieldValue.arrayUnion([token]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Web token registered in centralized collection');
    } catch (e) {
      debugPrint('❌ Error registering web token: $e');
    }
  }

  /// Remove web token when user logs out or revokes permission
  Future<void> removeWebToken(String token) async {
    if (!kIsWeb) return;

    try {
      await _firestore.collection('notification_tokens').doc('web_tokens').update({
        'tokens': FieldValue.arrayRemove([token]),
      });

      debugPrint('🗑️ Web token removed from centralized collection');
    } catch (e) {
      debugPrint('❌ Error removing web token: $e');
    }
  }

  /// Subscribe to the main CTRIM Belfast topic
  /// Note: Topic subscriptions are not supported on web, tokens must be managed server-side
  Future<void> subscribeToCTRIMBelfast() async {
    if (kIsWeb) {
      debugPrint('ℹ️ Web platform detected - using token-based notifications (topic subscriptions not supported)');
      // Web tokens are automatically registered in _registerWebToken()
      // Do NOT call removeWebToken here!
      return;
    }
    try {
      await _instance.subscribeToTopic(_ctrimBelfast);
      debugPrint('✅ Subscribed to topic: $_ctrimBelfast');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from the main CTRIM Belfast topic
  Future<void> unsubscribeFromCTRIMBelfast() async {
    if (kIsWeb) {
      debugPrint('ℹ️ Unsubscribing from web notifications');
      // Remove web token from collection
      final token = await getToken();
      if (token != null) {
        await removeWebToken(token);
      }
      return;
    }
    try {
      await _instance.unsubscribeFromTopic(_ctrimBelfast);
      debugPrint('✅ Unsubscribed from topic: $_ctrimBelfast');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe to a custom topic
  Future<void> subscribeToTopic(final String topic) async {
    if (kIsWeb) {
      // For web, store the token in a topic-specific collection
      final token = await getToken();
      if (token != null) {
        try {
          await _firestore.collection('notification_tokens').doc('web_topics').set({
            topic: FieldValue.arrayUnion([token]),
          }, SetOptions(merge: true));
          debugPrint('✅ Web user subscribed to topic: $topic');
        } catch (e) {
          debugPrint('❌ Error subscribing to web topic: $e');
        }
      }
      return;
    }
    try {
      await _instance.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a custom topic
  Future<void> unsubscribeFromTopic(final String topic) async {
    if (kIsWeb) {
      // For web, remove the token from the topic-specific collection
      final token = await getToken();
      if (token != null) {
        try {
          await _firestore.collection('notification_tokens').doc('web_topics').update({
            topic: FieldValue.arrayRemove([token]),
          });
          debugPrint('✅ Web user unsubscribed from topic: $topic');
        } catch (e) {
          debugPrint('❌ Error unsubscribing from web topic: $e');
        }
      }
      return;
    }
    try {
      await _instance.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Listen for token refresh (important for maintaining valid tokens)
  void onTokenRefresh(Function(String) callback) {
    _instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');

      // Update web token in Firestore
      if (kIsWeb) {
        _registerWebToken(newToken);
      }

      callback(newToken);
    });
  }

  /// Get all web tokens for sending notifications (used by admin/cloud functions)
  static Future<List<String>> getWebTokens() async {
    try {
      final doc = await _firestore.collection('notification_tokens').doc('web_tokens').get();

      if (doc.exists && doc.data() != null) {
        final tokens = List<String>.from(doc.data()!['tokens'] ?? []);
        debugPrint('📱 Retrieved ${tokens.length} web tokens');
        return tokens;
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error getting web tokens: $e');
      return [];
    }
  }

  /// Get web tokens subscribed to a specific topic (used by admin/cloud functions)
  static Future<List<String>> getWebTokensForTopic(String topic) async {
    try {
      final doc = await _firestore.collection('notification_tokens').doc('web_topics').get();

      if (doc.exists && doc.data() != null) {
        final tokens = List<String>.from(doc.data()![topic] ?? []);
        debugPrint('📱 Retrieved ${tokens.length} web tokens for topic: $topic');
        return tokens;
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error getting web tokens for topic: $e');
      return [];
    }
  }
}
