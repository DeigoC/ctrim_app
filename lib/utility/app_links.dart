import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/event/event_head.dart';

/// Public permalinks and in-app post navigation.
///
/// Path URLs (`/post/:id`) are the shareable form. Legacy `?postId=` query
/// params still redirect here. Editors and other screens stay on [Navigator.push].
class AppLinks {
  AppLinks._();

  static const String webOrigin = 'https://ctrim.app';
  static const String postPathPrefix = '/post/';

  static String postPath(String id) =>
      '$postPathPrefix${Uri.encodeComponent(id)}';

  static String postUrl(String id) => '$webOrigin${postPath(id)}';

  /// Maps a browser URI with `?postId=` to `/post/:id`, or null if none.
  static String? redirectFromUri(Uri uri) {
    final postId = uri.queryParameters['postId'];
    if (postId == null || postId.isEmpty) return null;
    return postPath(postId);
  }

  static Future<T?> openPost<T extends Object?>(
    BuildContext context, {
    required String id,
    EventHead? extra,
  }) {
    return context.push<T>(postPath(id), extra: extra);
  }
}
