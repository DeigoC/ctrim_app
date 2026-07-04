import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_tag.dart';

/// Helpers for resolving and styling admin-managed user tags.
class UserTagHelpers {
  UserTagHelpers._();

  static Color? parseColor(final String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  static List<UserTag> resolveTags({
    required List<String> tagIDs,
    required List<UserTag> allTags,
    bool activeOnly = true,
  }) {
    final tagMap = {for (final tag in allTags) tag.id: tag};
    final resolved = <UserTag>[];
    for (final id in tagIDs) {
      final tag = tagMap[id];
      if (tag == null) continue;
      if (activeOnly && !tag.isActive) continue;
      resolved.add(tag);
    }
    resolved.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    return resolved;
  }

  static List<UserTag> tagsForUser({
    required User user,
    required List<UserTag> allTags,
    bool activeOnly = true,
  }) {
    return resolveTags(tagIDs: user.tagIDs, allTags: allTags, activeOnly: activeOnly);
  }

  static bool userMatchesTagFilter({
    required User user,
    required Set<String> selectedTagIDs,
    bool matchAll = false,
  }) {
    if (selectedTagIDs.isEmpty) return true;
    if (matchAll) {
      return selectedTagIDs.every(user.hasTag);
    }
    return user.hasAnyTag(selectedTagIDs);
  }
}
