import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_head.dart';
import '../../models/event/event_program.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/team_rota.dart';
import '../../widgets/personal/team_rota_role_row.dart';
import 'team_rota_role_actions.dart';

/// Every programme line for one Ministry Schedule event.
///
/// Staffing is add and remove people. Time, ministry, and order stay on the post.
class ViewTeamRotaSchedulePage extends StatefulWidget {
  const ViewTeamRotaSchedulePage({
    super.key,
    required this.head,
    required this.program,
    required this.selectedTagIDs,
    required this.onProgramUpdated,
  });

  final EventHead head;
  final EventProgram program;

  /// Ministries selected on the list. Empty means every tagged line.
  final Set<String> selectedTagIDs;

  final ValueChanged<EventProgram> onProgramUpdated;

  @override
  State<ViewTeamRotaSchedulePage> createState() =>
      _ViewTeamRotaSchedulePageState();
}

class _ViewTeamRotaSchedulePageState extends State<ViewTeamRotaSchedulePage> {
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');

  late EventProgram _program;

  @override
  void initState() {
    super.initState();
    _program = widget.program;
  }

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => (c.usersEpoch, c.catalogsEpoch));
    final currentUserId = context.select((AppContext c) => c.currentUser.id);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = ResponsiveLayout.isWideScreenOf(context);
    final roles = TeamRotaQuery.rolesInStartOrder(_program);
    final filtered = TeamRotaPost(
      head: widget.head,
      roles: [
        for (final role in roles)
          if (TeamRotaQuery.roleMatchesTeamTags(
            role: role,
            selectedTagIDs: widget.selectedTagIDs,
          ))
            role,
      ],
    );
    final gapCount = TeamRotaQuery.unassignedCount(filtered);
    final serving = TeamRotaQuery.viewerIsServing(filtered, currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.head.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            tooltip: l10n.teamRotaOpenPost,
            onPressed: () => AppLinks.openPost(
              context,
              id: widget.head.id,
              extra: widget.head,
            ),
            icon: const Icon(Icons.open_in_new),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth;
          final horizontalPadding = isWide
              ? ((contentWidth -
                          ResponsiveLayout.maxContentWidth(contentWidth)) /
                      2)
                  .clamp(16.0, double.infinity)
              : 16.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              32,
            ),
            children: [
              _ScheduleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ScheduleHeader(
                      dateLabel: widget.head.eventDate != null
                          ? _eventDateFormat.format(widget.head.eventDate!)
                          : l10n.personalScheduleDateTbc,
                      title: widget.head.title,
                      location: widget.head.location.isEmpty
                          ? null
                          : VolunteerLocations.normalizePostLocation(
                              widget.head.location,
                            ),
                      gapLabel:
                          gapCount > 0 ? l10n.teamRotaCardGaps(gapCount) : null,
                      servingLabel: serving ? l10n.teamRotaYoureServing : null,
                      isWide: isWide,
                    ),
                    if (roles.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: colorScheme.outline.withValues(alpha: 0.12),
                        ),
                      ),
                      for (var i = 0; i < roles.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        TeamRotaRoleRow(
                          role: roles[i],
                          inlineChips: isWide,
                          emphasizeGap: TeamRotaQuery.roleMatchesTeamTags(
                            role: roles[i],
                            selectedTagIDs: widget.selectedTagIDs,
                          ),
                          onTap: () => _openRole(roles[i]),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openRole(Map<String, dynamic> role) {
    final appContext = context.read<AppContext>();
    return TeamRotaRoleActions(
      context: context,
      appContext: appContext,
      onProgramUpdated: (postId, program) {
        if (!mounted || postId != widget.head.id) return;
        setState(() => _program = program);
        widget.onProgramUpdated(program);
      },
    ).openRole(head: widget.head, role: role);
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: child,
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.dateLabel,
    required this.title,
    required this.location,
    required this.gapLabel,
    required this.servingLabel,
    required this.isWide,
  });

  final String dateLabel;
  final String title;
  final String? location;
  final String? gapLabel;
  final String? servingLabel;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final details = Column(
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
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (location != null) ...[
          const SizedBox(height: 2),
          Text(
            location!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    final status = _status(theme, colorScheme);
    if (status == null) return details;
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          details,
          const SizedBox(height: 8),
          status,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: details),
        const SizedBox(width: 16),
        status,
      ],
    );
  }

  Widget? _status(ThemeData theme, ColorScheme colorScheme) {
    if (gapLabel == null && servingLabel == null) return null;
    return Column(
      crossAxisAlignment:
          isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (gapLabel != null)
          Text(
            gapLabel!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (gapLabel != null && servingLabel != null) const SizedBox(height: 4),
        if (servingLabel != null)
          Text(
            servingLabel!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
