import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_tag.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../widgets/catalog/user_tag_chip.dart';
import '../../widgets/catalog/user_tag_graphic.dart';
import '../../widgets/responsive_content.dart';

/// Public detail for one team tag.
///
/// The main graphic and short description live here today. Further sections
/// (who leads the team, when they serve, and similar) should be added here.
class ViewUserTagPage extends StatelessWidget {
  const ViewUserTagPage({
    super.key,
    required this.tagId,
    this.onEdit,
  });

  final String tagId;

  /// Area-admin edit. Omitted for guests and other readers.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select((AppContext c) => c.catalogsEpoch);
    final tag = Provider.of<AppContext>(context, listen: false).tagById(tagId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tag?.name ?? l10n.manageUserTagsMenuTitle),
        actions: [
          if (tag != null && onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.manageUserTagsEdit,
              onPressed: onEdit,
            ),
        ],
      ),
      body: ResponsiveContent(
        narrowPadding: 16,
        child: tag == null
            ? _missing(theme, l10n)
            : _detail(theme, colorScheme, l10n, tag),
      ),
    );
  }

  Widget _missing(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l10n.userTagsUnavailable,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _detail(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    UserTag tag,
  ) {
    final description = tag.description;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        if (tag.imageUrl != null) ...[
          UserTagGraphic(imageUrl: tag.imageUrl, height: 200),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: UserTagChip(tag: tag),
        ),
        const SizedBox(height: 16),
        Text(
          tag.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description ?? l10n.userTagsDetailEmpty,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: description == null
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
