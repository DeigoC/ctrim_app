import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../utility/notification_token_resolver.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../firebase/functions_manager.dart';
import '../../models/event/event_head.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/network_image_helper.dart';
import '../../widgets/posts/add_header_meta_tab_body.dart';
import '../../widgets/posts/view_all_programs.dart';
import '../../widgets/posts/view_event_media_tab.dart';
import '../../widgets/posts/view_post_body.dart';
import 'add_program_role_page.dart';
import 'edit_body_page.dart';
import 'edit_gallery_page.dart';
import '../../utility/responsive_layout.dart';

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
  final NotificationTokenResolver _tokenResolver = NotificationTokenResolver();
  final CloudFunctionManager _cloudFunctionManager = CloudFunctionManager();
  final EventHeadDBManager _headDBManager = EventHeadDBManager();
  final UserDBManager _userDBManager = UserDBManager();

  bool _canSave = false;
  bool _allowPop = false;

  void _popRouteAfterAllowing() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

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
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 0);

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          _popRouteAfterAllowing();
        }
      },
      child: Scaffold(
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _canSave
              ? SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: FloatingActionButton.extended(
                      onPressed: _onSaveClick, label: const Text('Save New Post'), icon: const Icon(Icons.save)),
                )
              : null,
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
          ElevatedButton.icon(
              onPressed: () => _showSettings(),
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              label: const Text('Edit', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.55))),
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
      children: [
        Positioned.fill(
            child: Image.network(NetworkImageHelper.getImageUrl(widget.eventContext.head.getKeyGraphic()!),
                fit: BoxFit.cover))
      ],
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
      ViewEventMediaTab(eventContext: widget.eventContext, currentUID: _appContext.currentUser.id)
    ]);
  }

  // * Logic

  void _updateBody() {
    setState(() {});
    _onRequiredFieldTextChange('');
  }

  void _onRequiredFieldTextChange(final String newText) {
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

  void _onSaveClick() async {
    final confirmed = await _confirmSave();
    if (!confirmed || !mounted) return;

    DialogManager.showProgressDialog(context: context, title: 'Uploading Post');
    try {
      await _savePost();
      if (!mounted) return;
      Navigator.of(context).pop(); // pop the progress dialog
      Navigator.of(context).pop(); // pop this add page
      Navigator.of(context).pop(); // pop the template page
    } catch (e) {
      debugPrint('Error saving post: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress dialog
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to upload post: $e'), behavior: SnackBarBehavior.floating));
    }
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
    _updateAllUserPostInvolvement(newID);
    _notifyContributorAdditions(newID);

    if (widget.eventContext.head.eventDate != null) {
      await _cloudFunctionManager.syncUserRolesForPost(postId: newID);
    }

    if (widget.eventContext.notifyScheduledMembers) {
      debugPrint('---- NOTIFYING SCHEDULED MEMBERS ----');
      _notifyProgramRoleAddtitions(newID);
    }

    if (widget.eventContext.notifyBroadcast) {
      debugPrint('---- NOTIFYING BROADCAST TOPICS ----');
      for (final String topic in widget.eventContext.metadata.topics) {
        _notifyOfNewPost(newID, topic);
      }
    }
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

  void _notifyOfNewPost(final String newID, final String topic) async {
    _cloudFunctionManager.sendToTopic(
        topic: topic,
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
            await _tokenResolver.resolveForAuthID(_appContext.getAuthIDFromUID(thisUID));
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

  Future<void> _notifyProgramRoleAddtitions(final String newPostID) async {
    final String currentUserName = _appContext.currentUser.forname;
    final String currentUID = _appContext.currentUser.id;
    final String title = "📣 $currentUserName has assigned you to a task!";

    for (final additionEntry in widget.eventContext.roleAdditions.entries) {
      final roleEntry = widget.eventContext.program.roles.firstWhere((e) => e['id'] == additionEntry.key);
      final String body = "'${roleEntry['title']!}' for ${_tecTitle.text.trim()}";

      final List<String> tokens = [];
      for (final thisUID in additionEntry.value) {
        if (thisUID != currentUID) {
          if (!_appContext.haveTokensForUserID(thisUID)) {
            final List<String> fetchedTokens =
                await _tokenResolver.resolveForAuthID(_appContext.getAuthIDFromUID(thisUID));
            _appContext.addTokensToUserID(thisUID, fetchedTokens);
          }

          tokens.addAll(_appContext.getTokensFromUserID(thisUID));
        }
      }
      _cloudFunctionManager
          .sendMessageToSelectedTokens(tokens: tokens, title: title, body: body, data: {'PostID': newPostID});
    }
  }

  Future<void> _updateAllUserPostInvolvement(final String newPostID) async {
    // first up, the author
    await _userDBManager.addPostToUser(_appContext.currentUser.id, newPostID, 'author');

    // then all the contributors
    for (final String contributorID in widget.eventContext.contributorAdditionUIDs) {
      await _userDBManager.addPostToUser(contributorID, newPostID, 'contributor');
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

  void _showSettings() {
    showModalBottomSheet(
        showDragHandle: true,
        context: context,
        builder: (_) => SingleChildScrollView(
                child: SafeArea(
                    child: Column(children: [
              ListTile(
                title: const Text('Edit About'),
                leading: const Icon(Icons.edit),
                onTap: _onEditBodyClick,
              ),
              widget.eventContext.head.eventDate != null
                  ? ListTile(
                      title: const Text('Add Schedule Item'),
                      leading: const Icon(Icons.edit_calendar),
                      onTap: _onAddScheduleItem,
                    )
                  : Container(),
              ListTile(
                title: const Text('Edit Media Items'),
                leading: const Icon(Icons.photo_library),
                onTap: _onEditMediaTap,
              ),
            ]))));
  }

  void _onEditBodyClick() {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: widget.eventContext)))
        .then((_) {
      setState(() {
        _onRequiredFieldTextChange('');
      });
    });
  }

  void _onAddScheduleItem() async {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventProgramPage(eventContext: widget.eventContext)))
        .then((_) async {
      widget.eventContext.program.orderProgramsByStartTime();
      setState(() {});
    }).then((_) {});
  }

  void _onEditMediaTap() {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditGalleryPage(eventContext: widget.eventContext)))
        .then((_) {
      setState(() {});
    });
  }
}
