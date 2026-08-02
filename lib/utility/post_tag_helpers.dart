import 'package:flutter/material.dart';

import '../models/event/event_head.dart';
import '../models/post_tag.dart';
import 'user_tag_helpers.dart';

/// Helpers for resolving and filtering admin-managed post content tags.
class PostTagHelpers {
  PostTagHelpers._();

  static Color? parseColor(final String? hex) => UserTagHelpers.parseColor(hex);

  static List<PostTag> resolveTags({
    required List<String> tagIDs,
    required List<PostTag> allTags,
    bool activeOnly = true,
  }) {
    final tagMap = {for (final tag in allTags) tag.id: tag};
    final resolved = <PostTag>[];
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

  static List<PostTag> tagsForHead({
    required EventHead head,
    required List<PostTag> allTags,
    bool activeOnly = true,
  }) {
    return resolveTags(tagIDs: head.tagIDs, allTags: allTags, activeOnly: activeOnly);
  }

  static bool headMatchesTagFilter({
    required EventHead head,
    required Set<String> selectedTagIDs,
    bool matchAll = false,
  }) {
    if (selectedTagIDs.isEmpty) return true;
    if (matchAll) {
      return selectedTagIDs.every(head.hasTag);
    }
    return head.hasAnyTag(selectedTagIDs);
  }
}
