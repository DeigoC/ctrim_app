import 'package:flutter/material.dart';

import '../models/post_tag.dart';
import '../pages/events/select_catalog_items_page.dart';
import '../src/localization/app_localizations.dart';
import '../utility/catalog_picker_helpers.dart';
import '../utility/post_tag_helpers.dart';
import 'catalog_picker_card.dart';
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

    return CatalogPickerCard(
      title: l10n.postTagsAssignLabel,
      hasAvailableItems: activeTags.isNotEmpty,
      noneAvailableMessage: l10n.postTagsNoneAvailable,
      noneSelectedMessage: l10n.postTagsNoneSelected,
      selectedPreview:
          selectedTags.isEmpty ? null : PostTagChipRow(tags: selectedTags),
      onManage: () => _openPicker(context, l10n),
      manageLabel: l10n.postTagsManage,
      manageIcon: Icons.label_outline,
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
        allEntries: CatalogPickerHelpers.fromPostTags(allTags),
        selectedIds: selectedTagIDs,
      ),
    );
    if (result != null) {
      onChanged(result);
    }
  }
}
