import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/everyone_db_manager.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../firebase/functions_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../models/event/event_head.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/local_data_manager.dart';
import '../../widgets/posts/post_metadata_section.dart';
import '../../widgets/posts/view_event_media_tab.dart';
import '../../widgets/posts/view_post_body.dart';
import '../../widgets/posts/view_all_programs.dart';
import '../../widgets/posts/view_related_posts_tab.dart';
import 'edit_title_subtitle_page.dart';

class ViewEventPage extends StatefulWidget {
  const ViewEventPage({super.key, required this.eventHead});
  final EventHead eventHead;

  @override
  State<ViewEventPage> createState() => _ViewEventPageState();
}

class _ViewEventPageState extends State<ViewEventPage> with SingleTickerProviderStateMixin {
  static final MessagingManager _messagingManager = MessagingManager();
  static const String _post = 'post-';

  late final TabController _tabController;
  late final EventContext _eventContext;
  late final List<Map<String, String>> _originalHeadMedia;
  late final String _originalTitle, _originalSubtitle, _currentUID;
  late final DateTime? _originalEventDate;

  final List<Widget> _bodyTabs = List.empty(growable: true);
  final List<Widget> _appBarTabs = [
    const Tab(icon: Icon(Icons.info_outline), text: 'About'),
  ];

  bool _haveFetchedPost = false;

  @override
  void initState() {
    Provider.of<AppContext>(context, listen: false)
        .analytics
        .setCurrentScreen(screenName: 'post-${widget.eventHead.id}');
    _currentUID = Provider.of<AppContext>(context, listen: false).currentUser.id;

    _originalHeadMedia = List<Map<String, String>>.from(widget.eventHead.media);
    _originalTitle = widget.eventHead.title;
    _originalSubtitle = widget.eventHead.subtitle;
    _originalEventDate = widget.eventHead.eventDate;

    super.initState();
  }

