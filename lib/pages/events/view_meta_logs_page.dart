import 'package:avatar_stack/avatar_stack.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../utility/app_context.dart';
import '../../utility/event_context.dart';
import '../../widgets/user_avatar.dart';

class ViewMetaLogsPage extends StatefulWidget {
  const ViewMetaLogsPage({super.key, required this.eventContext});
  final EventContext eventContext;
  static final DateFormat _dateFormat = DateFormat('HH:mm. EEE, d MMM yyyy');

  @override
  State<ViewMetaLogsPage> createState() => _ViewMetaLogsPageState();
}

class _ViewMetaLogsPageState extends State<ViewMetaLogsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logs')),
      body: widget.eventContext.fetchedLogs ? _buildWithData(context) : _buildFB(),
    );
  }

  Widget _buildFB() {
    final EventSupplementalDBManager eventSupplementalDBManager = EventSupplementalDBManager(widget.eventContext.id);
    return FutureBuilder(
        future: eventSupplementalDBManager.fetchLog(),
        builder: (_, snap) {
          Widget result = const Center(
            child: CircularProgressIndicator(),
          );

          if (snap.hasData) {
            widget.eventContext.setFetchedLogs(snap.data!);
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

  // this will show both metadata and logs
  Widget _buildWithData(BuildContext context) {
    // TODO remember the optimisation of fetching (and storing) the key users on demand!
    final allUsers = Provider.of<AppContext>(context).allUsers;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Column(
            children: [
              ListTile(title: Text('Main Admin Here'), subtitle: Text('Main Admin')),
              Text('Assigned Contributors'),
              AvatarStack(height: 90, avatars: []),
              Divider(thickness: 1),
              Text('Logs'),
            ],
          ),
        ),
        SliverList.builder(
            itemCount: widget.eventContext.log.logs.length,
            itemBuilder: (_, index) {
              final thisEntry = widget.eventContext.log.logs[index];
              final thisU = allUsers.firstWhere((e) => e.id.compareTo(thisEntry['uid']) == 0);
              return ListTile(
                  title: Text(thisEntry['log']),
                  subtitle: Text(ViewMetaLogsPage._dateFormat.format(thisEntry['ts'])),
                  leading: MyUserAvatar(thisU));
            })
      ],
    );
  }
}
