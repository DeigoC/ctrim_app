import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_program.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/schedule_role_times.dart';
import '../../utility/team_rota.dart';
import '../catalog/user_tag_chip.dart';
import '../my_avatar_stack.dart';

/// One post on the team rota: open the post from the title, a slot from its row.
class TeamRotaPostCard extends StatelessWidget {
  const TeamRotaPostCard({
    super.key,
    required this.post,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onOpenPost,
    required this.onRoleTap,
  });

  final TeamRotaPost post;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onOpenPost;
  final void Function(Map<String, dynamic> role) onRoleTap;

  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => (c.usersEpoch, c.catalogsEpoch));
    final currentUserId = context.select((AppContext c) => c.currentUser.id);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = post.head.eventDate != null
        ? _eventDateFormat.format(post.head.eventDate!)
        : l10n.personalScheduleDateTbc;
    final canCollapse =
        post.roles.length > TeamRotaQuery.collapseAfterRoleCount;
    final gapCount = TeamRotaQuery.unassignedCount(post);
    final serving = TeamRotaQuery.viewerIsServing(post, currentUserId);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 12, canCollapse ? 6 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onOpenPost,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateLabel,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post.head.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (post.head.location.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  VolunteerLocations.normalizePostLocation(
                                    post.head.location,
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (gapCount > 0 || serving) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    if (gapCount > 0)
                                      Text(
                                        l10n.teamRotaCardGaps(gapCount),
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (serving)
                                      Text(
                                        l10n.teamRotaYoureServing,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              _buildRoleList(context, l10n, theme, currentUserId),
              if (canCollapse) _buildRoleToggle(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleList(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String currentUserId,
  ) {
    final visible = TeamRotaQuery.visibleRoleCount(
      total: post.roles.length,
      expanded: expanded,
    );
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < visible; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildRoleRow(
              context,
              post.roles[i],
              l10n,
              theme,
              currentUserId,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleToggle(AppLocalizations l10n) {
    final hidden = post.roles.length -
        TeamRotaQuery.visibleRoleCount(
          total: post.roles.length,
          expanded: false,
        );

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.only(top: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
        ),
        onPressed: onToggleExpanded,
        icon: Icon(
          expanded ? Icons.expand_less : Icons.expand_more,
          size: 18,
        ),
        label: Text(
          expanded ? l10n.teamRotaShowFewer : l10n.teamRotaShowMore(hidden),
        ),
      ),
    );
  }

  Widget _buildRoleRow(
    BuildContext context,
    Map<String, dynamic> role,
    AppLocalizations l10n,
    ThemeData theme,
    String currentUserId,
  ) {
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
    final assigned = _assignedUsers(appContext, role);
    final tags = UserTagHelpers.resolveTags(
      tagIDs: EventProgram.tagIDsOf(role),
      allTags: appContext.allTags,
    );
    final youAreOnIt = TeamRotaQuery.isAssignedTo(role, currentUserId);

    return InkWell(
      onTap: () => onRoleTap(role),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  role['title'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
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
                Text(
                  l10n.teamRotaYou,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              if (assigned.isNotEmpty)
                MyAvatarStack(
                  users: assigned,
                  height: 28,
                  width: (28.0 * assigned.length.clamp(1, 4)).clamp(28, 88),
                  borderWidth: 1.2,
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                ),
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

  List<User> _assignedUsers(AppContext appContext, Map<String, dynamic> role) {
    final users = <User>[];
    for (final id in TeamRotaQuery.uidsOf(role)) {
      final user = appContext.userById(id);
      if (user != null) users.add(user);
    }
    return users;
  }
}