  @override
  void dispose() {
    if (_haveFetchedPost) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _canSaveEditing
            ? () => DialogManager.discardChanges(context: context).then((confirmation) {
                  if (confirmation) {
                    widget.eventHead.resetMediaWithOriginal(_originalHeadMedia);
                    widget.eventHead.setTitle(_originalTitle);
                    widget.eventHead.setSubtitle(_originalSubtitle);
                    widget.eventHead.setEventDate(_originalEventDate);
                  }
                  return confirmation;
                })
            : () async => true,
        child: Scaffold(body: _haveFetchedPost ? _buildBodyWithData() : _buildCheckExistingPostBody()));
  }

  Widget _buildCheckExistingPostBody() {
    return FutureBuilder(
        future: _attemptToGetExistingPostData(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());
          if (snap.hasData) {
            // build with data, set the post context here
            final List<String> data = snap.data!;

            if (data.isNotEmpty) {
              debugPrint('Using existing post data for ID: ${widget.eventHead.id}');
              _eventContext = EventContext.viewing(eventHead: widget.eventHead, data: data, currentUID: _currentUID);
              _haveFetchedPost = true;

              _figureOutTabs();
              Provider.of<AppContext>(context, listen: false).setMetadata(_eventContext.id, _eventContext.metadata);
              _checkToUnbookForContributor();
              result = _buildBodyWithData();
            } else {
              debugPrint('Fetching from DB for post ID: ${widget.eventHead.id}');
              result = _buildFetchPostBody();
            }
          } else if (snap.hasError) {
            result = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Something went wrong with checking local data!\n\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close Page'))
              ],
            );
          }

          return result;
        });
  }

  Widget _buildFetchPostBody() {
    return FutureBuilder(
        future: _fetchEssentialPostData(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            Provider.of<AppContext>(context, listen: false).setMetadata(_eventContext.id, _eventContext.metadata);
            _figureOutTabs();
            _savePostDataToLocalStorage();
            _haveFetchedPost = true;
            _checkToUnbookForContributor();
            result = _buildBodyWithData();
          } else if (snap.hasError) {
            debugPrint('Something with fetching the post ${snap.error}');
            result = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Something went wrong with fetching the post!\n\n${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close Page'))
                ]);
          }
          return result;
        });
  }

  Widget _buildBodyWithData() {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 0;

    return NestedScrollView(
        headerSliverBuilder: (_, __) {
          return _buildHeaderSliver(webHorizontalPadding);
        },
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          child: _buildTabBody(),
        ));
  }

  List<Widget> _buildHeaderSliver(final double webHorizontalPadding) {
    final List<Widget> metaChildren = [PostMetadataSection(eventContext: _eventContext, update: _updateWholePostBody)];

    if (!_eventContext.isCurrentUserAuthor(_currentUID) && !_eventContext.isCurrentUserContributor(_currentUID)) {
      metaChildren.insert(0, _buildBookmarkButton());
    }
    final bool onDark = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

    return [
      SliverAppBar(
          expandedHeight: _eventContext.head.getKeyGraphic() != null ? MediaQuery.of(context).size.height * 0.33 : null,
          flexibleSpace: FlexibleSpaceBar(background: _buildAppBarBackground()),
          actions: _buildSaveButton()),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
        sliver: SliverList(
            delegate: SliverChildListDelegate([
          Padding(padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0), child: _buildTitle()),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: metaChildren),
          TabBar(labelColor: onDark ? Colors.white : Colors.black, controller: _tabController, tabs: _appBarTabs)
        ])),
      )
    ];
  }

  Widget _buildBookmarkButton() {
    return Consumer<AppContext>(builder: (_, appContext, __) {
      final bool bookmarked = appContext.sharedPref.bookmarkedPosts.contains(_eventContext.id);
      return IconButton.filled(
          onPressed: () => _bookmarkClick(appContext, bookmarked),
          icon: bookmarked ? const Icon(Icons.bookmark) : const Icon(Icons.bookmark_border));
    });
  }

  Widget _buildTitle() {
    return InkWell(
        onTap: _eventContext.isCurrentUserAuthor(_currentUID) ? _onTitleTap : null,
        child: Text(widget.eventHead.title, style: const TextStyle(fontSize: 28), textAlign: TextAlign.left));
  }

  Widget? _buildAppBarBackground() {
    // * If there are no images, we should just remove the expanded height
    final String? keyGraphicSrc = _eventContext.head.getKeyGraphic();

    if (keyGraphicSrc != null) {
      if (!kIsWeb) {
        return FutureBuilder(
          future: _fetchImage(keyGraphicSrc),
          builder: (_, snapshot) {
            Widget result = const Center(child: CircularProgressIndicator());
            if (snapshot.hasData) {
              return Image.file(snapshot.data!, fit: BoxFit.cover);
            } else if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong trying to get the image'));
            }

            return result;
          },
        );
      } else {
        return Image.network(keyGraphicSrc, fit: BoxFit.cover);
      }
    }
    return null;
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: _bodyTabs);
  }

  List<Widget>? _buildSaveButton() {
    if (_eventContext.isCurrentUserAuthor(_currentUID) || _eventContext.isCurrentUserContributor(_currentUID)) {
      return [
        ElevatedButton.icon(
            style: ButtonStyle(
                backgroundColor: _eventContext.canSaveTheEditing
                    ? MaterialStatePropertyAll<Color>(Colors.green.withOpacity(0.7))
                    : MaterialStatePropertyAll<Color>(Colors.grey.withOpacity(0.7)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)))),
            onPressed: _eventContext.canSaveTheEditing ? _updateClick : null,
            icon: Icon(
              Icons.save,
              color: _eventContext.canSaveTheEditing ? Colors.white : null,
            ),
            label: Text(
              'Update',
              style: _eventContext.canSaveTheEditing ? const TextStyle(color: Colors.white) : null,
            )),
        const SizedBox(width: 8)
      ];
    }
    return null;
  }

  // * Logic
  Future<File> _fetchImage(String src) async {
    final dir = await getTemporaryDirectory();
    final sanitisedFilePath = src.replaceAll(RegExp(r'[^\w]'), '');
    final fullPath = '${dir.path}/$sanitisedFilePath.png';
    final file = File(fullPath);

    if (!await file.exists()) {
      debugPrint('Creating image file for: $fullPath');
      final response = await http.get(Uri.parse(src));
      return await file.writeAsBytes(response.bodyBytes);
    }
    return file;
  }

  Future<bool> _fetchEssentialPostData() async {
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(widget.eventHead.id);
    final media = await dbManager.fetchMedia();
    final meta = await dbManager.fetchMetadata();
    final program = await dbManager.fetchProgram();
    final logs = await dbManager.fetchLog();
    final body = await dbManager.fetchBody();

    _eventContext = EventContext.viewing(eventHead: widget.eventHead, currentUID: _currentUID);
    _eventContext.setFetchedMedia(media);
    _eventContext.setFetchedMetadata(meta);
    _eventContext.setFetchedProgram(program);
    _eventContext.setFetchedLogs(logs);
    _eventContext.setFetchedBody(body);
    return true;
  }

  void _figureOutTabs() {
    final bool isAuthor = _eventContext.metadata.authorUID.compareTo(_currentUID) == 0;
    final bool isContributor = _eventContext.metadata.contributorUIDs.contains(_currentUID);
    final bool isLeader = Provider.of<AppContext>(context, listen: false).currentUser.isLeader;

    int length = 1;
    _bodyTabs.add(ViewPostBody(
      eventContext: _eventContext,
      updateBody: _updateWholePostBody,
      currentUID: _currentUID,
    ));

    if (_eventContext.head.eventDate != null || isAuthor) {
      _bodyTabs.add(ViewAllPrograms(eventContext: _eventContext, onProgramChanged: _updateWholePostBody));
      _appBarTabs.add(const Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'));
      length++;
    }
    if (_eventContext.media.allMedia.isNotEmpty || isAuthor || isContributor) {
      _bodyTabs.add(
          ViewEventMediaTab(eventContext: _eventContext, onMediaEdit: _updateWholePostBody, currentUID: _currentUID));
      _appBarTabs.add(const Tab(icon: Icon(Icons.photo_album), text: 'Media'));
      length++;
    }
    if (_eventContext.metadata.hasChildren || _eventContext.metadata.hasParent || isLeader) {
      _bodyTabs.add(ViewRelatedPostsTab(eventContext: _eventContext));
      _appBarTabs.add(const Tab(icon: Icon(Icons.library_books), text: 'Related'));
      length++;
    }

    _tabController = TabController(length: length, vsync: this);
  }

  void _updateWholePostBody() => setState(() {});

  void _bookmarkClick(final AppContext appContext, final bool bookmarked) {
    setState(() {
      if (bookmarked) {
        appContext.sharedPref.removePostBookmark(_eventContext.id);
        _messagingManager.unsubscribeFromTopic(_topic);
      } else {
        appContext.sharedPref.addPostBookmark(_eventContext.id);
        _messagingManager.subscribeToTopic(_topic);
      }
    });
  }

  void _onTitleTap() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditHeadDetailsPage(eventContext: _eventContext)))
        .then((_) {
      setState(() {});
    });
  }

  void _updateClick() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => EventLogDialog(
            eventContext: _eventContext,
            originalTitle: _originalTitle,
            topic: _topic,
            updatePage: () {
              setState(() {});
            }));
  }

  String get _topic => _post + _eventContext.id;

  Future<List<String>> _attemptToGetExistingPostData() async {
    final LocalDataManager localDataManager = LocalDataManager();
    final AppContext appContext = Provider.of<AppContext>(context, listen: false);
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final List<String> content = kIsWeb
        ? appContext.sharedPref.getPostData(widget.eventHead.id)
        : await localDataManager.readPostData(widget.eventHead.id);

    bool canUseLocalContent = false;
    if (content.isNotEmpty) {
      final firstLine = content[0].split('-');
      if (firstLine.length == 2) {
        canUseLocalContent = int.parse(firstLine[0]) == widget.eventHead.recentDate.millisecondsSinceEpoch &&
            firstLine[1] == packageInfo.version;
      }
    }

    if (canUseLocalContent) {
      return content;
    }
    return List.empty();
  }

  Future<void> _savePostDataToLocalStorage() async {
    final LocalDataManager localDataManager = LocalDataManager();
    final AppContext appContext = Provider.of<AppContext>(context, listen: false);
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String content = _eventContext.transformPostToTxtFile(packageInfo.version);

    if (kIsWeb) {
      appContext.sharedPref.writePostData(_eventContext.id, content);
      appContext.sharedPref.addPostTrackID(_eventContext.id);
    } else {
      localDataManager.writePostData(_eventContext.id, content);
      final postTrack = await localDataManager.readPostTrack();
      if (!postTrack.contains(_eventContext.id)) {
        postTrack.add(_eventContext.id);
        localDataManager.writePostTrack(postTrack);
      }
    }
  }

  bool get _canSaveEditing => _haveFetchedPost && _eventContext.canSaveTheEditing;

  void _checkToUnbookForContributor() {
    if (_eventContext.metadata.contributorUIDs.contains(_currentUID)) {
      debugPrint('removing post from bookmarks because user is already contributor!');
      Provider.of<AppContext>(context, listen: false).sharedPref.removePostBookmark(_eventContext.id);
    }
  }
}

