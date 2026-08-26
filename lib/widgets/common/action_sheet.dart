import 'package:flutter/material.dart';

import '../../utility/responsive_layout.dart';

/// Shared chrome for modal action sheets (post admin, template edit, bulletin sort).
class ActionSheetShell extends StatelessWidget {
  const ActionSheetShell({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.scrollable = true,
    this.decorateSurface = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool scrollable;

  /// When false, skips the surface fill and top-only radius (parent already clips).
  final bool decorateSurface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.outline.withValues(alpha: 0.1),
                colorScheme.outline.withValues(alpha: 0.3),
                colorScheme.outline.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 20),
      ],
    );

    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    if (!decorateSurface) return content;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(child: content),
    );
  }
}

class ActionSheetSectionLabel extends StatelessWidget {
  const ActionSheetSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One bordered action row used inside sheets.
class ActionSheetOption extends StatelessWidget {
  const ActionSheetOption({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.selected = false,
    this.showChevron = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool selected;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget? resolvedTrailing = trailing;
    if (resolvedTrailing == null) {
      if (selected) {
        resolvedTrailing =
            Icon(Icons.check_circle, color: colorScheme.primary, size: 20);
      } else if (showChevron) {
        resolvedTrailing =
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: selected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.2 : 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimaryContainer : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: resolvedTrailing,
      ),
    );
  }
}

/// Lays out action tiles in one column on phones, two on wide sheets.
class ActionSheetOptionGrid extends StatelessWidget {
  const ActionSheetOptionGrid({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            ResponsiveLayout.isWideScreen(constraints.maxWidth) ? 2 : 1;
        const spacing = 8.0;
        const horizontal = 16.0;

        if (columns == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontal),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: spacing),
                  children[i],
                ],
              ],
            ),
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          final rowChildren = <Widget>[];
          for (var c = 0; c < columns; c++) {
            if (c > 0) rowChildren.add(const SizedBox(width: spacing));
            if (i + c < children.length) {
              rowChildren.add(Expanded(child: children[i + c]));
            } else {
              rowChildren.add(const Expanded(child: SizedBox.shrink()));
            }
          }
          if (rows.isNotEmpty) rows.add(const SizedBox(height: spacing));
          rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontal),
          child: Column(children: rows),
        );
      },
    );
  }
}
