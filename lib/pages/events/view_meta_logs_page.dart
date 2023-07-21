import 'package:avatar_stack/avatar_stack.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/user.dart';
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
              child: Text('Something went wrong :('),
            );
          }

          return result;
        });
  }

  // this will show both metadata and logs
  Widget _buildWithData(BuildContext context) {
    // TODO remember the optimisation of fetching (and storing) the key users on demand!
    final allUsers = Provider.of<AppContext>(context).allUsers;
    final mainAdmin = allUsers.firstWhere((e) => e.id.compareTo(widget.eventContext.metadata.authorUID) == 0);
    final List<User> selectedUsers =
        allUsers.where((element) => widget.eventContext.metadata.contributorUIDs.contains(element.id)).toList();

    // final List<ImageProvider> contributors = _getContributors(selectedUsers);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                  title: Text(mainAdmin.fullname),
                  subtitle: const Text('Main Admin'),
                  leading: MyUserAvatar(mainAdmin)),
              ListTile(
                  title: const Text('Assigned Contributors'),
                  subtitle: const Text('Able to modify aspects of the post'),
                  trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.person_add_alt_1))),
              _buildContributors(selectedUsers),
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
              const Padding(padding: EdgeInsets.only(left: 16.0), child: Text('Update Logs')),
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

  Widget _buildContributors(final List<User> selectedUsers) {
    if (selectedUsers.isEmpty) {
      return const Padding(padding: EdgeInsets.only(left: 16.0), child: Text('None'));
    }

    final List<ImageProvider> avatars = List<ImageProvider>.empty(growable: true);
    for (final thisU in selectedUsers) {
      if (thisU.imgSrc.isNotEmpty) {
        avatars.add(NetworkImage(thisU.imgSrc));
      } else {
        avatars.add(const AssetImage('assets/images/Generic-Profile.jpg'));
      }
    }

    return InkWell(onTap: () => _showContributors(selectedUsers), child: AvatarStack(height: 90, avatars: avatars));
  }

  // * Logic
  void _showContributors(final List<User> selectedUsers) {
    showDialog(
        context: context,
        builder: (_) {
          return Dialog(
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView.builder(itemBuilder: (_, index) {
                    final thisU = selectedUsers[index];
                    return ListTile(
                      title: Text(thisU.fullname),
                      leading: MyUserAvatar(thisU),
                      subtitle: Text(thisU.location),
                    );
                  })));
        });
  }
}
