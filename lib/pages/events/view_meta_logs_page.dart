import 'package:avatar_stack/avatar_stack.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../widgets/user_avatar.dart';

class ViewMetaLogsPage extends StatefulWidget {
  const ViewMetaLogsPage({super.key, required this.eventContext});
  final EventContext eventContext;
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy. HH:mm');

  @override
  State<ViewMetaLogsPage> createState() => _ViewMetaLogsPageState();
}

class _ViewMetaLogsPageState extends State<ViewMetaLogsPage> {
  late final AppContext _appContext;
  late final List<String> _originalContribtors;

  @override
  void initState() {
    _originalContribtors = List.from(widget.eventContext.metadata.contributorUIDs, growable: false);
    _appContext = Provider.of<AppContext>(context, listen: false);
    widget.eventContext.log.orderLogsBackwards(); // needed?
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _checkForChangesToContributors();
          return true;
        },
        child: Scaffold(appBar: AppBar(title: const Text('Logs')), body: _buildWithData(context)));
  }

  // this will show both metadata and logs
  Widget _buildWithData(BuildContext context) {
    final List<User> allUsers = _appContext.allUsers;
    final User mainAdmin = allUsers.firstWhere((e) => e.id.compareTo(widget.eventContext.metadata.authorUID) == 0);
    final List<User> selectedUsers =
        allUsers.where((element) => widget.eventContext.metadata.contributorUIDs.contains(element.id)).toList();
    final bool isAuthor = widget.eventContext.isCurrentUserAuthor(_appContext.currentUser.id);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(title: Text(mainAdmin.fullname), subtitle: const Text('Author'), leading: MyUserAvatar(mainAdmin)),
          ListTile(
              title: const Text('Assigned Contributors'),
              subtitle: const Text('Able to modify aspects of the post'),
              trailing: isAuthor
                  ? IconButton(onPressed: _viewPotentialContributorsTap, icon: const Icon(Icons.person_add_alt_1))
                  : null),
          _buildContributors(selectedUsers),
          const SizedBox(height: 16),
          const Divider(thickness: 1),
          const SizedBox(height: 16),
          const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 16),
              child: Text('Update Logs', style: TextStyle(fontSize: 16))),
        ])),
        SliverList.builder(
            itemCount: widget.eventContext.log.logs.length,
            itemBuilder: (_, index) {
              final thisEntry = widget.eventContext.log.logs[index];
              final thisU = allUsers.firstWhere((e) => e.id.compareTo(thisEntry['uid']) == 0);
              return ListTile(
                title: Text(
                  thisEntry['log'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(ViewMetaLogsPage._dateFormat.format(thisEntry['ts'])),
                leading: MyUserAvatar(thisU),
                onTap: () => _showFullLog(thisEntry),
              );
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
  void _showFullLog(final Map<String, dynamic> entry) {}

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
                          trailing: widget.eventContext.isCurrentUserAuthor(_appContext.currentUser.id)
                              ? IconButton(
                                  icon: const Icon(Icons.remove), onPressed: () => _onRemoveContributorClick(thisU))
                              : null,
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
      widget.eventContext.metadata.contributorUIDs.remove(removed.id);
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
      widget.eventContext.metadata.contributorUIDs.add(newContributor.id);
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
