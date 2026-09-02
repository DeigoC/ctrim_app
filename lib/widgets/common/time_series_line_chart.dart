import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utility/activity_time_series.dart';

/// Themed weekly line chart for activity dashboards.
class TimeSeriesLineChart extends StatelessWidget {
  const TimeSeriesLineChart({
    super.key,
    required this.points,
    this.height = 200,
    this.valueIsInteger = true,
  });

  final List<TimeSeriesPoint> points;
  final double height;
  final bool valueIsInteger;

  static final DateFormat _weekLabelFormat = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(height: height);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxValue = points.fold<double>(
      0,
      (final max, final p) => p.value > max ? p.value : max,
    );
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.15;

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: points.length <= 1 ? 1 : (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 4 ? 1 : null,
            getDrawingHorizontalLine: (final value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: maxY <= 4 ? 1 : null,
                getTitlesWidget: (final value, final meta) {
                  if (value < 0 || value > maxY) {
                    return const SizedBox.shrink();
                  }
                  if (valueIsInteger && value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      valueIsInteger ? '${value.round()}' : value.toStringAsFixed(1),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _bottomLabelInterval(points.length),
                getTitlesWidget: (final value, final meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  if (!_shouldShowBottomLabel(index, points.length)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _weekLabelFormat.format(points[index].weekStart),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (final _) =>
                  colorScheme.inverseSurface.withValues(alpha: 0.92),
              getTooltipItems: (final touchedSpots) {
                return touchedSpots.map((final spot) {
                  final index = spot.x.round();
                  if (index < 0 || index >= points.length) {
                    return null;
                  }
                  final point = points[index];
                  final valueText = valueIsInteger
                      ? '${point.value.round()}'
                      : point.value.toStringAsFixed(1);
                  return LineTooltipItem(
                    '${_weekLabelFormat.format(point.weekStart)}\n$valueText',
                    theme.textTheme.labelSmall!.copyWith(
                      color: colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: colorScheme.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: points.length <= 14,
                getDotPainter: (final spot, final percent, final bar, final index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: colorScheme.primary,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  static double _bottomLabelInterval(final int count) {
    if (count <= 1) return 1;
    if (count <= 6) return 1;
    if (count <= 10) return 2;
    return 3;
  }

  static bool _shouldShowBottomLabel(final int index, final int count) {
    if (count <= 6) return true;
    if (index == 0 || index == count - 1) return true;
    final interval = _bottomLabelInterval(count).round();
    return index % interval == 0;
  }
}
