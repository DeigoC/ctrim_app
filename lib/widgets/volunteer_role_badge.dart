import 'package:flutter/material.dart';

import '../src/localization/app_localizations.dart';
import '../utility/volunteer_role_helpers.dart';

class VolunteerRoleBadge extends StatelessWidget {
  const VolunteerRoleBadge({
    super.key,
    required this.role,
    this.dense = false,
  });

  final VolunteerRoleKind role;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final (label, background, foreground) = switch (role) {
      VolunteerRoleKind.leader => (
          l10n.userProfileLeaderBadge,
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
      VolunteerRoleKind.areaAdmin => (
          l10n.userProfileAdminBadge,
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      VolunteerRoleKind.cellGroupLeader => (
          l10n.userProfileCellGroupLeaderBadge,
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 11 : 12,
        ),
      ),
    );
  }
}

class VolunteerRoleBadgeRow extends StatelessWidget {
  const VolunteerRoleBadgeRow({
    super.key,
    required this.roles,
    this.dense = false,
    this.alignment = WrapAlignment.start,
  });

  final Set<VolunteerRoleKind> roles;
  final bool dense;
  final WrapAlignment alignment;

  static const displayOrder = [
    VolunteerRoleKind.areaAdmin,
    VolunteerRoleKind.leader,
    VolunteerRoleKind.cellGroupLeader,
  ];

  static List<VolunteerRoleKind> ordered(Set<VolunteerRoleKind> roles) =>
      displayOrder.where(roles.contains).toList();

  @override
  Widget build(BuildContext context) {
    final shown = ordered(roles);
    if (shown.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: alignment,
      children: shown
          .map((role) => VolunteerRoleBadge(role: role, dense: dense))
          .toList(),
    );
  }
}
