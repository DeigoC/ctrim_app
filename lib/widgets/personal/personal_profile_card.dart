import 'package:flutter/material.dart';

import '../../utility/app_context.dart';
import '../user_avatar.dart';

class PersonalProfileCard extends StatelessWidget {
  const PersonalProfileCard({
    super.key,
    required this.appContext,
    required this.wide,
  });

  final AppContext appContext;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (appContext.isCurrentUserGuest) {
      return _buildGuestWelcomeCard(theme, colorScheme);
    }
    return _buildUserProfileCard(theme, colorScheme);
  }

  Widget _buildGuestWelcomeCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: wide
          ? const EdgeInsets.symmetric(horizontal: 28, vertical: 28)
          : const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.person_outline_rounded,
              size: wide ? 48 : 40, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Welcome to CTRIM',
            textAlign: TextAlign.center,
            style: (wide
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create an account to manage your schedule, notifications, and profile.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(ThemeData theme, ColorScheme colorScheme) {
    final double avatarRadius = wide ? 40 : 28;
    final EdgeInsets padding = wide
        ? const EdgeInsets.symmetric(horizontal: 28, vertical: 24)
        : const EdgeInsets.all(20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: padding,
      child: Row(
        children: [
          Hero(
            tag: 'user_avatar_${appContext.currentUser.id}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: MyUserAvatar(
                appContext.currentUser,
                radius: avatarRadius,
              ),
            ),
          ),
          SizedBox(width: wide ? 24 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${appContext.currentUser.forname}!',
                  style: (wide
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.titleLarge)
                      ?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appContext.currentUser.location,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
                if (appContext.currentUser.isAreaAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Admin',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
