import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/schedule_timeline_layout.dart';
import 'schedule_timeline_block.dart';

/// Day-view canvas for a post schedule.
///
/// Blocks are positioned by clock time and sized by duration, so concurrent
/// roles sit side by side in lanes instead of stacking into one list.
class ScheduleTimeline extends StatelessWidget {
  const ScheduleTimeline({
    super.key,
    required this.layout,
    required this.usersForRole,
    required this.onRoleTap,
    this.selectedRoleId,
    this.onOverflowTap,
    this.onRoleMoved,
    this.pixelsPerMinute = defaultPixelsPerMinute,
    this.snapMinutes = defaultSnapMinutes,
  });

  /// Keeps a five-minute slot tall enough to read and tap.
  static const double defaultPixelsPerMinute = 3.5;

  /// Drop times land on a five-minute grid, like the duration presets.
  static const int defaultSnapMinutes = 5;
  static const double _railWidth = 52;
  static const double _laneGap = 4;
  static const double _minBlockHeight = 18;
  static const Duration _tickInterval = Duration(minutes: 30);

  final ScheduleTimelineLayout layout;
  final List<User> Function(Map<String, dynamic> role) usersForRole;
  final void Function(Map<String, dynamic> role) onRoleTap;
  final int? selectedRoleId;
  final void Function(ScheduleTimelineOverflow overflow)? onOverflowTap;

  /// When set, blocks can be long-pressed and dragged to a new start time.
  final void Function(Map<String, dynamic> role, DateTime newStart)?
      onRoleMoved;
  final double pixelsPerMinute;
  final int snapMinutes;

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final dayStart = layout.dayStart;
    final dayEnd = layout.dayEnd;
    if (dayStart == null || dayEnd == null) return const SizedBox.shrink();

    final canvasHeight = layout.totalMinutes * pixelsPerMinute;

