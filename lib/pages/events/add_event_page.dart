import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/everyone_db_manager.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../firebase/functions_manager.dart';
import '../../models/event/event_head.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../widgets/posts/add_header_meta_tab_body.dart';
import '../../widgets/posts/view_all_programs.dart';
import '../../widgets/posts/view_event_media_tab.dart';
import '../../widgets/posts/view_post_body.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> with SingleTickerProviderStateMixin {
  // * Required variables
  late final AppContext _appContext;
  late final TabController _tabController;
  late final TextEditingController _tecTitle, _tecSubtitle;
  final EveryoneDBManager _everyoneDBManager = EveryoneDBManager();
  final CloudFunctionManager _cloudFunctionManager = CloudFunctionManager();
  final EventHeadDBManager _headDBManager = EventHeadDBManager();
  final UserDBManager _userDBManager = UserDBManager();

  bool _canSave = false;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _tabController = TabController(length: 4, vsync: this);
    _tecTitle = TextEditingController(text: widget.eventContext.head.title);
    _tecSubtitle = TextEditingController(text: widget.eventContext.head.subtitle);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tecTitle.dispose();
    _tecSubtitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 0;

    return WillPopScope(
      onWillPop: () => _onWillPop(),
      child: Scaffold(
          body: NestedScrollView(
              headerSliverBuilder: (_, __) => _buildHeaderSliver(webHorizontalPadding),
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
                child: _buildTabBody(),
              ))),
    );
  }

  List<Widget> _buildHeaderSliver(final double horizontalPadding) {
    final bool onDark = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

    return [
      SliverAppBar(
        expandedHeight: MediaQuery.of(context).size.height * 0.33,
        flexibleSpace: FlexibleSpaceBar(background: _buildAppBarBackground()),
        actions: [
          Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton.icon(
                  style: ButtonStyle(
                      backgroundColor: _canSave
                          ? MaterialStatePropertyAll<Color>(Colors.green.withOpacity(0.7))
                          : MaterialStatePropertyAll<Color>(Colors.grey.withOpacity(0.7)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)))),
                  onPressed: _canSave ? _onSaveClick : null,
                  icon: Icon(Icons.upload, color: _canSave ? Colors.white : null),
                  label: Text('Save', style: TextStyle(color: _canSave ? Colors.white : null)))),
          const SizedBox(width: 8)
        ],
      ),
      SliverPadding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: horizontalPadding),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            TabBar(
              labelColor: onDark ? Colors.white : Colors.black,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline), text: 'Header'),
                Tab(icon: Icon(Icons.note), text: 'Info'),
                Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'),
                Tab(icon: Icon(Icons.photo_album), text: 'Media')
              ],
            )
          ])))
    ];
  }

  Widget? _buildAppBarBackground() {
    // * If there are no images, we should just remove the expanded height
    if (widget.eventContext.head.getKeyGraphic() == null) {
      return null;
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [Positioned.fill(child: Image.network(widget.eventContext.head.getKeyGraphic()!, fit: BoxFit.cover))],
    );
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: [
      AddEventHeadMeta(
        tecTitle: _tecTitle,
        tecSubtitle: _tecSubtitle,
        onRequiredFieldChange: _onRequiredFieldTextChange,
        eventContext: widget.eventContext,
      ),
      ViewPostBody(
          eventContext: widget.eventContext, updateBody: () => _updateBody(), currentUID: _appContext.currentUser.id),
      ViewAllPrograms(eventContext: widget.eventContext, onProgramChanged: () => _updateBody(), isAddingPost: true),
      ViewEventMediaTab(
          eventContext: widget.eventContext, onMediaEdit: () => _updateBody(), currentUID: _appContext.currentUser.id)
    ]);
  }

  // * Logic

  void _updateBody() {
    setState(() {});
    _onRequiredFieldTextChange('');
  }

  void _onRequiredFieldTextChange(String newText) {
    if (_okToSave() && !_canSave) {
      setState(() {
        _canSave = true;
      });
    } else if (!_okToSave() && _canSave) {
      setState(() {
        _canSave = false;
      });
    }
  }

  // the core requirements of a post - title, subtitle, an update to the body
  bool _okToSave() {
    if (_tecTitle.text.trim().isEmpty || _tecSubtitle.text.trim().isEmpty) {
      return false;
    }

    if (widget.eventContext.isBodyUntouched) {
      return false;
    }
    return true;
  }

  void _onSaveClick() {
    _confirmSave().then((confirmed) {
      if (confirmed) {
        DialogManager.showProgressDialog(context: context, title: 'Uploading Post');
        _savePost().then((_) {
          Navigator.of(context).pop(); // pop the progress dialog
          Navigator.of(context).pop(); // pop this add page
          Navigator.of(context).pop(); // pop the template page
        });
      }
    });
  }

  Future<bool> _confirmSave() async {
    bool result = false;
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Save Post'),
              content: const Text('Are you sure all details are correct?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      result = true;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save')),
              ],
            ));
    return result;
  }

  Future<void> _savePost() async {
    final newID = await widget.eventContext
        .addNewPost(
            title: _tecTitle.text.trim(),
            subtitle: _tecSubtitle.text.trim(),
            eventDate: widget.eventContext.head.eventDate,
            uid: _appContext.currentUser.id,
            location: widget.eventContext.head.location)
        .then((newID) async {
      _updateParentMetadata(newID);
      final newHead = await _headDBManager.fetchHead(newID);
      _appContext.addNewPostHead(newHead);
      return newID;
    });

    // notify all that needs this
    _notifyContributorAdditions(newID);
    _notifyProgramRoleAddtitions(newID);
    _updateAllUserPostInvolvement(newID);
    _notifyOfNewPost(newID);
  }

  void _updateParentMetadata(final String thisPostID) async {
    final String? parentID = widget.eventContext.metadata.parentID;

    if (parentID != null) {
      final EventSupplementalDBManager dbManager = EventSupplementalDBManager(parentID);
      debugPrint('updating parent post metadata');

      // update parent metadata
      final metadata = await dbManager.fetchMetadata();
      metadata.childrenPostIDs.add(thisPostID);
      dbManager.updateMetadata(metadata);
      _appContext.setMetadata(parentID, metadata);

      // add parent log
      dbManager.addLogEntry(
          logMessage: "Created related post: '${_tecTitle.text.trim()}'",
          uid: _appContext.currentUser.id,
          ts: DateTime.now());

      // update the parent's recent date
      EventHead parentHead;
      if (_appContext.eventHeads.any((e) => e.id == parentID)) {
        parentHead = _appContext.getPostHead(parentID);
      } else {
        parentHead = await _headDBManager.fetchHead(parentID);
      }

      if (parentHead.recentDate.second == 59) {
        parentHead.setRecentDate(parentHead.recentDate.add(const Duration(seconds: -58)));
      } else {
        parentHead.setRecentDate(parentHead.recentDate.add(const Duration(seconds: 1)));
      }
      _headDBManager.updateHead(parentHead);
      _appContext.addOrUpdatePostHead(parentHead);
    }
  }

  void _notifyOfNewPost(final String newID) async {
    _cloudFunctionManager.sendToTopic(
        topic: 'ctrim-belfast',
        title: _tecTitle.text.trim(),
        body: _tecSubtitle.text.trim(),
        data: {'PostID': newID},
        iOSImage: widget.eventContext.head.getKeyGraphic(),
        androidImage: widget.eventContext.head.getKeyGraphic());
  }

  Future<void> _notifyContributorAdditions(final String newID) async {
    const String title = "Contributor update";
    final String body = "You can modify aspects of the post: '${_tecTitle.text.trim()}'";
    final List<String> allTokens = List<String>.empty(growable: true);

    for (final String thisUID in widget.eventContext.contributorAdditionUIDs) {
      if (!_appContext.haveTokensForUserID(thisUID)) {
        final List<String> tokens =
            await _everyoneDBManager.fetchTokensFromAuthID(_appContext.getAuthIDFromUID(thisUID));
        _appContext.addTokensToUserID(thisUID, tokens);
      }

      allTokens.addAll(_appContext.getTokensFromUserID(thisUID));
    }

    if (allTokens.isNotEmpty) {
      _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: allTokens,
          title: title,
          body: body,
          data: {'PostID': newID},
          androidImage: widget.eventContext.head.getKeyGraphic(),
          iOSImage: widget.eventContext.head.getKeyGraphic());
    }
  }

  // TODO: insane! We need to break these mothods down
  Future<void> _notifyProgramRoleAddtitions(final String newPostID) async {
    final String currentUserName = _appContext.currentUser.forname;
    final String currentUID = _appContext.currentUser.id;
    final String title = "$currentUserName has assinged you to a role!";

    for (final additionEntry in widget.eventContext.roleAdditions.entries) {
      final roleEntry = widget.eventContext.program.roles.firstWhere((e) => e['id'] == additionEntry.key);
      final String body = "You are assigned to '${roleEntry['title']!}' for ${_tecTitle.text.trim()}";

      final List<String> tokens = [];
      for (final thisUID in additionEntry.value) {
        if (thisUID != currentUID) {
          if (!_appContext.haveTokensForUserID(thisUID)) {
            final List<String> tokens =
                await _everyoneDBManager.fetchTokensFromAuthID(_appContext.getAuthIDFromUID(thisUID));
            _appContext.addTokensToUserID(thisUID, tokens);
          }

          tokens.addAll(_appContext.getTokensFromUserID(thisUID));
        }
        await _userDBManager.addUserRole(
            uid: thisUID,
            postID: newPostID,
            roleID: additionEntry.key,
            millisecondStart: (roleEntry['start'] as DateTime).millisecondsSinceEpoch,
            millisecondEnd: (roleEntry['end'] as DateTime).millisecondsSinceEpoch,
            title: roleEntry['title']);
      }
      _cloudFunctionManager
          .sendMessageToSelectedTokens(tokens: tokens, title: title, body: body, data: {'PostID': newPostID});
    }
  }

  Future<void> _updateAllUserPostInvolvement(final String newPostID) async {
    // first up, the author
    _userDBManager.addPostToUser(_appContext.currentUser.id, newPostID, 'author');

    // then all the contributors
    for (final String contributorID in widget.eventContext.contributorAdditionUIDs) {
      _userDBManager.addPostToUser(contributorID, newPostID, 'contributor');
    }
  }

  Future<bool> _onWillPop() async {
    final bool confirmation = await DialogManager.discardChanges(context: context);
    if (confirmation) {
      // reset all supplemental parts - media, program, body, head, metadata
      // logs should remain untouched at this point
    }

    return confirmation;
  }
}
