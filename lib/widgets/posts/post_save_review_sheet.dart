import 'package:flutter/material.dart';

import '../../utility/post_draft_review.dart';
import '../../utility/responsive_layout.dart';
import '../action_sheet.dart';
import '../app_dialog.dart';

/// Advisory confirmation shown before saving a new post.
class PostSaveReviewSheet extends StatelessWidget {
  const PostSaveReviewSheet({
    super.key,
    required this.review,
    required this.onNavigateToTab,
    required this.onSave,
    required this.onCancel,
    this.asDialog = false,
  });

  final PostDraftReview review;
  final ValueChanged<PostDraftReviewTab> onNavigateToTab;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool asDialog;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final suggestions = review.suggestionItems;
    final infos = review.infoItems;
    final readies = review.readyItems;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: ActionSheetShell(
              icon: Icons.fact_check_outlined,
              title: 'Ready to save?',
              subtitle: review.sheetSubtitle,
              scrollable: false,
              decorateSurface: false,
              children: [
                if (suggestions.isNotEmpty) ...[
                  const ActionSheetSectionLabel('Still optional'),
                  ...suggestions.map((item) => _ReviewRow(
                        item: item,
                        onTap: item.isTappable
                            ? () => _onItemTap(context, item)
                            : null,
                      )),
                ],
                if (infos.isNotEmpty) ...[
                  const ActionSheetSectionLabel('Notifications'),
                  ...infos.map((item) => _ReviewRow(
                        item: item,
                        onTap: item.isTappable
                            ? () => _onItemTap(context, item)
                            : null,
                      )),
                ],
                if (readies.isNotEmpty)
                  _ReadySection(
                    items: readies,
                    initiallyExpanded: suggestions.isEmpty,
                    onItemTap: (item) => _onItemTap(context, item),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, asDialog ? 20 : 16),
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
    );

    if (asDialog) {
      return Material(
        color: colorScheme.surface,
        child: body,
      );
    }

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
        child: body,
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

class _ReadySection extends StatefulWidget {
  const _ReadySection({
    required this.items,
    required this.initiallyExpanded,
    required this.onItemTap,
  });

  final List<PostDraftReviewItem> items;
  final bool initiallyExpanded;
  final ValueChanged<PostDraftReviewItem> onItemTap;

  @override
  State<_ReadySection> createState() => _ReadySectionState();
}

class _ReadySectionState extends State<_ReadySection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = widget.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'LOOKING GOOD · $count',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded)
          ...widget.items.map((item) => _ReviewRow(
                item: item,
                onTap: item.isTappable ? () => widget.onItemTap(item) : null,
              )),
      ],
    );
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
                  child: Icon(statusStyle.icon,
                      color: statusStyle.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
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
                  Icon(Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ReviewStatusStyle _statusStyle(
      ColorScheme colorScheme, PostDraftReviewStatus status) {
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
          iconBackground:
              colorScheme.secondaryContainer.withValues(alpha: 0.65),
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

/// Shows the save review and returns whether the user chose to save.
///
/// On wide screens this is a centered dialog; on phones it stays a bottom sheet.
Future<bool> showPostSaveReviewSheet({
  required BuildContext context,
  required PostDraftReview review,
  required ValueChanged<PostDraftReviewTab> onNavigateToTab,
}) async {
  final size = MediaQuery.sizeOf(context);
  final asDialog = ResponsiveLayout.isWideScreen(size.width);

  Widget buildReview(BuildContext sheetContext) => PostSaveReviewSheet(
        review: review,
        asDialog: asDialog,
        onNavigateToTab: onNavigateToTab,
        onSave: () => Navigator.of(sheetContext).pop(true),
        onCancel: () => Navigator.of(sheetContext).pop(false),
      );

  if (asDialog) {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: AppDialog.insetPadding,
        shape: AppDialog.shape,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.reviewDialogMaxWidth,
            maxHeight: size.height * 0.85,
          ),
          child: buildReview(dialogContext),
        ),
      ),
    );
    return result ?? false;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxWidth: size.width,
      maxHeight: size.height * 0.88,
    ),
    builder: buildReview,
  );
  return result ?? false;
}
