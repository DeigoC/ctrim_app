import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../utility/schedule_block_layout.dart';
import '../my_avatar_stack.dart';

/// A single schedule role drawn on the timeline canvas.
///
/// A short slot has no height to spare but plenty of width, so it lays its
/// time, title and avatars out on one line instead of stacking them. Taller
/// blocks stack, and only the tallest push avatars to the bottom.
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
    final fit = ScheduleBlockLayout.forHeight(
      height,
      hasUsers: assignedUsers.isNotEmpty,
    );

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

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(alpha: 0.7),
      ),
    );

    return Material(
      color: background,
      elevation: dragging ? 6 : 0,
      clipBehavior: Clip.antiAlias,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: SizedBox(
          height: height,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: ScheduleBlockLayout.maxTextScale,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: fit.stacked
                    ? ScheduleBlockLayout.stackedPadding
                    : ScheduleBlockLayout.tightPadding,
              ),
              child: _buildContent(
                theme: theme,
                fit: fit,
                foreground: foreground,
                mutedForeground: mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required ThemeData theme,
    required ScheduleBlockLayout fit,
    required Color foreground,
    required Color mutedForeground,
  }) {
    final titleText = Text(
      title,
      maxLines: fit.twoLineTitle ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelLarge?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    );

    if (!fit.stacked) {
      return Row(
        children: [
          if (staffOnly) ...[
            Icon(
              Icons.visibility_off_outlined,
              size: 12,
              color: mutedForeground,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _timeFormat.format(start),
            style: theme.textTheme.labelSmall?.copyWith(
              color: mutedForeground,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: titleText),
          if (fit.avatars == ScheduleBlockAvatars.inline) ...[
            const SizedBox(width: 6),
            MyAvatarStack(
              users: assignedUsers,
              height: ScheduleBlockLayout.compactAvatar,
              width: 44,
              borderWidth: 1.2,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (staffOnly) ...[
              Icon(
                Icons.visibility_off_outlined,
                size: 12,
                color: mutedForeground,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(child: titleText),
            if (fit.avatars == ScheduleBlockAvatars.inline) ...[
              const SizedBox(width: 6),
              MyAvatarStack(
                users: assignedUsers,
                height: ScheduleBlockLayout.inlineAvatar,
                width: 52,
                borderWidth: 1.5,
              ),
            ],
          ],
        ),
        Text(
          '${_timeFormat.format(start)} - ${_timeFormat.format(end)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: mutedForeground),
        ),
        if (fit.avatars == ScheduleBlockAvatars.bottom) ...[
          const Spacer(),
          MyAvatarStack(
            users: assignedUsers,
            height: ScheduleBlockLayout.bottomAvatar,
            width: 68,
            borderWidth: 1.5,
          ),
        ],
      ],
    );
  }
}
