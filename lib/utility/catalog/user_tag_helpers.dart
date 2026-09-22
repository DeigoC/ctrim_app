import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/user_tag.dart';

/// Helpers for resolving and styling admin-managed user tags.
class UserTagHelpers {
  UserTagHelpers._();

  /// Chip-friendly accents used by the catalog colour picker (not UI chrome).
  static const List<String> presetHexes = [
    '#6B4EAA',
    '#5C6BC0',
    '#3D6B9E',
    '#00838F',
    '#2E7D6F',
    '#4A7C59',
    '#C49A3C',
    '#C45B2C',
    '#B54A6A',
    '#8B5A2B',
    '#6D4C41',
    '#546E7A',
  ];

  static Color? parseColor(final String? hex) {
    if (hex == null) return null;
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }

  static String formatHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static String? normalizeHex(final String? hex) {
    final color = parseColor(hex);
    return color == null ? null : formatHex(color);
  }

  /// First unused palette colour, or the least-used preset if all are taken.
  static String nextPresetHex({Iterable<String?> usedHexes = const []}) {
    final counts = <String, int>{
      for (final hex in presetHexes) hex: 0,
    };
    for (final raw in usedHexes) {
      final hex = normalizeHex(raw);
      if (hex == null) continue;
      counts[hex] = (counts[hex] ?? 0) + 1;
    }
    var best = presetHexes.first;
    var bestCount = counts[best] ?? 0;
    for (final hex in presetHexes.skip(1)) {
      final count = counts[hex] ?? 0;
      if (count < bestCount) {
        best = hex;
        bestCount = count;
      }
    }
    return best;
  }

  static List<UserTag> resolveTags({
    required List<String> tagIDs,
    required List<UserTag> allTags,
    bool activeOnly = true,
    bool visibleToGuestsOnly = false,
  }) {
    final tagMap = {for (final tag in allTags) tag.id: tag};
    final resolved = <UserTag>[];
    for (final id in tagIDs) {
      final tag = tagMap[id];
      if (tag == null) continue;
      if (activeOnly && !tag.isActive) continue;
      if (visibleToGuestsOnly && !tag.visibleToGuests) continue;
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
    bool visibleToGuestsOnly = false,
  }) {
    return resolveTags(
      tagIDs: user.tagIDs,
      allTags: allTags,
      activeOnly: activeOnly,
      visibleToGuestsOnly: visibleToGuestsOnly,
    );
  }

  /// Catalogue rows for the team-tags page.
  ///
  /// Area admins see every tag. Everyone else sees active tags. Guests also
  /// skip tags marked hidden from guests.
  static List<UserTag> browseTags({
    required List<UserTag> allTags,
    required bool isGuest,
    required bool canManage,
  }) {
    final visible = allTags.where((tag) {
      if (canManage) return true;
      if (!tag.isActive) return false;
      if (isGuest && !tag.visibleToGuests) return false;
      return true;
    }).toList();
    visible.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    return visible;
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
  static int compareUsersByPrimaryTag(
    User a,
    User b,
    List<UserTag> allTags, {
    bool visibleToGuestsOnly = false,
  }) {
    const untaggedOrder = 0x7FFFFFFF;
    final tagsA = tagsForUser(
      user: a,
      allTags: allTags,
      visibleToGuestsOnly: visibleToGuestsOnly,
    );
    final tagsB = tagsForUser(
      user: b,
      allTags: allTags,
      visibleToGuestsOnly: visibleToGuestsOnly,
    );
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
