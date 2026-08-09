import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase/db_managers/everyone_db_manager.dart';
import '../firebase/messaging_manager.dart';
import 'app_shared_preferences.dart';
import 'dialog_manager.dart';
import 'notification_subscription_service.dart';
import 'notification_topics.dart';
import 'pwa_install_service.dart';
import 'responsive_layout.dart';
import 'web_notification_lifecycle.dart';

/// Outcome of [NotificationPermissionPrompt.promptAndRegister].
enum NotificationPromptOutcome {
  /// User enabled and a token was obtained.
  enabled,

  /// User tapped Not now on the explainer.
  declined,

  /// iOS Safari without Home Screen install — cannot prompt yet.
  blockedByPwa,

  /// User accepted the explainer but permission/token failed.
  failed,
}

class NotificationPromptResult {
  const NotificationPromptResult({
    required this.outcome,
    this.token,
  });

  final NotificationPromptOutcome outcome;
  final String? token;

  bool get isEnabled =>
      outcome == NotificationPromptOutcome.enabled && token != null;
}

/// In-app soft-ask before the browser/system notification permission prompt.
class NotificationPermissionPrompt {
  NotificationPermissionPrompt._();

  /// Whether the OS/browser has not yet decided on notification permission.
  static Future<bool> isPermissionUndecided() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.notDetermined;
  }

  /// Soft-ask sheet. Returns `true` only when the user taps Enable.
  static Future<bool> showExplainer(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ResponsiveLayout.dialogMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 32,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Stay in the loop',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Get notified about events, announcements, and important '
                    'CTRIM updates. You can choose what to receive anytime under '
                    'Personal → Push Notifications.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Enable notifications'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('Not now'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result == true;
  }

  /// After sign-in / create account: soft-ask only when permission is undecided
  /// and the user has not previously tapped Not now.
  ///
  /// Returns the FCM token when registration succeeds; otherwise `null`.
  static Future<String?> maybePromptAfterAuth({
    required BuildContext context,
    required AppSharedPreferences prefs,
    required String authId,
    bool isGuest = false,
  }) async {
    if (authId.isEmpty && !isGuest) return null;
    if (prefs.hasDeclinedNotificationPrePrompt) return null;
    if (!await isPermissionUndecided()) return null;
    if (!context.mounted) return null;

    final result = await promptAndRegister(
      context: context,
      prefs: prefs,
      authId: authId,
      isGuest: isGuest,
      recordDeclineIfNotNow: true,
    );
    if (!result.isEnabled) return null;

    prefs.setSubscribedToBelfast(true);
    for (final topic in NotificationTopics.serviceTopics) {
      prefs.setSubscribedToTopic(topic, true);
    }
    final webAuthId = kIsWeb && !isGuest && authId.isNotEmpty ? authId : null;
    await NotificationSubscriptionService().reconcile(
      prefs: prefs,
      webAuthId: webAuthId,
    );
    return result.token;
  }

  /// Shows the explainer (unless blocked by iOS Safari without PWA), then
  /// requests permission and registers the token when the user accepts.
  static Future<NotificationPromptResult> promptAndRegister({
    required BuildContext context,
    required AppSharedPreferences prefs,
    required String authId,
    bool isGuest = false,
    bool recordDeclineIfNotNow = false,
  }) async {
    final pwa = PwaInstallService.instance;
    if (kIsWeb && pwa.isIosBrowser && !pwa.isInstalled) {
      await DialogManager.showAlertDialog(
        context: context,
        title: 'Add to Home Screen first',
        content:
            'On iPhone and iPad, web push only works when CTRIM is opened from '
            'the Home Screen. Use Share → Add to Home Screen, open that icon, '
            'then enable notifications.',
        icon: Icons.install_mobile_outlined,
      );
      return const NotificationPromptResult(
        outcome: NotificationPromptOutcome.blockedByPwa,
      );
    }

    if (!context.mounted) {
      return const NotificationPromptResult(
        outcome: NotificationPromptOutcome.failed,
      );
    }
    final shouldProceed = await showExplainer(context);
    if (!shouldProceed) {
      if (recordDeclineIfNotNow) {
        prefs.setHasDeclinedNotificationPrePrompt(true);
      }
      return const NotificationPromptResult(
        outcome: NotificationPromptOutcome.declined,
      );
    }

    if (!context.mounted) {
      return const NotificationPromptResult(
        outcome: NotificationPromptOutcome.failed,
      );
    }
    final token = await registerWithPermission(
      prefs: prefs,
      authId: authId,
      isGuest: isGuest,
    );
    if (token == null) {
      return const NotificationPromptResult(
        outcome: NotificationPromptOutcome.failed,
      );
    }
    return NotificationPromptResult(
      outcome: NotificationPromptOutcome.enabled,
      token: token,
    );
  }

  /// Requests permission and persists the token (no explainer).
  static Future<String?> registerWithPermission({
    required AppSharedPreferences prefs,
    required String authId,
    bool isGuest = false,
  }) async {
    String? token;
    if (kIsWeb) {
      if (authId.isEmpty && !isGuest) return null;
      if (!isGuest && authId.isNotEmpty) {
        token = await WebNotificationLifecycle().register(
          authId: authId,
          requestPermission: true,
          onTokenSaved: prefs.saveFCMToken,
          prefs: prefs,
          webAuthId: authId,
        );
      } else {
        token = await MessagingManager().requestPermissionAndToken(
          authId: authId.isEmpty ? null : authId,
        );
      }
    } else {
      token = await MessagingManager().requestPermissionAndToken();
      if (token != null && authId.isNotEmpty && !isGuest) {
        await EveryoneDBManager().addTokenForAuthID(
          authID: authId,
          token: token,
          platform: Platform.operatingSystem,
        );
      }
    }

    if (token == null || token.isEmpty) return null;

    if (isGuest) {
      prefs.saveGuestFCMToken(token);
    } else {
      prefs.saveFCMToken(token);
    }
    return token;
  }
}
