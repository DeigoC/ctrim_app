import 'package:flutter/material.dart';

import '../models/catalog_picker_entry.dart';
import '../models/cell_group.dart';
import '../models/post_tag.dart';
import '../utility/post_tag_helpers.dart';
import '../utility/volunteer_locations.dart';

/// Builds and filters catalog rows for [SelectCatalogItemsPage].
abstract final class CatalogPickerHelpers {
  static List<CatalogPickerEntry> fromPostTags(List<PostTag> tags) {
    return tags
        .map(
          (tag) => CatalogPickerEntry(
            id: tag.id,
            label: tag.name,
            accentColor: PostTagHelpers.parseColor(tag.color),
            icon: Icons.label_outline,
            isActive: tag.isActive,
            displayOrder: tag.displayOrder,
          ),
        )
        .toList();
  }

  static List<CatalogPickerEntry> fromCellGroups(List<CellGroup> groups) {
    return groups
        .map(
          (group) => CatalogPickerEntry(
            id: group.id,
            label: group.name,
            subtitle: group.location,
            icon: Icons.groups_outlined,
            location: group.location,
            isActive: group.isActive,
            displayOrder: group.name.toLowerCase().hashCode,
          ),
        )
        .toList();
  }

  static List<String> locationFilterOptions(List<CatalogPickerEntry> entries) {
    final locations = entries
        .where((entry) => entry.isActive && (entry.location?.isNotEmpty ?? false))
        .map((entry) => entry.location!)
        .toSet()
        .toList()
      ..sort();
    return [VolunteerLocations.all, ...locations];
  }

  static List<CatalogPickerEntry> visibleEntries({
    required List<CatalogPickerEntry> allEntries,
    required Set<String> selectedIds,
  }) {
    return allEntries
        .where((entry) => entry.isActive || selectedIds.contains(entry.id))
        .toList();
  }

  static List<CatalogPickerEntry> filterEntries({
    required List<CatalogPickerEntry> entries,
    required String searchQuery,
    String locationFilter = VolunteerLocations.all,
    bool notifiableOnly = false,
  }) {
    final query = searchQuery.trim().toLowerCase();
    final filtered = entries.where((entry) {
      if (notifiableOnly && !entry.isNotifiable) return false;
      if (locationFilter != VolunteerLocations.all &&
          entry.location != locationFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      if (entry.label.toLowerCase().contains(query)) return true;
      final subtitle = entry.subtitle;
      if (subtitle != null && subtitle.toLowerCase().contains(query)) {
        return true;
      }
      return false;
    }).toList();

    filtered.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) return orderCompare;
      return a.label.compareTo(b.label);
    });
    return filtered;
  }
}
