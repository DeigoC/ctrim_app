import 'package:flutter/material.dart';

import '../../models/user_tag.dart';
import '../../src/localization/app_localizations.dart';
import 'catalog_picker_card.dart';
import 'user_tag_chip.dart';

class UserTagPicker extends StatelessWidget {
  const UserTagPicker({
    super.key,
    required this.allTags,
    required this.selectedTagIDs,
    required this.onChanged,
  });

  final List<UserTag> allTags;
  final Set<String> selectedTagIDs;
  final void Function(Set<String> selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeTags = allTags.where((tag) => tag.isActive).toList();

    return CatalogPickerCard(
      title: l10n.userTagsAssignLabel,
      hasAvailableItems: activeTags.isNotEmpty,
      noneAvailableMessage: l10n.userTagsNoneAvailable,
      inlinePicker: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: activeTags.map((tag) {
          final selected = selectedTagIDs.contains(tag.id);
          return UserTagChip(
            tag: tag,
            selected: selected,
            onTap: () {
              final next = Set<String>.from(selectedTagIDs);
              if (selected) {
                next.remove(tag.id);
              } else {
                next.add(tag.id);
              }
              onChanged(next);
            },
          );
        }).toList(),
      ),
    );
  }
}
