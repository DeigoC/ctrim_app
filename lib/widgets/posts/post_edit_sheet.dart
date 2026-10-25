import 'package:flutter/material.dart';

import '../../src/localization/app_localizations.dart';
import '../common/action_sheet.dart';

enum _PostEditSheetPage { menu, schedule, related }

/// Admin/editor actions for a post, styled like BulletinSettingSheet.
///
/// Schedule, and related posts for leaders, open inside this sheet. Each page
/// is stateless; only which page is open is remembered here.
class PostEditSheet extends StatefulWidget {
  const PostEditSheet({
    super.key,
    required this.isLeader,
    required this.hasParent,
    required this.onEditAbout,
    required this.onEditTitle,
    required this.onAddSchedule,
    required this.onArrangeSchedule,
    required this.onApplySchedulePreset,
    required this.onEditMedia,
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
  final VoidCallback onArrangeSchedule;
  final VoidCallback onApplySchedulePreset;
  final VoidCallback onEditMedia;
  final VoidCallback onManageContributors;
  final VoidCallback onManageLeadSpeaker;
  final VoidCallback onOpenPeopleTab;
  final VoidCallback onCreateSibling;
  final VoidCallback onCreateChild;
  final VoidCallback onBulkCreate;
  final VoidCallback onNotifyBroadcast;
  final VoidCallback onNotifyScheduled;

  @override
  State<PostEditSheet> createState() => _PostEditSheetState();
}

class _PostEditSheetState extends State<PostEditSheet> {
  _PostEditSheetPage _page = _PostEditSheetPage.menu;

  void _open(_PostEditSheetPage page) => setState(() => _page = page);

  void _backToMenu() => setState(() => _page = _PostEditSheetPage.menu);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onMenu = _page == _PostEditSheetPage.menu;

    return PopScope(
      canPop: onMenu,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || onMenu) return;
        _backToMenu();
      },
      child: ActionSheetShell(
        icon: _icon,
        title: _title(l10n),
        subtitle: _subtitle(l10n),
        onBack: onMenu ? null : _backToMenu,
        contentKey: ValueKey(_page),
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) =>
                  currentChild ?? const SizedBox.shrink(),
              child: _body(l10n),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (_page) {
      case _PostEditSheetPage.menu:
        return Icons.edit_note;
      case _PostEditSheetPage.schedule:
        return Icons.event;
      case _PostEditSheetPage.related:
        return Icons.account_tree_outlined;
    }
  }

  String _title(AppLocalizations l10n) {
    switch (_page) {
      case _PostEditSheetPage.menu:
        return 'Edit post';
      case _PostEditSheetPage.schedule:
        return l10n.postEditScheduleTitle;
      case _PostEditSheetPage.related:
        return l10n.postEditRelatedPageTitle;
    }
  }

  String _subtitle(AppLocalizations l10n) {
    switch (_page) {
      case _PostEditSheetPage.menu:
        return 'Update content, team, and related posts';
      case _PostEditSheetPage.schedule:
        return l10n.postEditScheduleSubtitle;
      case _PostEditSheetPage.related:
        return _relatedSubtitle(l10n);
    }
  }

  String _relatedSubtitle(AppLocalizations l10n) {
    return widget.hasParent
        ? l10n.postEditRelatedWithSiblingSubtitle
        : l10n.postEditRelatedSubtitle;
  }

  Widget _body(AppLocalizations l10n) {
    switch (_page) {
      case _PostEditSheetPage.menu:
        return _PostEditMenu(
          key: const ValueKey(_PostEditSheetPage.menu),
          isLeader: widget.isLeader,
          scheduleSubtitle: l10n.postEditScheduleSubtitle,
          relatedTitle: l10n.postEditRelatedTitle,
          relatedSubtitle: _relatedSubtitle(l10n),
          relatedSection: l10n.postEditRelatedPageTitle,
          onEditAbout: widget.onEditAbout,
          onEditTitle: widget.onEditTitle,
          onEditMedia: widget.onEditMedia,
          onOpenSchedule: () => _open(_PostEditSheetPage.schedule),
          onManageLeadSpeaker: widget.onManageLeadSpeaker,
          onManageContributors: widget.onManageContributors,
          onOpenPeopleTab: widget.onOpenPeopleTab,
          onOpenRelated: () => _open(_PostEditSheetPage.related),
          onNotifyBroadcast: widget.onNotifyBroadcast,
          onNotifyScheduled: widget.onNotifyScheduled,
        );
      case _PostEditSheetPage.schedule:
        return _PostEditSchedulePage(
          key: const ValueKey(_PostEditSheetPage.schedule),
          onAddSchedule: widget.onAddSchedule,
          onArrangeSchedule: widget.onArrangeSchedule,
          onApplySchedulePreset: widget.onApplySchedulePreset,
        );
      case _PostEditSheetPage.related:
        return _PostEditRelatedPage(
          key: const ValueKey(_PostEditSheetPage.related),
          hasParent: widget.hasParent,
          onCreateSibling: widget.onCreateSibling,
          onCreateChild: widget.onCreateChild,
          onBulkCreate: widget.onBulkCreate,
        );
    }
  }
}

