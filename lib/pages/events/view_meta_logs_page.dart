import 'package:avatar_stack/avatar_stack.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
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
  late final AppContext _appContext;
  late final List<String> _originalContribtors;

  @override
  void initState() {
    _originalContribtors = List.from(widget.eventContext.metadata.contributorUIDs);
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _checkForChangesToContributors();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Logs')),
        body: widget.eventContext.fetchedLogs ? _buildWithData(context) : _buildFB(),
      ),
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
    final List<User> allUsers = _appContext.allUsers;
    final User mainAdmin = allUsers.firstWhere((e) => e.id.compareTo(widget.eventContext.metadata.authorUID) == 0);
    final List<User> selectedUsers =
        allUsers.where((element) => widget.eventContext.metadata.contributorUIDs.contains(element.id)).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                  title: Text(mainAdmin.fullname), subtitle: const Text('Author'), leading: MyUserAvatar(mainAdmin)),
              ListTile(
                  title: const Text('Assigned Contributors'),
                  subtitle: const Text('Able to modify aspects of the post'),
                  trailing:
                      IconButton(onPressed: _viewPotentialContributorsTap, icon: const Icon(Icons.person_add_alt_1))),
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

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child:
            InkWell(onTap: () => _showContributors(selectedUsers), child: AvatarStack(height: 50, avatars: avatars)));
  }

  // * Logic
  void _showContributors(final List<User> selectedUsers) {
    showDialog(
        context: context,
        builder: (_) {
          return Dialog(
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView.builder(
                      itemCount: selectedUsers.length,
                      itemBuilder: (_, index) {
                        final thisU = selectedUsers[index];
                        return ListTile(
                          title: Text(thisU.fullname),
                          leading: MyUserAvatar(thisU),
                          subtitle: Text(thisU.location),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _onRemoveContributorClick(thisU),
                          ),
                        );
                      })));
        });
  }

  void _onRemoveContributorClick(final User thisU) {
    DialogManager.showConfirmationDialog(
            context: context, title: 'Remove Contributor', content: 'Are you sure you want to continue?')
        .then((confirm) {
      if (confirm) {
        _removeContributor(thisU);
      }
      Navigator.of(context).pop();
    });
  }

  void _removeContributor(final User removed) {
    setState(() {
      widget.eventContext.metadata.removeContributorUID(removed.id);
      widget.eventContext.allowSavingOfTheEdit();
    });
  }

  void _viewPotentialContributorsTap() {
    final List<User> potentialUsers =
        _appContext.allUsers.where((e) => !widget.eventContext.metadata.contributorUIDs.contains(e.id)).toList();
    potentialUsers.removeWhere((element) => element.id.compareTo(widget.eventContext.metadata.authorUID) == 0);

    showDialog(
        context: context,
        builder: (_) {
          return Dialog(
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: ListView.builder(
                      itemCount: potentialUsers.length,
                      itemBuilder: (_, index) {
                        final User thisU = potentialUsers[index];
                        return ListTile(
                            title: Text(thisU.fullname),
                            subtitle: Text(thisU.location),
                            leading: MyUserAvatar(thisU),
                            onTap: () => _onAddContributorTap(thisU));
                      })));
        });
  }

  void _onAddContributorTap(final User newContributor) {
    DialogManager.showConfirmationDialog(
            context: context,
            title: 'Add Contributor',
            content: 'Are you sure you want to add ${newContributor.forname} as a contributor?')
        .then((confirm) {
      if (confirm) {
        _addContributor(newContributor);
      }
      Navigator.of(context).pop();
    });
  }

  void _addContributor(final User newContributor) {
    setState(() {
      widget.eventContext.metadata.addContributorUID(newContributor.id);
      widget.eventContext.allowSavingOfTheEdit();
    });
  }

  void _checkForChangesToContributors() {
    bool haveContributorsChange = false;
    if (_originalContribtors.length != widget.eventContext.metadata.contributorUIDs.length) {
      haveContributorsChange = true;
    } else {
      for (final newContributorID in widget.eventContext.metadata.contributorUIDs) {
        if (!_originalContribtors.contains(newContributorID)) {
          haveContributorsChange = true;
          break;
        }
      }
    }

    if (haveContributorsChange) {
      widget.eventContext.allowSavingOfTheEdit();
    }
  }
}
