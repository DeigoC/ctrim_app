import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../my_avatar_stack.dart';

/// A single schedule role drawn on the timeline canvas.
///
/// Content thins out as the block gets shorter so a five-minute slot still
/// shows something readable.
class ScheduleTimelineBlock extends StatelessWidget {
  const ScheduleTimelineBlock({
    super.key,
    required this.title,
    required this.start,
    required this.end,
    required this.height,
    required this.assignedUsers,
    required this.selected,
    required this.staffOnly,
    this.onTap,
    this.dragging = false,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final double height;
  final List<User> assignedUsers;
  final bool selected;

  /// Roles hidden from guests (`for_guests` is false).
  final bool staffOnly;
  final VoidCallback? onTap;
  final bool dragging;

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color background = selected
        ? colorScheme.primary
        : staffOnly
            ? colorScheme.surfaceContainerHighest
            : colorScheme.primaryContainer.withValues(alpha: 0.55);
    final Color foreground =
        selected ? colorScheme.onPrimary : colorScheme.onSurface;
    final Color mutedForeground = selected
        ? colorScheme.onPrimary.withValues(alpha: 0.85)
        : colorScheme.onSurfaceVariant;

    return Material(
      color: background,
      elevation: dragging ? 6 : 0,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: height >= 34 ? 6 : 1,
            ),
            child: _buildContent(
              theme: theme,
              foreground: foreground,
              mutedForeground: mutedForeground,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required ThemeData theme,
    required Color foreground,
    required Color mutedForeground,
  }) {
    final titleText = Text(
      title,
      maxLines: height >= 58 ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelLarge?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    );

    final titleRow = Row(
      children: [
        if (staffOnly) ...[
          Icon(Icons.visibility_off_outlined, size: 12, color: mutedForeground),
          const SizedBox(width: 4),
        ],
        Expanded(child: titleText),
      ],
    );

    if (height < 34) return titleRow;

    final showAvatars = height >= 84 && assignedUsers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        Text(
          '${_timeFormat.format(start)} - ${_timeFormat.format(end)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: mutedForeground),
        ),
        if (showAvatars) ...[
          const Spacer(),
          MyAvatarStack(
            users: assignedUsers,
            height: 28,
            width: 68,
            borderWidth: 1.5,
          ),
        ],
      ],
    );
  }
}