class _PostEditMenu extends StatelessWidget {
  const _PostEditMenu({
    super.key,
    required this.isLeader,
    required this.scheduleSubtitle,
    required this.relatedTitle,
    required this.relatedSubtitle,
    required this.relatedSection,
    required this.onEditAbout,
    required this.onEditTitle,
    required this.onEditMedia,
    required this.onOpenSchedule,
    required this.onManageLeadSpeaker,
    required this.onManageContributors,
    required this.onOpenPeopleTab,
    required this.onOpenRelated,
    required this.onNotifyBroadcast,
    required this.onNotifyScheduled,
  });

  final bool isLeader;
  final String scheduleSubtitle;
  final String relatedTitle;
  final String relatedSubtitle;
  final String relatedSection;
  final VoidCallback onEditAbout;
  final VoidCallback onEditTitle;
  final VoidCallback onEditMedia;
  final VoidCallback onOpenSchedule;
  final VoidCallback onManageLeadSpeaker;
  final VoidCallback onManageContributors;
  final VoidCallback onOpenPeopleTab;
  final VoidCallback onOpenRelated;
  final VoidCallback onNotifyBroadcast;
  final VoidCallback onNotifyScheduled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
              subtitle: 'Title, subtitle, and speakers',
              onTap: onEditTitle,
            ),
            ActionSheetOption(
              icon: Icons.photo_library_outlined,
              color: Colors.purple,
              title: 'Edit Media',
              subtitle: 'Photos, videos, and the cover',
              onTap: onEditMedia,
            ),
            ActionSheetOption(
              icon: Icons.event,
              color: Colors.teal,
              title: l10n.postEditScheduleTitle,
              subtitle: scheduleSubtitle,
              onTap: onOpenSchedule,
            ),
          ],
        ),
        const ActionSheetSectionLabel('People & team'),
        ActionSheetOptionGrid(
          children: [
            ActionSheetOption(
              icon: Icons.record_voice_over_outlined,
              color: Colors.deepPurple,
              title: 'Speakers',
              subtitle: 'Up to 3. The first is the cover photo',
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
          ActionSheetSectionLabel(relatedSection),
          ActionSheetOptionGrid(
            children: [
              ActionSheetOption(
                icon: Icons.account_tree_outlined,
                color: Colors.deepOrange,
                title: relatedTitle,
                subtitle: relatedSubtitle,
                onTap: onOpenRelated,
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

class _PostEditSchedulePage extends StatelessWidget {
  const _PostEditSchedulePage({
    super.key,
    required this.onAddSchedule,
    required this.onArrangeSchedule,
    required this.onApplySchedulePreset,
  });

  final VoidCallback onAddSchedule;
  final VoidCallback onArrangeSchedule;
  final VoidCallback onApplySchedulePreset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ActionSheetOptionGrid(
      children: [
        ActionSheetOption(
          icon: Icons.event,
          color: Colors.teal,
          title: 'Add Schedule',
          subtitle: 'Add a program role or time slot',
          onTap: onAddSchedule,
        ),
        ActionSheetOption(
          icon: Icons.swap_vert,
          color: Colors.orange,
          title: l10n.scheduleArrangeTitle,
          subtitle: l10n.scheduleArrangeSubtitle,
          onTap: onArrangeSchedule,
        ),
        ActionSheetOption(
          icon: Icons.view_timeline_outlined,
          color: Colors.teal,
          title: 'Apply schedule preset',
          subtitle: 'Replace the running order from a template',
          onTap: onApplySchedulePreset,
        ),
      ],
    );
  }
}

class _PostEditRelatedPage extends StatelessWidget {
  const _PostEditRelatedPage({
    super.key,
    required this.hasParent,
    required this.onCreateSibling,
    required this.onCreateChild,
    required this.onBulkCreate,
  });

  final bool hasParent;
  final VoidCallback onCreateSibling;
  final VoidCallback onCreateChild;
  final VoidCallback onBulkCreate;

  @override
  Widget build(BuildContext context) {
    return ActionSheetOptionGrid(
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
    );
  }
}
