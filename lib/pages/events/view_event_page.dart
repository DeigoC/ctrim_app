import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../utility/notification_token_resolver.dart';
import '../../firebase/functions_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../models/event/event_head.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/local_data_manager.dart';
import '../../utility/notification_send_result.dart';
import '../../utility/notification_topics.dart';
import '../../utility/network_image_helper.dart';
import '../../widgets/posts/event_log_dialog.dart';
import '../../widgets/posts/post_edit_sheet.dart';
import '../../widgets/posts/post_metadata_section.dart';
import '../../widgets/posts/view_attendance_tab.dart';
import '../../widgets/posts/view_event_media_tab.dart';
import '../../widgets/posts/view_post_body.dart';
import '../../widgets/posts/view_all_programs.dart';
import '../../widgets/posts/view_related_posts_tab.dart';
import 'add_program_role_page.dart';
import 'edit_body_page.dart';
import 'edit_gallery_page.dart';
import 'edit_title_subtitle_page.dart';
import 'post_templates/select_post_template_page.dart';
import 'send_broadcast_notification_page.dart';
import 'view_meta_logs_page.dart';
import '../personal/select_users_page.dart';
import '../../utility/responsive_layout.dart';

class ViewEventPage extends StatefulWidget {
  const ViewEventPage({super.key, required this.eventHead});
  final EventHead eventHead;

  @override
  State<ViewEventPage> createState() => _ViewEventPageState();
}

class _ViewEventPageState extends State<ViewEventPage> with SingleTickerProviderStateMixin {
  static final MessagingManager _messagingManager = MessagingManager();

  late final TabController _tabController;
  late final EventContext _eventContext;
  late final List<Map<String, dynamic>> _originalHeadMedia;
  late final String _originalTitle, _originalSubtitle, _currentUID;
  late final DateTime? _originalEventDate;
  late final String? _originalLeadSpeakerUID, _originalLeadSpeakerImgSrc, _originalLeadSpeakerName;

  final List<Widget> _bodyTabs = List.empty(growable: true);
  final List<Widget> _appBarTabs = [
    const Tab(icon: Icon(Icons.info_outline), text: 'About'),
  ];

  bool _haveFetchedPost = false;
  Object? _loadError;
  String _loadStatusMessage = 'Checking saved copy…';
  int _loadCompletedSteps = 0;
  int _loadTotalSteps = 1;

  int _aboutTabIndex = 0;
  int _peopleTabIndex = 1;
  int? _mediaTabIndex;

  static const int _remoteFetchStepCount = 5;

