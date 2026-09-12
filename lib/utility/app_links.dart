import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/event/event_head.dart';
import '../models/user.dart';

/// Public permalinks and in-app navigation for shareable records.
///
/// Path URLs are the shareable form. Legacy `?postId=` / `?infoPage=` query
/// params still redirect here. Editors and other screens stay on [Navigator.push].
class AppLinks {
  AppLinks._();

  static const String webOrigin = 'https://ctrim.app';

  static const Map<String, String> _legacyInfoIds = {
    'assets/info/ctrim_info/core_values.json': 'core_values',
    'assets/info/ctrim_info/4xd.json': '4xd',
    'assets/info/ctrim_info/cell_group.json': 'cell_group',
    'assets/info/ctrim_info/devotionals.json': 'devotionals',
  };

  static String _seg(String id) => Uri.encodeComponent(id);

  static String postPath(String id) => '/post/${_seg(id)}';

  static String cellGroupPath(String id) => '/cell-groups/${_seg(id)}';

  static String churchPath(String id) => '/churches/${_seg(id)}';

  static String churchPagePath(String churchId, String pageId) =>
      '${churchPath(churchId)}/pages/${_seg(pageId)}';

  static String churchPastorsPath(String churchId) =>
      '${churchPath(churchId)}/pastors';

  static String infoPath(String id) => '/info/${_seg(id)}';

  static String testimonialPath(String id) => '/testimonials/${_seg(id)}';

  static String personPath(String id) => '/people/${_seg(id)}';

  static String postUrl(String id) => '$webOrigin${postPath(id)}';

  static String cellGroupUrl(String id) => '$webOrigin${cellGroupPath(id)}';

  static String churchUrl(String id) => '$webOrigin${churchPath(id)}';

  static String infoUrl(String id) => '$webOrigin${infoPath(id)}';

  static String testimonialUrl(String id) => '$webOrigin${testimonialPath(id)}';

  static String personUrl(String id) => '$webOrigin${personPath(id)}';

  /// Maps legacy JSON asset paths (and current document ids) to `/info/:id`.
  static String infoDocumentIdFromPayload(String rawValue) {
    return _legacyInfoIds[rawValue] ?? rawValue;
  }

  /// Maps a browser URI with `?postId=` / `?infoPage=` to a path, or null.
  static String? redirectFromUri(Uri uri) {
    final postId = uri.queryParameters['postId'];
    if (postId != null && postId.isNotEmpty) {
      return postPath(postId);
    }
    final infoPage = uri.queryParameters['infoPage'];
    if (infoPage != null && infoPage.isNotEmpty) {
      return infoPath(infoDocumentIdFromPayload(infoPage));
    }
    return null;
  }

  static Future<T?> openPost<T extends Object?>(
    BuildContext context, {
    required String id,
    EventHead? extra,
  }) {
    return context.push<T>(postPath(id), extra: extra);
  }

  static Future<T?> openCellGroup<T extends Object?>(
    BuildContext context, {
    required String id,
  }) {
    return context.push<T>(cellGroupPath(id));
  }

  static Future<T?> openChurch<T extends Object?>(
    BuildContext context, {
    required String id,
  }) {
    return context.push<T>(churchPath(id));
  }

  static Future<T?> openChurchPage<T extends Object?>(
    BuildContext context, {
    required String churchId,
    required String pageId,
  }) {
    return context.push<T>(churchPagePath(churchId, pageId));
  }

  static Future<T?> openChurchPastors<T extends Object?>(
    BuildContext context, {
    required String churchId,
  }) {
    return context.push<T>(churchPastorsPath(churchId));
  }

  static Future<T?> openInfo<T extends Object?>(
    BuildContext context, {
    required String id,
  }) {
    return context.push<T>(infoPath(infoDocumentIdFromPayload(id)));
  }

  static Future<T?> openTestimonial<T extends Object?>(
    BuildContext context, {
    required String id,
  }) {
    return context.push<T>(testimonialPath(id));
  }

  static Future<T?> openPerson<T extends Object?>(
    BuildContext context, {
    required String id,
    User? extra,
  }) {
    return context.push<T>(personPath(id), extra: extra);
  }
}
