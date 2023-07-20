import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// TODO turn this into a full page with MetaData stuff and Logs
class ViewLogsDialog extends StatelessWidget {
  const ViewLogsDialog({super.key, required this.eventContext});
  final EventContext eventContext;
  static final DateFormat _dateFormat = DateFormat('HH:mm. EEE, d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const ListTile(
              title: Text('Logs'),
              leading: Icon(Icons.work_history),
            ),
            const Divider(),
            Expanded(child: eventContext.fetchedLogs ? _buildWithData(context) : _buildFB())
          ],
        ),
      ),
    );
  }

  Widget _buildFB() {
    final EventSupplementalDBManager eventSupplementalDBManager = EventSupplementalDBManager(eventContext.id);
    return FutureBuilder(
        future: eventSupplementalDBManager.fetchLog(),
        builder: (_, snap) {
          Widget result = const Center(
            child: CircularProgressIndicator(),
          );

          if (snap.hasData) {
            eventContext.setFetchedLogs(snap.data!);
            result = _buildWithData(_);
          } else if (snap.hasError) {
            debugPrint('Something with fetching logs: ${snap.error}');
            result = const Center(
              child: CircularProgressIndicator(),
            );
          }

          return result;
        });
  }

  Widget _buildWithData(BuildContext context) {
    // TODO remember the optimisation of fetching (and storing) the key users on demand!
    final allUsers = Provider.of<AppContext>(context).allUsers;

    return ListView.builder(
        itemCount: eventContext.log.logs.length,
        itemBuilder: (_, index) {
          final thisEntry = eventContext.log.logs[index];
          final thisU = allUsers.firstWhere((e) => e.id.compareTo(thisEntry['uid']) == 0);
          return ListTile(
            title: Text(thisEntry['log']),
            subtitle: Text(_dateFormat.format(thisEntry['ts'])),
            leading: MyUserAvatar(thisU),
          );
        });
  }
}
