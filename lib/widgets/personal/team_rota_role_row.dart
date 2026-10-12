import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_program.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/schedule_role_times.dart';
import '../../utility/team_rota.dart';
import '../catalog/user_tag_chip.dart';
import '../my_avatar_stack.dart';

/// One programme line on Ministry Schedule: title, time, ministries, people.
class TeamRotaRoleRow extends StatelessWidget {
  const TeamRotaRoleRow({
    super.key,
    required this.role,
    required this.onTap,
    required this.emphasizeGap,
    this.inlineChips = false,
  });

  final Map<String, dynamic> role;
  final VoidCallback onTap;

  /// Empty ministry-filter slots use the error **Unassigned** chip.
  /// Other empty lines use a muted label.
  final bool emphasizeGap;

  /// Wide schedule page: chips share the row with the title and people.
  final bool inlineChips;

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => (c.usersEpoch, c.catalogsEpoch));
    final currentUserId = context.select((AppContext c) => c.currentUser.id);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appContext = context.read<AppContext>();
    final timeLabel = ScheduleRoleTimes.label(
      start: role['start'] as DateTime?,
      end: role['end'] as DateTime?,
      standing: EventProgram.isStanding(role),
      wholeEvent: l10n.scheduleWholeEventLabel,
      formatTime: _timeFormat.format,
      startsAt: l10n.scheduleStartsAt,
      range: (start, end) =>
          '${_timeFormat.format(start)} – ${_timeFormat.format(end)}',
    );
    final assigned = _assignedUsers(appContext);
    final tags = UserTagHelpers.resolveTags(
      tagIDs: EventProgram.tagIDsOf(role),
      allTags: appContext.allTags,
    );
    final youAreOnIt = TeamRotaQuery.isAssignedTo(role, currentUserId);
    final people = _buildPeople(l10n, theme, assigned);

    final title = Text(
      role['title'] as String? ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: inlineChips
          ? Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(child: title),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: UserTagChipLine(tags: tags),
                        ),
                      ] else
                        const Spacer(),
                    ],
                  ),
                ),
                if (timeLabel != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    timeLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (youAreOnIt) ...[
                  const SizedBox(width: 8),
                  _youLabel(l10n, colorScheme, theme),
                ],
                const SizedBox(width: 8),
                people,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: title),
                    if (timeLabel != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (youAreOnIt) ...[
                      const SizedBox(width: 8),
                      _youLabel(l10n, colorScheme, theme),
                    ],
                    const SizedBox(width: 8),
                    people,
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  UserTagChipLine(tags: tags),
                ],
              ],
            ),
    );
  }

  Widget _youLabel(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Text(
      l10n.teamRotaYou,
      style: theme.textTheme.labelSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildPeople(
    AppLocalizations l10n,
    ThemeData theme,
    List<User> assigned,
  ) {
    if (assigned.isNotEmpty) {
      return MyAvatarStack(
        users: assigned,
        height: 28,
        width: (28.0 * assigned.length.clamp(1, 4)).clamp(28, 88),
        borderWidth: 1.2,
      );
    }
    final colorScheme = theme.colorScheme;
    if (!emphasizeGap) {
      return Text(
        l10n.teamRotaNoOneAssigned,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        l10n.teamRotaUnassigned,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<User> _assignedUsers(AppContext appContext) {
    final users = <User>[];
    for (final id in TeamRotaQuery.uidsOf(role)) {
      final user = appContext.userById(id);
      if (user != null) users.add(user);
    }
    return users;
  }
}
