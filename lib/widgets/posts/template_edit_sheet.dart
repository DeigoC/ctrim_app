import 'package:flutter/material.dart';

/// Template editor actions, styled like [PostEditSheet] / BulletinSettingSheet.
class TemplateEditSheet extends StatelessWidget {
  const TemplateEditSheet({
    super.key,
    required this.onEditAbout,
    required this.onAddSchedule,
    required this.onEditMedia,
    required this.onSave,
  });

  final VoidCallback onEditAbout;
  final VoidCallback onAddSchedule;
  final VoidCallback onEditMedia;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
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
                      child: Icon(Icons.dashboard_customize_outlined, color: colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit template',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update content and save this template',
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
              _sectionLabel(theme, colorScheme, 'Content'),
              _option(
                theme,
                colorScheme,
                icon: Icons.article_outlined,
                color: Colors.blue,
                title: 'Edit About',
                subtitle: 'Update the template body',
                onTap: onEditAbout,
              ),
              _option(
                theme,
                colorScheme,
                icon: Icons.event,
                color: Colors.teal,
                title: 'Add Schedule Item',
                subtitle: 'Add a program role or time slot',
                onTap: onAddSchedule,
              ),
              _option(
                theme,
                colorScheme,
                icon: Icons.photo_library_outlined,
                color: Colors.purple,
                title: 'Edit Media',
                subtitle: 'Manage photos and videos',
                onTap: onEditMedia,
              ),
              _sectionLabel(theme, colorScheme, 'Save'),
              _option(
                theme,
                colorScheme,
                icon: Icons.save_rounded,
                color: Colors.green,
                title: 'Save template',
                subtitle: 'Write changes to the database',
                onTap: onSave,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, ColorScheme colorScheme, String label) {
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

  Widget _option(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
