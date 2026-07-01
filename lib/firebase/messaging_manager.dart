import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_debug.dart';

class MessagingManager {
  static final FirebaseMessaging _instance = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _webTokensDoc = 'web_tokens';
  static const String _webTopicsDoc = 'web_topics';
  static const String _vapidKey =
      'BA_LUkYRR60mG5nEYSRe4B260xxJFVSYRjxqDksn7DT8u0MvvVUZM6hln9W4acuiY7sbBjLQ3170UJFqiC0J7MI';

  Future<String?> requestPermissionAndToken({String? authId}) async {
    try {
      final settings = await _instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      NotificationDebug.log('permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _instance.getToken(vapidKey: kIsWeb ? _vapidKey : null);
        if (kIsWeb && token != null && authId != null && authId.isNotEmpty) {
          await registerWebToken(token: token, authId: authId);
        }
        return token;
      }

      NotificationDebug.warn('Notification permission not granted');
      return null;
    } catch (e) {
      NotificationDebug.error('Error requesting permission and token', e);
      return null;
    }
  }

  Future<String?> getToken({String? authId}) async {
    try {
      final token = await _instance.getToken(vapidKey: kIsWeb ? _vapidKey : null);
      if (kIsWeb && token != null && authId != null && authId.isNotEmpty) {
        await registerWebToken(token: token, authId: authId);
      }
      return token;
    } catch (e) {
      NotificationDebug.error('Error getting token', e);
      return null;
    }
  }

