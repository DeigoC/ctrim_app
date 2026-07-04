import 'package:flutter/material.dart';

class TimedButtonDialog extends StatefulWidget {
  const TimedButtonDialog({super.key});

  @override
  State<TimedButtonDialog> createState() => TimedButtonDialogState();
}

class TimedButtonDialogState extends State<TimedButtonDialog> {
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
                    Icons.explore_rounded,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Welcome Title
              Text(
                'Welcome to CTRIM! 🎉',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 16),

              // Introduction
              Text(
                'You\'re all set! Here\'s what you can explore:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              // Feature List
              _buildFeatureItem(
                icon: Icons.library_books_rounded,
                title: 'Events & Posts',
                description: 'View upcoming events, services, and community updates. Tap any post to see full details.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                icon: Icons.church_rounded,
                title: 'CTRIM Information',
                description: 'Learn about our churches, read testimonials, and explore ministry information.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                icon: Icons.person_rounded,
                title: 'Personal Hub',
                description: 'Create an account to stay connected. Staff features are granted by administrators.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 24),

              // Bottom Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'re browsing as a guest. Visit the Personal tab to create an account anytime.',
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
                  child: const Text('Get Started'),
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
