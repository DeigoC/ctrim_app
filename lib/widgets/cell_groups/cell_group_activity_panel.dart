import 'package:flutter/material.dart';

import '../../models/event/event_head.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/activity_time_series.dart';
import '../../utility/cell_group_activity_stats.dart';
import '../../utility/cell_group_detail_activity_stats.dart';
import '../common/activity_trend_section.dart';

/// Snapshot tiles + weekly chart for one cell group's linked meetings.
class CellGroupActivityPanel extends StatelessWidget {
  const CellGroupActivityPanel({
    super.key,
    required this.cellGroupId,
    required this.meetings,
  });

  final String cellGroupId;
  final List<EventHead> meetings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = CellGroupDetailActivityStats.compute(
      cellGroupId: cellGroupId,
      meetings: meetings,
    );
    final avgLabel = stats.averagePastAttendance == null
        ? '—'
        : stats.averagePastAttendance!.toStringAsFixed(
            stats.averagePastAttendance! ==
                    stats.averagePastAttendance!.roundToDouble()
                ? 0
                : 1,
          );

    final now = DateTime.now();
    final chartStart = CellGroupActivityStats.chartPastWindowStart(now);
    final chartEnd = CellGroupActivityStats.chartWindowEndExclusive(now);
    final countPoints = ActivityTimeSeries.fromCellGroupMeetings(
      meetings: meetings,
      metric: ActivityTimeSeriesMetric.count,
      startInclusive: chartStart,
      endExclusive: chartEnd,
      cellGroupId: cellGroupId,
    );
    final attendancePoints = ActivityTimeSeries.fromCellGroupMeetings(
      meetings: meetings,
      metric: ActivityTimeSeriesMetric.attendance,
      startInclusive: chartStart,
      endExclusive: chartEnd,
      cellGroupId: cellGroupId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            final tiles = [
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
            ];

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: tiles[i]),
                  ],
                ],
              );
            }

            return Column(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  tiles[i],
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              avgLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.cellGroupsActivityAvgAttendanceLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ActivityTrendSection(
          title: l10n.cellGroupsDetailActivityTrendTitle,
          subtitle: l10n.cellGroupsDetailActivityTrendSubtitle,
          countLabel: l10n.cellGroupsActivityTrendMetricMeetings,
          countPoints: countPoints,
          attendancePoints: attendancePoints,
          emptyMessage: l10n.activityTrendEmpty,
          weeklyHint: l10n.activityTrendWeeklyHint,
        ),
      ],
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
              color: colorScheme.onSurface,
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
