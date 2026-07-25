import 'package:flutter/foundation.dart';

/// Helper class for network image URLs with CORS proxy support for web platform.
///
/// The proxy is only applied for Google Drive hosts. Public image CDNs that
/// already send usable CORS headers are left unchanged.
class NetworkImageHelper {
  static const String _corsProxy =
      'https://ctrim-image-proxy.diegocollado117-729.workers.dev/?url=';

  /// Drive share/download hosts that commonly lack browser-friendly CORS.
  static final RegExp _driveHostPattern = RegExp(
    r'(^|\.)((drive\.google\.com)|(drive\.usercontent\.google\.com))$',
    caseSensitive: false,
  );

  /// Whether [url] should go through the web CORS proxy.
  static bool needsCorsProxy(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    try {
      final host = Uri.parse(trimmed).host;
      return host.isNotEmpty && _driveHostPattern.hasMatch(host);
    } catch (_) {
      return false;
    }
  }

  /// Returns the URL with CORS proxy prefix on web for Drive URLs only.
  /// On other platforms, or for non-Drive URLs, returns the original URL.
  static String getImageUrl(String url) {
    if (kIsWeb && needsCorsProxy(url)) {
      return '$_corsProxy${Uri.encodeComponent(url)}';
    }
    return url;
  }
}
