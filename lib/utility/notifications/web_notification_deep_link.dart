import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

/// Reads and clears notification deep-link query params from the browser URL,
/// and unwraps FCM click payloads (`FCM_MSG.data`).
class WebNotificationDeepLink {
  WebNotificationDeepLink._();

  static const String openKindPost = 'post';
  static const String openKindInfo = 'info';

  static bool _nonEmpty(Map<String, dynamic> data, String key) {
    final value = data[key]?.toString() ?? '';
    return value.isNotEmpty;
  }

  static Map<String, dynamic> _stringKeyed(Map<dynamic, dynamic> raw) {
    return {
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    };
  }

  static bool hasNavigableTarget(Map<String, dynamic> data) {
    return _nonEmpty(data, 'PostID') || _nonEmpty(data, 'InfoPage');
  }

  /// `post`, `info`, or null when the payload has no page to open.
  static String? openActionKind(Map<String, dynamic> data) {
    if (_nonEmpty(data, 'PostID')) return openKindPost;
    if (_nonEmpty(data, 'InfoPage')) return openKindInfo;
    return null;
  }

  /// Unwraps FCM's `FCM_MSG` envelope so `PostID` / `InfoPage` sit at the top
  /// level. Native `RemoteMessage.data` is already flat.
  static Map<String, dynamic> extractAppData(Map<dynamic, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const {};

    final asStringKeys = _stringKeyed(raw);
    if (hasNavigableTarget(asStringKeys)) {
      return asStringKeys;
    }

    final fcm = asStringKeys['FCM_MSG'];
    if (fcm is Map) {
      final fcmMap = _stringKeyed(fcm);
      final nested = fcmMap['data'];
      if (nested is Map) {
        final dataMap = _stringKeyed(nested);
        if (hasNavigableTarget(dataMap)) return dataMap;
      }
      if (hasNavigableTarget(fcmMap)) return fcmMap;
    }
    return asStringKeys;
  }

  /// Maps URL query params (`postId`, `infoPage`) to FCM-style data keys.
  static Map<String, String> paramsFromQuery(Map<String, String> query) {
    final result = <String, String>{};
    final postId = query['postId'];
    final infoPage = query['infoPage'];
    if (postId != null && postId.isNotEmpty) {
      result['PostID'] = postId;
    }
    if (infoPage != null && infoPage.isNotEmpty) {
      result['InfoPage'] = infoPage;
    }
    return result;
  }

  /// Path the service worker opens on a cold-start click (`/?postId=` …).
  static String pathFromData(Map<String, dynamic> data) {
    final appData = extractAppData(data);
    final postId = appData['PostID']?.toString() ?? '';
    if (postId.isNotEmpty) {
      return '/?postId=${Uri.encodeComponent(postId)}';
    }
    final infoPage = appData['InfoPage']?.toString() ?? '';
    if (infoPage.isNotEmpty) {
      return '/?infoPage=${Uri.encodeComponent(infoPage)}';
    }
    return '/';
  }

  static Map<String, String> consumeLaunchParams() {
    if (!kIsWeb) return const {};

    try {
      final uri = Uri.parse(html.window.location.href);
      final mapped = paramsFromQuery(uri.queryParameters);
      if (mapped.isEmpty) return const {};

      final cleaned = uri.replace(queryParameters: {});
      html.window.history.replaceState(null, '', cleaned.toString());
      return mapped;
    } catch (_) {
      return const {};
    }
  }
}
