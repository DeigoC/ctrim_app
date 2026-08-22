import 'package:flutter/material.dart';

import '../app_dialog.dart';
import '../../utility/responsive_layout.dart';

class BulletinFirstTimeDialog extends StatefulWidget {
  const BulletinFirstTimeDialog({super.key});

  @override
  State<BulletinFirstTimeDialog> createState() =>
      _BulletinFirstTimeDialogState();
}

class _BulletinFirstTimeDialogState extends State<BulletinFirstTimeDialog> {
  bool _enabledOk = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3)).then((_) {
        if (mounted) {
          setState(() {
            _enabledOk = true;
          });
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppDialog(
      icon: Icons.campaign_rounded,
      title: 'Welcome to the Bulletin!',
      message: 'Stay connected with everything happening in our community:',
      messageAlign: TextAlign.start,
      maxWidth: ResponsiveLayout.reviewDialogMaxWidth,
      banner: const AppDialogBanner(
        icon: Icons.tips_and_updates_rounded,
        message:
            'Bookmark posts to easily find them later in the Bookmarks tab.',
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFeatureItem(
            icon: Icons.event_rounded,
            title: 'Upcoming Events',
            description:
                'View all scheduled services, meetings, and special events with dates and times.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.article_rounded,
            title: 'Community Posts',
            description:
                'Read announcements, updates, and important messages from church leadership.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.bookmark_rounded,
            title: 'Bookmark & Filter',
            description:
                'Save important posts and sort by upcoming events, recent updates, or your bookmarks.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.refresh_rounded,
            title: 'Pull to Refresh',
            description:
                'Swipe down to check for the latest posts and stay up to date.',
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
      ),
      actions: AppDialogActions(
        onConfirm: _enabledOk ? () => Navigator.of(context).pop() : null,
        confirmEnabled: _enabledOk,
        confirmLabel: 'Got It',
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
