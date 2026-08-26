import 'package:flutter/material.dart';

/// Card chrome shared by [UserTagPicker], [PostTagPicker], and [CellGroupPicker].
///
/// Either [inlinePicker] (chip wrap on the card) or a selected preview plus
/// optional manage button that opens [SelectCatalogItemsPage].
class CatalogPickerCard extends StatelessWidget {
  const CatalogPickerCard({
    super.key,
    required this.title,
    required this.hasAvailableItems,
    required this.noneAvailableMessage,
    this.hint,
    this.noneSelectedMessage,
    this.selectedPreview,
    this.inlinePicker,
    this.onManage,
    this.manageLabel,
    this.manageIcon,
  });

  final String title;
  final String? hint;
  final bool hasAvailableItems;
  final String noneAvailableMessage;
  final String? noneSelectedMessage;
  final Widget? selectedPreview;
  final Widget? inlinePicker;
  final VoidCallback? onManage;
  final String? manageLabel;
  final IconData? manageIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (!hasAvailableItems)
              Text(noneAvailableMessage, style: muted)
            else if (inlinePicker != null)
              inlinePicker!
            else ...[
              if (selectedPreview != null)
                selectedPreview!
              else if (noneSelectedMessage != null)
                Text(noneSelectedMessage!, style: muted),
              if (onManage != null && manageLabel != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onManage,
                  icon: Icon(manageIcon ?? Icons.tune, size: 18),
                  label: Text(manageLabel!),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
