import 'package:flutter/material.dart';

import '../action_sheet.dart';

/// Admin/editor actions for a post, styled like BulletinSettingSheet.
class PostEditSheet extends StatelessWidget {
  const PostEditSheet({
    super.key,
    required this.isLeader,
    required this.hasParent,
    required this.onEditAbout,
    required this.onEditTitle,
    required this.onAddSchedule,
    required this.onEditMedia,
    required this.onChangeCover,
    required this.onManageContributors,
    required this.onManageLeadSpeaker,
    required this.onOpenPeopleTab,
    required this.onCreateSibling,
    required this.onCreateChild,
    required this.onBulkCreate,
    required this.onNotifyBroadcast,
    required this.onNotifyScheduled,
  });

  final bool isLeader;
  final bool hasParent;
  final VoidCallback onEditAbout;
  final VoidCallback onEditTitle;
  final VoidCallback onAddSchedule;
  final VoidCallback onEditMedia;
  final VoidCallback onChangeCover;
  final VoidCallback onManageContributors;
  final VoidCallback onManageLeadSpeaker;
  final VoidCallback onOpenPeopleTab;
  final VoidCallback onCreateSibling;
  final VoidCallback onCreateChild;
  final VoidCallback onBulkCreate;
  final VoidCallback onNotifyBroadcast;
  final VoidCallback onNotifyScheduled;

  @override
  Widget build(BuildContext context) {
    return ActionSheetShell(
      icon: Icons.edit_note,
      title: 'Edit post',
      subtitle: 'Update content, team, and related posts',
      children: [
        const ActionSheetSectionLabel('Content'),
        ActionSheetOptionGrid(
          children: [
            ActionSheetOption(
              icon: Icons.article_outlined,
              color: Colors.blue,
              title: 'Edit About',
              subtitle: 'Update the post body and details',
              onTap: onEditAbout,
            ),
            ActionSheetOption(
              icon: Icons.title,
              color: Colors.indigo,
              title: 'Edit title & details',
              subtitle: 'Title, subtitle, and lead speaker',
              onTap: onEditTitle,
            ),
            ActionSheetOption(
              icon: Icons.event,
              color: Colors.teal,
              title: 'Add Schedule',
              subtitle: 'Add a program role or time slot',
              onTap: onAddSchedule,
            ),
            ActionSheetOption(
              icon: Icons.image_outlined,
              color: Colors.deepOrange,
              title: 'Change cover',
              subtitle: 'Key graphic from a template cover pool',
              onTap: onChangeCover,
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
        const ActionSheetSectionLabel('People & team'),
        ActionSheetOptionGrid(
          children: [
            ActionSheetOption(
              icon: Icons.record_voice_over_outlined,
              color: Colors.deepPurple,
              title: 'Lead speaker',
              subtitle: 'Person sharing the message (card portrait)',
              onTap: onManageLeadSpeaker,
            ),
            ActionSheetOption(
              icon: Icons.group_outlined,
              color: Colors.orange,
              title: 'Manage contributors',
              subtitle: 'Who can edit this post',
              onTap: onManageContributors,
            ),
            ActionSheetOption(
              icon: Icons.groups_outlined,
              color: Colors.pink,
              title: 'People tab',
              subtitle: 'Interest and attendance',
              onTap: onOpenPeopleTab,
            ),
          ],
        ),
        if (isLeader) ...[
          const ActionSheetSectionLabel('Related posts'),
          ActionSheetOptionGrid(
            children: [
              if (hasParent)
                ActionSheetOption(
                  icon: Icons.account_tree_outlined,
                  color: Colors.brown,
                  title: 'Create Sibling Post',
                  subtitle: 'New post under the same parent',
                  onTap: onCreateSibling,
                ),
              ActionSheetOption(
                icon: Icons.subdirectory_arrow_right,
                color: Colors.deepOrange,
                title: 'Create Child Post',
                subtitle: 'New related post under this one',
                onTap: onCreateChild,
              ),
              ActionSheetOption(
                icon: Icons.calendar_month,
                color: Colors.cyan,
                title: 'Bulk Create Related Posts',
                subtitle: 'Create several related posts at once',
                onTap: onBulkCreate,
              ),
            ],
          ),
          const ActionSheetSectionLabel('Notify'),
          ActionSheetOptionGrid(
            children: [
              ActionSheetOption(
                icon: Icons.campaign_outlined,
                color: Colors.red,
                title: 'Broadcast',
                subtitle: 'Notify this post\'s topics (optional: all Belfast)',
                onTap: onNotifyBroadcast,
              ),
              ActionSheetOption(
                icon: Icons.notifications_active_outlined,
                color: Colors.amber.shade800,
                title: 'Scheduled members',
                subtitle: 'Notify people assigned on the schedule',
                onTap: onNotifyScheduled,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