  @override
  void initState() {
    Provider.of<AppContext>(context, listen: false).analytics.logScreenView(screenName: 'post-${widget.eventHead.id}');
    _currentUID = Provider.of<AppContext>(context, listen: false).currentUser.id;

    _originalHeadMedia = List<Map<String, dynamic>>.from(widget.eventHead.media);
    _originalTitle = widget.eventHead.title;
    _originalSubtitle = widget.eventHead.subtitle;
    _originalEventDate = widget.eventHead.eventDate;
    _originalLeadSpeakerUID = widget.eventHead.leadSpeakerUID;
    _originalLeadSpeakerImgSrc = widget.eventHead.leadSpeakerImgSrc;
    _originalLeadSpeakerName = widget.eventHead.leadSpeakerName;

    super.initState();
    _loadPost();
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
      widget.eventHead.setLeadSpeaker(
        uid: _originalLeadSpeakerUID,
        imgSrc: _originalLeadSpeakerImgSrc,
        name: _originalLeadSpeakerName,
      );
      if (_haveFetchedPost) {
        if (_originalLeadSpeakerUID == null || _originalLeadSpeakerUID!.isEmpty) {
          _eventContext.metadata.clearLeadSpeakerUID();
        } else {
          _eventContext.metadata.setLeadSpeakerUID(_originalLeadSpeakerUID);
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _haveFetchedPost
            ? null
            : AppBar(
                title: Text(
                  widget.eventHead.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        body: _haveFetchedPost ? _buildBodyWithData() : _buildLoadingOrErrorBody());
  }

  Widget _buildLoadingOrErrorBody() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong loading this post.\n\n$_loadError',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close Page'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double? progress =
        _loadTotalSteps > 0 ? (_loadCompletedSteps / _loadTotalSteps).clamp(0.0, 1.0) : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 16),
              Text(
                _loadStatusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (_loadTotalSteps > 1) ...[
                const SizedBox(height: 8),
                Text(
                  '$_loadCompletedSteps of $_loadTotalSteps',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _updateLoadProgress({
    required int completed,
    required int total,
    required String message,
  }) {
    if (!mounted) return;
    setState(() {
      _loadCompletedSteps = completed;
      _loadTotalSteps = total;
      _loadStatusMessage = message;
    });
  }

  Future<void> _loadPost() async {
    try {
      _updateLoadProgress(completed: 0, total: 1, message: 'Checking saved copy…');
      final List<String> data = await _attemptToGetExistingPostData();
      if (!mounted) return;

      if (data.isNotEmpty) {
        debugPrint('Using existing post data for ID: ${widget.eventHead.id}');
        _eventContext = EventContext.viewing(eventHead: widget.eventHead, data: data, currentUID: _currentUID);
        _figureOutTabs();
        Provider.of<AppContext>(context, listen: false).setMetadata(_eventContext.id, _eventContext.metadata);
        _checkToUnbookForContributor();
        setState(() => _haveFetchedPost = true);
        return;
      }

      debugPrint('Fetching from DB for post ID: ${widget.eventHead.id}');
      await _fetchEssentialPostData();
      if (!mounted) return;

      Provider.of<AppContext>(context, listen: false).setMetadata(_eventContext.id, _eventContext.metadata);
      _figureOutTabs();
      _savePostDataToLocalStorage();
      _checkToUnbookForContributor();
      setState(() => _haveFetchedPost = true);
    } catch (e, stack) {
      debugPrint('Something went wrong loading the post: $e\n$stack');
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  Widget _buildBodyWithData() {
    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 0);

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
          actions: _buildAppBarActions()),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
        sliver: SliverList(
            delegate: SliverChildListDelegate([
          Padding(padding: const EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0, bottom: 8.0), child: _buildTitle()),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: metaChildren),
          if (_canSaveEditing) ...[
            const SizedBox(height: 8),
            _buildUnsavedChangesBanner(theme, colorScheme),
          ],
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

  Widget _buildUnsavedChangesBanner(ThemeData theme, ColorScheme colorScheme) {
    return Material(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: colorScheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You have unsaved changes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: _updateClick,
              child: Text(
                'Save',
                style: TextStyle(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
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
        onTap: (_eventContext.isUserAuthor(_currentUID) || _eventContext.isUserContributor(_currentUID))
            ? _onTitleTap
            : null,
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
      return FutureBuilder<Uint8List?>(
        future: _fetchImage(keyGraphicSrc),
        builder: (_, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          } else if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong trying to get the image'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return null;
  }

  Widget _buildTabBody() {
    return TabBarView(controller: _tabController, children: _bodyTabs);
  }

  List<Widget>? _buildAppBarActions() {
    final bool canEdit =
        _eventContext.isUserAuthor(_currentUID) || _eventContext.isUserContributor(_currentUID);
    if (!canEdit) return null;

    final colorScheme = Theme.of(context).colorScheme;
    final actions = <Widget>[];

    if (_canSaveEditing) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: FilledButton.tonalIcon(
            onPressed: _updateClick,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
            ),
          ),
        ),
      );
    }

    actions.addAll([
      FilledButton.tonalIcon(
        onPressed: _showSettings,
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Edit'),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.8),
          foregroundColor: colorScheme.onPrimaryContainer,
        ),
      ),
      const SizedBox(width: 8),
    ]);
    return actions;
  }

  // * Logic
  Future<Uint8List> _fetchImage(final String src) async {
    final localDataManager = LocalDataManager();
    final sanitisedKey = src.replaceAll(RegExp(r'[^\w]'), '');

    // Check if image exists in cache
    final cachedImage = await localDataManager.readMediaImage(sanitisedKey);
    if (cachedImage != null && cachedImage.isNotEmpty) {
      debugPrint('Using cached key graphic for: $sanitisedKey');
      return cachedImage;
    }

    // Download and cache the image
    debugPrint('Downloading key graphic for: $sanitisedKey');
    try {
      final imageUrl = NetworkImageHelper.getImageUrl(src);
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {'Accept': 'image/*'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Image download timed out after 30 seconds');
        },
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to download image: HTTP ${response.statusCode}');
      }

      final imageBytes = response.bodyBytes;

      if (imageBytes.isEmpty) {
        throw Exception('Downloaded image is empty');
      }

      // Cache the image
      await localDataManager.writeMediaImage(sanitisedKey, imageBytes);
      debugPrint('Cached key graphic for: $sanitisedKey');

      return imageBytes;
    } catch (e) {
      debugPrint('Error downloading key graphic: $e');
      // Clean up partial cache if it exists
      await localDataManager.deleteMediaImage(sanitisedKey);
      rethrow;
    }
  }

  Future<void> _fetchEssentialPostData() async {
    final EventSupplementalDBManager dbManager = EventSupplementalDBManager(widget.eventHead.id);
    const total = _remoteFetchStepCount;

    _updateLoadProgress(completed: 0, total: total, message: 'Loading media…');
    final media = await dbManager.fetchMedia();

    _updateLoadProgress(completed: 1, total: total, message: 'Loading details…');
    final meta = await dbManager.fetchMetadata();

    _updateLoadProgress(completed: 2, total: total, message: 'Loading schedule…');
    final program = await dbManager.fetchProgram();

    _updateLoadProgress(completed: 3, total: total, message: 'Loading activity log…');
    final logs = await dbManager.fetchLog();

    _updateLoadProgress(completed: 4, total: total, message: 'Loading post content…');
    final body = await dbManager.fetchBody();

    _updateLoadProgress(completed: 5, total: total, message: 'Finishing…');

    _eventContext = EventContext.viewing(eventHead: widget.eventHead, currentUID: _currentUID);
    _eventContext.setFetchedMedia(media);
    _eventContext.setFetchedMetadata(meta);
    _eventContext.setFetchedProgram(program);
    _eventContext.setFetchedLogs(logs);
    _eventContext.setFetchedBody(body);
  }

  void _figureOutTabs() {
    final bool isAuthor = _eventContext.metadata.authorUID.compareTo(_currentUID) == 0;
    final bool isContributor = _eventContext.metadata.contributorUIDs.contains(_currentUID);
    final bool isLeader = Provider.of<AppContext>(context, listen: false).currentUser.isLeader;

    _bodyTabs.clear();
    _appBarTabs
      ..clear()
      ..add(const Tab(icon: Icon(Icons.info_outline), text: 'About'));

    int length = 0;
    _aboutTabIndex = length;
    _bodyTabs.add(ViewPostBody(
      eventContext: _eventContext,
      updateBody: _updateWholePostBody,
      currentUID: _currentUID,
    ));
    length++;

    _peopleTabIndex = length;
    _bodyTabs.add(ViewAttendanceTab(
      eventContext: _eventContext,
      onChanged: _updateWholePostBody,
    ));
    _appBarTabs.add(const Tab(icon: Icon(Icons.groups_outlined), text: 'People'));
    length++;

    if (_eventContext.head.eventDate != null || isAuthor) {
      _bodyTabs.add(ViewAllPrograms(
          eventContext: _eventContext,
          onProgramChanged: _updateWholePostBody));
      _appBarTabs.add(const Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'));
      length++;
    }

    _mediaTabIndex = null;
    if (_eventContext.media.allMedia.isNotEmpty || isAuthor || isContributor) {
      _mediaTabIndex = length;
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
    final webAuthId = kIsWeb ? AuthManager().currentAuthUID : null;
    setState(() {
      if (bookmarked) {
        appContext.sharedPref.removePostBookmark(_eventContext.id);
        _messagingManager.unsubscribeFromTopic(_topic, authId: webAuthId);
      } else {
        appContext.sharedPref.addPostBookmark(_eventContext.id);
        _messagingManager.subscribeToTopic(_topic, authId: webAuthId);
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
    final appContext = Provider.of<AppContext>(context, listen: false);
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      builder: (_) => PostEditSheet(
        isLeader: appContext.currentUser.isLeader,
        hasParent: _eventContext.metadata.hasParent,
        onEditAbout: _onEditBodyClick,
        onEditTitle: _onEditTitleFromSheet,
        onAddSchedule: _onAddScheduleItem,
        onEditMedia: _onEditMediaClick,
        onManageContributors: _onManageContributorsFromSheet,
        onManageLeadSpeaker: _onManageLeadSpeakerFromSheet,
        onOpenPeopleTab: _onOpenPeopleTabFromSheet,
        onCreateSibling: () => _onAddPost(_eventContext.metadata.parentID!),
        onCreateChild: () => _onAddPost(_eventContext.id),
        onBulkCreate: _onBulkCreateRelatedPosts,
        onNotifyBroadcast: _notifyBroadcastClick,
        onNotifyScheduled: _notifyScheduledMembersClick,
      ),
    );
  }

  void _onEditTitleFromSheet() {
    Navigator.of(context).pop();
    _onTitleTap();
  }

  void _onManageContributorsFromSheet() {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewMetaLogsPage(eventContext: _eventContext)),
    ).then((_) => setState(() {}));
  }

  Future<void> _onManageLeadSpeakerFromSheet() async {
    Navigator.of(context).pop();
    final appContext = Provider.of<AppContext>(context, listen: false);
    final currentUid = _eventContext.metadata.leadSpeakerUID ?? _eventContext.head.leadSpeakerUID;
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: currentUid == null ? <String>[] : [currentUid],
          includeCurrentUser: true,
          maxSelection: 1,
          title: 'Select lead speaker',
        ),
      ),
    );
    if (result == null || !mounted) return;

    if (result.isEmpty) {
      _eventContext.applyLeadSpeaker(uid: null);
    } else {
      final user = appContext.getUserFromID(result.first);
      _eventContext.applyLeadSpeaker(uid: user.id, imgSrc: user.imgSrc, name: user.fullname);
    }
    _eventContext.allowSavingOfTheEdit();
    setState(() {});
  }

  void _onOpenPeopleTabFromSheet() {
    Navigator.of(context).pop();
    _tabController.animateTo(_peopleTabIndex);
  }

  void _onEditBodyClick() {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditBodyPage(eventContext: _eventContext))).then((_) {
      setState(() {});
      _tabController.animateTo(_aboutTabIndex);
    });
  }

  void _onAddScheduleItem() {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventProgramPage(eventContext: _eventContext)))
        .then((_) {
      setState(() {});
      _eventContext.program.orderProgramsByStartTime();
    });
  }

