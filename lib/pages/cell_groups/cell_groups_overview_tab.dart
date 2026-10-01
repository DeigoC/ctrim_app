import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/cell_group_db_manager.dart';
import '../../models/cell_group.dart';
import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/activity_time_series.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/cache/directory_cache.dart';
import '../../utility/cell_group_activity_stats.dart';
import '../../utility/cell_group_roster_cache.dart';
import '../../utility/personal_cell_group_meetings.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/volunteer_role_helpers.dart';
import '../../widgets/common/activity_trend_section.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/user_avatar.dart';

/// Intro for Cell Groups, plus an activity card for people who serve.
class CellGroupsOverviewTab extends StatefulWidget {
  const CellGroupsOverviewTab({
    super.key,
    required this.onBrowseGroups,
    this.loadActivityMeetings,
  });

  /// Switches the Cell Groups shell to the Groups tab.
  final VoidCallback onBrowseGroups;

  /// Bulletin meetings for the activity card. Tests supply this so the
  /// overview does not query Firestore.
  final Future<List<EventHead>> Function()? loadActivityMeetings;

  /// Same Drive `uc?id=` form as Information → About hardcoded images.
  /// [CachedImageWidget] applies the web CORS proxy and local byte cache.
  static const String _overviewImage =
      'https://drive.google.com/uc?id=1nG1r-fbzkxJxD6qa9jsvcubqCbye2DOS';

  @override
  State<CellGroupsOverviewTab> createState() => _CellGroupsOverviewTabState();
}

class _CellGroupsOverviewTabState extends State<CellGroupsOverviewTab> {
  List<CellGroup> _memberGroups = const [];
  bool _membershipReady = false;
  String? _loadedForUserId;
  int _loadGeneration = 0;
  Object? _epochStamp;
  bool _showActivity = false;
  CellGroupActivityStats? _stats;
  List<EventHead> _meetings = const [];
  bool _loadingStats = false;
  Object? _statsError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = Provider.of<AppContext>(context);
    final stamp = Object.hash(
      app.catalogsEpoch,
      app.usersEpoch,
      app.sessionEpoch,
      app.currentUser.id,
    );
    if (stamp == _epochStamp) return;
    _epochStamp = stamp;

