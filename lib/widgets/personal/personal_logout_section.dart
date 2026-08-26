import 'package:flutter/material.dart';

import 'personal_action_section.dart';

class PersonalLogoutSection extends StatelessWidget {
  const PersonalLogoutSection({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.errorContainer,
          width: 1,
        ),
      ),
      child: PersonalActionListTile(
        icon: Icons.logout_rounded,
        title: 'Sign Out',
        subtitle: 'Sign out of your account',
        onTap: onLogout,
        iconColor: colorScheme.error,
        isFirst: true,
        isLast: true,
      ),
    );
  }
}
