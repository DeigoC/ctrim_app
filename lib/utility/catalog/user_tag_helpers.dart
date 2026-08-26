import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/user_tag.dart';

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
    return resolveTags(
        tagIDs: user.tagIDs, allTags: allTags, activeOnly: activeOnly);
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

  /// Surname, then forename (case-insensitive).
  static int compareUsersBySurname(User a, User b) {
    final bySurname =
        a.surname.toLowerCase().compareTo(b.surname.toLowerCase());
    if (bySurname != 0) return bySurname;
    return a.forname.toLowerCase().compareTo(b.forname.toLowerCase());
  }

  /// Primary tag display order, then tag name, then [compareUsersBySurname].
  /// Users without tags sort last.
  static int compareUsersByPrimaryTag(User a, User b, List<UserTag> allTags) {
    const untaggedOrder = 0x7FFFFFFF;
    final tagsA = tagsForUser(user: a, allTags: allTags);
    final tagsB = tagsForUser(user: b, allTags: allTags);
    final orderA = tagsA.isEmpty ? untaggedOrder : tagsA.first.displayOrder;
    final orderB = tagsB.isEmpty ? untaggedOrder : tagsB.first.displayOrder;

    final orderCompare = orderA.compareTo(orderB);
    if (orderCompare != 0) return orderCompare;

    if (tagsA.isNotEmpty && tagsB.isNotEmpty) {
      final nameCompare = tagsA.first.name
          .toLowerCase()
          .compareTo(tagsB.first.name.toLowerCase());
      if (nameCompare != 0) return nameCompare;
    }

    return compareUsersBySurname(a, b);
  }
}
