import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/post_template.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../common/action_sheet.dart';
import '../my_avatar_stack.dart';

/// People count summary for an [ExpectedAttendancePreset].
String expectedAttendancePresetSubtitle(ExpectedAttendancePreset preset) {
  final count = preset.userIds.length;
  if (count == 0) return 'No expected people';
  return count == 1 ? '1 expected' : '$count expected';
}

/// Bottom sheet to pick one [ExpectedAttendancePreset]. Returns null if dismissed.
Future<ExpectedAttendancePreset?> showExpectedAttendancePresetPicker({
  required BuildContext context,
  required List<ExpectedAttendancePreset> presets,
  String? selectedId,
  String title = 'Expected attendance preset',
  String subtitle = 'Choose which expected-member list to apply',
}) {
  if (presets.isEmpty) return Future.value(null);
  return showModalBottomSheet<ExpectedAttendancePreset>(
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
        icon: Icons.groups_outlined,
        title: title,
        subtitle: subtitle,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                for (var i = 0; i < presets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _ExpectedAttendancePresetOption(
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

List<User> _usersForPreset(
    AppContext appContext, ExpectedAttendancePreset preset) {
  final users = <User>[];
  final seen = <String>{};
  for (final uid in preset.userIds) {
    if (!seen.add(uid)) continue;
    final user = appContext.userById(uid);
    if (user != null) users.add(user);
  }
  return users;
}

class _ExpectedAttendancePresetOption extends StatelessWidget {
  const _ExpectedAttendancePresetOption({
    required this.preset,
    required this.selected,
    required this.users,
    required this.onTap,
  });

  final ExpectedAttendancePreset preset;
  final bool selected;
  final List<User> users;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionSheetOption(
      icon: Icons.groups_outlined,
      color: Colors.pink,
      title: preset.name,
      subtitle: expectedAttendancePresetSubtitle(preset),
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
