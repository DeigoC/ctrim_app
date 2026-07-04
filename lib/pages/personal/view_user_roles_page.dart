import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../utility/user_schedule_service.dart';
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
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);

    if (widget.selectedUser.roles != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runRoleCleanup(showSnackBar: true));
    }
    super.initState();
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
    return widget.selectedUser.roles == null ? _buildScheduleFBBody() : _buildScheduleBodyWithData();
  }

  Widget _buildScheduleFBBody() {
    debugPrint('fetching roles');
    return FutureBuilder(
        future: _scheduleService.fetchRoles(widget.selectedUser.id),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            widget.selectedUser.setRoles(snap.data!);
            result = _buildScheduleBodyWithData();

            WidgetsBinding.instance.addPostFrameCallback((_) => _runRoleCleanup(showSnackBar: true));
          } else if (snap.hasError) {
            debugPrint('something with fetching roles: ${snap.error}');
            result = const Center(child: Text('Something went wrong!'));
          }

          return result;
        });
  }

  Widget _buildScheduleBodyWithData() {
    debugPrint('using existing roles');

    final Map<String, int> roleConterPerPost = {};

    for (final roleEntry in widget.selectedUser.roles!) {
      final String thisPostID = roleEntry.postID;
      roleConterPerPost[thisPostID] = (roleConterPerPost[thisPostID] ?? 0) + 1;
    }

    if (roleConterPerPost.isEmpty) {
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
          ]);
    }

    final sortedPostIDs = roleConterPerPost.keys.toList();
    debugPrint('pre sort: $sortedPostIDs');
    final stalePostIDs = UserScheduleService.staleRolePostIDs(
      user: widget.selectedUser,
      eventHeads: _appContext.eventHeads,
    );
    if (stalePostIDs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runRoleCleanup(showSnackBar: false));
    }
    sortedPostIDs.removeWhere(stalePostIDs.contains);
    sortedPostIDs
        .sort((a, b) => _appContext.getPostHead(a).eventDate!.compareTo(_appContext.getPostHead(b).eventDate!));
    debugPrint('post sort: $sortedPostIDs');

    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 8);

    return RefreshIndicator(
      onRefresh: () async {
        await _refreshRoles();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Refresh Complete!'), behavior: SnackBarBehavior.floating));
      },
      child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          itemCount: sortedPostIDs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final postID = sortedPostIDs[index];
            return _buildTile(postID, roleConterPerPost[postID]!);
          }),
    );
  }

  Widget _buildPostsBody() {
    if (widget.selectedUser.posts == null) {
      return _buildPostsFBBody();
    }
    return _buildPostsBodyWithData();
  }

  Widget _buildPostsFBBody() {
    return FutureBuilder(
        future: _scheduleService.fetchPosts(widget.selectedUser.id),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator.adaptive());

          if (snap.hasData) {
            widget.selectedUser.setPosts(snap.data!);
            result = _buildPostsBodyWithData();
            WidgetsBinding.instance.addPostFrameCallback((_) => _runPostCleanup());
          } else if (snap.hasError) {
            result = Center(child: Text('Something went wrong!\n\n${snap.error}'));
          }

          return result;
        });
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

    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 0);

    return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
        itemCount: postIDs.length,
        itemBuilder: (_, index) {
          final thisHead = _appContext.getPostHead(postIDs[index]);
          return PostHead(
              thisHead: thisHead,
              updatePost: () {
                setState(() {});
              });
        });
  }

  Widget _buildTile(final String postID, final int roleCount) {
    if (_appContext.eventHeads.any((e) => e.id == postID)) {
      debugPrint('building with existing post head');
      return _buildTileWithData(postID, roleCount);
    }

    final EventHeadDBManager eventHeadDBManager = EventHeadDBManager();
    debugPrint('fetching post head');
    return FutureBuilder(
        future: eventHeadDBManager.fetchHead(postID),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            _appContext.addAllEventHeads([snap.data!]);
            result = _buildTileWithData(postID, roleCount);
          } else if (snap.hasError) {
            debugPrint('Something with fetching head: ${snap.error}');
            result = const Center(child: Text('Something went wrong!'));
          }

          return result;
        });
  }

  Widget _buildTileWithData(final String postID, final int roleCount) {
    final postHead = _appContext.eventHeads.firstWhere((e) => e.id == postID);
    final List<Widget> roleChildren = [];

    final userRoles = widget.selectedUser.roles!.where((e) => e.postID == postID).toList();
    userRoles.sort(((a, b) => a.start.compareTo(b.start)));

    for (final roleElement in userRoles) {
      final String timeString = '${_timeFormat.format(roleElement.start)} - ${_timeFormat.format(roleElement.end)}';
      roleChildren.add(ListTile(
        title: Text(roleElement.title),
        subtitle: Text(timeString),
        leading: const Icon(Icons.event),
      ));
    }
    return Card(
      child: InkWell(
        onTap: () => _onPostTap(postHead),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(postHead.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(_eventDateFormat.format(postHead.eventDate!)),
              ),
              const Divider(indent: 8, endIndent: 8),
              ...roleChildren,
            ],
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
      await Future.delayed(const Duration(seconds: 1));
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

  Future<void> _runPostCleanup() async {
    final removed = await _scheduleService.pruneStalePostInvolvements(
      user: widget.selectedUser,
      eventHeads: _appContext.eventHeads,
    );
    if (!mounted || !removed) return;
    setState(() {});
  }

  void _onPostTap(final EventHead head) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: head))).then((_) {
        setState(() {
          // technically a user can edit a post from here! 🥲
        });
      });
}
