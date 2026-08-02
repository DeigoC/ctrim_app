import 'package:flutter/material.dart';

import '../models/post_tag.dart';
import '../src/localization/app_localizations.dart';
import 'post_tag_chip.dart';

class PostTagPicker extends StatelessWidget {
  const PostTagPicker({
    super.key,
    required this.allTags,
    required this.selectedTagIDs,
    required this.onChanged,
  });

  final List<PostTag> allTags;
  final Set<String> selectedTagIDs;
  final void Function(Set<String> selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeTags = allTags.where((tag) => tag.isActive).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.postTagsAssignLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (activeTags.isEmpty)
              Text(
                l10n.postTagsNoneAvailable,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeTags.map((tag) {
                  final selected = selectedTagIDs.contains(tag.id);
                  return PostTagChip(
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
          ],
        ),
      ),
    );
  }
}
