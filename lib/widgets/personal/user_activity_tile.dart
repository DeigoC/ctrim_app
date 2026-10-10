import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_activity_record.dart';
import '../../pages/personal/view_post_tag_page.dart';
import '../../pages/personal/view_user_tag_page.dart';
import '../../utility/app_context.dart';
import '../../utility/app_links.dart';
import '../../utility/user_activity_lookups.dart';
import '../../utility/user_activity_subjects.dart';

/// One activity row: what happened, which record, the editor's note, and when.
/// Taps open the record when it still exists.
class UserActivityTile extends StatelessWidget {
  const UserActivityTile({
    super.key,
    required this.record,
    required this.subject,
    required this.dateLabel,
    this.lookupData = UserActivityLookupData.empty,
  });

  final UserActivityRecord record;
  final UserActivitySubject subject;
  final String dateLabel;
  final UserActivityLookupData lookupData;

  static IconData iconFor(final UserActivityKind kind) {
    switch (kind) {
      case UserActivityKind.post:
        return Icons.article_outlined;
      case UserActivityKind.person:
        return Icons.person_outline;
      case UserActivityKind.church:
        return Icons.church_outlined;
      case UserActivityKind.churchPage:
        return Icons.description_outlined;
      case UserActivityKind.testimonial:
        return Icons.format_quote_outlined;
      case UserActivityKind.ctrimInfo:
        return Icons.info_outline;
      case UserActivityKind.cellGroup:
        return Icons.groups_outlined;
      case UserActivityKind.ministry:
        return Icons.badge_outlined;
      case UserActivityKind.postTag:
        return Icons.sell_outlined;
      case UserActivityKind.location:
        return Icons.place_outlined;
      case UserActivityKind.postTemplate:
        return Icons.dashboard_customize_outlined;
      case UserActivityKind.other:
        return Icons.history;
    }
  }

  void _open(final BuildContext context) {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final id = subject.id;
    switch (subject.kind) {
      case UserActivityKind.post:
        AppLinks.openPost(
          context,
          id: id,
          extra: appContext.headById(id) ?? lookupData.fetchedHeads[id],
        );
      case UserActivityKind.person:
        AppLinks.openPerson(context, id: id, extra: appContext.userById(id));
      case UserActivityKind.church:
        AppLinks.openChurch(context, id: id);
      case UserActivityKind.churchPage:
        AppLinks.openChurchPage(
          context,
          churchId: subject.parentId,
          pageId: id,
        );
      case UserActivityKind.testimonial:
        AppLinks.openTestimonial(context, id: id);
      case UserActivityKind.ctrimInfo:
        AppLinks.openInfo(context, id: id);
      case UserActivityKind.cellGroup:
        AppLinks.openCellGroup(context, id: id);
      case UserActivityKind.ministry:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViewUserTagPage(tagId: id)),
        );
      case UserActivityKind.postTag:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViewPostTagPage(tagId: id)),
        );
      case UserActivityKind.location:
      case UserActivityKind.postTemplate:
      case UserActivityKind.other:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: colorScheme.onSurfaceVariant);

    return InkWell(
      onTap: subject.canOpen ? () => _open(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconFor(subject.kind), color: colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.log, style: theme.textTheme.bodyLarge),
                  if (subject.title.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subject.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (record.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '“${record.note}”',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(dateLabel, style: muted),
                ],
              ),
            ),
            if (subject.canOpen) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
