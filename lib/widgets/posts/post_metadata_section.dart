import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
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
    return Consumer<AppContext>(
      builder: (context, appContext, child) {
        if (eventContext.fetchedMetadata) {
          return _buildWithData(context);
        }
        // EventMetadata? meta = appContext.getMetadata(eventContext.id);
        // if (meta != null) {
        //   eventContext.setFetchedMetadata(meta);
        //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        //     update();
        //   });
        //   return _buildWithData(context);
        // }
        return _buildFB();
      },
    );
  }

  Widget _buildFB() {
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(eventContext.head.id);
    return FutureBuilder(
        future: dbManager.fetchMetadata(),
        builder: (_, snap) {
          Widget result = const Center(
            child: CircularProgressIndicator(),
          );

          if (snap.hasData) {
            eventContext.setFetchedMetadata(snap.data!);
            result = _buildWithData(_);
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              update();
            });
          } else if (snap.hasError) {
            debugPrint('Error with fetching metadata: ${snap.error}');
            result = const Center(
              child: Text('Something went wrong :('),
            );
          }

          return result;
        });
  }

  Widget _buildWithData(BuildContext context) {
    final String recentDateStr = _recentDateFormat.format(eventContext.head.recentDate);
    final String recentU = Provider.of<AppContext>(context, listen: false)
        .allUsers
        .firstWhere((e) => e.id.compareTo(eventContext.metadata.lastUID) == 0)
        .forname;
    return TextButton(onPressed: () => _onMetaTap(context), child: Text('Updated $recentDateStr by $recentU'));
  }

  // * Logic
  void _onMetaTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ViewMetaLogsPage(eventContext: eventContext)));
  }
}
