import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../widgets/my_avatar_stack.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_selector_dialog.dart';

class ViewMetaLogsPage extends StatefulWidget {
  const ViewMetaLogsPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<ViewMetaLogsPage> createState() => _ViewMetaLogsPageState();
}

class _ViewMetaLogsPageState extends State<ViewMetaLogsPage> {
  late final AppContext _appContext;
  late final List<String> _originalContribtors;
  static final DateFormat _dateFormat = DateFormat('d MMM yyyy. HH:mm');
  @override
  void initState() {
    _originalContribtors = List.from(widget.eventContext.metadata.contributorUIDs, growable: false);
    _appContext = Provider.of<AppContext>(context, listen: false);
    _appContext.analytics.setCurrentScreen(screenName: 'Meta-logs for Post:${widget.eventContext.id}');
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
        child: Scaffold(appBar: AppBar(title: const Text('Change History')), body: _buildWithData(context)));
  }

  Widget _buildWithData(BuildContext context) {
    final List<User> allUsers = _appContext.allUsers;
    final User mainAdmin = allUsers.firstWhere((e) => e.id.compareTo(widget.eventContext.metadata.authorUID) == 0);
    final List<User> selectedUsers =
        allUsers.where((element) => widget.eventContext.metadata.contributorUIDs.contains(element.id)).toList();
    final bool isAuthor = widget.eventContext.isCurrentUserAuthor(_appContext.currentUser.id);
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          sliver: SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ListTile(title: Text(mainAdmin.fullname), subtitle: const Text('Author'), leading: MyUserAvatar(mainAdmin)),
            ListTile(
                title: const Text('Contributors'),
                subtitle: const Text('Able to edit the post'),
                trailing: isAuthor
                    ? IconButton(onPressed: _viewPotentialContributorsTap, icon: const Icon(Icons.person_add_alt_1))
                    : null),
            _buildContributors(selectedUsers),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            // const SizedBox(height: 16),
            // const Padding(
            //     padding: EdgeInsets.only(left: 16.0, bottom: 16),
            //     child: Text('Update Logs', style: TextStyle(fontSize: 16))),
          ])),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          sliver: SliverList.builder(
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
                  subtitle: Text(_dateFormat.format(thisEntry['ts'])),
                  leading: MyUserAvatar(thisU),
                  onTap: () => _showFullLog(thisEntry, webHorizontalPadding),
                );
              }),
        )
      ],
    );
  }

  Widget _buildContributors(final List<User> selectedUsers) {
    if (selectedUsers.isEmpty) {
      return const Padding(padding: EdgeInsets.only(left: 16.0), child: Text('None'));
    }

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: InkWell(
            onTap: () => _showContributors(selectedUsers),
            child: MyAvatarStack(
              users: selectedUsers,
              appDir: _appContext.appDir,
            )));
  }

  // * Logic
  void _showFullLog(final Map<String, dynamic> entry, final double horizontalPadding) {
    final thisU = _appContext.getUserFromID(entry['uid']);
    showDialog(
        context: context,
        builder: (_) => Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Dialog(
                child: SingleChildScrollView(
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                    ListTile(
                        title: Text(thisU.fullname),
                        subtitle: Text(_dateFormat.format(entry['ts'])),
                        leading: MyUserAvatar(thisU)),
                    const Divider(),
                    Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 16),
                        child: Text(entry['log'], style: const TextStyle(fontSize: 16))),
                  ]),
                ),
              ),
            ));
  }

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
        _removeContributor(thisU.id);
      }
      Navigator.of(context).pop();
    });
  }

  void _removeContributor(final String removedUID) {
    setState(() {
      widget.eventContext.metadata.contributorUIDs.remove(removedUID);
      widget.eventContext.contributorAdditionUIDs.remove(removedUID);
      widget.eventContext.contributorRemovalUIDs.add(removedUID);
      widget.eventContext.allowSavingOfTheEdit();
    });
  }

  void _viewPotentialContributorsTap() {
    final List<String> alreadySelected = List<String>.from(widget.eventContext.metadata.contributorUIDs);
    alreadySelected.add(widget.eventContext.metadata.authorUID);

    showDialog(
        context: context,
        builder: (_) =>
            UserSelectorDialog(alreadySelectedUIDs: alreadySelected, onSelected: (newID) => _addContributor(newID)));
  }

  void _addContributor(final String newContributorID) {
    setState(() {
      // bothersome? just put all of this in eventContext?
      widget.eventContext.metadata.contributorUIDs.add(newContributorID);
      widget.eventContext.contributorAdditionUIDs.add(newContributorID);
      widget.eventContext.contributorRemovalUIDs.remove(newContributorID);
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
