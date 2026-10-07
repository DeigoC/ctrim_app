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
    this.subtitle = '',
    this.onTap,
    this.dragging = false,
  });

  final String title;

  /// Role detail, such as "By Rhey Eusebio". Shown under the title when the
  /// block is tall enough.
  final String subtitle;
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
      hasSubtitle: subtitle.trim().isNotEmpty,
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
    final motionDuration =
        dragging ? Duration.zero : const Duration(milliseconds: 200);

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
      animationDuration: motionDuration,
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
                motionDuration: motionDuration,
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
    required Duration motionDuration,
  }) {
    final titleStyle = (theme.textTheme.labelLarge ?? const TextStyle())
        .copyWith(color: foreground, fontWeight: FontWeight.w600);
    final mutedStyle = (theme.textTheme.labelSmall ?? const TextStyle())
        .copyWith(color: mutedForeground);
    final titleText = AnimatedDefaultTextStyle(
      duration: motionDuration,
      style: titleStyle,
      maxLines: fit.twoLineTitle ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      child: Text(title),
    );

    Widget staffIcon() {
      return TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: mutedForeground),
        duration: motionDuration,
        builder: (context, value, _) {
          return Icon(
            Icons.visibility_off_outlined,
            size: 12,
            color: value ?? mutedForeground,
          );
        },
      );
    }

    Widget timeText(String label) {
      return AnimatedDefaultTextStyle(
        duration: motionDuration,
        style: mutedStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: Text(label),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!fit.stacked) {
          return Row(
            children: [
              if (staffOnly) ...[
                staffIcon(),
                const SizedBox(width: 4),
              ],
              timeText(_timeFormat.format(start)),
              const SizedBox(width: 6),
              Expanded(child: titleText),
              if (fit.avatars == ScheduleBlockAvatars.inline) ...[
                const SizedBox(width: 6),
                MyAvatarStack(
                  users: assignedUsers,
                  height: ScheduleBlockLayout.compactAvatar,
                  width: ScheduleBlockLayout.avatarStackWidth(
                    userCount: assignedUsers.length,
                    avatarSize: ScheduleBlockLayout.compactAvatar,
                    // Leave room for time + a readable title fragment.
                    maxWidth: (maxWidth * 0.45).clamp(
                      ScheduleBlockLayout.compactAvatar,
                      maxWidth,
                    ),
                  ),
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
                  staffIcon(),
                  const SizedBox(width: 4),
                ],
                Expanded(child: titleText),
                if (fit.avatars == ScheduleBlockAvatars.inline) ...[
                  const SizedBox(width: 6),
                  MyAvatarStack(
                    users: assignedUsers,
                    height: ScheduleBlockLayout.inlineAvatar,
                    width: ScheduleBlockLayout.avatarStackWidth(
                      userCount: assignedUsers.length,
                      avatarSize: ScheduleBlockLayout.inlineAvatar,
                      maxWidth: (maxWidth * 0.45).clamp(
                        ScheduleBlockLayout.inlineAvatar,
                        maxWidth,
                      ),
                    ),
                    borderWidth: 1.5,
                  ),
                ],
              ],
            ),
            if (fit.showSubtitle) timeText(subtitle.trim()),
            timeText(
              '${_timeFormat.format(start)} - ${_timeFormat.format(end)}',
            ),
            if (fit.avatars == ScheduleBlockAvatars.bottom) ...[
              const Spacer(),
              MyAvatarStack(
                users: assignedUsers,
                height: ScheduleBlockLayout.bottomAvatar,
                width: ScheduleBlockLayout.avatarStackWidth(
                  userCount: assignedUsers.length,
                  avatarSize: ScheduleBlockLayout.bottomAvatar,
                  maxWidth: maxWidth,
                ),
                borderWidth: 1.5,
              ),
            ],
          ],
        );
      },
    );
  }
}
