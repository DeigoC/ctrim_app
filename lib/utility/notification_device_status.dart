import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase/db_managers/everyone_db_manager.dart';
import '../firebase/messaging_manager.dart';
import 'app_shared_preferences.dart';
import 'notification_debug.dart';
import 'notification_subscription_service.dart';
import 'pwa_install_service.dart';

/// Snapshot of whether this browser/device can receive pushes.
class NotificationDeviceStatus {
  const NotificationDeviceStatus({
    required this.permission,
    required this.hasLocalToken,
    required this.tokenPreview,
    required this.isWeb,
    required this.isPwaInstalled,
    required this.isIosBrowser,
    required this.subscribedTopicCount,
  });

  final AuthorizationStatus permission;
  final bool hasLocalToken;
  final String? tokenPreview;
  final bool isWeb;
  final bool isPwaInstalled;
  final bool isIosBrowser;
  final int subscribedTopicCount;

  bool get permissionGranted =>
      permission == AuthorizationStatus.authorized ||
      permission == AuthorizationStatus.provisional;

  /// iOS Safari/Chrome in a normal tab cannot reliably receive web push.
  bool get needsHomeScreenInstall =>
      isWeb && isIosBrowser && !isPwaInstalled;

  bool get looksHealthy =>
      permissionGranted && hasLocalToken && !needsHomeScreenInstall;

  String get permissionLabel {
    switch (permission) {
      case AuthorizationStatus.authorized:
        return 'Allowed';
      case AuthorizationStatus.provisional:
        return 'Provisional';
      case AuthorizationStatus.denied:
        return 'Blocked';
      case AuthorizationStatus.notDetermined:
        return 'Not asked yet';
    }
  }

  String? get primaryIssue {
    if (needsHomeScreenInstall) {
      return 'On iPhone/iPad, open CTRIM from the Home Screen app '
          '(Add to Home Screen) before enabling notifications.';
    }
    if (!permissionGranted) {
      return permission == AuthorizationStatus.denied
          ? 'Notifications are blocked for this site. Enable them in browser settings.'
          : 'Notification permission has not been granted yet.';
    }
    if (!hasLocalToken) {
      return 'No push token on this device yet. Use Re-register below.';
    }
    return null;
  }
}

/// Probes and repairs push registration for the current device.
class NotificationDeviceStatusService {
  NotificationDeviceStatusService({
    MessagingManager? messagingManager,
    NotificationSubscriptionService? subscriptionService,
    PwaInstallService? pwaInstallService,
    EveryoneDBManager? everyoneDBManager,
  })  : _messagingManager = messagingManager ?? MessagingManager(),
        _subscriptionService =
            subscriptionService ?? NotificationSubscriptionService(),
        _pwa = pwaInstallService ?? PwaInstallService.instance,
        _everyoneDBManager = everyoneDBManager ?? EveryoneDBManager();

  final MessagingManager _messagingManager;
  final NotificationSubscriptionService _subscriptionService;
  final PwaInstallService _pwa;
  final EveryoneDBManager _everyoneDBManager;

  Future<NotificationDeviceStatus> probe({
    required AppSharedPreferences prefs,
    String? webAuthId,
  }) async {
    final settings =
        await FirebaseMessaging.instance.getNotificationSettings();
    final permission = settings.authorizationStatus;

    String? token;
    if (permission == AuthorizationStatus.authorized ||
        permission == AuthorizationStatus.provisional) {
      token = await _messagingManager.getToken(authId: webAuthId);
    }

    final local = prefs.fcmToken;
    final effective = (token != null && token.isNotEmpty) ? token : local;
    final hasToken = effective.isNotEmpty;

    if (token != null && token.isNotEmpty && token != local) {
      prefs.saveFCMToken(token);
    }

    final preview = hasToken
        ? (effective.length > 20
            ? '${effective.substring(0, 20)}…'
            : effective)
        : null;

    return NotificationDeviceStatus(
      permission: permission,
      hasLocalToken: hasToken,
      tokenPreview: preview,
      isWeb: kIsWeb,
      isPwaInstalled: kIsWeb && _pwa.isInstalled,
      isIosBrowser: kIsWeb && _pwa.isIosBrowser,
      subscribedTopicCount:
          NotificationSubscriptionService.topicsFromPrefs(prefs).length,
    );
  }

  /// Requests permission if needed, registers the token, and re-subscribes topics.
  ///
  /// Returns a short user-facing result message.
  Future<String> repairRegistration({
    required AppSharedPreferences prefs,
    required String authId,
    bool requestPermission = true,
  }) async {
    NotificationDebug.section('repairRegistration');

    if (kIsWeb && _pwa.isIosBrowser && !_pwa.isInstalled) {
      return 'On iPhone/iPad, add CTRIM to your Home Screen first, '
          'then open it from there and try again.';
    }

    final webAuthId = kIsWeb && authId.isNotEmpty ? authId : null;
    String? token;

    if (requestPermission) {
      token = await _messagingManager.requestPermissionAndToken(
        authId: webAuthId,
      );
    } else {
      token = await _messagingManager.getToken(authId: webAuthId);
    }

    if (token == null || token.isEmpty) {
      NotificationDebug.warn('repairRegistration: no token');
      return 'Could not get a push token. Check notification permission and try again.';
    }

    prefs.saveFCMToken(token);

    if (!kIsWeb && authId.isNotEmpty) {
      await _everyoneDBManager.addTokenForAuthID(
        authID: authId,
        token: token,
        platform: defaultTargetPlatform.name,
      );
    }

    final result = await _subscriptionService.reconcile(
      prefs: prefs,
      webAuthId: webAuthId,
    );

    if (result.attempted == 0) {
      return 'Token saved, but no topics are enabled yet. Turn on topics above.';
    }
    if (result.failed > 0) {
      return 'Token saved. Subscribed to ${result.succeeded}/${result.attempted} topics '
          '(${result.failed} failed).';
    }
    return 'Token registered and subscribed to ${result.succeeded} topic(s).';
  }

  /// Current device token only (for a self-test push).
  Future<String?> currentDeviceToken({String? webAuthId}) async {
    return _messagingManager.getToken(authId: webAuthId);
  }
}
