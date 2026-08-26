import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../firebase/db_managers/everyone_db_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../app_shared_preferences.dart';
import 'notification_debug.dart';
import 'notification_subscription_service.dart';

/// Registers and refreshes web FCM tokens in Firestore + everyone/device_tokens.
class WebNotificationLifecycle {
  final MessagingManager _messagingManager = MessagingManager();
  final EveryoneDBManager _everyoneDBManager = EveryoneDBManager();
  final NotificationSubscriptionService _subscriptionService =
      NotificationSubscriptionService();

  Future<String?> register({
    required String authId,
    bool requestPermission = false,
    void Function(String token)? onTokenSaved,
    AppSharedPreferences? prefs,
    String? webAuthId,
  }) async {
    if (!kIsWeb || authId.isEmpty) return null;

    try {
      NotificationDebug.section('WebNotificationLifecycle.register');

      String? token;
      if (requestPermission) {
        token =
            await _messagingManager.requestPermissionAndToken(authId: authId);
      } else {
        final settings =
            await FirebaseMessaging.instance.getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) {
          NotificationDebug.warn('Web notification permission not granted');
          return null;
        }
        token = await _messagingManager.getToken(authId: authId);
      }

      if (token != null) {
        await _syncToEveryone(
            authId: authId, token: token, onTokenSaved: onTokenSaved);
        if (prefs != null) {
          await _subscriptionService.reconcile(
              prefs: prefs, webAuthId: webAuthId ?? authId);
        }
      }
      return token;
    } catch (e) {
      NotificationDebug.error('Web token registration failed', e);
      return null;
    }
  }

  void listenForTokenRefresh({
    required String authId,
    void Function(String token)? onTokenSaved,
    AppSharedPreferences? prefs,
    String? webAuthId,
  }) {
    if (!kIsWeb) return;

    _messagingManager.listenForTokenRefresh(
      authId: authId,
      onRefreshed: (token) async {
        final previousToken = prefs?.fcmToken ?? '';
        if (prefs != null &&
            previousToken.isNotEmpty &&
            previousToken != token) {
          await _subscriptionService.migrateWebTopicsAfterTokenRefresh(
            oldToken: previousToken,
            newToken: token,
            prefs: prefs,
          );
        }
        await _syncToEveryone(
            authId: authId, token: token, onTokenSaved: onTokenSaved);
        if (prefs != null) {
          await _subscriptionService.reconcile(
              prefs: prefs, webAuthId: webAuthId ?? authId);
        }
      },
    );
  }

  Future<void> unregister(
      {required String authId, required String token}) async {
    if (!kIsWeb) return;

    NotificationDebug.section('WebNotificationLifecycle.unregister');
    await _messagingManager.removeWebToken(token);
    await _everyoneDBManager.removeTokenForAuthID(authId, token);
  }

  Future<void> _syncToEveryone({
    required String authId,
    required String token,
    void Function(String token)? onTokenSaved,
  }) async {
    await _everyoneDBManager.addTokenForAuthID(
        authID: authId, token: token, platform: 'Web');
    onTokenSaved?.call(token);
    NotificationDebug.log(
        'Token synced to notification_tokens and everyone/device_tokens');
  }
}
