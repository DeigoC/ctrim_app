import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/responsive_layout.dart';
import '../user_avatar.dart';

/// Detail for one schedule role: timing, notes, and who is assigned.
///
/// Shown in a modal sheet on phones and as a side pane on wide screens.
class ScheduleRoleDetailSheet extends StatelessWidget {
  const ScheduleRoleDetailSheet({
    super.key,
    required this.role,
    required this.assignedUsers,
    required this.canEdit,
    required this.onEdit,
    this.onClose,
  });

  final Map<String, dynamic> role;
  final List<User> assignedUsers;
  final bool canEdit;
  final VoidCallback onEdit;

  /// Shown as a close affordance when the detail lives in a side pane.
  final VoidCallback? onClose;

  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final detail = (role['detail'] as String?) ?? '';
    final start = role['start'] as DateTime?;
    final end = role['end'] as DateTime?;
    final staffOnly = role['for_guests'] != true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  role['title'] as String,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (start != null && end != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_timeFormat.format(start)} - ${_timeFormat.format(end)}'
                    ' | ${_durationLabel(end.difference(start))}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (staffOnly)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Icon(Icons.visibility_off_outlined,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.scheduleStaffOnly,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (detail.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(detail, style: theme.textTheme.bodyLarge),
          ),
        if (assignedUsers.isNotEmpty) ...[
          const Divider(indent: 16, endIndent: 16),
          for (final user in assignedUsers)
            ListTile(
              title: Text(user.fullname),
              leading: MyUserAvatar(user),
              onTap: () => DialogManager.showUserProfile(
                selectedUser: user,
                context: context,
              ),
            ),
        ],
        if (canEdit)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FilledButton.tonalIcon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: Text(l10n.scheduleEditTask),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  static String _durationLabel(final Duration difference) {
    if (difference.inHours > 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      final hourLabel = hours == 1 ? '$hours hour' : '$hours hours';
      if (minutes == 0) return hourLabel;
      return '$hourLabel $minutes minutes';
    }
    final minutes = difference.inMinutes;
    return minutes == 1 ? '$minutes minute' : '$minutes minutes';
  }
}

/// Opens [ScheduleRoleDetailSheet] as a modal sheet (phone / narrow layouts).
Future<void> showScheduleRoleDetailSheet({
  required BuildContext context,
  required Map<String, dynamic> role,
  required List<User> assignedUsers,
  required bool canEdit,
  required VoidCallback onEdit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: ResponsiveLayout.bottomSheetConstraintsOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
    ),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        child: ScheduleRoleDetailSheet(
          role: role,
          assignedUsers: assignedUsers,
          canEdit: canEdit,
          onEdit: onEdit,
        ),
      ),
    ),
  );
}
