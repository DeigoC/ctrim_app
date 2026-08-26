import 'package:flutter/material.dart';

/// Colored label chip used by catalog tags (user tags, post tags).
class ColoredChip extends StatelessWidget {
  const ColoredChip({
    super.key,
    required this.label,
    this.color,
    this.dense = false,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final Color? color;
  final bool dense;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = selected
        ? (color ?? colorScheme.primaryContainer)
        : (color?.withValues(alpha: 0.15) ??
            colorScheme.surfaceContainerHighest);
    final foreground = color != null && !selected
        ? color!
        : (selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant);

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: selected
            ? Border.all(color: color ?? colorScheme.primary, width: 1.5)
            : null,
      ),
      child: Text(
        label,
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

class ColoredChipRow extends StatelessWidget {
  const ColoredChipRow({
    super.key,
    required this.children,
    this.alignment = WrapAlignment.start,
  });

  final List<Widget> children;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: alignment,
      children: children,
    );
  }
}
