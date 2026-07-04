import 'package:flutter/foundation.dart';

/// Helper class for network image URLs with CORS proxy support for web platform
class NetworkImageHelper {
  static const String _corsProxy = 'https://hidden-meadow-a566.diegocollado117.workers.dev/?url=';

  /// Returns the URL with CORS proxy prefix if running on web platform
  /// On other platforms, returns the original URL
  static String getImageUrl(String url) {
    if (kIsWeb) {
      return '$_corsProxy${Uri.encodeComponent(url)}';
    }
    return url;
  }
}
