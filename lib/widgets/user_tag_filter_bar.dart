import 'package:flutter/material.dart';

import '../models/user_tag.dart';
import '../src/localization/app_localizations.dart';
import 'user_tag_chip.dart';

class UserTagFilterBar extends StatelessWidget {
  const UserTagFilterBar({
    super.key,
    required this.tags,
    required this.selectedTagIDs,
    required this.onSelectionChanged,
    this.horizontalPadding = 0,
  });

  final List<UserTag> tags;
  final Set<String> selectedTagIDs;
  final void Function(Set<String> selected) onSelectionChanged;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final activeTags = tags.where((tag) => tag.isActive).toList();
    if (activeTags.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: Row(
        children: [
          if (selectedTagIDs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(l10n.userTagsFilterClear),
                onPressed: () => onSelectionChanged({}),
              ),
            ),
          ...activeTags.map((tag) {
            final selected = selectedTagIDs.contains(tag.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UserTagChip(
                tag: tag,
                selected: selected,
                onTap: () {
                  final next = Set<String>.from(selectedTagIDs);
                  if (selected) {
                    next.remove(tag.id);
                  } else {
                    next.add(tag.id);
                  }
                  onSelectionChanged(next);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
