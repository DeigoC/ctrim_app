import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/info/church_info.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/activity_time_series.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/catalog/user_tag_helpers.dart';
import '../../utility/church_location_report.dart';
import '../../utility/church_location_stats.dart';
import '../../utility/info_repository.dart';
import '../../utility/cache/refresh_cooldown.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/common/activity_trend_section.dart';
import '../../widgets/common/load_progress_body.dart';
import '../../widgets/information/info_section_card.dart';
import '../../widgets/two_column_masonry.dart';

/// Statistics for the church's linked location.
///
/// Opened from the hub's At this location card, and from
/// `/churches/:id/statistics`.
class ChurchLocationStatsPage extends StatefulWidget {
  const ChurchLocationStatsPage({
    super.key,
    required this.documentId,
    this.initialChurch,
  });

  final String documentId;

  /// Church already on screen. The cover is not shown here; this only skips
  /// the first church fetch's empty frame.
  final ChurchInfo? initialChurch;

  @override
  State<ChurchLocationStatsPage> createState() =>
      _ChurchLocationStatsPageState();
}

class _ChurchLocationStatsPageState extends State<ChurchLocationStatsPage> {
  final InfoRepository _repository = InfoRepository();
  final EventHeadDBManager _eventHeads = EventHeadDBManager();

  ChurchInfo? _church;
  List<EventHead>? _heads;
  DateTime? _asOf;
  bool _loadingChurch = true;
  bool _loggedScreen = false;
  Object? _error;
  Object? _statsError;

  @override
  void initState() {
    super.initState();
    final seeded = widget.initialChurch;
    if (seeded != null && seeded.id == widget.documentId) {
      _church = seeded;
      _loadingChurch = false;
    }
    _load(forceRefresh: false);
  }

