import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

/// Reads and clears notification deep-link query params from the browser URL.
class WebNotificationDeepLink {
  WebNotificationDeepLink._();

  static Map<String, String> consumeLaunchParams() {
    if (!kIsWeb) return const {};

    try {
      final uri = Uri.parse(html.window.location.href);
      final postId = uri.queryParameters['postId'];
      final infoPage = uri.queryParameters['infoPage'];
      if ((postId == null || postId.isEmpty) &&
          (infoPage == null || infoPage.isEmpty)) {
        return const {};
      }

      final cleaned = uri.replace(queryParameters: {});
      html.window.history.replaceState(null, '', cleaned.toString());

      final result = <String, String>{};
      if (postId != null && postId.isNotEmpty) {
        result['PostID'] = postId;
      }
      if (infoPage != null && infoPage.isNotEmpty) {
        result['InfoPage'] = infoPage;
      }
      return result;
    } catch (_) {
      return const {};
    }
  }
}
