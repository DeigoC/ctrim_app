import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../pages/events/view_meta_logs_page.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';

class PostMetadataSection extends StatelessWidget {
  const PostMetadataSection({super.key, required this.eventContext, required this.update});
  final EventContext eventContext;
  final Function update;
  static final DateFormat _recentDateFormat = DateFormat('d MMM, HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String recentDateStr = _recentDateFormat.format(eventContext.head.recentDate);
    final String recentU = Provider.of<AppContext>(context, listen: false)
        .allUsers
        .firstWhere((e) => e.id.compareTo(eventContext.metadata.lastUID) == 0)
        .forname;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () => _onMetaTap(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Updated $recentDateStr by $recentU',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // * Logic
  void _onMetaTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewMetaLogsPage(eventContext: eventContext)))
        .then((_) => update());
  }
}