    return LayoutBuilder(
      builder: (final context, final constraints) {
        final laneAreaWidth = constraints.maxWidth - _railWidth;

        return SizedBox(
          height: canvasHeight + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ..._buildTicks(context, dayStart: dayStart, dayEnd: dayEnd),
              for (final placement in layout.placements)
                _buildPlacement(placement, laneAreaWidth, dayStart),
              for (final overflow in layout.overflows)
                _buildOverflowMarker(context, overflow),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTicks(
    final BuildContext context, {
    required DateTime dayStart,
    required DateTime dayEnd,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ticks = <Widget>[];

    var tick = dayStart;
    while (!tick.isAfter(dayEnd)) {
      final top = _minutesBetween(dayStart, tick) * pixelsPerMinute;
      final isHour = tick.minute == 0;
      ticks.add(Positioned(
        top: top - 7,
        left: 0,
        right: 0,
        height: 14,
        child: Row(
          children: [
            SizedBox(
              width: _railWidth,
              child: Text(
                _timeFormat.format(tick),
                textAlign: TextAlign.right,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isHour
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: isHour ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: colorScheme.outlineVariant
                    .withValues(alpha: isHour ? 0.6 : 0.3),
              ),
            ),
          ],
        ),
      ));
      tick = tick.add(_tickInterval);
    }

    return ticks;
  }

  Widget _buildPlacement(
    final ScheduleTimelinePlacement placement,
    final double laneAreaWidth,
    final DateTime dayStart,
  ) {
    final laneWidth = laneAreaWidth / placement.laneCount;
    final proportionalHeight = placement.durationMinutes * pixelsPerMinute;
    final height = proportionalHeight < _minBlockHeight
        ? _minBlockHeight
        : proportionalHeight - 2;
    final onMoved = onRoleMoved;

    final Widget block = onMoved == null
        ? ScheduleTimelineBlock(
            title: placement.role['title'] as String,
            start: placement.start,
            end: placement.end,
            height: height,
            assignedUsers: usersForRole(placement.role),
            selected: selectedRoleId == placement.roleId,
            staffOnly: placement.role['for_guests'] != true,
            onTap: () => onRoleTap(placement.role),
          )
        : _DraggableTimelineBlock(
            key: ValueKey(placement.roleId),
            placement: placement,
            height: height,
            assignedUsers: usersForRole(placement.role),
            selected: selectedRoleId == placement.roleId,
            pixelsPerMinute: pixelsPerMinute,
            snapMinutes: snapMinutes,
            earliestStart: dayStart,
            onTap: () => onRoleTap(placement.role),
            onMoved: (newStart) => onMoved(placement.role, newStart),
          );

    return Positioned(
      key: ValueKey(
        '${placement.roleId}-${placement.start.millisecondsSinceEpoch}-'
        '${placement.laneIndex}',
      ),
      top: placement.minutesFromStart * pixelsPerMinute,
      left: _railWidth + placement.laneIndex * laneWidth + _laneGap,
      width: laneWidth - _laneGap * 2,
      child: block,
    );
  }

  Widget _buildOverflowMarker(
    final BuildContext context,
    final ScheduleTimelineOverflow overflow,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: overflow.minutesFromStart * pixelsPerMinute + 2,
      right: _laneGap,
      child: Material(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onOverflowTap == null ? null : () => onOverflowTap!(overflow),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              AppLocalizations.of(context)!
                  .scheduleParallelCount(overflow.count),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  static double _minutesBetween(final DateTime from, final DateTime to) =>
      to.difference(from).inSeconds / Duration.secondsPerMinute;
}

/// Long-press then drag a block to a new start time.
///
/// A long press is required so the gesture does not fight the page scroll.
class _DraggableTimelineBlock extends StatefulWidget {
  const _DraggableTimelineBlock({
    super.key,
    required this.placement,
    required this.height,
    required this.assignedUsers,
    required this.selected,
    required this.pixelsPerMinute,
    required this.snapMinutes,
    required this.earliestStart,
    required this.onTap,
    required this.onMoved,
  });

  final ScheduleTimelinePlacement placement;
  final double height;
  final List<User> assignedUsers;
  final bool selected;
  final double pixelsPerMinute;
  final int snapMinutes;
  final DateTime earliestStart;
  final VoidCallback onTap;
  final void Function(DateTime newStart) onMoved;

  @override
  State<_DraggableTimelineBlock> createState() =>
      _DraggableTimelineBlockState();
}

class _DraggableTimelineBlockState extends State<_DraggableTimelineBlock> {
  double _dragDy = 0;
  bool _dragging = false;

  /// Minutes the block has moved, rounded onto the snap grid and clamped so it
  /// cannot start before the timeline does.
  int get _snappedOffsetMinutes {
    final rawMinutes = _dragDy / widget.pixelsPerMinute;
    final snapped =
        (rawMinutes / widget.snapMinutes).round() * widget.snapMinutes;
    final earliestOffset =
        widget.earliestStart.difference(widget.placement.start).inMinutes;
    return snapped < earliestOffset ? earliestOffset : snapped;
  }

  @override
  Widget build(BuildContext context) {
    final offsetMinutes = _dragging ? _snappedOffsetMinutes : 0;
    final shift = Duration(minutes: offsetMinutes);

    return Transform.translate(
      offset: Offset(0, offsetMinutes * widget.pixelsPerMinute),
      child: GestureDetector(
        onLongPressStart: (_) {
          HapticFeedback.selectionClick();
          setState(() {
            _dragging = true;
            _dragDy = 0;
          });
        },
        onLongPressMoveUpdate: (details) {
          setState(() => _dragDy = details.offsetFromOrigin.dy);
        },
        onLongPressEnd: (_) => _finishDrag(),
        onLongPressCancel: () => setState(() {
          _dragging = false;
          _dragDy = 0;
        }),
        child: ScheduleTimelineBlock(
          title: widget.placement.role['title'] as String,
          start: widget.placement.start.add(shift),
          end: widget.placement.end.add(shift),
          height: widget.height,
          assignedUsers: widget.assignedUsers,
          selected: widget.selected,
          staffOnly: widget.placement.role['for_guests'] != true,
          onTap: widget.onTap,
          dragging: _dragging,
        ),
      ),
    );
  }

  void _finishDrag() {
    final offsetMinutes = _snappedOffsetMinutes;
    setState(() {
      _dragging = false;
      _dragDy = 0;
    });
    if (offsetMinutes == 0) return;
    widget.onMoved(
      widget.placement.start.add(Duration(minutes: offsetMinutes)),
    );
  }
}
