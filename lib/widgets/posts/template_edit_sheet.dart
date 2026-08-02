import 'package:flutter/material.dart';

import '../action_sheet.dart';

/// Template editor actions, styled like [PostEditSheet] / BulletinSettingSheet.
class TemplateEditSheet extends StatelessWidget {
  const TemplateEditSheet({
    super.key,
    required this.onEditAbout,
    required this.onAddSchedule,
    required this.onEditMedia,
    required this.onSave,
  });

  final VoidCallback onEditAbout;
  final VoidCallback onAddSchedule;
  final VoidCallback onEditMedia;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ActionSheetShell(
      icon: Icons.dashboard_customize_outlined,
      title: 'Edit template',
      subtitle: 'Update content and save this template',
      children: [
        const ActionSheetSectionLabel('Content'),
        ActionSheetOptionGrid(
          children: [
            ActionSheetOption(
              icon: Icons.article_outlined,
              color: Colors.blue,
              title: 'Edit About',
              subtitle: 'Update the template body',
              onTap: onEditAbout,
            ),
            ActionSheetOption(
              icon: Icons.event,
              color: Colors.teal,
              title: 'Add Schedule Item',
              subtitle: 'Add a program role or time slot',
              onTap: onAddSchedule,
            ),
            ActionSheetOption(
              icon: Icons.photo_library_outlined,
              color: Colors.purple,
              title: 'Edit Media',
              subtitle: 'Manage photos and videos',
              onTap: onEditMedia,
            ),
          ],
        ),
        const ActionSheetSectionLabel('Save'),
        ActionSheetOptionGrid(
          children: [
            ActionSheetOption(
              icon: Icons.save_rounded,
              color: Colors.green,
              title: 'Save template',
              subtitle: 'Write changes to the database',
              onTap: onSave,
            ),
          ],
        ),
      ],
    );
  }
}
