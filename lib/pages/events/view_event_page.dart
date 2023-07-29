import 'package:ctrim_app/firebase/db_managers/user_contact_db_manager.dart';
import 'package:ctrim_app/firebase/functions_manager.dart';
import 'package:ctrim_app/firebase/messaging_manager.dart';
import 'package:ctrim_app/models/user_contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
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
    // TODO for the future: make user unsubscibe to post if they are a contributor

    _originalHeadMedia = List<Map<String, String>>.from(widget.eventHead.media);
    _originalTitle = widget.eventHead.title;
    _originalSubtitle = widget.eventHead.subtitle;
    _eventContext = EventContext.viewing(eventHead: widget.eventHead, viewingChild: widget.viewingChild);

    _currentUID = Provider.of<AppContext>(context, listen: false).currentUser.id;

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
        onWillPop: _eventContext.canSaveTheEditing
            ? () => DialogManager.discardChanges(context: context).then((confirmation) {
                  if (confirmation) {
                    widget.eventHead.resetMediaWithOriginal(_originalHeadMedia);
                    widget.eventHead.setTitle(_originalTitle);
                    widget.eventHead.setSubtitle(_originalSubtitle);
                  }
                  return confirmation;
                })
            : () async => true,
        child: Scaffold(body: _haveFetchedPost ? _buildBodyWithData() : _buildFB()));
  }

  Widget _buildFB() {
    return FutureBuilder(
        future: _fetchEssentialPostData(),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.connectionState == ConnectionState.done) {
            _figureOutTabs();
            _haveFetchedPost = true;
            Provider.of<AppContext>(context, listen: false).setMetadata(_eventContext.id, _eventContext.metadata);
            result = _buildBodyWithData();
          } else if (snap.hasError) {
            debugPrint('Something with fetching the post ${snap.error}');
            result = const Center(child: Text('Something went wrong!'));
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
      return Image.network(keyGraphicSrc, fit: BoxFit.cover);
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
  Future<void> _fetchEssentialPostData() async {
    // we need to fetch the media, program and metadata to figure out how many tabs to create
    // for the guest.
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(_eventContext.id);
    final media = await dbManager.fetchMedia();
    final meta = await dbManager.fetchMetadata();
    final program = await dbManager.fetchProgram();
    _eventContext.setFetchedMedia(media);
    _eventContext.setFetchedMetadata(meta);
    _eventContext.setFetchedProgram(program);
  }

  void _figureOutTabs() {
    int length = 1;
    _bodyTabs.add(ViewPostBody(
      eventContext: _eventContext,
      updateBody: _updateWholePostBody,
      currentUID: _currentUID,
    ));

    if (_eventContext.head.eventDate != null) {
      _bodyTabs.add(ViewAllPrograms(eventContext: _eventContext, onProgramChanged: _updateWholePostBody));
      _appBarTabs.add(const Tab(icon: Icon(Icons.calendar_today), text: 'Program'));
      length++;
    }
    if (_eventContext.media.allMedia.isNotEmpty) {
      _bodyTabs.add(
          ViewEventMediaTab(eventContext: _eventContext, onMediaEdit: _updateWholePostBody, currentUID: _currentUID));
      _appBarTabs.add(const Tab(icon: Icon(Icons.photo_album), text: 'Media'));
      length++;
    }
    if (_eventContext.metadata.hasChildren || _eventContext.metadata.hasParent) {
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
  final TextEditingController _tecLog = TextEditingController();
  bool _canSave = false;

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
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        });
      }
    });
  }

  Future<void> _performUpdate(String uid) async {
    if (!widget.eventContext.fetchedLogs) {
      final EventSupplementalDBManager dbManager = EventSupplementalDBManager(widget.eventContext.id);
      widget.eventContext.setFetchedLogs(await dbManager.fetchLog());
    }

    await widget.eventContext.updatePost(log: _tecLog.text.trim(), uid: uid);
    await _sendNotification();
  }

  Future<void> _sendNotification() async {
    // message to topic
    // message to author + contributors
    // hmm basically both will use the same title-subtitle but we should mention who updated it
    final AppContext appContext = Provider.of<AppContext>(context, listen: false);
    final CloudFunctionManager cloudFunctionManager = CloudFunctionManager();
    final String currentUserName = appContext.currentUser.forname;
    final String subtitle = _tecLog.text.trim();
    final String adminSubtitle = '$currentUserName updated: $subtitle';

    final List<String> deviceTokens = await _getAdminContactTokens(appContext);

    if (deviceTokens.isNotEmpty) {
      await cloudFunctionManager.sendMessageToSelectedTokens(
          tokens: deviceTokens, title: widget.originalTitle, body: adminSubtitle, data: {});
    }

    await cloudFunctionManager.sendToTopic(topic: widget.topic, title: widget.originalTitle, body: subtitle, data: {});
  }

  Future<List<String>> _getAdminContactTokens(final AppContext appContext) async {
    // ! oh man, test this out please
    // Fetching all the contacts for the admins
    // Remember to remove the current user from this list
    // Fetch all the contributor device tokens (unless it's the current user)
    final String currentUID = appContext.currentUser.id;

    final List<String> missingContacts = widget.eventContext.metadata.contributorUIDs
        .where((contributorID) =>
            contributorID.compareTo(currentUID) != 0 &&
            !appContext.userContacts.any((contact) => contact.id.compareTo(contributorID) == 0))
        .toList();

    // fetch the author contact (if the current user isn't already the author)
    if (currentUID.compareTo(widget.eventContext.metadata.authorUID) != 0 &&
        !appContext.userContacts.any((contact) => contact.id.compareTo(widget.eventContext.metadata.authorUID) == 0)) {
      missingContacts.add(widget.eventContext.metadata.authorUID);
    }

    // fetch and add any missing contacts we need for this operation
    if (missingContacts.isNotEmpty) {
      final List<UserContact> contacts = await _fetchMissingContacts(missingContacts);
      appContext.addAllUserContacts(contacts);
    }

    // create the cumulative device token list and return it
    final List<String> deviceTokens = List<String>.empty(growable: true);
    for (final String contributorID in widget.eventContext.metadata.contributorUIDs) {
      deviceTokens.addAll(appContext.userContacts.firstWhere((e) => e.id.compareTo(contributorID) == 0).deviceTokens);
    }

    return deviceTokens;
  }

  Future<List<UserContact>> _fetchMissingContacts(final List<String> missingIds) async {
    final UserContactDBManager userContactDBManager = UserContactDBManager();
    return await userContactDBManager.fetchUserContacts(missingIds);
  }
}
