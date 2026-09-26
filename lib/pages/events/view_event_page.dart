import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../firebase/auth_manager.dart';
import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/messaging_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/post_template.dart';
import '../../utility/app_context.dart';
import '../../utility/dialog_manager.dart';
import '../../utility/event_context.dart';
import '../../utility/notifications/notification_topics.dart';
import '../../utility/placeholder_user_permissions.dart';
import '../../utility/post_template_mapper.dart';
import '../../widgets/media/cached_image_widget.dart';
import '../../widgets/posts/event_log_dialog.dart';
import '../../widgets/posts/post_edit_sheet.dart';
import '../../widgets/posts/post_metadata_section.dart';
import '../../widgets/posts/view_attendance_tab.dart';
import '../../widgets/posts/view_event_media_tab.dart';
import '../../widgets/posts/view_post_body.dart';
import '../../widgets/posts/view_all_programs.dart';
import '../../widgets/posts/view_related_posts_tab.dart';
import 'arrange_schedule_page.dart';
import 'edit_program_role_page.dart';
import 'edit_body_page.dart';
import 'edit_gallery_page.dart';
import 'edit_title_subtitle_page.dart';
import 'post_templates/select_post_template_page.dart';
import 'select_template_cover_page.dart';
import 'select_schedule_preset_page.dart';
import 'send_broadcast_notification_page.dart';
import 'view_meta_logs_page.dart';
import '../personal/select_users_page.dart';
import '../../utility/responsive_layout.dart';
import 'view_event_local_store.dart';
import 'view_event_notify_helpers.dart';

class ViewEventPage extends StatefulWidget {
  const ViewEventPage({super.key, required this.eventHead});
  final EventHead eventHead;

  @override
  State<ViewEventPage> createState() => _ViewEventPageState();
}