  void _onEditMediaClick() {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditGalleryPage(eventContext: _eventContext))).then((_) {
      setState(() {});
      final mediaIndex = _mediaTabIndex;
      if (mediaIndex != null) {
        _tabController.animateTo(mediaIndex);
      } else {
        _tabController.animateTo(_aboutTabIndex);
      }
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

  void _syncChildrenMetadataFromAppContext() {
    final cached = Provider.of<AppContext>(context, listen: false).getMetadata(_eventContext.id);
    if (cached == null) return;
    for (final childId in cached.childrenPostIDs) {
      if (!_eventContext.metadata.childrenPostIDs.contains(childId)) {
        _eventContext.metadata.childrenPostIDs.add(childId);
      }
    }
  }

  void _onBulkCreateRelatedPosts() {
    Navigator.of(context).pop();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SelectPostTemplatePage(
                eventContext: EventContext.adding(
                    currentUserID: Provider.of<AppContext>(context, listen: false).currentUser.id,
                    parentID: _eventContext.id),
                bulkMode: true,
                sourcePostId: _eventContext.id,
                sourcePostParentId: _eventContext.metadata.parentID,
                sourcePostEventDate: _eventContext.head.eventDate))).then((_) {
      _syncChildrenMetadataFromAppContext();
      setState(() {});
    });
  }

  String get _topic => NotificationTopics.postTopic(_eventContext.id);

  Future<List<String>> _attemptToGetExistingPostData() async {
    final LocalDataManager localDataManager = LocalDataManager();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final List<String> content = await localDataManager.readPostData(widget.eventHead.id);

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
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String content = _eventContext.transformPostToTxtFile(packageInfo.version);

    await localDataManager.writePostData(_eventContext.id, content);
    final postTrack = await localDataManager.readPostTrack();
    if (!postTrack.contains(_eventContext.id)) {
      postTrack.add(_eventContext.id);
      await localDataManager.writePostTrack(postTrack);
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
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendBroadcastNotificationPage(eventContext: _eventContext),
      ),
    );
  }

  void _notifyScheduledMembersClick() {
    Navigator.of(context).pop();
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
    try {
      final AppContext appContext = Provider.of<AppContext>(context, listen: false);
      final CloudFunctionManager cloudFunctionManager = CloudFunctionManager();
      final NotificationTokenResolver tokenResolver = NotificationTokenResolver();
      final DateFormat dateFormat = DateFormat('EEE, MMM d'), timeFormat = DateFormat('HH:mm');

      final String currentUID = appContext.currentUser.id;
      final String title = "📣 Reminder of your task - ${dateFormat.format(_eventContext.head.eventDate!)}!";

      var combined = const NotificationSendResult();
      var usersWithoutTokens = 0;

      for (final roleEntry in _eventContext.program.roles) {
        try {
          final DateTime? startingTime = roleEntry['start'];
          if (startingTime == null) {
            debugPrint('Warning: Role entry missing start time, skipping...');
            continue;
          }

          final String roleTitle = roleEntry['title'] ?? 'Untitled Role';
          final String body =
              "'$roleTitle' for ${_eventContext.head.title}.\nStarting ${timeFormat.format(startingTime)}";
          final List<String> tokens = [];
          final List<dynamic> uidsRaw = roleEntry['uids'] ?? [];
          final List<String> uids = uidsRaw.whereType<String>().toList();

          for (final thisUID in uids) {
            if (thisUID != currentUID) {
              try {
                if (!appContext.haveTokensForUserID(thisUID)) {
                  final String authID = appContext.getAuthIDFromUID(thisUID);
                  if (authID.isNotEmpty) {
                    final List<String> fetchedTokens = await tokenResolver.resolveForAuthID(authID);
                    if (fetchedTokens.isNotEmpty) {
                      appContext.addTokensToUserID(thisUID, fetchedTokens);
                      tokens.addAll(fetchedTokens);
                    } else {
                      usersWithoutTokens++;
                    }
                  } else {
                    debugPrint('Warning: Could not get authID for user $thisUID, skipping...');
                    usersWithoutTokens++;
                  }
                } else {
                  tokens.addAll(appContext.getTokensFromUserID(thisUID));
                }
              } catch (e) {
                debugPrint('Error fetching tokens for user $thisUID: $e');
                usersWithoutTokens++;
                continue;
              }
            }
          }

          if (tokens.isNotEmpty) {
            try {
              final result = await cloudFunctionManager.sendMessageToSelectedTokens(
                tokens: tokens,
                title: title,
                body: body,
                data: {'PostID': _eventContext.id},
              );
              combined = combined.merge(result);
            } catch (e) {
              debugPrint('Error sending notification for role "$roleTitle": $e');
              combined = combined.merge(const NotificationSendResult(failureCount: 1));
            }
          }
        } catch (e) {
          debugPrint('Error processing role entry: $e');
          combined = combined.merge(const NotificationSendResult(failureCount: 1));
          continue;
        }
      }

      if (mounted) {
        var message = combined.feedbackMessage;
        if (usersWithoutTokens > 0) {
          message =
              '$message · $usersWithoutTokens member${usersWithoutTokens == 1 ? '' : 's'} had no device';
        }
        DialogManager.showSnackBar(
          context: context,
          message: message,
          isError: combined.hasFailures && !combined.hasSuccess,
        );
      }
    } catch (e) {
      debugPrint('Critical error in _sendRoleNotifications: $e');
      if (mounted) {
        DialogManager.showSnackBar(
          context: context,
          message: 'Failed to send notifications: $e',
          isError: true,
        );
      }
    }
  }
}
