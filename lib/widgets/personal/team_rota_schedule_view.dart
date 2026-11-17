import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_head.dart';
import '../../models/event/event_program.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/catalog/volunteer_locations.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/schedule_agenda_layout.dart';
import '../../utility/schedule_block_layout.dart';
import '../../utility/schedule_role_times.dart';
import '../../utility/team_rota.dart';
import '../catalog/user_tag_chip.dart';
import '../my_avatar_stack.dart';
import '../user_avatar.dart';

/// Whole-event staffing view: on-duty people, then the running order.
///
/// Card height follows the people, not the clock. Duration is a bar.
class TeamRotaScheduleView extends StatefulWidget {
  const TeamRotaScheduleView({
    super.key,
    required this.head,
    required this.roles,
    required this.selectedTagIDs,
    required this.onRoleTap,
  });

  final EventHead head;
  final List<Map<String, dynamic>> roles;
  final Set<String> selectedTagIDs;
  final ValueChanged<Map<String, dynamic>> onRoleTap;

  @override
  State<TeamRotaScheduleView> createState() => _TeamRotaScheduleViewState();
}

class _TeamRotaScheduleViewState extends State<TeamRotaScheduleView> {
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static const double _gutterWidth = 52;
  static const double _silhouetteWidth = 12;
  static const double _silhouetteGap = 16;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final GlobalKey _gapKey = GlobalKey();
  final List<GlobalKey> _clusterKeys = [];