class _ViewEventPageState extends State<ViewEventPage>
    with SingleTickerProviderStateMixin {
  static final MessagingManager _messagingManager = MessagingManager();

  late final TabController _tabController;
  late final EventContext _eventContext;
  late List<Map<String, dynamic>> _originalHeadMedia;
  late String _originalTitle, _originalSubtitle;
  late final String _currentUID;
  late DateTime? _originalEventDate;
  late String? _originalLeadSpeakerUID,
      _originalLeadSpeakerImgSrc,
      _originalLeadSpeakerName;
  late int _originalAttendeeCount;

  final List<Widget> _appBarTabs = [
    const Tab(icon: Icon(Icons.info_outline), text: 'About'),
  ];

  bool _haveFetchedPost = false;

  /// NestedScrollView lays its header out too late for the push flight.
  /// Keep a plain scroll view until that animation has finished.
  bool _openFlightDone = false;
  Animation<double>? _routeAnimation;
  bool _allowPop = false;
  bool _showScheduleTab = false;
  bool _showMediaTab = false;
  bool _showRelatedTab = false;
  Object? _loadError;
  String _loadStatusMessage = 'Checking saved copy…';
  int _loadCompletedSteps = 0;
  int _loadTotalSteps = 1;

  int _aboutTabIndex = 0;
  int _peopleTabIndex = 1;
  int? _scheduleTabIndex;
  int? _mediaTabIndex;

  static const int _remoteFetchStepCount = 5;

  void _popRouteAfterAllowing() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void initState() {
    Provider.of<AppContext>(context, listen: false)
        .analytics
        .logScreenView(screenName: 'post-${widget.eventHead.id}');
    _currentUID =
        Provider.of<AppContext>(context, listen: false).currentUser.id;

    _captureOriginalHeadState();

    super.initState();
    _loadPost();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (identical(animation, _routeAnimation)) return;
    _routeAnimation?.removeStatusListener(_onRouteAnimation);
    _routeAnimation = animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      _openFlightDone = true;
      return;
    }
    animation.addStatusListener(_onRouteAnimation);
  }

  void _onRouteAnimation(AnimationStatus status) {
    if (status != AnimationStatus.completed || _openFlightDone || !mounted) {
      return;
    }
    setState(() => _openFlightDone = true);
  }

  /// Deep-copies current head fields so discard-on-exit can restore last saved state.
  void _captureOriginalHeadState() {
    _originalHeadMedia = widget.eventHead.media
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _originalTitle = widget.eventHead.title;
    _originalSubtitle = widget.eventHead.subtitle;
    _originalEventDate = widget.eventHead.eventDate;
    _originalLeadSpeakerUID = widget.eventHead.leadSpeakerUID;
    _originalLeadSpeakerImgSrc = widget.eventHead.leadSpeakerImgSrc;
    _originalLeadSpeakerName = widget.eventHead.leadSpeakerName;
    _originalAttendeeCount = widget.eventHead.attendeeCount;
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimation);
    if (_haveFetchedPost) {
      _tabController.dispose();
    }

    // Discard unsaved in-memory edits on the shared AppContext head when leaving.
    // After a successful save, [_captureOriginalHeadState] is refreshed so this
    // reverts to the last saved Media/title — not the values from page open.
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
      widget.eventHead.setAttendeeCount(_originalAttendeeCount);
      if (_haveFetchedPost) {
        if (_originalLeadSpeakerUID == null ||
            _originalLeadSpeakerUID!.isEmpty) {
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
    return PopScope(
      canPop: _allowPop || !_canSaveEditing,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _allowPop || !_canSaveEditing) return;
        final shouldPop = await DialogManager.discardChanges(context: context);
        if (shouldPop && mounted) {
          _popRouteAfterAllowing();
        }
      },
      child: Scaffold(
        // A key graphic is already on the head. Paint it on the first frame so
        // the bulletin cover has a destination for the open hero flight.
        // Waiting for the supplemental fetch only leaves a hero on the way out.
        appBar: _showCoverShell
            ? null
            : AppBar(
                title: Text(
                  widget.eventHead.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        body:
            _showCoverShell ? _buildBodyWithData() : _buildLoadingOrErrorBody(),
      ),
    );
  }

  /// Cover shell while the body is still loading, and the full page after.
  bool get _showCoverShell =>
      _haveFetchedPost || widget.eventHead.getKeyGraphic() != null;

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
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
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

    final double? progress = _loadTotalSteps > 0
        ? (_loadCompletedSteps / _loadTotalSteps).clamp(0.0, 1.0)
        : null;

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
      _updateLoadProgress(
          completed: 0, total: 1, message: 'Checking saved copy…');
      final List<String> data = await readCachedPostDataIfCurrent(
        postId: widget.eventHead.id,
        recentDate: widget.eventHead.recentDate,
      );
      if (!mounted) return;

      if (data.isNotEmpty) {
        debugPrint('Using existing post data for ID: ${widget.eventHead.id}');
        _eventContext = EventContext.viewing(
            eventHead: widget.eventHead, data: data, currentUID: _currentUID);
        _figureOutTabs();
        Provider.of<AppContext>(context, listen: false)
            .setMetadata(_eventContext.id, _eventContext.metadata);
        _checkToUnbookForContributor();
        setState(() => _haveFetchedPost = true);
        return;
      }

      debugPrint('Fetching from DB for post ID: ${widget.eventHead.id}');
      await _fetchEssentialPostData();
      if (!mounted) return;

      Provider.of<AppContext>(context, listen: false)
          .setMetadata(_eventContext.id, _eventContext.metadata);
      _figureOutTabs();
      writeCachedPostData(_eventContext, trackPost: true);
      _checkToUnbookForContributor();
      setState(() => _haveFetchedPost = true);
    } catch (e, stack) {
      debugPrint('Something went wrong loading the post: $e\n$stack');
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  Widget _buildBodyWithData() {
    final double webHorizontalPadding = ResponsiveLayout.horizontalGutter(
        MediaQuery.sizeOf(context).width,
        narrowPadding: 0);

    if (!_openFlightDone) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ..._buildHeaderSliver(webHorizontalPadding),
          if (!_haveFetchedPost)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildLoadingOrErrorBody(),
            ),
        ],
      );
    }

    return NestedScrollView(
        clipBehavior: Clip.none,
        headerSliverBuilder: (_, __) {
          return _buildHeaderSliver(webHorizontalPadding);
        },
        body: _haveFetchedPost
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
                child: _buildTabBody(),
              )
            : CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildLoadingOrErrorBody(),
                  ),
                ],
              ));
  }

  List<Widget> _buildHeaderSliver(final double webHorizontalPadding) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final String? keyGraphic = widget.eventHead.getKeyGraphic();
    final header = <Widget>[
      SliverAppBar(
          key: ValueKey('post_cover_bar_${widget.eventHead.id}'),
          expandedHeight: keyGraphic != null
              ? MediaQuery.of(context).size.height * 0.33
              : null,
          flexibleSpace: FlexibleSpaceBar(background: _buildAppBarBackground()),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          actions: _haveFetchedPost ? _buildAppBarActions() : null),
    ];
    if (!_haveFetchedPost) {
      header.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
              child: Text(
                widget.eventHead.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
      return header;
    }

    final List<Widget> metaChildren = [
      PostMetadataSection(
          eventContext: _eventContext, update: _updateWholePostBody)
    ];

    if (!_eventContext.isUserAuthor(_currentUID) &&
        !_eventContext.isUserContributor(_currentUID)) {
      metaChildren.insert(0, _buildBookmarkButton());
    }

    header.add(
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
        sliver: SliverList(
            delegate: SliverChildListDelegate([
          Padding(
              padding: const EdgeInsets.only(
                  top: 16.0, left: 8.0, right: 8.0, bottom: 8.0),
              child: _buildTitle()),
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: metaChildren),
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
      ),
    );
    return header;
  }

  Widget _buildUnsavedChangesBanner(ThemeData theme, ColorScheme colorScheme) {
    return Material(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 20, color: colorScheme.onTertiaryContainer),
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
                style: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkButton() {
    final appContext = Provider.of<AppContext>(context, listen: false);
    final bool bookmarked =
        appContext.sharedPref.bookmarkedPosts.contains(_eventContext.id);
    return IconButton.filled(
        onPressed: () => _bookmarkClick(appContext, bookmarked),
        icon: bookmarked
            ? const Icon(Icons.bookmark)
            : const Icon(Icons.bookmark_border));
  }

  Widget _buildTitle() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
        onTap: (_eventContext.isUserAuthor(_currentUID) ||
                _eventContext.isUserContributor(_currentUID))
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
    final String? keyGraphicSrc = widget.eventHead.getKeyGraphic();
    if (keyGraphicSrc == null) return null;

    return CachedImageWidget(
      key: ValueKey('post_cover_${widget.eventHead.id}'),
      imageUrl: keyGraphicSrc,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      heroTag: 'post_cover_${widget.eventHead.id}',
    );
  }

  Widget _buildTabBody() {
    // Build children each rebuild so edits (e.g. About body) aren't stuck on
    // cached Widget instances that Flutter would short-circuit.
    return TabBarView(
        controller: _tabController, children: _buildBodyTabChildren());
  }

  List<Widget> _buildBodyTabChildren() {
    final tabs = <Widget>[
      ViewPostBody(
        key: ValueKey(_eventContext.encodedBody),
        eventContext: _eventContext,
        updateBody: _updateWholePostBody,
        currentUID: _currentUID,
      ),
      ViewAttendanceTab(
        eventContext: _eventContext,
        onChanged: _updateWholePostBody,
      ),
    ];
    if (_showScheduleTab) {
      tabs.add(ViewAllPrograms(
        key: ValueKey(_eventContext.program.scheduleLayoutSignature),
        eventContext: _eventContext,
        onProgramChanged: _updateWholePostBody,
      ));
    }
    if (_showMediaTab) {
      tabs.add(ViewEventMediaTab(
          eventContext: _eventContext, currentUID: _currentUID));
    }
    if (_showRelatedTab) {
      tabs.add(ViewRelatedPostsTab(eventContext: _eventContext));
    }
    return tabs;
  }

  List<Widget>? _buildAppBarActions() {
    final bool canEdit = _eventContext.isUserAuthor(_currentUID) ||
        _eventContext.isUserContributor(_currentUID);
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

  Future<void> _fetchEssentialPostData() async {
    final EventSupplementalDBManager dbManager =
        EventSupplementalDBManager(widget.eventHead.id);
    const total = _remoteFetchStepCount;

    _updateLoadProgress(completed: 0, total: total, message: 'Loading media…');
    final media = await dbManager.fetchMedia();

    _updateLoadProgress(
        completed: 1, total: total, message: 'Loading details…');
    final meta = await dbManager.fetchMetadata();

    _updateLoadProgress(
        completed: 2, total: total, message: 'Loading schedule…');
    final program = await dbManager.fetchProgram();

    _updateLoadProgress(
        completed: 3, total: total, message: 'Loading activity log…');
    final logs = await dbManager.fetchLog();

    _updateLoadProgress(
        completed: 4, total: total, message: 'Loading post content…');
    final body = await dbManager.fetchBody();

    _updateLoadProgress(completed: 5, total: total, message: 'Finishing…');

    _eventContext = EventContext.viewing(
        eventHead: widget.eventHead, currentUID: _currentUID);
    _eventContext.setFetchedMedia(media);
    _eventContext.setFetchedMetadata(meta);
    _eventContext.setFetchedProgram(program);
    _eventContext.setFetchedLogs(logs);
    _eventContext.setFetchedBody(body);
  }

  void _figureOutTabs() {
    final bool isAuthor =
        _eventContext.metadata.authorUID.compareTo(_currentUID) == 0;
    final bool isContributor =
        _eventContext.metadata.contributorUIDs.contains(_currentUID);
    final bool isLeader =
        Provider.of<AppContext>(context, listen: false).currentUser.isLeader;

    _showScheduleTab = _eventContext.head.eventDate != null || isAuthor;
    _showMediaTab =
        _eventContext.media.allMedia.isNotEmpty || isAuthor || isContributor;
    _showRelatedTab = _eventContext.metadata.hasChildren ||
        _eventContext.metadata.hasParent ||
        isLeader;

    _appBarTabs
      ..clear()
      ..add(const Tab(icon: Icon(Icons.info_outline), text: 'About'));

    int length = 0;
    _aboutTabIndex = length;
    length++;

    _peopleTabIndex = length;
    _appBarTabs
        .add(const Tab(icon: Icon(Icons.groups_outlined), text: 'People'));
    length++;

    _scheduleTabIndex = null;
    if (_showScheduleTab) {
      _scheduleTabIndex = length;
      _appBarTabs
          .add(const Tab(icon: Icon(Icons.calendar_today), text: 'Schedule'));
      length++;
    }

    _mediaTabIndex = null;
    if (_showMediaTab) {
      _mediaTabIndex = length;
      _appBarTabs.add(const Tab(icon: Icon(Icons.photo_album), text: 'Media'));
      length++;
    }
    if (_showRelatedTab) {
      _appBarTabs
          .add(const Tab(icon: Icon(Icons.library_books), text: 'Related'));
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
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                EditHeadDetailsPage(eventContext: _eventContext))).then((_) {
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
              // Baseline for discard-on-exit must match what was just written to Firebase.
              _captureOriginalHeadState();
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
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      builder: (_) => PostEditSheet(
        isLeader: appContext.currentUser.isLeader,
        hasParent: _eventContext.metadata.hasParent,
        onEditAbout: _onEditBodyClick,
        onEditTitle: _onEditTitleFromSheet,
        onAddSchedule: _onAddScheduleItem,
        onArrangeSchedule: _onArrangeSchedule,
        onApplySchedulePreset: _onApplySchedulePresetFromSheet,
        onEditMedia: _onEditMediaClick,
        onChangeCover: _onChangeCoverFromSheet,
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
      MaterialPageRoute(
          builder: (_) => ViewMetaLogsPage(eventContext: _eventContext)),
    ).then((_) => setState(() {}));
  }

  Future<void> _onManageLeadSpeakerFromSheet() async {
    Navigator.of(context).pop();
    final appContext = Provider.of<AppContext>(context, listen: false);
    final currentUid = _eventContext.metadata.leadSpeakerUID ??
        _eventContext.head.leadSpeakerUID;
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersPage(
          selectedUIDs: currentUid == null ? <String>[] : [currentUid],
          includeCurrentUser: true,
          maxSelection: 1,
          title: 'Select lead speaker',
          preferServing: true,
          allowCreatePlaceholder: canCreatePlaceholderUser(
            actor: appContext.currentUser,
            postAuthorUid: _eventContext.metadata.authorUID,
          ),
          postIdForPlaceholderCreate: _eventContext.id,
        ),
      ),
    );
    if (result == null || !mounted) return;

    if (result.isEmpty) {
      _eventContext.applyLeadSpeaker(uid: null);
    } else {
      final user = appContext.userById(result.first);
      if (user != null) {
        _eventContext.applyLeadSpeaker(
            uid: user.id, imgSrc: user.imgSrc, name: user.fullname);
      }
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
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EditBodyPage(eventContext: _eventContext)))
        .then((_) {
      setState(() {});
      _tabController.animateTo(_aboutTabIndex);
    });
  }

  void _onAddScheduleItem() {
    Navigator.of(context).pop();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AddEventProgramPage(eventContext: _eventContext))).then((_) {
      setState(() {});
      _eventContext.program.orderProgramsByStartTime();
    });
  }

  void _onArrangeSchedule() {
    Navigator.of(context).pop();
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ArrangeSchedulePage(eventContext: _eventContext),
      ),
    ).then((changed) {
      if (!mounted) return;
      setState(() {});
      final scheduleIndex = _scheduleTabIndex;
      if (scheduleIndex != null) _tabController.animateTo(scheduleIndex);
    });
  }

  Future<void> _onApplySchedulePresetFromSheet() async {
    Navigator.of(context).pop();
    final selected =
        await Navigator.push<({PostTemplate template, SchedulePreset preset})>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectSchedulePresetPage(
          preferredTitle: _eventContext.head.title,
          preferredLocation: _eventContext.head.location,
        ),
      ),
    );
    if (!mounted || selected == null) return;

    final templateTitle = selected.template.title;
    final presetName = selected.preset.name;
    final confirm = await DialogManager.showConfirmationDialog(
      context: context,
      title: 'Replace the running order?',
      content:
          'This replaces the current schedule with “$presetName” from “$templateTitle”. '
          'Start and finish times update. Attendance and expected people stay. '
          'Save the post to keep the change.',
      confirmText: 'Replace',
      icon: Icons.view_timeline_outlined,
    );
    if (!confirm || !mounted) return;

    PostTemplateMapper.applySchedulePreset(
      _eventContext,
      selected.preset,
      eventDate: _eventContext.head.eventDate,
      trackRoleDiff: true,
      applyEventWindow: _eventContext.head.eventDate != null,
    );
    _eventContext.allowSavingOfTheEdit();
    setState(() {});
    final scheduleIndex = _scheduleTabIndex;
    if (scheduleIndex != null) _tabController.animateTo(scheduleIndex);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Schedule updated to “$presetName” — save the post to keep the change'),
      ),
    );
  }

  void _onEditMediaClick() {
    Navigator.of(context).pop();
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EditGalleryPage(eventContext: _eventContext)))
        .then((_) {
      setState(() {});
      final mediaIndex = _mediaTabIndex;
      if (mediaIndex != null) {
        _tabController.animateTo(mediaIndex);
      } else {
        _tabController.animateTo(_aboutTabIndex);
      }
    });
  }

  Future<void> _onChangeCoverFromSheet() async {
    Navigator.of(context).pop();
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectTemplateCoverPage(
          preferredTitle: _eventContext.head.title,
          preferredLocation: _eventContext.head.location,
        ),
      ),
    );
    if (!mounted || selected == null) return;

    setState(() {
      _eventContext.head.replaceKeyGraphic(
        type: selected['type'] ?? 'img',
        src: selected['src'] ?? '',
        title: selected['title'] ?? '',
        thumbnail: selected['thumbnailSrc'] ?? '',
      );
      _eventContext.allowSavingOfTheEdit();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Cover updated — save the post to keep the change')),
    );
  }

  void _onAddPost(final String parentID) {
    Navigator.of(context).pop();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SelectPostTemplatePage(
                eventContext: EventContext.adding(
                    currentUserID:
                        Provider.of<AppContext>(context, listen: false)
                            .currentUser
                            .id,
                    parentID: parentID)))).then((_) {
      setState(() {
        // rebuild? - will this update when creating sibling posts?
      });
    });
  }

  void _syncChildrenMetadataFromAppContext() {
    final cached = Provider.of<AppContext>(context, listen: false)
        .getMetadata(_eventContext.id);
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
                    currentUserID:
                        Provider.of<AppContext>(context, listen: false)
                            .currentUser
                            .id,
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

  bool get _canSaveEditing =>
      _haveFetchedPost && _eventContext.canSaveTheEditing;

  void _checkToUnbookForContributor() {
    if (_eventContext.metadata.contributorUIDs.contains(_currentUID)) {
      debugPrint(
          'removing post from bookmarks because user is already contributor!');
      Provider.of<AppContext>(context, listen: false)
          .sharedPref
          .removePostBookmark(_eventContext.id);
    }
  }

  void _notifyBroadcastClick() {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SendBroadcastNotificationPage(eventContext: _eventContext),
      ),
    );
  }

  void _notifyScheduledMembersClick() {
    Navigator.of(context).pop();
    DialogManager.showConfirmationDialog(
            context: context,
            title: 'Notify Scheduled Members',
            content:
                'This action will send a push notification to people of the schedule. Do you wish to continue?')
        .then((confirmation) {
      if (confirmation) {
        _sendRoleNotifications();
      }
    });
  }

  Future<void> _sendRoleNotifications() async {
    try {
      final result = await sendScheduledMemberRoleNotifications(
        appContext: Provider.of<AppContext>(context, listen: false),
        eventContext: _eventContext,
      );
      if (mounted) {
        DialogManager.showSnackBar(
          context: context,
          message: result.feedbackMessage,
          isError: result.combined.hasFailures && !result.combined.hasSuccess,
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
