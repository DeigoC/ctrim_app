import 'package:flutter/material.dart';

class BulletinFirstTimeDialog extends StatefulWidget {
  const BulletinFirstTimeDialog({super.key});

  @override
  State<BulletinFirstTimeDialog> createState() => _BulletinFirstTimeDialogState();
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Welcome Title
              Text(
                'Welcome to the Bulletin! 📢',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 16),

              // Introduction
              Text(
                'Stay connected with everything happening in our community:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              // Feature List
              _buildFeatureItem(
                icon: Icons.event_rounded,
                title: 'Upcoming Events',
                description: 'View all scheduled services, meetings, and special events with dates and times.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                icon: Icons.article_rounded,
                title: 'Community Posts',
                description: 'Read announcements, updates, and important messages from church leadership.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                icon: Icons.bookmark_rounded,
                title: 'Bookmark & Filter',
                description: 'Save important posts and sort by upcoming events, recent updates, or your bookmarks.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                icon: Icons.refresh_rounded,
                title: 'Pull to Refresh',
                description: 'Swipe down to check for the latest posts and stay up to date.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 24),

              // Bottom Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bookmark posts to easily find them later in the Bookmarks tab.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _enabledOk ? () => Navigator.of(context).pop() : null,
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        ),
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
            color: colorScheme.primaryContainer.withOpacity(0.5),
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
