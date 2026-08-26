import 'package:flutter/material.dart';

import '../models/cell_group.dart';
import '../pages/events/select_catalog_items_page.dart';
import '../src/localization/app_localizations.dart';
import '../utility/catalog_picker_helpers.dart';

/// Multi-select picker for linking bulletin posts / templates to cell groups.
class CellGroupPicker extends StatelessWidget {
  const CellGroupPicker({
    super.key,
    required this.allGroups,
    required this.selectedCellGroupIDs,
    required this.onChanged,
  });

  final List<CellGroup> allGroups;
  final Set<String> selectedCellGroupIDs;
  final void Function(Set<String> selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeGroups = allGroups.where((g) => g.isActive).toList();
    final selectedGroups = _resolveSelectedGroups();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cellGroupsAssignLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.cellGroupsAssignHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            if (activeGroups.isEmpty)
              Text(
                l10n.cellGroupsNoneAvailable,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else ...[
              if (selectedGroups.isEmpty)
                Text(
                  l10n.cellGroupsNoneSelected,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedGroups
                      .map(
                        (group) => Chip(
                          avatar: Icon(
                            Icons.groups,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                          label: Text(group.name),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openPicker(context, l10n),
                icon: const Icon(Icons.groups_outlined, size: 18),
                label: Text(l10n.cellGroupsManage),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<CellGroup> _resolveSelectedGroups() {
    final groupMap = {for (final group in allGroups) group.id: group};
    final resolved = <CellGroup>[];
    for (final id in selectedCellGroupIDs) {
      final group = groupMap[id];
      if (group != null) resolved.add(group);
    }
    resolved.sort((a, b) => a.name.compareTo(b.name));
    return resolved;
  }

  Future<void> _openPicker(BuildContext context, AppLocalizations l10n) async {
    final result = await SelectCatalogItemsPage.open(
      context: context,
      page: SelectCatalogItemsPage(
        title: l10n.cellGroupsSelectTitle,
        searchHint: l10n.cellGroupsSearchHint,
        emptyMessage: l10n.cellGroupsNoneAvailable,
        noResultsMessage: l10n.selectCatalogNoResults,
        allEntries: CatalogPickerHelpers.fromCellGroups(allGroups),
        selectedIds: selectedCellGroupIDs,
        showLocationFilter: true,
      ),
    );
    if (result != null) {
      onChanged(result);
    }
  }
}
