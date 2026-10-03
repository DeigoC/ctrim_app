part of 'edit_cell_group_page.dart';

class _MeetingSetupField extends StatelessWidget {
  const _MeetingSetupField({
    required this.label,
    required this.helper,
    required this.prefixIcon,
    required this.value,
    required this.valueIsError,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String helper;
  final IconData prefixIcon;
  final String value;
  final bool valueIsError;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _cellGroupFieldDecoration(
          colorScheme,
          label: label,
          helperText: helper,
          helperMaxLines: 4,
          prefixIcon: prefixIcon,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueIsError ? colorScheme.error : null,
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: l10n.cellGroupsMeetingClear,
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _CellGroupPhotoGrid extends StatelessWidget {
  const _CellGroupPhotoGrid({
    required this.media,
    required this.keyGraphicSrc,
    required this.canAdd,
    required this.onAdd,
    required this.onToggleCover,
    required this.onRemove,
  });

  final List<Map<String, dynamic>> media;
  final String? keyGraphicSrc;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<String> onToggleCover;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in media)
              SizedBox(
                width: tileWidth,
                child: _PhotoTile(
                  item: item,
                  isCover: (item['src'] as String?) == keyGraphicSrc &&
                      ((item['src'] as String?) ?? '').isNotEmpty,
                  onToggleCover: onToggleCover,
                  onRemove: onRemove,
                ),
              ),
            if (canAdd)
              SizedBox(
                width: tileWidth,
                child: _AddPhotoTile(onAdd: onAdd),
              ),
          ],
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.item,
    required this.isCover,
    required this.onToggleCover,
    required this.onRemove,
  });

  final Map<String, dynamic> item;
  final bool isCover;
  final ValueChanged<String> onToggleCover;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final src = (item['src'] as String?) ?? '';
    final caption =
        isCover ? l10n.cellGroupsCoverPhoto : l10n.cellGroupsSetAsCover;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCover
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: src.isEmpty ? null : () => onToggleCover(src),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: src.isEmpty
                          ? ColoredBox(
                              color: colorScheme.surfaceContainerHigh,
                              child: Icon(
                                Icons.image_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : CachedImageWidget(imageUrl: src, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: colorScheme.surface.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: Tooltip(
                          message: l10n.cellGroupsRemove,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onRemove(src),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isCover
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isCover ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cellGroupsAddPhoto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CellGroupLeaderWrap extends StatelessWidget {
  const _CellGroupLeaderWrap({
    required this.userIds,
    required this.userById,
    required this.onRemove,
  });

  final List<String> userIds;
  final User? Function(String id) userById;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final twoUp = constraints.maxWidth >= 420;
        final tileWidth =
            twoUp ? (constraints.maxWidth - spacing) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final uid in userIds)
              SizedBox(
                width: tileWidth,
                child: _LeaderTile(
                  user: userById(uid),
                  onRemove: () => onRemove(uid),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LeaderTile extends StatelessWidget {
  const _LeaderTile({required this.user, required this.onRemove});

  final User? user;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        child: Row(
          children: [
            if (user != null)
              MyUserAvatar(user!, radius: 18)
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.surfaceContainerHigh,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                user?.fullname ?? l10n.cellGroupsUnknownLeader,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            IconButton(
              tooltip: l10n.cellGroupsRemove,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _cellGroupFieldDecoration(
  ColorScheme colorScheme, {
  required String label,
  String? hintText,
  String? helperText,
  int helperMaxLines = 2,
  String? errorText,
  IconData? prefixIcon,
  bool alignLabelWithHint = false,
}) {
  final borderRadius = BorderRadius.circular(16);
  OutlineInputBorder outline(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    hintText: hintText,
    helperText: helperText,
    helperMaxLines: helperMaxLines,
    errorText: errorText,
    alignLabelWithHint: alignLabelWithHint,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: colorScheme.onSurfaceVariant),
    border: outline(colorScheme.outline),
    enabledBorder: outline(colorScheme.outline),
    focusedBorder: outline(colorScheme.primary, width: 2),
    errorBorder: outline(colorScheme.error),
    focusedErrorBorder: outline(colorScheme.error, width: 2),
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
  );
}
