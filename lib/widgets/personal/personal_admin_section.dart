import 'package:flutter/material.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import 'personal_action_section.dart';

class PersonalAdminSection extends StatelessWidget {
  const PersonalAdminSection({
    super.key,
    required this.appContext,
    required this.wide,
    this.gridColumns = 1,
    required this.onViewTemplates,
    required this.onManageUserTags,
    required this.onManagePostTags,
    required this.onManageUserLocations,
  });

  final AppContext appContext;
  final bool wide;
  final int gridColumns;
  final VoidCallback onViewTemplates;
  final VoidCallback onManageUserTags;
  final VoidCallback onManagePostTags;
  final VoidCallback onManageUserLocations;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showTemplates = appContext.currentUser.canManagePostTemplates;
    final showUserTags = appContext.currentUser.canManageVolunteers;
    final sectionTitle = showUserTags && !showTemplates
        ? 'Admin Tools'
        : showTemplates && !showUserTags
            ? 'Leader Tools'
            : 'Admin Tools';

    return PersonalActionSection(
      title: sectionTitle,
      titleIcon: Icons.admin_panel_settings_rounded,
      actions: _adminActions(context, colorScheme),
      wide: wide,
      gridColumns: gridColumns,
    );
  }

  List<PersonalAction> _adminActions(
      BuildContext context, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <PersonalAction>[];
    if (appContext.currentUser.canManagePostTemplates) {
      actions.add(
        PersonalAction(
          icon: Icons.newspaper_rounded,
          title: 'Post Templates',
          subtitle: 'Create and edit post templates',
          onTap: onViewTemplates,
          iconColor: colorScheme.primary,
        ),
      );
    }
    if (appContext.currentUser.canManageVolunteers) {
      actions.add(
        PersonalAction(
          icon: Icons.label_rounded,
          title: l10n.manageUserTagsMenuTitle,
          subtitle: l10n.manageUserTagsMenuSubtitle,
          onTap: onManageUserTags,
          iconColor: colorScheme.primary,
        ),
      );
      actions.add(
        PersonalAction(
          icon: Icons.style_rounded,
          title: l10n.managePostTagsMenuTitle,
          subtitle: l10n.managePostTagsMenuSubtitle,
          onTap: onManagePostTags,
          iconColor: colorScheme.primary,
        ),
      );
      actions.add(
        PersonalAction(
          icon: Icons.location_on_rounded,
          title: l10n.manageUserLocationsMenuTitle,
          subtitle: l10n.manageUserLocationsMenuSubtitle,
          onTap: onManageUserLocations,
          iconColor: colorScheme.primary,
        ),
      );
    }
    return actions;
  }
}
