import 'package:flutter/material.dart';

import '../../src/localization/app_localizations.dart';
import '../../utility/activity_time_series.dart';
import 'time_series_line_chart.dart';

/// Chart block with count vs attendance toggle for activity dashboards.
class ActivityTrendSection extends StatefulWidget {
  const ActivityTrendSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.countPoints,
    required this.attendancePoints,
    required this.emptyMessage,
    required this.weeklyHint,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final List<TimeSeriesPoint> countPoints;
  final List<TimeSeriesPoint> attendancePoints;
  final String emptyMessage;
  final String weeklyHint;

  @override
  State<ActivityTrendSection> createState() => _ActivityTrendSectionState();
}

class _ActivityTrendSectionState extends State<ActivityTrendSection> {
  ActivityTimeSeriesMetric _metric = ActivityTimeSeriesMetric.count;

  List<TimeSeriesPoint> get _activePoints =>
      _metric == ActivityTimeSeriesMetric.count
          ? widget.countPoints
          : widget.attendancePoints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final points = _activePoints;
    final hasData = ActivityTimeSeries.hasNonZeroValues(points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(widget.countLabel),
              selected: _metric == ActivityTimeSeriesMetric.count,
              onSelected: (final selected) {
                if (!selected) return;
                setState(() => _metric = ActivityTimeSeriesMetric.count);
              },
            ),
            FilterChip(
              label: Text(l10n.activityTrendMetricAttendance),
              selected: _metric == ActivityTimeSeriesMetric.attendance,
              onSelected: (final selected) {
                if (!selected) return;
                setState(() => _metric = ActivityTimeSeriesMetric.attendance);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.weeklyHint,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (!hasData)
          Text(
            widget.emptyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          TimeSeriesLineChart(points: points),
      ],
    );
  }
}
