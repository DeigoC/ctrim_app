import 'package:flutter/material.dart';

import '../../models/cell_group.dart';
import '../../pages/events/select_catalog_items_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/catalog/catalog_picker_helpers.dart';
import 'catalog_picker_card.dart';

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

    return CatalogPickerCard(
      title: l10n.cellGroupsAssignLabel,
      hint: l10n.cellGroupsAssignHint,
      hasAvailableItems: activeGroups.isNotEmpty,
      noneAvailableMessage: l10n.cellGroupsNoneAvailable,
      noneSelectedMessage: l10n.cellGroupsNoneSelected,
      selectedPreview: selectedGroups.isEmpty
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedGroups
                  .map(
                    (group) => Chip(
                      avatar: Icon(
                        Icons.groups,
                        size: 18,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      label: Text(group.name),
                    ),
                  )
                  .toList(),
            ),
      onManage: () => _openPicker(context, l10n),
      manageLabel: l10n.cellGroupsManage,
      manageIcon: Icons.groups_outlined,
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
