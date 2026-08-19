import 'package:flutter/material.dart';

import '../models/post_tag.dart';
import '../pages/events/select_catalog_items_page.dart';
import '../src/localization/app_localizations.dart';
import '../utility/catalog_picker_helpers.dart';
import '../utility/post_tag_helpers.dart';
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
    final selectedTags = PostTagHelpers.resolveTags(
      tagIDs: selectedTagIDs.toList(),
      allTags: allTags,
      activeOnly: false,
    );

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
            else ...[
              if (selectedTags.isEmpty)
                Text(
                  l10n.postTagsNoneSelected,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                PostTagChipRow(tags: selectedTags),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openPicker(context, l10n),
                icon: const Icon(Icons.label_outline, size: 18),
                label: Text(l10n.postTagsManage),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, AppLocalizations l10n) async {
    final result = await SelectCatalogItemsPage.open(
      context: context,
      page: SelectCatalogItemsPage(
        title: l10n.postTagsSelectTitle,
        searchHint: l10n.postTagsSearchHint,
        emptyMessage: l10n.postTagsNoneAvailable,
        noResultsMessage: l10n.selectCatalogNoResults,
        allEntries: CatalogPickerHelpers.fromPostTags(allTags, l10n: l10n),
        selectedIds: selectedTagIDs,
        showNotifiableFilter: true,
        notifiableFilterLabel: l10n.postTagsNotifiableFilter,
      ),
    );
    if (result != null) {
      onChanged(result);
    }
  }
}