  int? _activeCluster;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncActiveCluster);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncActiveCluster();
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_syncActiveCluster);
    _scroll.dispose();
    super.dispose();
  }

  void _ensureClusterKeys(final int count) {
    if (_clusterKeys.length == count) return;
    if (_clusterKeys.length < count) {
      _clusterKeys.addAll([
        for (var i = _clusterKeys.length; i < count; i++) GlobalKey(),
      ]);
      return;
    }
    _clusterKeys.removeRange(count, _clusterKeys.length);
  }

  void _syncActiveCluster() {
    if (!mounted || !_scroll.hasClients) return;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null || !listBox.hasSize) return;
    final viewportTop = listBox.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + listBox.size.height;
    int? best;
    var bestDistance = double.infinity;
    for (var i = 0; i < _clusterKeys.length; i++) {
      final box =
          _clusterKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (bottom < viewportTop || top > viewportBottom) continue;
      final distance = (top - viewportTop).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    if (best == _activeCluster) return;
    setState(() => _activeCluster = best);
  }

  void _scrollToCluster(final int index) {
    if (index < 0 || index >= _clusterKeys.length) return;
    final target = _clusterKeys[index].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _scrollToGap() {
    final target = _gapKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _onSilhouetteTap(
    final ScheduleAgendaLayout agenda,
    final double dy,
    final double height,
  ) {
    final start = agenda.dayStart;
    final end = agenda.dayEnd;
    if (start == null || end == null || height <= 0) return;
    final totalMs = end.difference(start).inMilliseconds;
    if (totalMs <= 0 || agenda.clusters.isEmpty) return;
    final at = start.add(Duration(
      milliseconds: (totalMs * (dy / height)).round().clamp(0, totalMs),
    ));
    var best = 0;
    var bestDistance = 1 << 62;
    for (var i = 0; i < agenda.clusters.length; i++) {
      final cluster = agenda.clusters[i];
      var clusterEnd = cluster.turns.first.end;
      for (final turn in cluster.turns) {
        if (turn.end.isAfter(clusterEnd)) clusterEnd = turn.end;
      }
      if (!at.isBefore(cluster.start) && !at.isAfter(clusterEnd)) {
        _scrollToCluster(i);
        return;
      }
      final distance = at.difference(cluster.start).inMilliseconds.abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    _scrollToCluster(best);
  }

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => (c.usersEpoch, c.catalogsEpoch));
    final currentUserId = context.select((AppContext c) => c.currentUser.id);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = ResponsiveLayout.isWideScreenOf(context);
    final agenda = ScheduleAgendaLayout.build(widget.roles);
    _ensureClusterKeys(agenda.clusters.length);
    final yourTitles = agenda.titlesAssignedTo(currentUserId);
    final gapRoleId = agenda.firstGapRoleId(
      (role) => TeamRotaQuery.roleMatchesTeamTags(
        role: role,
        selectedTagIDs: widget.selectedTagIDs,
      ),
    );
    final gapCount = TeamRotaQuery.unassignedCount(TeamRotaPost(
      head: widget.head,
      roles: [
        for (final role in widget.roles)
          if (TeamRotaQuery.roleMatchesTeamTags(
            role: role,
            selectedTagIDs: widget.selectedTagIDs,
          ))
            role,
      ],
    ));
    final showSilhouette = isWide &&
        agenda.hasRunningOrder &&
        agenda.dayStart != null &&
        agenda.dayEnd != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = isWide
            ? ((constraints.maxWidth -
                        ResponsiveLayout.maxContentWidth(
                            constraints.maxWidth)) /
                    2)
                .clamp(16.0, double.infinity)
            : 16.0;
        final list = ListView(
          key: _listKey,
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding +
                (showSilhouette ? _silhouetteWidth + _silhouetteGap : 0),
            32,
          ),
          children: [
            _ScheduleIntro(
              dateLabel: widget.head.eventDate != null
                  ? _eventDateFormat.format(widget.head.eventDate!)
                  : l10n.personalScheduleDateTbc,
              title: widget.head.title,
              location: widget.head.location.isEmpty
                  ? null
                  : VolunteerLocations.normalizePostLocation(
                      widget.head.location,
                    ),
              gapLabel: gapCount > 0 ? l10n.teamRotaCardGaps(gapCount) : null,
              youreOnLabel: _youreOnLabel(l10n, yourTitles),
              isWide: isWide,
              onGapTap: gapRoleId == null ? null : _scrollToGap,
            ),
            if (agenda.hasDuties) ...[
              _SectionTitle(l10n.teamRotaOnDuty),
              _DutyWrap(
                duties: agenda.duties,
                isWide: isWide,
                currentUserId: currentUserId,
                selectedTagIDs: widget.selectedTagIDs,
                gapRoleId: gapRoleId,
                gapKey: _gapKey,
                onRoleTap: widget.onRoleTap,
              ),
            ],
            if (agenda.hasRunningOrder) ...[
              _SectionTitle(l10n.teamRotaRunningOrder),
              for (var i = 0; i < agenda.clusters.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                _RunningCluster(
                  key: _clusterKeys[i],
                  cluster: agenda.clusters[i],
                  isWide: isWide,
                  currentUserId: currentUserId,
                  selectedTagIDs: widget.selectedTagIDs,
                  gapRoleId: gapRoleId,
                  gapKey: _gapKey,
                  onRoleTap: widget.onRoleTap,
                ),
              ],
            ],
            if (agenda.untimedRoles.isNotEmpty) ...[
              _SectionTitle(l10n.scheduleUntimedSectionTitle),
              for (var i = 0; i < agenda.untimedRoles.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _RoleCard(
                  key: _gapKeyFor(agenda.untimedRoles[i], gapRoleId),
                  yours: TeamRotaQuery.isAssignedTo(
                    agenda.untimedRoles[i],
                    currentUserId,
                  ),
                  empty: TeamRotaQuery.isVacancy(agenda.untimedRoles[i]),
                  emphasizeEmpty: TeamRotaQuery.roleMatchesTeamTags(
                    role: agenda.untimedRoles[i],
                    selectedTagIDs: widget.selectedTagIDs,
                  ),
                  onTap: () => widget.onRoleTap(agenda.untimedRoles[i]),
                  child: _TurnBody(
                    role: agenda.untimedRoles[i],
                    durationFraction: 0,
                    sameAsTitle:
                        agenda.sameAsDutyTitleFor(agenda.untimedRoles[i]),
                    isWide: isWide,
                    yours: TeamRotaQuery.isAssignedTo(
                      agenda.untimedRoles[i],
                      currentUserId,
                    ),
                    emphasizeEmpty: TeamRotaQuery.roleMatchesTeamTags(
                      role: agenda.untimedRoles[i],
                      selectedTagIDs: widget.selectedTagIDs,
                    ),
                  ),
                ),
              ],
            ],
          ],
        );

        if (!showSilhouette) return list;
        return Stack(
          children: [
            list,
            Positioned(
              top: 12,
              bottom: 12,
              right: horizontalPadding,
              child: SizedBox(
                width: _silhouetteWidth,
                child: _AgendaSilhouette(
                  agenda: agenda,
                  activeCluster: _activeCluster,
                  onTap: (dy, height) => _onSilhouetteTap(agenda, dy, height),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Key? _gapKeyFor(final Map<String, dynamic> role, final int? gapRoleId) {
    if (gapRoleId == null) return null;
    if (ScheduleAgendaLayout.roleIdOf(role) != gapRoleId) return null;
    return _gapKey;
  }
}

String _youreOnLabel(final AppLocalizations l10n, final List<String> titles) {
  switch (titles.length) {
    case 0:
      return '';
    case 1:
      return l10n.teamRotaYoureOnOne(titles[0]);
    case 2:
      return l10n.teamRotaYoureOnTwo(titles[0], titles[1]);
    case 3:
      return l10n.teamRotaYoureOnThree(titles[0], titles[1], titles[2]);
    default:
      return l10n.teamRotaYoureOnMore(
        titles[0],
        titles[1],
        titles.length - 2,
      );
  }
}

String _givenName(final User user) {
  final name = user.forname.trim();
  if (name.isNotEmpty) return name;
  return user.shortenedFullName;
}

List<User> _assignedUsers(
  final AppContext appContext,
  final Map<String, dynamic> role,
) {
  final users = <User>[];
  for (final id in TeamRotaQuery.uidsOf(role)) {
    final user = appContext.userById(id);
    if (user != null) users.add(user);
  }
  return users;
}

class _ScheduleIntro extends StatelessWidget {
  const _ScheduleIntro({
    required this.dateLabel,
    required this.title,
    required this.location,
    required this.gapLabel,
    required this.youreOnLabel,
    required this.isWide,
    required this.onGapTap,
  });

  final String dateLabel;
  final String title;
  final String? location;
  final String? gapLabel;
  final String youreOnLabel;
  final bool isWide;
  final VoidCallback? onGapTap;

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
        Flexible(child: status),
      ],
    );
  }

  Widget? _status(final ThemeData theme, final ColorScheme colorScheme) {
    final gap = gapLabel;
    final you = youreOnLabel;
    if (gap == null && you.isEmpty) return null;
    return Column(
      crossAxisAlignment:
          isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (gap != null)
          TextButton(
            onPressed: onGapTap,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: isWide ? Alignment.centerRight : Alignment.centerLeft,
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child:
                Text(gap, textAlign: isWide ? TextAlign.end : TextAlign.start),
          ),
        if (gap != null && you.isNotEmpty) const SizedBox(height: 4),
        if (you.isNotEmpty)
          Text(
            you,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: isWide ? TextAlign.end : TextAlign.start,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DutyWrap extends StatelessWidget {
  const _DutyWrap({
    required this.duties,
    required this.isWide,
    required this.currentUserId,
    required this.selectedTagIDs,
    required this.gapRoleId,
    required this.gapKey,
    required this.onRoleTap,
  });

  final List<ScheduleAgendaDuty> duties;
  final bool isWide;
  final String currentUserId;
  final Set<String> selectedTagIDs;
  final int? gapRoleId;
  final GlobalKey gapKey;
  final ValueChanged<Map<String, dynamic>> onRoleTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns =
            isWide && constraints.maxWidth >= 560 && duties.length > 1;
        final itemWidth =
            twoColumns ? (constraints.maxWidth - 8) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final duty in duties)
              SizedBox(
                width: itemWidth,
                child: _DutyCard(
                  duty: duty,
                  currentUserId: currentUserId,
                  selectedTagIDs: selectedTagIDs,
                  gapKey: duty.roleId == gapRoleId ? gapKey : null,
                  onTap: () => onRoleTap(duty.role),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DutyCard extends StatelessWidget {
  const _DutyCard({
    required this.duty,
    required this.currentUserId,
    required this.selectedTagIDs,
    required this.gapKey,
    required this.onTap,
  });

  final ScheduleAgendaDuty duty;
  final String currentUserId;
  final Set<String> selectedTagIDs;
  final Key? gapKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appContext = context.read<AppContext>();
    final role = duty.role;
    final emphasizeEmpty = TeamRotaQuery.roleMatchesTeamTags(
      role: role,
      selectedTagIDs: selectedTagIDs,
    );
    final timeLabel = ScheduleRoleTimes.label(
      start: duty.start,
      end: duty.end,
      standing: EventProgram.isStanding(role),
      wholeEvent: l10n.scheduleWholeEventLabel,
      formatTime: _TeamRotaScheduleViewState._timeFormat.format,
      startsAt: l10n.scheduleStartsAt,
      range: (start, end) =>
          '${_TeamRotaScheduleViewState._timeFormat.format(start)} – ${_TeamRotaScheduleViewState._timeFormat.format(end)}',
    );
    final tags = UserTagHelpers.resolveTags(
      tagIDs: EventProgram.tagIDsOf(role),
      allTags: appContext.allTags,
    );

    return _RoleCard(
      key: gapKey,
      yours: TeamRotaQuery.isAssignedTo(role, currentUserId),
      empty: TeamRotaQuery.isVacancy(role),
      emphasizeEmpty: emphasizeEmpty,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            duty.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (timeLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              timeLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            UserTagChipLine(tags: tags),
          ],
          if (!TeamRotaQuery.hidesAssigneeLine(role)) ...[
            const SizedBox(height: 8),
            _Assignees(
              role: role,
              avatarSize: 40,
              emphasizeEmpty: emphasizeEmpty,
            ),
          ],
        ],
      ),
    );
  }
}

class _RunningCluster extends StatelessWidget {
  const _RunningCluster({
    super.key,
    required this.cluster,
    required this.isWide,
    required this.currentUserId,
    required this.selectedTagIDs,
    required this.gapRoleId,
    required this.gapKey,
    required this.onRoleTap,
  });

  final ScheduleAgendaCluster cluster;
  final bool isWide;
  final String currentUserId;
  final Set<String> selectedTagIDs;
  final int? gapRoleId;
  final GlobalKey gapKey;
  final ValueChanged<Map<String, dynamic>> onRoleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = _TeamRotaScheduleViewState._timeFormat.format(cluster.start);
    return Column(
      children: [
        for (var i = 0; i < cluster.turns.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _TeamRotaScheduleViewState._gutterWidth,
                child: i == 0
                    ? Text(
                        time,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 16, left: 8),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: _TurnCard(
                  turn: cluster.turns[i],
                  isWide: isWide,
                  currentUserId: currentUserId,
                  selectedTagIDs: selectedTagIDs,
                  gapKey: cluster.turns[i].roleId == gapRoleId ? gapKey : null,
                  onTap: () => onRoleTap(cluster.turns[i].role),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TurnCard extends StatelessWidget {
  const _TurnCard({
    required this.turn,
    required this.isWide,
    required this.currentUserId,
    required this.selectedTagIDs,
    required this.gapKey,
    required this.onTap,
  });

  final ScheduleAgendaTurn turn;
  final bool isWide;
  final String currentUserId;
  final Set<String> selectedTagIDs;
  final Key? gapKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = turn.role;
    final yours = TeamRotaQuery.isAssignedTo(role, currentUserId);
    final emphasizeEmpty = TeamRotaQuery.roleMatchesTeamTags(
      role: role,
      selectedTagIDs: selectedTagIDs,
    );
    return _RoleCard(
      key: gapKey,
      yours: yours,
      empty: TeamRotaQuery.isVacancy(role),
      emphasizeEmpty: emphasizeEmpty,
      onTap: onTap,
      child: _TurnBody(
        role: role,
        durationFraction: turn.durationFraction,
        sameAsTitle: turn.sameAsDutyTitle,
        isWide: isWide,
        yours: yours,
        emphasizeEmpty: emphasizeEmpty,
      ),
    );
  }
}

class _TurnBody extends StatelessWidget {
  const _TurnBody({
    required this.role,
    required this.durationFraction,
    required this.sameAsTitle,
    required this.isWide,
    required this.yours,
    required this.emphasizeEmpty,
  });

  final Map<String, dynamic> role;
  final double durationFraction;
  final String? sameAsTitle;
  final bool isWide;
  final bool yours;
  final bool emphasizeEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appContext = context.read<AppContext>();
    final tags = UserTagHelpers.resolveTags(
      tagIDs: EventProgram.tagIDsOf(role),
      allTags: appContext.allTags,
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ScheduleAgendaLayout.titleOf(role),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          UserTagChipLine(tags: tags),
        ],
        if (durationFraction > 0) ...[
          const SizedBox(height: 8),
          _DurationBar(fraction: durationFraction, yours: yours),
        ],
      ],
    );
    if (TeamRotaQuery.hidesAssigneeLine(role)) return text;
    final people = _Assignees(
      role: role,
      avatarSize: 36,
      emphasizeEmpty: emphasizeEmpty,
      sameAsTitle: sameAsTitle,
    );
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text,
          const SizedBox(height: 8),
          people,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: text),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: people,
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.yours,
    required this.empty,
    required this.emphasizeEmpty,
    required this.onTap,
    required this.child,
  });

  final bool yours;
  final bool empty;
  final bool emphasizeEmpty;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    final dashed = empty;
    final card = Material(
      color: colorScheme.surface,
      shape: dashed
          ? RoundedRectangleBorder(borderRadius: radius)
          : RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(yours ? 16 : 12, 10, 12, 10),
          child: child,
        ),
      ),
    );
    return Stack(
      children: [
        if (dashed)
          CustomPaint(
            foregroundPainter: _DashedRRectPainter(
              color: emphasizeEmpty
                  ? colorScheme.error
                  : colorScheme.outlineVariant,
              radius: 16,
            ),
            child: card,
          )
        else
          card,
        if (yours)
          Positioned(
            left: 6,
            top: 8,
            bottom: 8,
            width: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _Assignees extends StatelessWidget {
  const _Assignees({
    required this.role,
    required this.avatarSize,
    required this.emphasizeEmpty,
    this.sameAsTitle,
  });

  final Map<String, dynamic> role;
  final double avatarSize;
  final bool emphasizeEmpty;
  final String? sameAsTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sameAs = sameAsTitle;
    if (sameAs != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.teamRotaSameAs(sameAs),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final assignedCount = TeamRotaQuery.uidsOf(role).length;
    if (assignedCount == 0) {
      if (TeamRotaQuery.isSharedResponsibility(role)) {
        return Text(
          l10n.teamRotaSharedResponsibility,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        );
      }
      if (!emphasizeEmpty) {
        return Text(
          l10n.teamRotaNoOneAssigned,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        );
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
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
        ),
      );
    }

    final users = _assignedUsers(context.read<AppContext>(), role);
    if (assignedCount >= 4) {
      final stackCount = users.length > 3 ? 3 : users.length;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stackCount > 0) ...[
            MyAvatarStack(
              users: users.take(stackCount).toList(),
              height: avatarSize,
              width: ScheduleBlockLayout.avatarStackWidth(
                userCount: stackCount,
                avatarSize: avatarSize,
                maxWidth: avatarSize * 3,
              ),
              borderWidth: 1.5,
              borderColor: colorScheme.surface,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            l10n.teamRotaPeopleCount(assignedCount),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final user in users)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyUserAvatar(user, radius: avatarSize / 2),
              const SizedBox(width: 6),
              Text(
                _givenName(user),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
      ],
    );
  }
}

class _DurationBar extends StatelessWidget {
  const _DurationBar({
    required this.fraction,
    required this.yours,
  });

  final double fraction;
  final bool yours;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fill = yours
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: 0.4);
    return SizedBox(
      height: 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaSilhouette extends StatelessWidget {
  const _AgendaSilhouette({
    required this.agenda,
    required this.activeCluster,
    required this.onTap,
  });

  final ScheduleAgendaLayout agenda;
  final int? activeCluster;
  final void Function(double dy, double height) onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => onTap(
            details.localPosition.dy,
            constraints.maxHeight,
          ),
          child: CustomPaint(
            painter: _SilhouettePainter(
              agenda: agenda,
              activeCluster: activeCluster,
              active: colorScheme.primary,
              idle: colorScheme.outline.withValues(alpha: 0.45),
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter({
    required this.agenda,
    required this.activeCluster,
    required this.active,
    required this.idle,
  });

  final ScheduleAgendaLayout agenda;
  final int? activeCluster;
  final Color active;
  final Color idle;

  @override
  void paint(final Canvas canvas, final Size size) {
    final start = agenda.dayStart;
    final end = agenda.dayEnd;
    if (start == null || end == null || size.height <= 0) return;
    final totalMs = end.difference(start).inMilliseconds;
    if (totalMs <= 0) return;

    double yFor(final DateTime time) {
      final ms = time.difference(start).inMilliseconds;
      return (ms / totalMs * size.height).clamp(0.0, size.height);
    }

    for (var i = 0; i < agenda.clusters.length; i++) {
      final paint = Paint()
        ..color = i == activeCluster ? active : idle
        ..style = PaintingStyle.fill;
      for (final turn in agenda.clusters[i].turns) {
        final top = yFor(turn.start);
        final height = (yFor(turn.end) - top).clamp(2.0, size.height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, top, size.width, height),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(final _SilhouettePainter oldDelegate) {
    return oldDelegate.activeCluster != activeCluster ||
        oldDelegate.agenda != agenda ||
        oldDelegate.active != active ||
        oldDelegate.idle != idle;
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(final Canvas canvas, final Size size) {
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
        Radius.circular(radius),
      ));
    final dashed = Path();
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 5;
        dashed.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + 4;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(final _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
