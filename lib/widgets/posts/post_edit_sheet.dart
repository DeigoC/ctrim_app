import 'package:flutter/material.dart';

/// Admin/editor actions for a post, styled like BulletinSettingSheet.
class PostEditSheet extends StatelessWidget {
  const PostEditSheet({
    super.key,
    required this.isLeader,
    required this.hasParent,
    required this.onEditAbout,
    required this.onEditTitle,
    required this.onAddSchedule,
    required this.onEditMedia,
    required this.onManageContributors,
    required this.onManageLeadSpeaker,
    required this.onOpenPeopleTab,
    required this.onCreateSibling,
    required this.onCreateChild,
    required this.onBulkCreate,
    required this.onNotifyBroadcast,
    required this.onNotifyScheduled,
  });

  final bool isLeader;
  final bool hasParent;
  final VoidCallback onEditAbout;
  final VoidCallback onEditTitle;
  final VoidCallback onAddSchedule;
  final VoidCallback onEditMedia;
  final VoidCallback onManageContributors;
  final VoidCallback onManageLeadSpeaker;
  final VoidCallback onOpenPeopleTab;
  final VoidCallback onCreateSibling;
  final VoidCallback onCreateChild;
  final VoidCallback onBulkCreate;
  final VoidCallback onNotifyBroadcast;
  final VoidCallback onNotifyScheduled;

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
                      child: Icon(Icons.edit_note, color: colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit post',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update content, team, and related posts',
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
                subtitle: 'Update the post body and details',
                onTap: onEditAbout,
              ),
              _option(
                theme,
                colorScheme,
                icon: Icons.title,
                color: Colors.indigo,
                title: 'Edit title & details',
                subtitle: 'Title, subtitle, and cover image',
                onTap: onEditTitle,
              ),
              _option(
                theme,
                colorScheme,
                icon: Icons.event,
                color: Colors.teal,
                title: 'Add Schedule',
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
              _sectionLabel(theme, colorScheme, 'People & team'),
              _option(
                theme,
                colorScheme,
                icon: Icons.record_voice_over_outlined,
                color: Colors.deepPurple,
                title: 'Lead speaker',
                subtitle: 'Person sharing the message (card portrait)',
                onTap: onManageLeadSpeaker,
              ),
              _option(
                theme,
                colorScheme,
                icon: Icons.group_outlined,
                color: Colors.orange,
                title: 'Manage contributors',
                subtitle: 'Who can edit this post',
                onTap: onManageContributors,
              ),
              _option(
                theme,
                colorScheme,
                icon: Icons.groups_outlined,
                color: Colors.pink,
                title: 'People tab',
                subtitle: 'Interest and attendance',
                onTap: onOpenPeopleTab,
              ),
              if (isLeader) ...[
                _sectionLabel(theme, colorScheme, 'Related posts'),
                if (hasParent)
                  _option(
                    theme,
                    colorScheme,
                    icon: Icons.account_tree_outlined,
                    color: Colors.brown,
                    title: 'Create Sibling Post',
                    subtitle: 'New post under the same parent',
                    onTap: onCreateSibling,
                  ),
                _option(
                  theme,
                  colorScheme,
                  icon: Icons.subdirectory_arrow_right,
                  color: Colors.deepOrange,
                  title: 'Create Child Post',
                  subtitle: 'New related post under this one',
                  onTap: onCreateChild,
                ),
                _option(
                  theme,
                  colorScheme,
                  icon: Icons.calendar_month,
                  color: Colors.cyan,
                  title: 'Bulk Create Related Posts',
                  subtitle: 'Create several related posts at once',
                  onTap: onBulkCreate,
                ),
                _sectionLabel(theme, colorScheme, 'Notify'),
                _option(
                  theme,
                  colorScheme,
                  icon: Icons.campaign_outlined,
                  color: Colors.red,
                  title: 'Broadcast',
                  subtitle: 'Send a notification to everyone',
                  onTap: onNotifyBroadcast,
                ),
                _option(
                  theme,
                  colorScheme,
                  icon: Icons.notifications_active_outlined,
                  color: Colors.amber.shade800,
                  title: 'Scheduled members',
                  subtitle: 'Notify people assigned on the schedule',
                  onTap: onNotifyScheduled,
                ),
              ],
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
