import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_program.dart';
import '../../models/user.dart';
import '../../pages/personal/team_rota_role_actions.dart';
import '../../pages/personal/view_team_rota_page.dart';
import '../../pages/personal/view_team_rota_schedule_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/ministry_schedule_preview.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/team_rota.dart';
import '../information/info_section_card.dart';
import '../my_avatar_stack.dart';

/// Personal home card for the next ministry services.
///
/// Wide windows place this under My Schedule and Cell Groups, full width.
/// A row opens that event's schedule. The button opens the month list.
class PersonalMinistrySchedulePreviewCard extends StatefulWidget {
  const PersonalMinistrySchedulePreviewCard({
    super.key,
    required this.appContext,
  });

  final AppContext appContext;

  @override
  State<PersonalMinistrySchedulePreviewCard> createState() =>
      _PersonalMinistrySchedulePreviewCardState();
}

class _PersonalMinistrySchedulePreviewCardState
    extends State<PersonalMinistrySchedulePreviewCard> {
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');

  MinistrySchedulePreviewSnapshot? _snapshot;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && (!_loading || _error != null)) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final snapshot = await MinistrySchedulePreview.load(
        user: widget.appContext.currentUser,
        allTags: widget.appContext.allTags,
        locations: widget.appContext.allLocations,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      debugPrint('Could not load ministry schedule preview: $e\n$st');
      if (!mounted) return;
      if (silent && _snapshot != null) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _applyProgram(String postId, EventProgram program) {
    final current = _snapshot;
    if (current == null) return;
    final programs = Map<String, EventProgram>.from(current.programs);
    programs[postId] = program;
    TeamRotaPost? existing;
    for (final post in current.posts) {
      if (post.head.id == postId) {
        existing = post;
        break;
      }
    }
    final updated = existing == null
        ? null
        : MinistrySchedulePreview.singlePost(
            head: existing.head,
            program: program,
            selectedTagIDs: current.selectedTagIDs,
            locationFilter: current.locationFilter,
          );
    final posts = <TeamRotaPost>[
      for (final post in current.posts)
        if (post.head.id != postId) post else if (updated != null) updated,
    ];
    setState(() {
      _snapshot = MinistrySchedulePreviewSnapshot(
        posts: posts,
        programs: programs,
        selectedTagIDs: current.selectedTagIDs,
        locationFilter: current.locationFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select((AppContext c) => (c.usersEpoch, c.catalogsEpoch));

    return InfoSectionCard(
      icon: Icons.groups_rounded,
      title: l10n.teamRota,
      subtitle: l10n.teamRotaSubtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBody(l10n),
          if (!_loading) ...[
            const SizedBox(height: 12),
            _buildViewButton(l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.teamRotaCouldNotLoad,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.personalMinistryScheduleRetry),
          ),
        ],
      );
    }
    final snapshot = _snapshot;
    if (snapshot == null || snapshot.posts.isEmpty) {
      return Text(
        l10n.personalMinistryScheduleEmpty,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    final gap = snapshot.firstGap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gap != null) ...[
          _NeedsPeopleLine(
            label: l10n.personalMinistryNeedsPeopleLine(
              gap.role['title'] as String? ?? '',
              gap.post.head.title,
            ),
            onTap: () => _openGap(gap),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < snapshot.posts.length; i++)
                _ServiceRow(
                  post: snapshot.posts[i],
                  showDivider: i > 0,
                  dateLabel: _dateLabel(l10n, snapshot.posts[i]),
                  showFaces: ResponsiveLayout.isWideScreenOf(context),
                  users: _assignees(snapshot.posts[i]),
                  onTap: () => _openSchedule(snapshot.posts[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewButton(AppLocalizations l10n) {
    final open = _snapshot?.hasOpenSlot ?? false;
    final icon = const Icon(Icons.groups_rounded);
    final label = Text(l10n.personalMinistryScheduleView);
    if (open) {
      return FilledButton.icon(
        onPressed: _openFullSchedule,
        icon: icon,
        label: label,
      );
    }
    return OutlinedButton.icon(
      onPressed: _openFullSchedule,
      icon: icon,
      label: label,
    );
  }

  String _dateLabel(AppLocalizations l10n, TeamRotaPost post) {
    final date = post.head.eventDate;
    if (date == null) return l10n.personalScheduleDateTbc;
    return _eventDateFormat.format(date);
  }

  List<User> _assignees(TeamRotaPost post) {
    final users = <User>[];
    for (final id in MinistrySchedulePreview.assigneeIds(post)) {
      final user = widget.appContext.userById(id);
      if (user != null) users.add(user);
    }
    return users;
  }

  Future<void> _openFullSchedule() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewTeamRotaPage()),
    );
    if (mounted) _load(silent: true);
  }

  void _openSchedule(TeamRotaPost post) {
    final program = _snapshot?.programs[post.head.id];
    final tagIDs = _snapshot?.selectedTagIDs;
    if (program == null || tagIDs == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewTeamRotaSchedulePage(
          head: post.head,
          program: program,
          selectedTagIDs: Set<String>.from(tagIDs),
          onProgramUpdated: (updated) => _applyProgram(post.head.id, updated),
        ),
      ),
    );
  }

  Future<void> _openGap(TeamRotaGap gap) {
    return TeamRotaRoleActions(
      context: context,
      appContext: widget.appContext,
      onProgramUpdated: _applyProgram,
    ).openRole(head: gap.post.head, role: gap.role);
  }
}

class _NeedsPeopleLine extends StatelessWidget {
  const _NeedsPeopleLine({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.errorContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.post,
    required this.showDivider,
    required this.dateLabel,
    required this.showFaces,
    required this.users,
    required this.onTap,
  });

  final TeamRotaPost post;
  final bool showDivider;
  final String dateLabel;
  final bool showFaces;
  final List<User> users;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = context.select((AppContext c) => c.currentUser.id);
    final gapCount = TeamRotaQuery.unassignedCount(post);
    final serving = TeamRotaQuery.viewerIsServing(post, currentUserId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showFaces && users.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    MyAvatarStack(
                      users: users,
                      height: 28,
                      width: (28.0 * users.length.clamp(1, 4)).clamp(28, 88),
                      borderWidth: 1.2,
                    ),
                  ],
                  const SizedBox(width: 8),
                  _Status(
                    gapCount: gapCount,
                    serving: serving,
                    gapsLabel: l10n.teamRotaCardGaps(gapCount),
                    servingLabel: l10n.teamRotaYoureServing,
                    coveredLabel: l10n.personalMinistryScheduleCovered,
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.gapCount,
    required this.serving,
    required this.gapsLabel,
    required this.servingLabel,
    required this.coveredLabel,
  });

  final int gapCount;
  final bool serving;
  final String gapsLabel;
  final String servingLabel;
  final String coveredLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (gapCount > 0)
          Text(
            gapsLabel,
            textAlign: TextAlign.end,
            style: style?.copyWith(color: colorScheme.error),
          ),
        if (gapCount > 0 && serving) const SizedBox(height: 2),
        if (serving)
          Text(
            servingLabel,
            textAlign: TextAlign.end,
            style: style?.copyWith(color: colorScheme.primary),
          ),
        if (gapCount == 0 && !serving)
          Text(
            coveredLabel,
            textAlign: TextAlign.end,
            style: style?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
