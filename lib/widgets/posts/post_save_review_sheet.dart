import 'package:flutter/material.dart';

import '../../utility/post_draft_review.dart';
import '../action_sheet.dart';

/// Advisory bottom sheet shown before saving a new post.
class PostSaveReviewSheet extends StatelessWidget {
  const PostSaveReviewSheet({
    super.key,
    required this.review,
    required this.onNavigateToTab,
    required this.onSave,
    required this.onCancel,
  });

  final PostDraftReview review;
  final ValueChanged<PostDraftReviewTab> onNavigateToTab;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summaryItems = review.items.take(3).toList();
    final detailItems = review.items.skip(3).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ActionSheetShell(
                  icon: Icons.fact_check_outlined,
                  title: 'Ready to save?',
                  subtitle: review.sheetSubtitle,
                  children: [
                    const ActionSheetSectionLabel('Summary'),
                    ...summaryItems.map((item) => _ReviewRow(
                          item: item,
                          onTap: item.isTappable ? () => _onItemTap(context, item) : null,
                        )),
                    const ActionSheetSectionLabel('Details'),
                    ...detailItems.map((item) => _ReviewRow(
                          item: item,
                          onTap: item.isTappable ? () => _onItemTap(context, item) : null,
                        )),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Go back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save post'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTap(BuildContext context, PostDraftReviewItem item) {
    final tab = item.tab;
    if (tab == null) return;
    Navigator.of(context).pop(false);
    onNavigateToTab(tab);
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.item,
    this.onTap,
  });

  final PostDraftReviewItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusStyle = _statusStyle(colorScheme, item.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: statusStyle.background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusStyle.iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusStyle.icon, color: statusStyle.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ReviewStatusStyle _statusStyle(ColorScheme colorScheme, PostDraftReviewStatus status) {
    switch (status) {
      case PostDraftReviewStatus.ready:
        return _ReviewStatusStyle(
          icon: Icons.check_circle_outline,
          iconColor: colorScheme.primary,
          iconBackground: colorScheme.primaryContainer.withValues(alpha: 0.55),
          background: colorScheme.surfaceContainerLow.withValues(alpha: 0.35),
        );
      case PostDraftReviewStatus.suggestion:
        return _ReviewStatusStyle(
          icon: Icons.info_outline,
          iconColor: colorScheme.tertiary,
          iconBackground: colorScheme.tertiaryContainer.withValues(alpha: 0.65),
          background: colorScheme.tertiaryContainer.withValues(alpha: 0.22),
        );
      case PostDraftReviewStatus.info:
        return _ReviewStatusStyle(
          icon: Icons.notifications_active_outlined,
          iconColor: colorScheme.secondary,
          iconBackground: colorScheme.secondaryContainer.withValues(alpha: 0.65),
          background: colorScheme.secondaryContainer.withValues(alpha: 0.22),
        );
    }
  }
}

class _ReviewStatusStyle {
  const _ReviewStatusStyle({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.background,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color background;
}

/// Shows the save review sheet and returns whether the user chose to save.
Future<bool> showPostSaveReviewSheet({
  required BuildContext context,
  required PostDraftReview review,
  required ValueChanged<PostDraftReviewTab> onNavigateToTab,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => PostSaveReviewSheet(
      review: review,
      onNavigateToTab: onNavigateToTab,
      onSave: () => Navigator.of(sheetContext).pop(true),
      onCancel: () => Navigator.of(sheetContext).pop(false),
    ),
  );
  return result ?? false;
}
