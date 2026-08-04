import 'package:flutter/material.dart';

import '../models/cell_group.dart';
import '../src/localization/app_localizations.dart';

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
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeGroups.map((group) {
                  final selected = selectedCellGroupIDs.contains(group.id);
                  return FilterChip(
                    avatar: Icon(
                      Icons.groups,
                      size: 18,
                      color: selected
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    label: Text(group.name),
                    selected: selected,
                    onSelected: (_) {
                      final next = Set<String>.from(selectedCellGroupIDs);
                      if (selected) {
                        next.remove(group.id);
                      } else {
                        next.add(group.id);
                      }
                      onChanged(next);
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
