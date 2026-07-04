import 'package:flutter/foundation.dart';

/// Filter browser/IDE console logs with: [NOTIF]
class NotificationDebug {
  NotificationDebug._();

  static void log(String message) {
    debugPrint('[NOTIF] $message');
  }

  static void section(String title) {
    debugPrint('[NOTIF] ── $title ──');
  }

  static void token(String label, String? token) {
    if (token == null || token.isEmpty) {
      log('$label: (null/empty)');
      return;
    }
    final preview = token.length > 24 ? '${token.substring(0, 24)}…' : token;
    log('$label: $preview (${token.length} chars)');
  }

  static void tokenForManualTest(String? token) {
    if (!kDebugMode || token == null || token.isEmpty) return;
    debugPrint('[NOTIF] COPY_FCM_TOKEN $token');
  }

  static void warn(String message) {
    debugPrint('[NOTIF] ⚠️ $message');
  }

  static void error(String message, [Object? e]) {
    if (e != null) {
      debugPrint('[NOTIF] ❌ $message: $e');
    } else {
      debugPrint('[NOTIF] ❌ $message');
    }
  }
}
