import 'dart:convert';
import 'dart:io';

import 'package:avatar_stack/avatar_stack.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
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
    _originalContribtors = List.from(widget.eventContext.metadata.contributorUIDs);
    _appContext = Provider.of<AppContext>(context, listen: false);
    if (widget.eventContext.fetchedLogs) {
      widget.eventContext.log.orderLogsBackwards();
    }
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
            body: widget.eventContext.fetchedLogs ? _buildWithData(context) : _buildFB()));
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
            widget.eventContext.log.orderLogsBackwards();
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
          ListTile(
            title: const Text('Test Part of the Post'),
            leading: const Icon(Icons.science),
            onTap: () async {
              // _onTestBody();
              // _onTestProgramDetails();
              // _onTestProgramRoles();
              // _onTestMedia();
              // _onTestLogs();
              // _onTestMetaData();
              final String result = widget.eventContext.transformPostToTxtFile();
              // debugPrint(result);

              final File tempF = File('${(await getTemporaryDirectory()).path}/postTest.txt');
              await tempF.writeAsString(result);

              // const LineSplitter ls = LineSplitter();
              final content = await tempF.readAsLines();
              for (var line in content) {
                debugPrint(line);
              }

              // final dataTest = ls.convert(content);
              // EventContext.viewing(eventHead: widget.eventContext.head, data: content);

              // debugPrint('Finished!');
              // ! Time for a critical test:
              // save the result to file and then try to create a new event context with the data and see if it
              // just initialises as normal!
            },
          ),
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

  void _onTestLogs() {
    final eventLog = widget.eventContext.log;
    // final List<String> testFileData = List<String>.empty(growable: true);
    String result = '----LOGS_START----';
    for (final entry in eventLog.logs) {
      final String log = (entry['log'] as String).replaceAll('\n', r'\n');
      final DateTime ts = entry['ts'];
      final String uid = entry['uid'];
      result += '\n$log';
      result += '\n${ts.millisecondsSinceEpoch}';
      result += '\n$uid';
    }
    result += '\n----LOGS_END----';
    debugPrint(result);
    debugPrint('------That is the end of the raw string to be saved, now comes the linesplitter:\n');

    LineSplitter ls = const LineSplitter();
    final lines = ls.convert(result);
    for (final line in lines) {
      debugPrint(line.replaceAll(r'\n', '\n'));
    }
  }

  void _onTestBody() {
    String result = '----BODY_START----';
    result += '\n${widget.eventContext.encodedBody}';
    result += '\n----BODY_END----';
    debugPrint(result);
  }

  void _onTestProgramDetails() {
    final program = widget.eventContext.program;
    String result = '----PROGRAM_DETAILS_START----';
    result += '\n${program.allDay ? '1' : '0'}';
    result += '\n${program.finishTime != null ? program.finishTime!.millisecondsSinceEpoch.toString() : 'null'}';
    result += '\n----PROGRAM_DETAILS_END----';
    debugPrint(result);
  }

  void _onTestProgramRoles() {
    final program = widget.eventContext.program;
    String result = '----PROGRAM_ROLES_START----';
    final roles = program.roles;
    for (final role in roles) {
      result += '\n${role['uids']}';
      result += '\n${role['title'] as String}';
      result += '\n${(role['detail'] as String).replaceAll('\n', r'\n')}';
      result += '\n${role['start'] != null ? (role['start'] as DateTime).millisecondsSinceEpoch.toString() : 'null'}';
      result += '\n${role['end'] != null ? (role['end'] as DateTime).millisecondsSinceEpoch.toString() : 'null'}';
      result += '\n${role['for_guests'] == true ? '1' : '0'}';
      result += '\n${role['priority'] as int}';
    }
    result += '\n----PROGRAM_ROLES_END----';
    debugPrint(result);
  }

  void _onTestMedia() {
    final media = widget.eventContext.media;
    String result = '----MEDIA_START----';
    final items = media.allMedia;
    for (final item in items) {
      result += '\n${item['type']}';
      result += '\n${item['src']}';
      result += '\n${item['title']}';
    }
    result += '\n----MEDIA_END----';
    debugPrint(result);
  }

  void _onTestMetaData() {
    final meta = widget.eventContext.metadata;
    String result = '----META_START----';

    result += '\n${meta.authorUID}';
    result += '\n${meta.lastUID}';
    result += '\n${meta.contributorUIDs}';
    result += '\n${meta.parentID ?? ''}';
    result += '\n${meta.children}';

    result += '\n----META_END----';
    debugPrint(result);
  }
}