  /// Persist web token with auth metadata (replaces legacy flat array-only storage).
  Future<void> registerWebToken({required String token, required String authId}) async {
    if (!kIsWeb) return;

    try {
      final docRef = _firestore.collection('notification_tokens').doc(_webTokensDoc);
      final doc = await docRef.get();
      final existing = _parseTokenEntries(doc.data());

      final staleDeletes = <String, dynamic>{};
      for (final entry in existing.entries) {
        if (entry.value['authId'] == authId && entry.key != token) {
          staleDeletes[entry.key] = FieldValue.delete();
        }
      }

      if (staleDeletes.isNotEmpty) {
        await docRef.set({'entries': staleDeletes}, SetOptions(merge: true));
      }

      await docRef.set(
        {
          'entries': {
            token: {
              'authId': authId,
              'lastActive': FieldValue.serverTimestamp(),
            },
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      NotificationDebug.log('Registered web token for authId=$authId');
      NotificationDebug.token('saved', token);
      NotificationDebug.tokenForManualTest(token);
    } catch (e) {
      NotificationDebug.error('Error registering web token', e);
    }
  }

  Future<void> removeWebToken(String token) async {
    if (!kIsWeb) return;

    try {
      await _firestore.collection('notification_tokens').doc(_webTokensDoc).set({
        'entries': {token: FieldValue.delete()},
      }, SetOptions(merge: true));

      await _removeTokenFromAllWebTopics(token);
      NotificationDebug.log('Removed web token from notification_tokens');
    } catch (e) {
      NotificationDebug.error('Error removing web token', e);
    }
  }

  Future<void> _removeTokenFromAllWebTopics(String token) async {
    try {
      final doc = await _firestore.collection('notification_tokens').doc(_webTopicsDoc).get();
      if (!doc.exists || doc.data() == null) return;

      final updates = <String, dynamic>{};
      for (final entry in doc.data()!.entries) {
        if (entry.value is List && (entry.value as List).contains(token)) {
          updates[entry.key] = FieldValue.arrayRemove([token]);
        }
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('notification_tokens').doc(_webTopicsDoc).update(updates);
      }
    } catch (e) {
      NotificationDebug.warn('Could not remove token from web_topics: $e');
    }
  }

  Future<void> subscribeToTopic(final String topic, {String? authId}) async {
    if (kIsWeb) {
      final token = await getToken(authId: authId);
      if (token == null) return;

      try {
        await _firestore.collection('notification_tokens').doc(_webTopicsDoc).set({
          topic: FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));
        NotificationDebug.log('Web subscribed to topic "$topic" (Firestore web_topics)');
      } catch (e) {
        NotificationDebug.error('Error subscribing to web topic', e);
      }
      return;
    }

    try {
      await _instance.subscribeToTopic(topic);
      NotificationDebug.log('Subscribed to FCM topic: $topic');
    } catch (e) {
      NotificationDebug.error('Error subscribing to topic', e);
    }
  }

  Future<void> unsubscribeFromTopic(final String topic, {String? authId}) async {
    if (kIsWeb) {
      final token = await _instance.getToken(vapidKey: _vapidKey);
      if (token == null) return;

      try {
        await _firestore.collection('notification_tokens').doc(_webTopicsDoc).update({
          topic: FieldValue.arrayRemove([token]),
        });
        NotificationDebug.log('Web unsubscribed from topic "$topic"');
      } catch (e) {
        NotificationDebug.error('Error unsubscribing from web topic', e);
      }
      return;
    }

    try {
      await _instance.unsubscribeFromTopic(topic);
    } catch (e) {
      NotificationDebug.error('Error unsubscribing from topic', e);
    }
  }

  void listenForTokenRefresh({required String authId, required void Function(String) onRefreshed}) {
    _instance.onTokenRefresh.listen((newToken) async {
      NotificationDebug.section('onTokenRefresh');
      NotificationDebug.token('new token', newToken);

      if (kIsWeb) {
        await registerWebToken(token: newToken, authId: authId);
      }

      onRefreshed(newToken);
    });
  }

  static Future<List<String>> getWebTokensForTopic(String topic) async {
    try {
      final topicDoc = await _firestore.collection('notification_tokens').doc(_webTopicsDoc).get();
      final topicTokens = <String>{};

      if (topicDoc.exists && topicDoc.data() != null) {
        topicTokens.addAll(List<String>.from(topicDoc.data()![topic] ?? []));
      }

      final deduped = topicTokens.toList();
      NotificationDebug.log('Topic "$topic" → ${deduped.length} web token(s)');
      return deduped;
    } catch (e) {
      NotificationDebug.error('Error getting web tokens for topic', e);
      return [];
    }
  }

  static Future<List<String>> getWebTokensForAuthId(String authId) async {
    try {
      final doc = await _firestore.collection('notification_tokens').doc(_webTokensDoc).get();
      final entries = _parseTokenEntries(doc.data());
      final tokens = _oneLatestTokenPerAuthId(entries, authId: authId);
      return tokens;
    } catch (e) {
      NotificationDebug.error('Error getting web tokens for authId', e);
      return [];
    }
  }

  static Map<String, Map<String, dynamic>> _parseTokenEntries(Map<String, dynamic>? data) {
    if (data == null) return {};

    final parsed = <String, Map<String, dynamic>>{};

    final nested = data['entries'];
    if (nested is Map) {
      for (final entry in nested.entries) {
        if (entry.value is Map) {
          parsed[entry.key.toString()] = Map<String, dynamic>.from(entry.value as Map);
        }
      }
    }

    // Legacy flat array — no authId metadata; kept for reads until migrated.
    final legacy = data['tokens'];
    if (legacy is List) {
      for (final raw in legacy) {
        final token = raw.toString();
        parsed.putIfAbsent(token, () => {});
      }
    }

    return parsed;
  }

  static List<String> _oneLatestTokenPerAuthId(
    Map<String, Map<String, dynamic>> entries, {
    String? authId,
  }) {
    if (authId != null) {
      String? bestToken;
      DateTime bestActive = DateTime.fromMillisecondsSinceEpoch(0);

      for (final entry in entries.entries) {
        if (entry.value['authId'] != authId) continue;
        final lastActive = (entry.value['lastActive'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        if (bestToken == null || lastActive.isAfter(bestActive)) {
          bestToken = entry.key;
          bestActive = lastActive;
        }
      }
      return bestToken == null ? [] : [bestToken];
    }

    final latestByAuth = <String, ({String token, DateTime lastActive})>{};
    final withoutAuth = <String>[];

    for (final entry in entries.entries) {
      final userAuth = entry.value['authId'];
      if (userAuth is! String || userAuth.isEmpty) {
        withoutAuth.add(entry.key);
        continue;
      }

      final lastActive = (entry.value['lastActive'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final current = latestByAuth[userAuth];
      if (current == null || lastActive.isAfter(current.lastActive)) {
        latestByAuth[userAuth] = (token: entry.key, lastActive: lastActive);
      }
    }

    return [...withoutAuth, ...latestByAuth.values.map((pick) => pick.token)];
  }
}
