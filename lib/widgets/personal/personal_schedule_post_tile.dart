import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../src/localization/app_localizations.dart';
import '../../utility/user_schedule_service.dart';

/// Compact post row for Personal schedule preview cards.
class PersonalSchedulePostTile extends StatelessWidget {
  const PersonalSchedulePostTile({
    super.key,
    required this.postID,
    required this.user,
    required this.eventHeads,
    required this.onTap,
    this.showDivider = false,
  });

  final String postID;
  final User user;
  final List<EventHead> eventHeads;
  final VoidCallback onTap;
  final bool showDivider;

  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final postHead = UserScheduleService.eventHeadForRole(
      postID: postID,
      eventHeads: eventHeads,
    );
    final roleCount = UserScheduleService.roleCountForPost(
      user: user,
      postID: postID,
      eventHeads: eventHeads,
    );
    final dateLabel = postHead?.eventDate != null
        ? _eventDateFormat.format(postHead!.eventDate!)
        : l10n.personalScheduleDateTbc;
    final title = postHead?.title ?? l10n.personalScheduleUntitledEvent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (roleCount > 1) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.personalScheduleRolesCount(roleCount),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