  Future<void> _load({required bool forceRefresh}) async {
    final appContext = Provider.of<AppContext>(context, listen: false);
    setState(() {
      _error = null;
      _loadingChurch = _church == null;
    });
    try {
      final church = await _repository.fetchChurchById(
        widget.documentId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      if (church != null && !_loggedScreen) {
        _loggedScreen = true;
        appContext.analytics.logChurchStatistics(church.id);
      }

      if (church == null || !church.hasLocation) {
        setState(() {
          _church = church;
          _loadingChurch = false;
          _heads = const [];
          _asOf = DateTime.now();
          _statsError = null;
        });
        return;
      }

      setState(() {
        _church = church;
        _loadingChurch = false;
        _statsError = null;
      });

      final clock = DateTime.now();
      final heads = await _eventHeads.fetchHeadsWithEventDateInRange(
        startInclusive: ChurchLocationStats.queryRangeStart(clock),
        endExclusive: ChurchLocationStats.queryRangeEndExclusive(clock),
      );
      if (!mounted) return;
      setState(() {
        _heads = heads;
        _asOf = clock;
        _statsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingChurch = false;
        if (_church == null) {
          _error = e;
        } else {
          _statsError = e;
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    final pref = Provider.of<AppContext>(context, listen: false).sharedPref;
    if (!pref.canRefreshInfo) {
      await Future.delayed(kRefreshCooldownBusyWait);
      return;
    }
    pref.setInfoRefreshTime();
    await _load(forceRefresh: true);
  }

  ChurchLocationReport? _report() {
    final church = _church;
    final heads = _heads;
    final asOf = _asOf;
    if (church == null ||
        !church.hasLocation ||
        heads == null ||
        asOf == null ||
        _statsError != null) {
      return null;
    }
    final appContext = Provider.of<AppContext>(context, listen: false);
    return ChurchLocationReport.compute(
      location: church.location,
      users: appContext.allUsers,
      groups: appContext.allCellGroups,
      heads: heads,
      ministries: appContext.allTags,
      postTags: appContext.allPostTags,
      viewerIsGuest: appContext.isCurrentUserGuest,
      now: asOf,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select((AppContext c) => c.usersEpoch);
    context.select((AppContext c) => c.catalogsEpoch);
    context.select((AppContext c) => c.sessionEpoch);

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final church = _church;
    final report = _report();
    final waitingForStats = church != null &&
        church.hasLocation &&
        report == null &&
        _statsError == null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.churchLocationStatsTitle),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (_loadingChurch || waitingForStats)
              SliverFillRemaining(
                hasScrollBody: false,
                child: LoadProgressBody(
                  message: l10n.churchLocationStatsLoading,
                  completedSteps: 0,
                  totalSteps: 1,
                  error: _error,
                  errorTitle: l10n.churchInfoLoadError,
                  onRetry:
                      _error == null ? null : () => _load(forceRefresh: true),
                ),
              )
            else if (church == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(l10n.churchInfoNotFound)),
              )
            else if (_statsError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: LoadProgressBody(
                  message: '',
                  completedSteps: 0,
                  totalSteps: 1,
                  error: _statsError,
                  errorTitle: l10n.churchHubStatsError,
                  onRetry: () => _load(forceRefresh: true),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveLayout.horizontalGutter(
                        MediaQuery.sizeOf(context).width,
                        narrowPadding: 0,
                      ) +
                      16,
                  20,
                  ResponsiveLayout.horizontalGutter(
                        MediaQuery.sizeOf(context).width,
                        narrowPadding: 0,
                      ) +
                      16,
                  40,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: ResponsiveLayout.maxContentWidth(
                          MediaQuery.sizeOf(context).width,
                        ),
                      ),
                      child: _StatsBody(
                        church: church,
                        report: report,
                        asOf: _asOf,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({
    required this.church,
    required this.report,
    required this.asOf,
  });

  final ChurchInfo church;
  final ChurchLocationReport? report;
  final DateTime? asOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!church.hasLocation || report == null) {
      return Text(
        l10n.churchHubSetLocationHint,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final cards = <Widget>[
      _PeopleCard(section: report!.people),
      _GroupsCard(section: report!.cellGroups),
      _PostsCard(section: report!.posts, asOf: asOf ?? DateTime.now()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          church.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          church.location,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        if (ResponsiveLayout.isWideScreenOf(context))
          TwoColumnMasonry(children: cards)
        else ...[
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            cards[i],
          ],
        ],
      ],
    );
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({required this.section});

  final ChurchLocationPeopleSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = [
      _StatTile(
        icon: Icons.people_outline,
        value: '${section.profileCount}',
        label: l10n.churchHubPeopleLabel,
        hint: l10n.churchHubPeopleHint,
      ),
      _StatTile(
        icon: Icons.badge_outlined,
        value: '${section.inMinistryCount}',
        label: l10n.churchLocationStatsInMinistry,
        hint: l10n.churchLocationStatsInMinistryHint,
      ),
      _StatTile(
        icon: Icons.person_outline,
        value: '${section.notInMinistryCount}',
        label: l10n.churchLocationStatsNotInMinistry,
        hint: l10n.churchLocationStatsNotInMinistryHint,
      ),
      _StatTile(
        icon: Icons.verified_outlined,
        value: '${section.leaderCount}',
        label: l10n.churchLocationStatsLeaders,
        hint: l10n.churchLocationStatsLeadersHint,
      ),
    ];

    return InfoSectionCard(
      icon: Icons.people_outline,
      title: l10n.churchLocationStatsPeopleTitle,
      subtitle: l10n.churchLocationStatsPeopleSubtitle,
      content: section.isEmpty
          ? _EmptyLine(l10n.churchLocationStatsPeopleEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatGrid(tiles: tiles, wideColumns: 2, narrowColumns: 2),
                if (section.ministries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _CountRows(rows: section.ministries),
                  const SizedBox(height: 8),
                  _Footnote(l10n.churchLocationStatsMinistryHint),
                ],
              ],
            ),
    );
  }
}

class _GroupsCard extends StatelessWidget {
  const _GroupsCard({required this.section});

  final ChurchLocationGroupsSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final average = section.averageSize;

    return InfoSectionCard(
      icon: Icons.groups_outlined,
      title: l10n.churchHubCellGroupsLabel,
      subtitle: l10n.churchHubCellGroupsHint,
      content: section.isEmpty
          ? _EmptyLine(l10n.churchHubNoCellGroups)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatGrid(
                  tiles: [
                    _StatTile(
                      icon: Icons.groups_outlined,
                      value: '${section.groupCount}',
                      label: l10n.churchHubCellGroupsLabel,
                      hint: l10n.churchHubCellGroupsHint,
                    ),
                    _StatTile(
                      icon: Icons.people_outline,
                      value: '${section.membersListed}',
                      label: l10n.churchLocationStatsMembersListed,
                      hint: l10n.churchLocationStatsMembersListedHint,
                    ),
                    _StatTile(
                      icon: Icons.pie_chart_outline,
                      value: average == null ? '—' : _formatAverage(average),
                      label: l10n.churchLocationStatsAverageSize,
                      hint: l10n.churchLocationStatsAverageSizeHint,
                    ),
                  ],
                  wideColumns: 3,
                  narrowColumns: 1,
                ),
                if (section.groups.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _CountRows(
                    rows: section.groups,
                    onOpen: (row) =>
                        AppLinks.openCellGroup(context, id: row.id),
                  ),
                  const SizedBox(height: 8),
                  _Footnote(l10n.churchLocationStatsGroupsDoubleCount),
                ],
              ],
            ),
    );
  }
}

class _PostsCard extends StatelessWidget {
  const _PostsCard({required this.section, required this.asOf});

  final ChurchLocationPostsSection section;
  final DateTime asOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final average = section.averageAttendance;
    final chartStart = ChurchLocationStats.queryRangeStart(asOf);
    final chartEnd = ChurchLocationStats.queryRangeEndExclusive(asOf);
    final countPoints = ActivityTimeSeries.fromPosts(
      posts: section.posts,
      metric: ActivityTimeSeriesMetric.count,
      startInclusive: chartStart,
      endExclusive: chartEnd,
    );
    final attendancePoints = ActivityTimeSeries.fromPosts(
      posts: section.posts,
      metric: ActivityTimeSeriesMetric.attendance,
      startInclusive: chartStart,
      endExclusive: chartEnd,
    );

    return InfoSectionCard(
      icon: Icons.event_note_outlined,
      title: l10n.churchHubPostsLabel,
      subtitle: l10n.churchHubPostsHint,
      content: section.isEmpty
          ? _EmptyLine(l10n.churchHubNoRecentPosts)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatGrid(
                  tiles: [
                    _StatTile(
                      icon: Icons.event_note_outlined,
                      value: '${section.postCount}',
                      label: l10n.churchHubPostsLabel,
                      hint: l10n.churchHubPostsHint,
                    ),
                    _StatTile(
                      icon: Icons.groups_outlined,
                      value: '${section.cellGroupMeetingCount}',
                      label: l10n.churchLocationStatsMeetings,
                      hint: l10n.churchLocationStatsMeetingsHint,
                    ),
                    _StatTile(
                      icon: Icons.article_outlined,
                      value: '${section.otherPostCount}',
                      label: l10n.churchLocationStatsOtherPosts,
                      hint: l10n.churchLocationStatsOtherPostsHint,
                    ),
                    _StatTile(
                      icon: Icons.how_to_reg_outlined,
                      value: '${section.attendanceTotal}',
                      label: l10n.churchLocationStatsAttendance,
                      hint: l10n.churchLocationStatsAttendanceHint,
                    ),
                    _StatTile(
                      icon: Icons.show_chart,
                      value: average == null ? '—' : _formatAverage(average),
                      label: l10n.churchLocationStatsAverageAttendance,
                      hint: l10n.churchLocationStatsAverageAttendanceHint,
                    ),
                    _StatTile(
                      icon: Icons.favorite_border,
                      value: '${section.interestedTotal}',
                      label: l10n.churchLocationStatsInterested,
                      hint: l10n.churchLocationStatsInterestedHint,
                    ),
                  ],
                  wideColumns: 3,
                  narrowColumns: 2,
                ),
                if (section.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _CountRows(rows: section.tags),
                  const SizedBox(height: 8),
                  _Footnote(l10n.churchLocationStatsPostTagHint),
                ],
                const SizedBox(height: 20),
                ActivityTrendSection(
                  title: l10n.churchHubActivityTrendTitle,
                  subtitle: l10n.churchHubActivityTrendSubtitle,
                  countLabel: l10n.churchHubActivityTrendMetricPosts,
                  countPoints: countPoints,
                  attendancePoints: attendancePoints,
                  emptyMessage: l10n.activityTrendEmpty,
                  weeklyHint: l10n.activityTrendWeeklyHint,
                ),
              ],
            ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.tiles,
    required this.wideColumns,
    required this.narrowColumns,
  });

