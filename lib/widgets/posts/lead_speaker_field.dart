import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event/lead_speaker.dart';
import '../../models/user.dart';
import '../../pages/personal/select_users_page.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../user_avatar.dart';

/// Speaker list for a post or template. Order is sermon order; the first
/// person is the cover photo when the post has no pictures.
class LeadSpeakerField extends StatelessWidget {
  const LeadSpeakerField({
    super.key,
    required this.eventContext,
    required this.onChanged,
  });

  final EventContext eventContext;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appContext = Provider.of<AppContext>(context, listen: false);
    final speakers = eventContext.head.leadSpeakers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Up to ${LeadSpeakerSnapshot.maxCount}. Shown on the bulletin card when the post has no pictures. The first person is the cover photo.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (speakers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No speakers selected',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          )
        else
          Material(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < speakers.length; index++) ...[
                  if (index > 0)
                    Divider(height: 1, color: colorScheme.outlineVariant),
                  _SpeakerRow(
                    speaker: speakers[index],
                    user: appContext.userById(speakers[index].uid),
                    showCoverLabel: speakers.length > 1 && index == 0,
                    canMoveEarlier: index > 0,
                    canMoveLater: index < speakers.length - 1,
                    showMove: speakers.length > 1,
                    onMoveEarlier: () => _move(index, -1),
                    onMoveLater: () => _move(index, 1),
                    onRemove: () => _remove(index),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _pick(context),
          icon: const Icon(Icons.person_search, size: 18),
          label: Text(speakers.isEmpty ? 'Select speakers' : 'Change speakers'),
        ),
        if (speakers.isNotEmpty) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              eventContext.applyLeadSpeakers(const []);
              onChanged();
            },
            child: const Text('Clear'),
          ),
        ],
      ],
    );
  }

  void _move(final int index, final int delta) {
    final speakers =
        List<LeadSpeakerSnapshot>.from(eventContext.head.leadSpeakers);
    final next = index + delta;
    if (next < 0 || next >= speakers.length) return;
    final speaker = speakers.removeAt(index);
    speakers.insert(next, speaker);
    eventContext.applyLeadSpeakers(speakers);
    onChanged();
  }

  void _remove(final int index) {
    final speakers =
        List<LeadSpeakerSnapshot>.from(eventContext.head.leadSpeakers);
    if (index < 0 || index >= speakers.length) return;
    speakers.removeAt(index);
    eventContext.applyLeadSpeakers(speakers);
    onChanged();
  }

  Future<void> _pick(final BuildContext context) async {
    final applied = await pickLeadSpeakers(
      context: context,
      eventContext: eventContext,
    );
    if (applied) onChanged();
  }
}

class _SpeakerRow extends StatelessWidget {
  const _SpeakerRow({
    required this.speaker,
    required this.user,
    required this.showCoverLabel,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.showMove,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onRemove,
  });

  final LeadSpeakerSnapshot speaker;
  final User? user;
  final bool showCoverLabel;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final bool showMove;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = user?.fullname ?? speaker.name ?? 'Speaker';
    final noPhoto = (user?.imgSrc.isEmpty ?? true) &&
        (speaker.imgSrc == null || speaker.imgSrc!.isEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          user != null
              ? MyUserAvatar(user!, radius: 20)
              : CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    _initials(name),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                if (showCoverLabel)
                  Text(
                    'Cover photo',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  )
                else if (noPhoto)
                  Text(
                    'No profile picture — card will show initials',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (showMove) ...[
            IconButton(
              tooltip: 'Move earlier',
              visualDensity: VisualDensity.compact,
              onPressed: canMoveEarlier ? onMoveEarlier : null,
              icon: const Icon(Icons.arrow_upward, size: 20),
            ),
            IconButton(
              tooltip: 'Move later',
              visualDensity: VisualDensity.compact,
              onPressed: canMoveLater ? onMoveLater : null,
              icon: const Icon(Icons.arrow_downward, size: 20),
            ),
          ],
          IconButton(
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  String _initials(final String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts
        .take(2)
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join();
  }
}

/// Opens the people picker and writes the chosen speakers onto [eventContext].
///
/// Returns true when the picker was confirmed, including a clear.
Future<bool> pickLeadSpeakers({
  required BuildContext context,
  required EventContext eventContext,
}) async {
  final appContext = Provider.of<AppContext>(context, listen: false);
  final fromHead = eventContext.head.leadSpeakers.map((speaker) => speaker.uid);
  final selected = fromHead.isEmpty
      ? eventContext.metadata.leadSpeakerUIDs
      : fromHead.toList();
  final result = await Navigator.push<List<String>>(
    context,
    MaterialPageRoute(
      builder: (_) => SelectUsersPage(
        selectedUIDs: List<String>.from(selected),
        includeCurrentUser: true,
        maxSelection: LeadSpeakerSnapshot.maxCount,
        title: 'Select speakers',
        preferServing: true,
        allowCreatePlaceholder: canCreatePlaceholderUser(
          actor: appContext.currentUser,
          postAuthorUid: eventContext.metadata.authorUID,
        ),
        postIdForPlaceholderCreate: eventContext.id,
      ),
    ),
  );
  if (result == null) return false;

  final previous = <String, LeadSpeakerSnapshot>{
    for (final speaker in eventContext.head.leadSpeakers) speaker.uid: speaker,
  };
  final next = <LeadSpeakerSnapshot>[];
  for (final uid in result) {
    final user = appContext.userById(uid);
    if (user != null) {
      next.add(LeadSpeakerSnapshot(
        uid: user.id,
        imgSrc: user.imgSrc,
        name: user.fullname,
      ));
    } else {
      final prior = previous[uid];
      if (prior != null) next.add(prior);
    }
  }
  eventContext.applyLeadSpeakers(next);
  return true;
}
