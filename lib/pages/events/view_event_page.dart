import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/user_contact_db_manager.dart';
import '../../firebase/functions_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/user_contact.dart';
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
  const ViewEventPage({super.key, required this.eventHead, required this.viewingChild});
  final EventHead eventHead;
  final bool viewingChild;

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
  final List<Widget> _appBarTabs = [
    const Tab(icon: Icon(Icons.info_outline), text: 'About'),
  ];
  final List<Widget> _bodyTabs = List.empty(growable: true);

  bool _haveFetchedPost = false;

  @override
  void initState() {
    _currentUID = Provider.of<AppContext>(context, listen: false).currentUser.id;

    _originalHeadMedia = List<Map<String, String>>.from(widget.eventHead.media);
    _originalTitle = widget.eventHead.title;
    _originalSubtitle = widget.eventHead.subtitle;

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
            // build with data
            // set the post context here
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
            result = const Center(child: Text('Something went wrong!'));
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
            _savePostData();
            _haveFetchedPost = true;
            _checkToUnbookForContributor();
            result = _buildBodyWithData();
          } else if (snap.hasError) {
            debugPrint('Something with fetching the post ${snap.error}');
            result = const Center(child: Text('Something went wrong!'));
            // TODO show an error dialog and pop the page
          }
          return result;
        });
  }

  Widget _buildBodyWithData() {
    return NestedScrollView(
        headerSliverBuilder: (_, __) {
          return _buildHeaderSliver();
        },
        body: _buildTabBody());
  }

  List<Widget> _buildHeaderSliver() {
    final List<Widget> metaChildren = [PostMetadataSection(eventContext: _eventContext, update: _updateWholePostBody)];
    if (!_eventContext.isCurrentUserAuthor(_currentUID) && !_eventContext.isCurrentUserContributor(_currentUID)) {
      metaChildren.insert(0, _buildBookmarkButton());
    }
    final bool onDark = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    return [
      SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * 0.33,
          flexibleSpace: FlexibleSpaceBar(background: _buildAppBarBackground()),
          actions: _buildAppBarAction()),
      SliverList(
          delegate: SliverChildListDelegate([
        Padding(padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0), child: _buildTitle()),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: metaChildren),
        TabBar(labelColor: onDark ? Colors.white : Colors.black, controller: _tabController, tabs: _appBarTabs)
      ]))
    ];
  }

  Widget _buildBookmarkButton() {
    return Consumer<AppContext>(builder: (_, appContext, __) {
      final bool bookmarked = appContext.dataManager.bookmarkedPosts.contains(_eventContext.id);
      return IconButton.filled(
          onPressed: () => _bookmarkClick(appContext, bookmarked),
          icon: bookmarked ? const Icon(Icons.bookmark) : const Icon(Icons.bookmark_border));
    });
  }

  Widget _buildTitle() {
    return InkWell(
        onTap: _eventContext.isCurrentUserAuthor(_currentUID) ? _onTitleTap : null,
        child: Text(widget.eventHead.title, style: const TextStyle(fontSize: 28)));
  }

  Widget? _buildAppBarBackground() {
    // * If there are no images, we should just remove the expanded height
    final String? keyGraphicSrc = _eventContext.head.getKeyGraphic();
    if (keyGraphicSrc != null) {
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
    }
    return null;
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: _bodyTabs);
  }

  List<Widget>? _buildAppBarAction() {
    if (_eventContext.isCurrentUserAuthor(_currentUID) || _eventContext.isCurrentUserContributor(_currentUID)) {
      return [
        ElevatedButton.icon(
            style: ButtonStyle(
                backgroundColor: _eventContext.canSaveTheEditing
                    ? const MaterialStatePropertyAll<Color>(Colors.green)
                    : const MaterialStatePropertyAll<Color>(Colors.grey),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)))),
            onPressed: _eventContext.canSaveTheEditing ? _updateClick : null,
            icon: const Icon(Icons.save),
            label: const Text('Update')),
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
      _appBarTabs.add(const Tab(icon: Icon(Icons.calendar_today), text: 'Program'));
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
        appContext.dataManager.removePostBookmark(_eventContext.id);
        _messagingManager.unsubscribeFromTopic(_topic);
      } else {
        appContext.dataManager.addPostBookmark(_eventContext.id);
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
    // TODO we should also make sure that we unconditionally fetch when an update has occured for safety
    final LocalDataManager localDataManager = LocalDataManager();
    final content = await localDataManager.readPostData(widget.eventHead.id);

    // debugPrint('Is local post data not empty: ${content.isNotEmpty}');
    final bool canUseLocalContent =
        content.isNotEmpty && int.parse(content[0]) == widget.eventHead.recentDate.millisecondsSinceEpoch;

    if (canUseLocalContent) {
      return content;
    }
    return List.empty();
  }

  Future<void> _savePostData() async {
    final LocalDataManager localDataManager = LocalDataManager();
    final String content = _eventContext.transformPostToTxtFile();
    localDataManager.writePostData(_eventContext.id, content);

    final postTrack = await localDataManager.readPostTrack();
    if (!postTrack.contains(_eventContext.id)) {
      postTrack.add(_eventContext.id);
      localDataManager.writePostTrack(postTrack);
    }
  }

  bool get _canSaveEditing => _haveFetchedPost && _eventContext.canSaveTheEditing;

  void _checkToUnbookForContributor() {
    if (_eventContext.metadata.contributorUIDs.contains(_currentUID)) {
      debugPrint('removing post from bookmarks because user is already contributor!');
      Provider.of<AppContext>(context, listen: false).dataManager.removePostBookmark(_eventContext.id);
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
  final UserContactDBManager _userContactDBManager = UserContactDBManager();
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
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Please describe the update',
                style: TextStyle(fontSize: 16),
              ),
              TextField(
                controller: _tecLog,
                decoration: const InputDecoration(hintText: 'e.g. Added new images!', label: Text('Log')),
                maxLength: 128,
                maxLines: null,
                onChanged: _onTextChange,
              ),
              ElevatedButton.icon(
                  onPressed: _canSave ? _saveClick : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Update'))
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
            title: 'Last Chance',
            content: 'The log will be sent to all who have bookmarked this post',
            confirmText: 'I understand, Save!',
            cancelText: 'Wait a sec.')
        .then((confirmation) {
      if (confirmation) {
        DialogManager.showProgressDialog(context: context, title: 'Uploading Changes');
        final appContext = Provider.of<AppContext>(context, listen: false);
        _performUpdate(appContext.currentUser.id).then((_) {
          widget.eventContext.resetSavingOfTheEdit();
          appContext.setMetadata(widget.eventContext.id, widget.eventContext.metadata);
          widget.updatePage();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        });
      }
    });
  }

  Future<void> _performUpdate(String uid) async {
    final LocalDataManager localDataManager = LocalDataManager();
    await widget.eventContext.updatePost(log: _tecLog.text.trim(), uid: uid);

    final content = widget.eventContext.transformPostToTxtFile();
    localDataManager.writePostData(widget.eventContext.id, content);

    await _sendPostNotification();

    if (widget.eventContext.head.eventDate != null) {
      await _sendRoleAdditionNotiifications();
      await _sendRoleRemovalNotiifications();
    }
    await _sendContributorAdditionNotificaitons();
    await _sendContributorRemovalNotificaitons();
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
            contributorID.compareTo(_currentUID) != 0 &&
            !_appContext.userContacts.any((contact) => contact.id.compareTo(contributorID) == 0))
        .toList();

    // fetch the author contact (if the current user isn't already the author)
    if (_currentUID.compareTo(widget.eventContext.metadata.authorUID) != 0 &&
        !_appContext.userContacts.any((contact) => contact.id.compareTo(widget.eventContext.metadata.authorUID) == 0)) {
      missingContacts.add(widget.eventContext.metadata.authorUID);
    }

    // fetch and add any missing contacts we need for this operation
    debugPrint('missing contacts are: $missingContacts');
    if (missingContacts.isNotEmpty) {
      final List<UserContact> contacts = await _userContactDBManager.fetchUserContacts(missingContacts);
      _appContext.addAllUserContacts(contacts);
    }

    // create the cumulative device token list and return it
    final List<String> deviceTokens = List<String>.empty(growable: true);
    for (final String contributorID in widget.eventContext.metadata.contributorUIDs) {
      deviceTokens.addAll(_appContext.userContacts.firstWhere((e) => e.id.compareTo(contributorID) == 0).deviceTokens);
    }

    return deviceTokens;
  }

  Future<void> _sendRoleAdditionNotiifications() async {
    final String title = "$_currentUserName has assinged you to a role!";

    for (final additionEntry in widget.eventContext.roleAdditionNotifications) {
      final String body = "You are assigned to '${additionEntry['title']!}' for ${widget.originalTitle}";

      final String thisUID = additionEntry['uid']!;
      if (thisUID != _currentUID && !_appContext.userContacts.any((e) => e.id.compareTo(thisUID) == 0)) {
        final contact = await _userContactDBManager.fetchUserContact(thisUID);
        _appContext.addAllUserContacts([contact]);
      }

      final contact = _appContext.userContacts.firstWhere((e) => e.id.compareTo(thisUID) == 0);
      await _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: contact.deviceTokens, title: title, body: body, data: _notificationdata);
    }
  }

  Future<void> _sendRoleRemovalNotiifications() async {
    final String title = "$_currentUserName has removed you from a role";

    for (final removalEntry in widget.eventContext.roleRemovalNotifications) {
      final String body = "You are no longer assigned to '${removalEntry['title']!}' for ${widget.originalTitle}";

      final String thisUID = removalEntry['uid']!;
      if (thisUID != _currentUID && !_appContext.userContacts.any((e) => e.id.compareTo(thisUID) == 0)) {
        final contact = await _userContactDBManager.fetchUserContact(thisUID);
        _appContext.addAllUserContacts([contact]);
      }

      final contact = _appContext.userContacts.firstWhere((e) => e.id.compareTo(thisUID) == 0);
      await _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: contact.deviceTokens, title: title, body: body, data: _notificationdata);
    }
  }

  // mention whether a user has been added or removed
  Future<void> _sendContributorAdditionNotificaitons() async {
    const String title = "Contributor update";
    final String body = "You are given access to perform updates for '${widget.originalTitle}'";

    for (final thisUID in widget.eventContext.contributorAdditionUIDs) {
      if (!_appContext.userContacts.any((e) => e.id.compareTo(thisUID) == 0)) {
        final contact = await _userContactDBManager.fetchUserContact(thisUID);
        _appContext.addAllUserContacts([contact]);
      }

      final contact = _appContext.userContacts.firstWhere((e) => e.id.compareTo(thisUID) == 0);
      await _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: contact.deviceTokens, title: title, body: body, data: _notificationdata);
    }
  }

  Future<void> _sendContributorRemovalNotificaitons() async {
    const String title = "Contributor update";
    final String body = "You have been removed as a contributor for '${widget.originalTitle}'";

    for (final thisUID in widget.eventContext.contributorRemovalUIDs) {
      if (!_appContext.userContacts.any((e) => e.id.compareTo(thisUID) == 0)) {
        final contact = await _userContactDBManager.fetchUserContact(thisUID);
        _appContext.addAllUserContacts([contact]);
      }

      final contact = _appContext.userContacts.firstWhere((e) => e.id.compareTo(thisUID) == 0);
      await _cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: contact.deviceTokens, title: title, body: body, data: _notificationdata);
    }
  }

  Map<String, String> get _notificationdata => {'PostID': widget.eventContext.id};
}
