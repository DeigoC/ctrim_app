import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/schedule_timeline_layout.dart';
import '../my_avatar_stack.dart';

/// Roles that run for most of the event, shown above the timeline canvas.
///
/// Drawing an all-morning duty block on the canvas costs the full height of the
/// schedule and tells nobody what happens at 10:15, so these sit in a compact
/// band instead and leave the canvas to the running order.
class ScheduleCoverageBand extends StatelessWidget {
  const ScheduleCoverageBand({
    super.key,
    required this.coverageRoles,
    required this.usersForRole,
    required this.onRoleTap,
    this.selectedRoleId,
  });

  final List<ScheduleCoverageRole> coverageRoles;
  final List<User> Function(Map<String, dynamic> role) usersForRole;
  final void Function(Map<String, dynamic> role) onRoleTap;
  final int? selectedRoleId;

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Below this the band stacks; above it entries pair up.
  static const double _twoColumnWidth = 560;

  @override
  Widget build(BuildContext context) {
    if (coverageRoles.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.all_inclusive,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.scheduleAllEventSectionTitle,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= _twoColumnWidth &&
                coverageRoles.length > 1;
            final itemWidth = twoColumns
                ? (constraints.maxWidth - 8) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final coverage in coverageRoles)
                  SizedBox(
                    width: itemWidth,
                    child: _buildEntry(context, coverage),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEntry(
    final BuildContext context,
    final ScheduleCoverageRole coverage,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = coverage.role;
    final staffOnly = role['for_guests'] == false;
    final selected =
        selectedRoleId != null && selectedRoleId == coverage.roleId;
    final users = usersForRole(role);

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
      clipBehavior: Clip.antiAlias,
      shape: shape,
      child: InkWell(
        onTap: () => onRoleTap(role),
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                        Expanded(
                          child: Text(
                            role['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_timeFormat.format(coverage.start)} - ${_timeFormat.format(coverage.end)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: mutedForeground),
                    ),
                  ],
                ),
              ),
              if (users.isNotEmpty) ...[
                const SizedBox(width: 8),
                MyAvatarStack(
                  users: users,
                  height: 26,
                  width: 62,
                  borderWidth: 1.5,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
