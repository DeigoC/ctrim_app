import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/post_template.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../common/action_sheet.dart';
import '../my_avatar_stack.dart';

/// Typical clock time + assigned people summary for a [SchedulePreset].
String schedulePresetSubtitle(SchedulePreset preset) {
  final time = preset.startTime == null
      ? 'No typical start'
      : DateFormat.jm().format(preset.startTime!);
  final assigned = SchedulePreset.assignedUserIdsOf(preset);
  final roleCount = preset.roles.length;
  final rolesLabel = roleCount == 1 ? '1 role' : '$roleCount roles';
  if (assigned.isEmpty) return '$time · $rolesLabel';
  final peopleLabel =
      assigned.length == 1 ? '1 person' : '${assigned.length} people';
  return '$time · $rolesLabel · $peopleLabel';
}

/// Bottom sheet to pick one [SchedulePreset]. Returns null if dismissed.
Future<SchedulePreset?> showSchedulePresetPicker({
  required BuildContext context,
  required List<SchedulePreset> presets,
  String? selectedId,
  String title = 'Schedule preset',
  String subtitle = 'Choose which running order to apply',
}) {
  if (presets.isEmpty) return Future.value(null);
  return showModalBottomSheet<SchedulePreset>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
    ),
    builder: (sheetContext) {
      final appContext = Provider.of<AppContext>(context, listen: false);
      return ActionSheetShell(
        icon: Icons.view_timeline_outlined,
        title: title,
        subtitle: subtitle,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                for (var i = 0; i < presets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _SchedulePresetOption(
                    preset: presets[i],
                    selected: presets[i].id == selectedId,
                    users: _usersForPreset(appContext, presets[i]),
                    onTap: () => Navigator.of(sheetContext).pop(presets[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

List<User> _usersForPreset(AppContext appContext, SchedulePreset preset) {
  final users = <User>[];
  final seen = <String>{};
  for (final uid in SchedulePreset.assignedUserIdsOf(preset)) {
    if (!seen.add(uid)) continue;
    final user = appContext.userById(uid);
    if (user != null) users.add(user);
  }
  return users;
}

class _SchedulePresetOption extends StatelessWidget {
  const _SchedulePresetOption({
    required this.preset,
    required this.selected,
    required this.users,
    required this.onTap,
  });

  final SchedulePreset preset;
  final bool selected;
  final List<User> users;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionSheetOption(
      icon: Icons.schedule,
      color: Colors.teal,
      title: preset.name,
      subtitle: schedulePresetSubtitle(preset),
      selected: selected,
      showChevron: !selected,
      trailing: users.isEmpty
          ? null
          : SizedBox(
              width: 88,
              child: MyAvatarStack(users: users, height: 32),
            ),
      onTap: onTap,
    );
  }
}
