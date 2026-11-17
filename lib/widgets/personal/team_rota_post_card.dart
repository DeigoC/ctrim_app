import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/team_rota.dart';
import 'team_rota_role_row.dart';

/// One post on the team rota: open the post from the title, a slot from its row.
class TeamRotaPostCard extends StatelessWidget {
  const TeamRotaPostCard({
    super.key,
    required this.post,
    required this.onViewSchedule,
    required this.onOpenPost,
    required this.onRoleTap,
  });

  final TeamRotaPost post;
  final VoidCallback onViewSchedule;
  final VoidCallback onOpenPost;
  final void Function(Map<String, dynamic> role) onRoleTap;

  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');

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
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
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
              _buildRoleList(),
              _buildViewSchedule(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleList() {
    final visible = TeamRotaQuery.visibleRoleCount(post.roles.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          TeamRotaRoleRow(
            role: post.roles[i],
            emphasizeGap: true,
            onTap: () => onRoleTap(post.roles[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildViewSchedule(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.fromLTRB(0, 14, 8, 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
        ),
        onPressed: onViewSchedule,
        icon: const Icon(Icons.calendar_view_day_outlined, size: 18),
        label: Text(l10n.teamRotaViewSchedule),
      ),
    );
  }
}