class EventLogDialog extends StatefulWidget {
  const EventLogDialog(
      {super.key,
      required this.eventContext,
      required this.updatePage,
      required this.originalTitle,
      required this.topic});
  final EventContext eventContext;
  final Function() updatePage;
  final String originalTitle;
  final String topic;

  @override
  State<EventLogDialog> createState() => _EventLogDialogState();
}

class _EventLogDialogState extends State<EventLogDialog> {
  late final AppContext _appContext;
  late final String _currentUserName, _currentUID;
  final TextEditingController _tecLog = TextEditingController();
  final CloudFunctionManager _cloudFunctionManager = CloudFunctionManager();
  final EveryoneDBManager _everyoneDBManager = EveryoneDBManager();
  final UserDBManager _userDBManager = UserDBManager();
  bool _canSave = false;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    _currentUID = _appContext.currentUser.id;
    _currentUserName = _appContext.currentUser.forname;
    super.initState();
  }

  @override
  void dispose() {
    _tecLog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _tecLog,
                  decoration: const InputDecoration(hintText: 'e.g. Added new images!', label: Text('Update Log')),
                  maxLength: 128,
                  maxLines: null,
                  onChanged: _onTextChange),
              const SizedBox(height: 8),
              TextButton.icon(
                  onPressed: _canSave ? _saveClick : null,
                  style: ButtonStyle(
                      backgroundColor:
                          _canSave ? MaterialStateProperty.all(Colors.green) : MaterialStateProperty.all(Colors.grey)),
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text('Save', style: TextStyle(color: Colors.white))),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))
            ],
          ),
        ),
      ),
    );
  }

  // * Logic

  void _onTextChange(String newString) {
    if (_canSave && newString.trim().isEmpty) {
      setState(() {
        _canSave = false;
      });
    } else if (!_canSave) {
      setState(() {
        _canSave = true;
      });
    }
  }

  void _saveClick() {
    DialogManager.showConfirmationDialog(
            context: context,
            title: 'Confirm Save',
            content: 'This log will be sent to all who have bookmarked this post. Are you sure you want to continue?',
            confirmText: 'Save',
            cancelText: 'Cancel')
        .then((confirmation) {
      if (confirmation) {
        DialogManager.showProgressDialog(context: context, title: 'Uploading Changes');
        final appContext = Provider.of<AppContext>(context, listen: false);
        _performUpdate(appContext.currentUser.id).then((_) {
          appContext.setMetadata(widget.eventContext.id, widget.eventContext.metadata);
          widget.eventContext.resetSavingOfTheEdit();
          widget.updatePage();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Changes Saved!'), behavior: SnackBarBehavior.floating));
        });
      }
    });
  }

  Future<void> _performUpdate(String uid) async {
    final LocalDataManager localDataManager = LocalDataManager();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    await widget.eventContext.updatePost(log: _tecLog.text.trim(), uid: uid);
    final content = widget.eventContext.transformPostToTxtFile(packageInfo.version);
    localDataManager.writePostData(widget.eventContext.id, content);

    if (widget.eventContext.head.eventDate != null) {
      await _sortRoleAdditions();
      await _sendRoleRemovals();
    }
    await _sendContributorAdditionNotificaitons();
    await _sendContributorRemovalNotificaitons();
    await _updateAllUserPostInvolvement();
    _sendPostNotification();
  }

  Future<void> _sendPostNotification() async {
    // message to topic
    // message to author + contributors
    // hmm basically both will use the same title-subtitle but we should mention who updated it

    final String subtitle = _tecLog.text.trim();
    final String adminSubtitle = '$_currentUserName updated: $subtitle';
    final String? keyGraphic = widget.eventContext.head.getKeyGraphic();

    final List<String> deviceTokens = await _getAdminContactTokens();

    if (deviceTokens.isNotEmpty) {
      await _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: deviceTokens, title: widget.originalTitle, body: adminSubtitle, data: _notificationdata);
    }

    await _cloudFunctionManager.sendToTopic(
        topic: widget.topic,
        title: widget.originalTitle,
        body: subtitle,
        data: _notificationdata,
        iOSImage: keyGraphic,
        androidImage: keyGraphic);
  }

  Future<List<String>> _getAdminContactTokens() async {
    // Fetching all the contacts for the admins
    // Remember to remove the current user from this list
    // Fetch all the contributor device tokens (unless it's the current user)

    final List<String> missingContacts = widget.eventContext.metadata.contributorUIDs
        .where((contributorID) =>
            contributorID.compareTo(_currentUID) != 0 && !_appContext.haveTokensForUserID(contributorID))
        .toList();

    // fetch the author contact (if the current user isn't already the author)
    if (_currentUID.compareTo(widget.eventContext.metadata.authorUID) != 0 &&
        !_appContext.haveTokensForUserID(widget.eventContext.metadata.authorUID)) {
      missingContacts.add(widget.eventContext.metadata.authorUID);
    }

    // fetch and add any missing contacts we need for this operation
    debugPrint('missing contacts are: $missingContacts');
    for (final String uid in missingContacts) {
      final tokens = await _everyoneDBManager.fetchTokensFromAuthID(_appContext.getAuthIDFromUID(uid));
      _appContext.addTokensToUserID(uid, tokens);
    }

    // create token list of contributors
    final List<String> deviceTokens = List<String>.empty(growable: true);
    for (final String contributorID in widget.eventContext.metadata.contributorUIDs) {
      if (_appContext.currentUser.id.compareTo(contributorID) != 0) {
        deviceTokens.addAll(_appContext.getTokensFromUserID(contributorID));
      }
    }

    // add the author tokens
    if (_appContext.currentUser.id.compareTo(widget.eventContext.metadata.authorUID) != 0) {
      deviceTokens.addAll(_appContext.getTokensFromUserID(widget.eventContext.metadata.authorUID));
    }

    return deviceTokens;
  }

  // sends notifications and handles the user roles document for addition of role
  Future<void> _sortRoleAdditions() async {
    final String title = "$_currentUserName has assinged you to a role!";

    for (final additionEntry in widget.eventContext.roleAdditions.entries) {
      debugPrint('----- this addition entry looks like: $additionEntry');
      final roleEntry = widget.eventContext.program.roles.firstWhere((e) => e['id'] == additionEntry.key);
      final String body = "You are assigned to '${roleEntry['title']!}' for ${widget.originalTitle}";

      final List<String> tokens = [];
      for (final thisUID in additionEntry.value) {
        if (thisUID != _currentUID) {
          if (!_appContext.haveTokensForUserID(thisUID)) {
            debugPrint('fetching tokens for UID: $thisUID');
            final tokens = await _everyoneDBManager.fetchTokensFromAuthID(_appContext.getAuthIDFromUID(thisUID));
            _appContext.addTokensToUserID(thisUID, tokens);
          }

          tokens.addAll(_appContext.getTokensFromUserID(thisUID));
        }
        await _userDBManager.addUserRole(
            uid: thisUID,
            postID: widget.eventContext.id,
            roleID: additionEntry.key,
            millisecondStart: (roleEntry['start'] as DateTime).millisecondsSinceEpoch,
            millisecondEnd: (roleEntry['end'] as DateTime).millisecondsSinceEpoch,
            title: roleEntry['title']);
      }
      _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: tokens, title: title, body: body, data: _notificationdata);
    }
  }

  // sends notifications and handles the user roles document for removal of role
  Future<void> _sendRoleRemovals() async {
    final String title = "$_currentUserName has removed you from a role";

    debugPrint('on the removals: the entries look like:${widget.eventContext.roleRemovalals.entries}');
    for (final removalEntry in widget.eventContext.roleRemovalals.entries) {
      final String roleTitle = widget.eventContext.deletedRoleTitle(removalEntry.key);
      final String body = "You are no longer assigned to '$roleTitle' for ${widget.originalTitle}";

      final List<String> tokens = [];
      for (final thisUID in removalEntry.value) {
        if (thisUID != _currentUID) {
          if (!_appContext.haveTokensForUserID(thisUID)) {
            debugPrint('fetching tokens for UID: $thisUID');
            final tokens = await _everyoneDBManager.fetchTokensFromAuthID(_appContext.getAuthIDFromUID(thisUID));
            _appContext.addTokensToUserID(thisUID, tokens);
          }

          tokens.addAll(_appContext.getTokensFromUserID(thisUID));
        }
        await _userDBManager.removeUserRole(thisUID, removalEntry.key);
      }
      await _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: tokens, title: title, body: body, data: _notificationdata);
    }
  }

  Future<void> _sendContributorAdditionNotificaitons() async {
    const String title = "Contributor update";
    final String body = "You can modify aspects of the post: '${widget.originalTitle}'";
    final List<String> allTokens = List<String>.empty(growable: true);

    for (final String thisUID in widget.eventContext.contributorAdditionUIDs) {
      if (thisUID != _currentUID) {
        if (!_appContext.haveTokensForUserID(thisUID)) {
          final tokens = await _everyoneDBManager.fetchTokensFromAuthID(_appContext.getAuthIDFromUID(thisUID));
          _appContext.addTokensToUserID(thisUID, tokens);
        }

        allTokens.addAll(_appContext.getTokensFromUserID(thisUID));
      }
    }

    if (allTokens.isNotEmpty) {
      _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: allTokens, title: title, body: body, data: _notificationdata);
    }
  }

  Future<void> _sendContributorRemovalNotificaitons() async {
    const String title = "Contributor update";
    final String body = "You have been removed as a contributor for '${widget.originalTitle}'";
    final List<String> allTokens = List<String>.empty(growable: true);

    for (final String thisUID in widget.eventContext.contributorRemovalUIDs) {
      if (thisUID != _currentUID) {
        if (!_appContext.haveTokensForUserID(thisUID)) {
          final tokens = await _everyoneDBManager.fetchTokensFromAuthID(_appContext.getAuthIDFromUID(thisUID));
          _appContext.addTokensToUserID(thisUID, tokens);
        }

        allTokens.addAll(_appContext.getTokensFromUserID(thisUID));
      }
    }

    if (allTokens.isNotEmpty) {
      _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: allTokens, title: title, body: body, data: _notificationdata);
    }
  }

  Future<void> _updateAllUserPostInvolvement() async {
    final String postID = widget.eventContext.id;
    final UserDBManager userDBManager = UserDBManager();

    // then add the new contributors
    for (final String contributorID in widget.eventContext.contributorAdditionUIDs) {
      userDBManager.addPostToUser(contributorID, postID, 'contributor');
    }

    // then remove the old contributors
    for (final String contributorID in widget.eventContext.contributorRemovalUIDs) {
      userDBManager.removePostFromUser(contributorID, postID);
    }
  }

  Map<String, String> get _notificationdata => {'PostID': widget.eventContext.id};
}
