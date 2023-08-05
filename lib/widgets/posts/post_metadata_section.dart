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
    final String recentDateStr = _recentDateFormat.format(eventContext.head.recentDate);
    final String recentU = Provider.of<AppContext>(context, listen: false)
        .allUsers
        .firstWhere((e) => e.id.compareTo(eventContext.metadata.lastUID) == 0)
        .forname;
    return TextButton(onPressed: () => _onMetaTap(context), child: Text('Updated $recentDateStr by $recentU'));
  }

  // * Logic
  void _onMetaTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewMetaLogsPage(eventContext: eventContext)))
        .then((_) => update());
  }
}
