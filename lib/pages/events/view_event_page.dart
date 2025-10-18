import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/everyone_db_manager.dart';
import '../../firebase/functions_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../models/event/event_head.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/local_data_manager.dart';
import '../../widgets/posts/event_log_dialog.dart';
import '../../widgets/posts/post_metadata_section.dart';
import '../../widgets/posts/view_event_media_tab.dart';
import '../../widgets/posts/view_post_body.dart';
import '../../widgets/posts/view_all_programs.dart';
import '../../widgets/posts/view_related_posts_tab.dart';
import 'add_program_role_page.dart';
import 'edit_body_page.dart';
import 'edit_gallery_page.dart';
import 'edit_title_subtitle_page.dart';
import 'post_templates/select_post_template_page.dart';

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
  late final List<Map<String, dynamic>> _originalHeadMedia;
  late final String _originalTitle, _originalSubtitle, _currentUID;
  late final DateTime? _originalEventDate;

  final List<Widget> _bodyTabs = List.empty(growable: true);
  final List<Widget> _appBarTabs = [
    const Tab(icon: Icon(Icons.info_outline), text: 'About'),
  ];

  bool _haveFetchedPost = false;

  @override
  void initState() {
    Provider.of<AppContext>(context, listen: false).analytics.logScreenView(screenName: 'post-${widget.eventHead.id}');
    _currentUID = Provider.of<AppContext>(context, listen: false).currentUser.id;

    _originalHeadMedia = List<Map<String, dynamic>>.from(widget.eventHead.media);
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

    // ! temporary fix for the issue below
    if (_canSaveEditing) {
      widget.eventHead.resetMediaWithOriginal(_originalHeadMedia);
      widget.eventHead.setTitle(_originalTitle);
      widget.eventHead.setSubtitle(_originalSubtitle);
      widget.eventHead.setEventDate(_originalEventDate);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO somthing terrible has happened! PopScope sucks so bad!
    // ! This breaks things for the admin, they can make changes and it won't be discarded when returning.
    // ! This is fine for now but not in the future when more admins come in...
    return Scaffold(
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        floatingActionButton: _buildSaveFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: _haveFetchedPost ? _buildBodyWithData() : _buildCheckExistingPostBody());
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<Widget> metaChildren = [PostMetadataSection(eventContext: _eventContext, update: _updateWholePostBody)];

    if (!_eventContext.isUserAuthor(_currentUID) && !_eventContext.isUserContributor(_currentUID)) {
      metaChildren.insert(0, _buildBookmarkButton());
    }

    return [
      SliverAppBar(
          expandedHeight: _eventContext.head.getKeyGraphic() != null ? MediaQuery.of(context).size.height * 0.33 : null,
          flexibleSpace: FlexibleSpaceBar(background: _buildAppBarBackground()),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          actions: _buildEditButton()),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
        sliver: SliverList(
            delegate: SliverChildListDelegate([
          Padding(padding: const EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0, bottom: 8.0), child: _buildTitle()),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: metaChildren),
          const SizedBox(height: 8),
          TabBar(
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3,
              controller: _tabController,
              tabs: _appBarTabs)
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
        onTap: _eventContext.isUserAuthor(_currentUID) ? _onTitleTap : null,
        child: Text(widget.eventHead.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.left));
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

  List<Widget>? _buildEditButton() {
    if (_eventContext.isUserAuthor(_currentUID) || _eventContext.isUserContributor(_currentUID)) {
      final colorScheme = Theme.of(context).colorScheme;
      return [
        FilledButton.tonalIcon(
            onPressed: () => _showSettings(),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.8),
              foregroundColor: colorScheme.onPrimaryContainer,
            )),
        const SizedBox(width: 8)
      ];
    }
    return null;
  }

  Widget? _buildSaveFAB() {
    if (_haveFetchedPost &&
        (_eventContext.isUserAuthor(_currentUID) || _eventContext.isUserContributor(_currentUID)) &&
        _eventContext.canSaveTheEditing) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: FloatingActionButton.extended(
            onPressed: _updateClick, label: const Text('Save Changes'), icon: const Icon(Icons.save)),
      );
    }
    return null;
  }

  // * Logic
  Future<File> _fetchImage(final String src) async {
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
      _bodyTabs.add(ViewAllPrograms(
          // key: ValueKey(DateTime.now().millisecondsSinceEpoch),
          eventContext: _eventContext,
          onProgramChanged: _updateWholePostBody));
      _appBarTabs.add(const Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'));
      length++;
    }
    if (_eventContext.media.allMedia.isNotEmpty || isAuthor || isContributor) {
      _bodyTabs.add(ViewEventMediaTab(eventContext: _eventContext, currentUID: _currentUID));
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

  void _showSettings() {
    List<Widget> children = [
      ListTile(
        title: const Text('Edit About'),
        leading: const Icon(Icons.edit),
        onTap: _onEditBodyClick,
      ),
      ListTile(
        title: const Text('Add Schedule'),
        leading: const Icon(Icons.edit_calendar),
        onTap: _onAddScheduleItem,
      )
    ];

    if (!kIsWeb) {
      children.add(ListTile(
        title: const Text('Edit Media'),
        leading: const Icon(Icons.photo_library),
        onTap: _onEditMediaClick,
      ));
    }

    if (Provider.of<AppContext>(context, listen: false).currentUser.isLeader) {
      children.addAll([
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          title: const Text('Create Sibling Post'),
          leading: const Icon(Icons.post_add),
          onTap: () => _onAddPost(_eventContext.metadata.parentID!),
        ),
        ListTile(
          title: const Text('Create Child Post'),
          leading: const Icon(Icons.post_add),
          onTap: () => _onAddPost(_eventContext.id),
        ),
        const Divider(indent: 16, endIndent: 16),
        ListTile(
          title: const Text('Notify: Broadcast'),
          leading: const Icon(Icons.notifications_active),
          onTap: _notifyBroadcastClick,
        ),
        ListTile(
          title: const Text('Notify: Scheduled Members'),
          leading: const Icon(Icons.notifications_active),
          onTap: _notifyScheduledMembersClick,
        ),
      ]);
    }

    showModalBottomSheet(
        showDragHandle: true,
        context: context,
        builder: (_) => SingleChildScrollView(child: SafeArea(child: Column(children: children))));
  }

  void _onEditBodyClick() {
    Navigator.of(context).pop();
    _tabController.animateTo(1);
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: _eventContext))).then((_) {
      setState(() {});
      _tabController.animateTo(0);
    });
  }

  void _onAddScheduleItem() {
    Navigator.of(context).pop();
    // _tabController.animateTo(2);
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventProgramPage(eventContext: _eventContext)))
        .then((_) {
      setState(() {});
      _eventContext.program.orderProgramsByStartTime();
      // _tabController.animateTo(1);
    });
  }

  void _onEditMediaClick() {
    Navigator.of(context).pop();
    _tabController.animateTo(0);
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditGalleryPage(eventContext: _eventContext))).then((_) {
      setState(() {});
      _tabController.animateTo(2);
    });
  }

  void _onAddPost(final String parentID) {
    Navigator.of(context).pop();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SelectPostTemplatePage(
                eventContext: EventContext.adding(
                    currentUserID: Provider.of<AppContext>(context, listen: false).currentUser.id,
                    parentID: parentID)))).then((_) {
      setState(() {
        // rebuild? - will this update when creating sibling posts?
      });
    });
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

  void _notifyBroadcastClick() {
    DialogManager.showConfirmationDialog(
            context: context,
            title: 'Notify Broadcast',
            content:
                'This action will send a push notification to people who subscribed to these notifications. Do you wish to continue?')
        .then((confirmation) {
      if (confirmation) {
        final List<String> topics = _eventContext.metadata.topics;
        final CloudFunctionManager cloudFunctionManager = CloudFunctionManager();
        final String title = _eventContext.head.title;
        final String subtitle = _eventContext.head.subtitle;

        for (final topic in topics) {
          cloudFunctionManager.sendToTopic(
              topic: topic,
              title: title,
              body: subtitle,
              data: {'PostID': _eventContext.id},
              iOSImage: _eventContext.head.getKeyGraphic(),
              androidImage: _eventContext.head.getKeyGraphic());
        }
      }
    });
  }

  void _notifyScheduledMembersClick() {
    DialogManager.showConfirmationDialog(
            context: context,
            title: 'Notify Scheduled Members',
            content: 'This action will send a push notification to people of the schedule. Do you wish to continue?')
        .then((confirmation) {
      if (confirmation) {
        _sendRoleNotifications();
      }
    });
  }

  Future<void> _sendRoleNotifications() async {
    final AppContext appContext = Provider.of<AppContext>(context, listen: false);
    final CloudFunctionManager cloudFunctionManager = CloudFunctionManager();
    final EveryoneDBManager everyoneDBManager = EveryoneDBManager();
    final DateFormat dateFormat = DateFormat('EEE, MMM d'), timeFormat = DateFormat('HH:mm');

    final String currentUID = appContext.currentUser.id;
    final String title = "📣 Reminder of your task - ${dateFormat.format(_eventContext.head.eventDate!)}!";

    for (final roleEntry in _eventContext.program.roles) {
      final DateTime startingTime = roleEntry['start'];
      final String body =
          "'${roleEntry['title']!}' for ${_eventContext.head.title}.\nStarting ${timeFormat.format(startingTime)}";
      final List<String> tokens = [];
      final List<String> uids = roleEntry['uids'];

      for (final thisUID in uids) {
        if (thisUID != currentUID) {
          if (!appContext.haveTokensForUserID(thisUID)) {
            final List<String> tokens =
                await everyoneDBManager.fetchTokensFromAuthID(appContext.getAuthIDFromUID(thisUID));
            appContext.addTokensToUserID(thisUID, tokens);
          }

          tokens.addAll(appContext.getTokensFromUserID(thisUID));
        }
      }

      if (tokens.isNotEmpty) {
        cloudFunctionManager
            .sendMessageToSelectedTokens(tokens: tokens, title: title, body: body, data: {'PostID': _eventContext.id});
      }
    }
  }
}