  final List<Widget> tiles;
  final int wideColumns;
  final int narrowColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 520 ? wideColumns : narrowColumns;
        final rows = <Widget>[];
        for (var i = 0; i < tiles.length; i += columns) {
          final end = i + columns > tiles.length ? tiles.length : i + columns;
          final slice = tiles.sublist(i, end);
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: 12),
                  Expanded(
                    child:
                        j < slice.length ? slice[j] : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
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

class _CountRows extends StatelessWidget {
  const _CountRows({required this.rows, this.onOpen});

  final List<ChurchLocationCountRow> rows;
  final void Function(ChurchLocationCountRow row)? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          _CountRow(
            row: rows[i],
            label: rows[i].id == ChurchLocationReport.untaggedPostId
                ? l10n.churchLocationStatsNoTag
                : rows[i].name,
            onTap: onOpen == null ? null : () => onOpen!(rows[i]),
          ),
        ],
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.row,
    required this.label,
    this.onTap,
  });

  final ChurchLocationCountRow row;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parsed = UserTagHelpers.parseColor(row.colorHex);
    final Color dotColor;
    if (row.id == ChurchLocationReport.untaggedPostId) {
      dotColor = colorScheme.outline;
    } else {
      dotColor = parsed ?? colorScheme.primary;
    }

    final rowChild = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${row.count}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );

    if (onTap == null) return rowChild;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: rowChild,
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
    );
  }
}

String _formatAverage(final double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}
