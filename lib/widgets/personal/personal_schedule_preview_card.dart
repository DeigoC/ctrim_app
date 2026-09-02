import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event/event_head.dart';
import '../../pages/events/view_event_page.dart';
import '../../pages/personal/view_user_roles_page.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/app_context.dart';
import '../../utility/user_schedule_service.dart';
import '../information/info_section_card.dart';
import 'personal_schedule_post_tile.dart';

/// Personal home dashboard card showing up to three upcoming schedule posts.
class PersonalSchedulePreviewCard extends StatelessWidget {
  const PersonalSchedulePreviewCard({
    super.key,
    required this.appContext,
  });

  final AppContext appContext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.select((AppContext c) => (c.sessionEpoch, c.headsEpoch));

    final user = appContext.currentUser;
    final eventHeads = appContext.eventHeads;
    final rolesLoaded = user.roles != null;
    final postIDs = rolesLoaded
        ? UserScheduleService.upcomingSchedulePostIDsLimited(
            user: user,
            eventHeads: eventHeads,
            limit: 3,
          )
        : const <String>[];
    final totalCount = rolesLoaded
        ? UserScheduleService.upcomingPostCount(
            user: user,
            eventHeads: eventHeads,
          )
        : 0;

    Widget content;
    if (!rolesLoaded) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (postIDs.isEmpty) {
      content = Text(
        l10n.personalScheduleEmpty,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    } else {
      content = Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < postIDs.length; i++)
              PersonalSchedulePostTile(
                postID: postIDs[i],
                user: user,
                eventHeads: eventHeads,
                showDivider: i > 0,
                onTap: () => _openPost(context, postIDs[i], eventHeads),
              ),
          ],
        ),
      );
    }

    return InfoSectionCard(
      icon: Icons.checklist_rounded,
      title: l10n.mySchedule,
      subtitle: l10n.myScheduleSubtitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          if (rolesLoaded) ...[
            const SizedBox(height: 12),
            if (totalCount > 3)
              FilledButton.icon(
                onPressed: () => _openFullSchedule(context),
                icon: const Icon(Icons.checklist_rounded),
                label: Text(l10n.personalScheduleViewAll(totalCount)),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _openFullSchedule(context),
                icon: const Icon(Icons.checklist_rounded),
                label: Text(l10n.personalScheduleViewFull),
              ),
          ],
        ],
      ),
    );
  }

  void _openFullSchedule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewUserRolesPage(selectedUser: appContext.currentUser),
      ),
    );
  }

  void _openPost(
    BuildContext context,
    String postID,
    List<EventHead> eventHeads,
  ) {
    final head = UserScheduleService.eventHeadForRole(
      postID: postID,
      eventHeads: eventHeads,
    );
    if (head == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewEventPage(eventHead: head),
      ),
    );
  }
}
