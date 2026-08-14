import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/refresh_cooldown.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_schedule_service.dart';
import '../../widgets/load_progress_body.dart';
import '../../widgets/posts/post_head.dart';
import '../events/view_event_page.dart';

class ViewUserRolesPage extends StatefulWidget {
  const ViewUserRolesPage({
    super.key,
    required this.selectedUser,
    this.allowPostView = false,
    this.initialTab = 0,
  });
  final User selectedUser;
  final bool allowPostView;
  final int initialTab;

  @override
  State<ViewUserRolesPage> createState() => _ViewUserRolesPageState();
}

class _ViewUserRolesPageState extends State<ViewUserRolesPage> {
  late final AppContext _appContext;
  final UserScheduleService _scheduleService = UserScheduleService();
  final EventHeadDBManager _eventHeadDBManager = EventHeadDBManager();
  final Map<String, Future<EventHead>> _headFutures = {};
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  bool _loadingRoles = false;
  Object? _rolesError;
  String _rolesStatusMessage = 'Loading schedule…';
  int _rolesCompletedSteps = 0;
  int _rolesTotalSteps = 2;

  bool _loadingPosts = false;
  Object? _postsError;
  String _postsStatusMessage = 'Loading posts…';
  int _postsCompletedSteps = 0;
  int _postsTotalSteps = 2;

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();

