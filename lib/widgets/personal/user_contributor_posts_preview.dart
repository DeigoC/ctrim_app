import 'package:flutter/material.dart';

import '../../models/event/event_head.dart';
import '../posts/post_head.dart';

/// Up to a few bulletin cards for posts this person contributes to.
class UserContributorPostsPreview extends StatelessWidget {
  const UserContributorPostsPreview({
    super.key,
    required this.heads,
    required this.emptyMessage,
    required this.onPostUpdated,
  });

  final List<EventHead> heads;
  final String emptyMessage;
  final VoidCallback onPostUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (heads.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            emptyMessage,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < heads.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          PostHead(
            thisHead: heads[i],
            updatePost: onPostUpdated,
          ),
        ],
      ],
    );
  }
}
