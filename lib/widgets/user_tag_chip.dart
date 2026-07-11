import 'package:flutter/material.dart';

import '../models/user_tag.dart';
import '../utility/user_tag_helpers.dart';

class UserTagChip extends StatelessWidget {
  const UserTagChip({
    super.key,
    required this.tag,
    this.dense = false,
    this.selected = false,
    this.onTap,
  });

  final UserTag tag;
  final bool dense;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tagColor = UserTagHelpers.parseColor(tag.color);
    final background = selected
        ? (tagColor ?? colorScheme.primaryContainer)
        : (tagColor?.withValues(alpha: 0.15) ?? colorScheme.surfaceContainerHighest);
    final foreground = tagColor != null && !selected
        ? tagColor
        : (selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant);

    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: selected ? Border.all(color: tagColor ?? colorScheme.primary, width: 1.5) : null,
      ),
      child: Text(
        tag.name,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 11 : 12,
        ),
      ),
    );

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: chip,
    );
  }
}

class UserTagChipRow extends StatelessWidget {
  const UserTagChipRow({
    super.key,
    required this.tags,
    this.dense = false,
    this.alignment = WrapAlignment.start,
  });

  final List<UserTag> tags;
  final bool dense;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: alignment,
      children: tags.map((tag) => UserTagChip(tag: tag, dense: dense)).toList(),
    );
  }
}
