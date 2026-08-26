import 'package:flutter/material.dart';

import '../common/app_dialog.dart';
import '../../utility/responsive_layout.dart';

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

    return AppDialog(
      icon: Icons.explore_rounded,
      title: 'Welcome to CTRIM!',
      message: 'You\'re all set! Here\'s what you can explore:',
      messageAlign: TextAlign.start,
      maxWidth: ResponsiveLayout.reviewDialogMaxWidth,
      banner: const AppDialogBanner(
        icon: Icons.info_outline_rounded,
        message:
            'You\'re browsing as a guest. Visit the Personal tab to create an account anytime.',
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFeatureItem(
            icon: Icons.library_books_rounded,
            title: 'Events & Posts',
            description:
                'View upcoming events, services, and community updates. Tap any post to see full details.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.church_rounded,
            title: 'CTRIM Information',
            description:
                'Learn about our churches, read testimonials, and explore ministry information.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.person_rounded,
            title: 'Personal Hub',
            description:
                'Create an account to stay connected. Staff features are granted by administrators.',
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
      ),
      actions: AppDialogActions(
        onConfirm: _enabledOk ? () => Navigator.of(context).pop() : null,
        confirmEnabled: _enabledOk,
        confirmLabel: 'Get Started',
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