    // Assign before build. setState here runs inside the current build.
    if (app.currentUser.id != _loadedForUserId) {
      _memberGroups = const [];
      _membershipReady = app.isCurrentUserGuest;
      _applyActivityVisibility(app);
    }
    _enqueueMembershipLoad();
  }

  void _applyActivityVisibility(AppContext app) {
    _showActivity = VolunteerRoleHelpers.canSeeOverviewActivity(
      user: app.currentUser,
      isGuest: app.isCurrentUserGuest,
      catalogue: app.allCellGroups,
    );
    if (_showActivity) {
      _loadingStats = _stats == null;
      _statsError = null;
    } else {
      _stats = null;
      _meetings = const [];
      _loadingStats = false;
      _statsError = null;
    }
  }

  void _enqueueMembershipLoad({bool force = false}) {
    final generation = ++_loadGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _loadGeneration) return;
      _loadMembership(generation: generation, force: force);
    });
  }

  Future<void> _loadMembership({
    bool force = false,
    int? generation,
  }) async {
    final loadGeneration = generation ?? ++_loadGeneration;
    final app = Provider.of<AppContext>(context, listen: false);
    final userId = app.currentUser.id;

    if (app.isCurrentUserGuest) {
      if (!mounted || loadGeneration != _loadGeneration) return;
      setState(() {
        _memberGroups = const [];
        _membershipReady = true;
        _loadedForUserId = userId;
        _showActivity = false;
        _stats = null;
        _meetings = const [];
        _loadingStats = false;
        _statsError = null;
      });
      return;
    }

    if (_loadedForUserId != userId) {
      setState(() {
        _memberGroups = const [];
        _membershipReady = false;
      });
    }

    try {
      if (app.allCellGroups.isEmpty) {
        await DirectoryCacheCoordinator.instance.revalidate(
          app: app,
          ignoreCooldown: true,
        );
      }
      if (!mounted || loadGeneration != _loadGeneration) return;

      final current = Provider.of<AppContext>(context, listen: false);
      final active =
          current.allCellGroups.where((group) => !group.isArchived).toList();
      if (force) {
        for (final group in active) {
          CellGroupRosterCache.invalidate(group.id);
        }
      }
      await CellGroupRosterCache.ensureLoaded(active.map((group) => group.id));
      if (!mounted || loadGeneration != _loadGeneration) return;

      final latest = Provider.of<AppContext>(context, listen: false);
      setState(() {
        _memberGroups = CellGroupRosterCache.groupsForUser(
          user: latest.currentUser,
          catalogue: latest.allCellGroups,
        );
        _membershipReady = true;
        _loadedForUserId = latest.currentUser.id;
      });
      await _refreshActivity(latest, loadGeneration);
    } catch (_) {
      if (!mounted || loadGeneration != _loadGeneration) return;
      setState(() {
        _membershipReady = true;
        _loadedForUserId = userId;
      });
      final latest = Provider.of<AppContext>(context, listen: false);
      await _refreshActivity(latest, loadGeneration);
    }
  }

  Future<void> _refreshActivity(AppContext app, int loadGeneration) async {
    final show = VolunteerRoleHelpers.canSeeOverviewActivity(
      user: app.currentUser,
      isGuest: app.isCurrentUserGuest,
      catalogue: app.allCellGroups,
    );
    if (!show) {
      if (!mounted || loadGeneration != _loadGeneration) return;
      setState(() {
        _showActivity = false;
        _stats = null;
        _meetings = const [];
        _loadingStats = false;
        _statsError = null;
      });
      return;
    }

    if (!mounted || loadGeneration != _loadGeneration) return;
    setState(() {
      _showActivity = true;
      _loadingStats = true;
      _statsError = null;
    });

    try {
      final meetings = widget.loadActivityMeetings != null
          ? await widget.loadActivityMeetings!()
          : await CellGroupDBManager().fetchLinkedMeetingsInActivityWindow();
      if (!mounted || loadGeneration != _loadGeneration) return;
      final latest = Provider.of<AppContext>(context, listen: false);
      setState(() {
        _meetings = meetings;
        _stats = CellGroupActivityStats.compute(
          groups: latest.allCellGroups,
          meetings: meetings,
        );
        _showActivity = true;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted || loadGeneration != _loadGeneration) return;
      setState(() {
        _showActivity = true;
        _statsError = e;
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isGuest = context.select((AppContext c) => c.isCurrentUserGuest);
    context.select((AppContext c) => c.usersEpoch);
    final users = Provider.of<AppContext>(context, listen: false).allUsers;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final maxWidth = ResponsiveLayout.maxContentWidth(screenWidth);
        final horizontalPadding =
            screenWidth < ResponsiveLayout.compact ? 16.0 : 32.0;
        final isWideScreen = ResponsiveLayout.isWideScreenOf(context);

        return RefreshIndicator(
          onRefresh: () => _loadMembership(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primaryContainer,
                            colorScheme.secondaryContainer
                                .withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.groups,
                              size: 48, color: colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            l10n.cellGroupsOverviewHeadline,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.cellGroupsOverviewIntro,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    InfoSectionCard(
                      icon: Icons.auto_stories_outlined,
                      title: l10n.cellGroupsMeetingLikeTitle,
                      content: _MeetingPoints(l10n: l10n),
                    ),
                    const SizedBox(height: 24),
                    InfoSectionCard(
                      icon: Icons.search,
                      title: l10n.cellGroupsFindTitle,
                      content: _buildFindContent(
                        context,
                        l10n,
                        users: users,
                        showMembership: !isGuest,
                      ),
                    ),
                    if (_showActivity) ...[
                      const SizedBox(height: 24),
                      InfoSectionCard(
                        icon: Icons.insights_outlined,
                        title: l10n.cellGroupsActivityTitle,
                        subtitle: l10n.cellGroupsActivitySubtitle,
                        content: _buildActivityContent(context, l10n),
                      ),
                    ],
                    const SizedBox(height: 24),
                    InfoSectionCard(
                      icon: Icons.menu_book,
                      title: l10n.cellGroupsOverviewVerseTitle,
                      subtitle: l10n.cellGroupsOverviewVerseReference,
                      content: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          l10n.cellGroupsOverviewVerseBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedImageWidget(
                        imageUrl: CellGroupsOverviewTab._overviewImage,
                        height: isWideScreen ? 250 : 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFindContent(
    BuildContext context,
    AppLocalizations l10n, {
    required List<User> users,
    required bool showMembership,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groups = showMembership ? _memberGroups : const <CellGroup>[];
    final waiting = showMembership && !_membershipReady;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (waiting)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (groups.isNotEmpty) ...[
          Text(
            l10n.cellGroupsFindMembershipHeading(groups.length),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < groups.length; i++)
                  _MemberGroupRow(
                    group: groups[i],
                    users: users,
                    showDivider: i > 0,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          l10n.cellGroupsFindHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.onBrowseGroups,
            icon: const Icon(Icons.groups_outlined),
            label: Text(l10n.cellGroupsFindBrowse),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityContent(BuildContext context, AppLocalizations l10n) {
    if (_loadingStats && _stats == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_statsError != null && _stats == null) {
      return Column(
        children: [
          Text(
            l10n.cellGroupsActivityLoadError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _loadMembership(force: true),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.cellGroupsActivityRetry),
          ),
        ],
      );
    }

    final stats = _stats ?? CellGroupActivityStats.empty();
    final avgLabel = stats.averagePastAttendance == null
        ? '—'
        : stats.averagePastAttendance!.toStringAsFixed(
            stats.averagePastAttendance! ==
                    stats.averagePastAttendance!.roundToDouble()
                ? 0
                : 1,
          );

    return Column(
      children: [
        _ActivityMetricRow(
          tiles: [
            _ActivityStatTile(
              icon: Icons.event_available_outlined,
              value: '${stats.pastMeetingsCount}',
              label: l10n.cellGroupsActivityPastMeetings,
              hint: l10n.cellGroupsActivityPastMeetingsHint,
            ),
            _ActivityStatTile(
              icon: Icons.people_outline,
              value: '${stats.pastAttendeesTotal}',
              label: l10n.cellGroupsActivityPastAttendees,
              hint: l10n.cellGroupsActivityPastAttendeesHint,
            ),
            _ActivityStatTile(
              icon: Icons.upcoming_outlined,
              value: '${stats.upcomingMeetingsCount}',
              label: l10n.cellGroupsActivityUpcoming,
              hint: l10n.cellGroupsActivityUpcomingHint,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 12),
        _ActivitySecondaryMetrics(
          metrics: [
            (
              '${stats.activeGroupsCount}',
              l10n.cellGroupsActivityActiveGroupsLabel,
            ),
            (
              '${stats.totalActiveMembers}',
              l10n.cellGroupsActivityTotalMembersLabel,
            ),
            (
              '${stats.distinctGroupsMetPast}',
              l10n.cellGroupsActivityGroupsMetLabel,
            ),
            (avgLabel, l10n.cellGroupsActivityAvgAttendanceLabel),
            if (stats.pausedGroupsCount > 0)
              (
                '${stats.pausedGroupsCount}',
                l10n.cellGroupsActivityPausedGroupsLabel,
              ),
          ],
        ),
        const SizedBox(height: 20),
        _buildActivityTrendChart(context, l10n),
      ],
    );
  }

  Widget _buildActivityTrendChart(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final chartStart = CellGroupActivityStats.chartPastWindowStart(now);
    final chartEnd = CellGroupActivityStats.chartWindowEndExclusive(now);
    final countPoints = ActivityTimeSeries.fromCellGroupMeetings(
      meetings: _meetings,
      metric: ActivityTimeSeriesMetric.count,
      startInclusive: chartStart,
      endExclusive: chartEnd,
    );
    final attendancePoints = ActivityTimeSeries.fromCellGroupMeetings(
      meetings: _meetings,
      metric: ActivityTimeSeriesMetric.attendance,
      startInclusive: chartStart,
      endExclusive: chartEnd,
    );

    return ActivityTrendSection(
      title: l10n.cellGroupsActivityTrendTitle,
      subtitle: l10n.cellGroupsActivityTrendSubtitle,
      countLabel: l10n.cellGroupsActivityTrendMetricMeetings,
      countPoints: countPoints,
      attendancePoints: attendancePoints,
      emptyMessage: l10n.activityTrendEmpty,
      weeklyHint: l10n.activityTrendWeeklyHint,
    );
  }
}

class _MeetingPoints extends StatelessWidget {
  const _MeetingPoints({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final points = [
      _MeetingPoint(
        icon: Icons.menu_book_outlined,
        title: l10n.cellGroupsMeetingLikeBibleTitle,
        body: l10n.cellGroupsMeetingLikeBibleBody,
      ),
      _MeetingPoint(
        icon: Icons.favorite_outline,
        title: l10n.cellGroupsMeetingLikeCareTitle,
        body: l10n.cellGroupsMeetingLikeCareBody,
      ),
      _MeetingPoint(
        icon: Icons.groups_outlined,
        title: l10n.cellGroupsMeetingLikeFellowshipTitle,
        body: l10n.cellGroupsMeetingLikeFellowshipBody,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < points.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                points[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < points.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: points[i]),
            ],
          ],
        );
      },
    );
  }
}

class _MeetingPoint extends StatelessWidget {
  const _MeetingPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberGroupRow extends StatelessWidget {
  const _MemberGroupRow({
    required this.group,
    required this.users,
    required this.showDivider,
  });

  final CellGroup group;
  final List<User> users;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final leader = PersonalCellGroupMeetings.primaryLeaderForGroup(
      group: group,
      users: users,
    );
    final leaderName = PersonalCellGroupMeetings.leaderDisplayName(
      group: group,
      users: users,
      fallbackLabel: l10n.personalCellGroupLeaderTbc,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => AppLinks.openCellGroup(context, id: group.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  _leaderAvatar(colorScheme, leader),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.personalCellGroupLedBy(leaderName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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

  Widget _leaderAvatar(ColorScheme colorScheme, User? leader) {
    if (leader != null) {
      return MyUserAvatar(leader, radius: 20);
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        Icons.groups_outlined,
        size: 22,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _ActivityMetricRow extends StatelessWidget {
  const _ActivityMetricRow({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                tiles[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: tiles[i]),
            ],
          ],
        );
      },
    );
  }
}

class _ActivityStatTile extends StatelessWidget {
  const _ActivityStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.hint,
  });

  final IconData icon;
  final String value;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySecondaryMetrics extends StatelessWidget {
  const _ActivitySecondaryMetrics({required this.metrics});

  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 420;
        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _ActivitySecondaryMetric(
                  value: metrics[i].$1,
                  label: metrics[i].$2,
                ),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < metrics.length; i += 2) {
          if (i > 0) rows.add(const SizedBox(height: 10));
          if (i + 1 < metrics.length) {
            rows.add(Row(
              children: [
                Expanded(
                  child: _ActivitySecondaryMetric(
                    value: metrics[i].$1,
                    label: metrics[i].$2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActivitySecondaryMetric(
                    value: metrics[i + 1].$1,
                    label: metrics[i + 1].$2,
                  ),
                ),
              ],
            ));
          } else {
            rows.add(_ActivitySecondaryMetric(
              value: metrics[i].$1,
              label: metrics[i].$2,
            ));
          }
        }
        return Column(children: rows);
      },
    );
  }
}

class _ActivitySecondaryMetric extends StatelessWidget {
  const _ActivitySecondaryMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
