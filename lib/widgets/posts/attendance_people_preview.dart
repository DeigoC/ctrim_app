import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../utility/attendance_list_preview.dart';
import '../my_avatar_stack.dart';

/// Name list for expected people or attendees.
///
/// Short lists stay open. A long list folds to faces, a few names, and how
/// many people are hidden, until [expanded] is set.
class AttendancePeoplePreview extends StatelessWidget {
  const AttendancePeoplePreview({
    super.key,
    required this.names,
    required this.tiles,
    required this.overviewUsers,
    required this.isWide,
    required this.expanded,
    required this.onToggle,
    this.overviewDetail,
  });

  /// Display names, same order and length as [tiles].
  final List<String> names;
  final List<Widget> tiles;

  /// Directory profiles for the face row. Guests without a profile are omitted.
  final List<User> overviewUsers;
  final bool isWide;
  final bool expanded;
  final VoidCallback onToggle;

  /// One status line under the faces, such as how many expected people are marked.
  final String? overviewDetail;

  @override
  Widget build(BuildContext context) {
    final collapse = AttendanceListPreview.shouldCollapse(
      count: tiles.length,
      isWide: isWide,
    );
    if (!collapse || expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (collapse) _toggleButton(context, expanded: true, hidden: 0),
          ...tiles,
        ],
      );
    }

    final preview = AttendanceListPreview.names(names: names, isWide: isWide);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overviewUsers.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              return MyAvatarStack(
                users: overviewUsers,
                height: 40,
                width: constraints.maxWidth,
                borderWidth: 1.5,
                borderColor: colorScheme.surface,
              );
            },
          ),
        if (overviewDetail != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              overviewDetail!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (preview.shown.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              preview.shown.join(', '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        _toggleButton(context, expanded: false, hidden: preview.hidden),
      ],
    );
  }

  Widget _toggleButton(
    BuildContext context, {
    required bool expanded,
    required int hidden,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onToggle,
        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18),
        label: Text(expanded ? 'Show less' : '+$hidden more'),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}