    if (widget.selectedUser.roles == null) {
      _loadingRoles = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadRoles();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runRoleCleanup(showSnackBar: true));
    }

    if (widget.allowPostView && widget.selectedUser.posts == null) {
      _loadingPosts = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPosts();
      });
    }
  }

  Future<void> _loadRoles() async {
    setState(() {
      _loadingRoles = true;
      _rolesError = null;
      _rolesStatusMessage = 'Fetching assignments…';
      _rolesCompletedSteps = 0;
      _rolesTotalSteps = 2;
    });

    try {
      final roles = await _scheduleService.fetchRoles(widget.selectedUser.id);
      if (!mounted) return;

      setState(() {
        _rolesCompletedSteps = 1;
        _rolesStatusMessage = 'Cleaning up schedule…';
      });

      widget.selectedUser.setRoles(roles);
      await _scheduleService.pruneStaleRoles(
        user: widget.selectedUser,
        eventHeads: _appContext.eventHeads,
      );
      if (!mounted) return;

      setState(() {
        _loadingRoles = false;
        _rolesCompletedSteps = 2;
        _rolesStatusMessage = 'Done';
      });
    } catch (e, st) {
      debugPrint('Error fetching roles: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadingRoles = false;
        _rolesError = e;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loadingPosts = true;
      _postsError = null;
      _postsStatusMessage = 'Fetching posts…';
      _postsCompletedSteps = 0;
      _postsTotalSteps = 2;
    });

    try {
      final posts = await _scheduleService.fetchPosts(widget.selectedUser.id);
      if (!mounted) return;

      setState(() {
        _postsCompletedSteps = 1;
        _postsStatusMessage = 'Cleaning up posts…';
      });

      widget.selectedUser.setPosts(posts);
      await _scheduleService.pruneStalePostInvolvements(
        user: widget.selectedUser,
        eventHeads: _appContext.eventHeads,
      );
      if (!mounted) return;

      setState(() {
        _loadingPosts = false;
        _postsCompletedSteps = 2;
        _postsStatusMessage = 'Done';
      });
    } catch (e, st) {
      debugPrint('Error fetching posts: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadingPosts = false;
        _postsError = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allowPostView) {
      return DefaultTabController(
        length: 2,
        initialIndex: widget.initialTab.clamp(0, 1),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.selectedUser.fullname),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Schedule'),
                Tab(text: 'Posts'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildScheduleBody(),
              _buildPostsBody(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("${widget.selectedUser.forname}'s Schedule")),
      body: _buildScheduleBody(),
    );
  }

  Widget _buildScheduleBody() {
    if (_loadingRoles || _rolesError != null) {
      return LoadProgressBody(
        message: _rolesStatusMessage,
        completedSteps: _rolesCompletedSteps,
        totalSteps: _rolesTotalSteps,
        error: _rolesError,
        errorTitle: 'Could not load schedule',
        onRetry: _loadRoles,
      );
    }

    if (widget.selectedUser.roles == null) {
      return LoadProgressBody(
        message: 'Loading schedule…',
        completedSteps: 0,
        totalSteps: 1,
        onRetry: _loadRoles,
      );
    }

    return _buildScheduleBodyWithData();
  }

  Widget _buildScheduleBodyWithData() {
    final roles = widget.selectedUser.roles;
    if (roles == null || roles.isEmpty) {
      return _buildEmptySchedule();
    }

    final stalePostIDs = UserScheduleService.staleRolePostIDs(
      user: widget.selectedUser,
      eventHeads: _appContext.eventHeads,
    );
    if (stalePostIDs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runRoleCleanup(showSnackBar: false));
    }

    final upcomingPostIDs = UserScheduleService.upcomingSchedulePostIDs(
      user: widget.selectedUser,
      eventHeads: _appContext.eventHeads,
    );
    final recentPastPostIDs = UserScheduleService.recentPastSchedulePostIDs(
      user: widget.selectedUser,
      eventHeads: _appContext.eventHeads,
    );

    if (upcomingPostIDs.isEmpty && recentPastPostIDs.isEmpty) {
      return _buildEmptySchedule();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final isWideScreen = ResponsiveLayout.isWideScreen(contentWidth);
        final horizontalPadding = isWideScreen
            ? ((contentWidth - ResponsiveLayout.maxContentWidth(contentWidth)) / 2)
                .clamp(16.0, double.infinity)
            : 8.0;

        return RefreshIndicator(
          onRefresh: () async {
            await _refreshRoles();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refresh Complete!'), behavior: SnackBarBehavior.floating));
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 24),
            children: [
              if (upcomingPostIDs.isNotEmpty) ...[
                _buildSectionHeader('Upcoming'),
                const SizedBox(height: 8),
                for (var i = 0; i < upcomingPostIDs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _buildTile(upcomingPostIDs[i], isPast: false),
                ],
              ],
              if (recentPastPostIDs.isNotEmpty) ...[
                if (upcomingPostIDs.isNotEmpty) const SizedBox(height: 24),
                _buildSectionHeader('Recent'),
                const SizedBox(height: 4),
                Text(
                  'Last ${UserScheduleService.roleRetention.inDays} days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < recentPastPostIDs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _buildTile(recentPastPostIDs[i], isPast: true),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'No tasks assigned... for now! 😎',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        TextButton.icon(
          onPressed: () async {
            await _refreshRoles();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refresh Complete!'), behavior: SnackBarBehavior.floating));
          },
          label: const Text('Refresh'),
          icon: const Icon(Icons.refresh),
        )
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildPostsBody() {
    if (_loadingPosts || _postsError != null) {
      return LoadProgressBody(
        message: _postsStatusMessage,
        completedSteps: _postsCompletedSteps,
        totalSteps: _postsTotalSteps,
        error: _postsError,
        errorTitle: 'Could not load posts',
        onRetry: _loadPosts,
      );
    }

    if (widget.selectedUser.posts == null) {
      return LoadProgressBody(
        message: 'Loading posts…',
        completedSteps: 0,
        totalSteps: 1,
        onRetry: _loadPosts,
      );
    }

    return _buildPostsBodyWithData();
  }

  Widget _buildPostsBodyWithData() {
    final List<String> postIDs = widget.selectedUser.posts!
        .where((e) => _appContext.eventHeads.any((head) => head.id == e.postID))
        .map((e) => e.postID)
        .toList();

    if (postIDs.isEmpty) {
      return const Center(
        child: Text(
          'No posts yet.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final isWideScreen = ResponsiveLayout.isWideScreen(contentWidth);
        final horizontalPadding = isWideScreen
            ? ((contentWidth - ResponsiveLayout.maxContentWidth(contentWidth)) / 2)
                .clamp(16.0, double.infinity)
            : 8.0;

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          itemCount: postIDs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final thisHead = _appContext.getPostHead(postIDs[index]);
            return PostHead(
              thisHead: thisHead,
              updatePost: () {
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTile(final String postID, {required bool isPast}) {
    if (_appContext.eventHeads.any((e) => e.id == postID)) {
      return _buildScheduleCard(postID, isPast: isPast);
    }

    final future = _headFutures.putIfAbsent(postID, () => _eventHeadDBManager.fetchHead(postID));
    return FutureBuilder<EventHead>(
      future: future,
      builder: (_, snap) {
        if (snap.hasData) {
          _appContext.addAllEventHeads([snap.data!]);
          return _buildScheduleCard(postID, isPast: isPast);
        }
        if (snap.hasError) {
          return LoadProgressBody(
            message: '',
            completedSteps: 0,
            totalSteps: 1,
            error: snap.error,
            errorTitle: 'Could not load this event',
            onRetry: () {
              setState(() {
                _headFutures[postID] = _eventHeadDBManager.fetchHead(postID);
              });
            },
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: LoadProgressBody(
            message: 'Loading event…',
            completedSteps: 0,
            totalSteps: 1,
            padding: EdgeInsets.zero,
          ),
        );
      },
    );
  }

  Widget _buildScheduleCard(final String postID, {required bool isPast}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final postHead = _appContext.eventHeads.firstWhere((e) => e.id == postID);
    final userRoles = widget.selectedUser.roles!.where((e) => e.postID == postID).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final roleCount = userRoles.length;
    final dateLabel = postHead.eventDate != null ? _eventDateFormat.format(postHead.eventDate!) : 'Date TBC';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onPostTap(postHead),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Opacity(
            opacity: isPast ? 0.72 : 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLabel,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              postHead.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (roleCount > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$roleCount roles',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  if (userRoles.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.12)),
                    ),
                    for (var i = 0; i < userRoles.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              userRoles[i].title,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_timeFormat.format(userRoles[i].start)} – ${_timeFormat.format(userRoles[i].end)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshRoles() async {
    if (_appContext.sharedPref.canRefreshRoles) {
      debugPrint('Real Refreshing!');
      final roles = await _scheduleService.fetchRoles(widget.selectedUser.id);
      widget.selectedUser.setRoles(roles);
      await _scheduleService.pruneStaleRoles(
        user: widget.selectedUser,
        eventHeads: _appContext.eventHeads,
      );
      if (!mounted) return;
      setState(() {
        _appContext.sharedPref.setRoleRefreshTime();
      });
    } else {
      debugPrint('Fake Refreshing');
      await Future.delayed(kRefreshCooldownBusyWait);
    }
  }

  Future<void> _runRoleCleanup({required bool showSnackBar}) async {
    final removed = await _scheduleService.pruneStaleRoles(
      user: widget.selectedUser,
      eventHeads: _appContext.eventHeads,
    );
    if (!mounted || !removed) return;
    setState(() {});
    if (showSnackBar) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Updated Schedule!'), behavior: SnackBarBehavior.floating));
    }
  }

  void _onPostTap(final EventHead head) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: head))).then((_) {
        setState(() {
          // technically a user can edit a post from here! 🥲
        });
      });
}
