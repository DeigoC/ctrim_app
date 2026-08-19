import 'package:flutter/material.dart';

import '../models/catalog_picker_entry.dart';
import '../models/cell_group.dart';
import '../models/post_tag.dart';
import '../src/localization/app_localizations.dart';
import '../utility/notification_topics.dart';
import '../utility/post_tag_helpers.dart';
import '../utility/volunteer_locations.dart';

/// Builds and filters catalog rows for [SelectCatalogItemsPage].
abstract final class CatalogPickerHelpers {
  static List<CatalogPickerEntry> fromPostTags(
    List<PostTag> tags, {
    required AppLocalizations l10n,
  }) {
    return tags.map((tag) {
      final kind = tag.streamKind;
      final kindLabel = kind == null
          ? null
          : (NotificationTopics.serviceTopicLabels[kind] ?? kind);
      final subtitle = kindLabel == null
          ? l10n.managePostTagsNoStream
          : l10n.managePostTagsStreamKindHint(kindLabel);
      return CatalogPickerEntry(
        id: tag.id,
        label: tag.name,
        subtitle: subtitle,
        accentColor: PostTagHelpers.parseColor(tag.color),
        icon: tag.isNotifiable
            ? Icons.notifications_active_outlined
            : Icons.label_outline,
        isActive: tag.isActive,
        isNotifiable: tag.isNotifiable,
        displayOrder: tag.displayOrder,
      );
    }).toList();
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
