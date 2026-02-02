import 'package:flutter/material.dart';

class PersonalFirstTimeDialog extends StatefulWidget {
  const PersonalFirstTimeDialog({super.key});

  @override
  State<PersonalFirstTimeDialog> createState() => _PersonalFirstTimeDialogState();
}

class _PersonalFirstTimeDialogState extends State<PersonalFirstTimeDialog> {
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
                    Icons.person_rounded,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Welcome Title
              Text(
                'Your Personal Hub 👤',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 16),

              // Introduction
              Text(
                'Manage your account and preferences:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              // Feature List
              _buildFeatureItem(
                icon: Icons.person_add_rounded,
                title: 'Create an Account',
                description: 'Sign up to save your preferences and stay connected with the community.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                icon: Icons.church_rounded,
                title: 'Sunday Service Attendance',
                description: 'Learn about checking in for Sunday services and what to expect.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                icon: Icons.notifications_active_rounded,
                title: 'Notification Settings',
                description: 'Control when and how you receive notifications about events and updates.',
                colorScheme: colorScheme,
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                icon: Icons.settings_rounded,
                title: 'App Preferences',
                description:
                    'Customize your startup tab, manage bookmarks, and adjust other settings to suit your needs.',
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
                      Icons.info_outline_rounded,
                      size: 20,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can browse as a guest or create an account later in Settings.',
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
