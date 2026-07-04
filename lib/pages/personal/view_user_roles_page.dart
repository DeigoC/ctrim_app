import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
import '../../utility/responsive_layout.dart';
import '../../widgets/posts/post_head.dart';
import '../events/view_event_page.dart';

class ViewUserRolesPage extends StatefulWidget {
  const ViewUserRolesPage({super.key, required this.selectedUser, this.allowPostView = false});
  final User selectedUser;
  final bool allowPostView;

  @override
  State<ViewUserRolesPage> createState() => _ViewUserRolesPageState();
}

class _ViewUserRolesPageState extends State<ViewUserRolesPage> {
  late final AppContext _appContext;
  final UserDBManager _userDBManager = UserDBManager();
  static final DateFormat _eventDateFormat = DateFormat('EEE d MMM');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);

    // pre-emptively cleanup
    if (widget.selectedUser.roles != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performRoleCleanupCheck().then((removedOldStuff) {
          if (!mounted) return;
          setState(() {
            // cleanup complete
            if (removedOldStuff) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Updated Schedule!'), behavior: SnackBarBehavior.floating));
            }
          });
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allowPostView) {
      return DefaultTabController(
        length: 2,
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
        future: _userDBManager.fetchUserRoles(widget.selectedUser.id),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            widget.selectedUser.setRoles(snap.data!);
            result = _buildScheduleBodyWithData();

            // in the chance we're looking at some other person's roles
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _performRoleCleanupCheck().then((removedOldStuff) {
                if (!mounted) return;
                if (removedOldStuff) {
                  setState(() {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Updated Schedule!'), behavior: SnackBarBehavior.floating));
                  });
                }
              });
            });
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
      final String thisPostID = roleEntry['postID'];
      if (roleConterPerPost.containsKey(thisPostID)) {
        roleConterPerPost[thisPostID] = roleConterPerPost[thisPostID]! + 1;
      } else {
        roleConterPerPost[thisPostID] = 1;
      }
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

    // grabbing and cleaning up the user roles
    final sortedPostIDs = roleConterPerPost.keys.toList();
    debugPrint('pre sort: $sortedPostIDs');
    final List<String> postsToDelete =
        sortedPostIDs.where((e) => !_appContext.eventHeads.any((head) => head.id == e)).toList();
    if (postsToDelete.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _removePostsFromUser(postsToDelete));
    }
    sortedPostIDs.removeWhere((e) => postsToDelete.contains(e));
    sortedPostIDs
        .sort((a, b) => _appContext.getPostHead(a).eventDate!.compareTo(_appContext.getPostHead(b).eventDate!));
    debugPrint('post sort: $sortedPostIDs');

    // finish building
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
        future: _userDBManager.fetchUserPosts(widget.selectedUser.id),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator.adaptive());

          if (snap.hasData) {
            widget.selectedUser.setPosts(snap.data!);
            result = _buildPostsBodyWithData();
            WidgetsBinding.instance.addPostFrameCallback((_) => _removeOldPosts());
          } else if (snap.hasError) {
            result = Center(child: Text('Something went wrong!\n\n${snap.error}'));
          }

          return result;
        });
  }

  Widget _buildPostsBodyWithData() {
    final List<String> postIDs = widget.selectedUser.posts!
        .where((e) => _appContext.eventHeads.any((head) => head.id == e['id']))
        .map((e) => e['id'] as String)
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

    final userRoles = widget.selectedUser.roles!.where((e) => e['postID'] == postID).toList();
    userRoles.sort(((a, b) => (a['startMil'] as int).compareTo(b['startMil'] as int)));

    for (final roleElement in userRoles) {
      final String timeString =
          '${_timeFormat.format(DateTime.fromMillisecondsSinceEpoch(roleElement['startMil']))} - ${_timeFormat.format(DateTime.fromMillisecondsSinceEpoch(roleElement['endMil']))}';
      roleChildren.add(ListTile(
        title: Text(roleElement['title']),
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

  // * Logic

  Future<void> _refreshRoles() async {
    if (_appContext.sharedPref.canRefreshRoles) {
      debugPrint('Real Refreshing!');
      final roles = await _userDBManager.fetchUserRoles(widget.selectedUser.id);
      setState(() {
        _appContext.sharedPref.setRoleRefreshTime();
        widget.selectedUser.setRoles(roles);
      });

      // do we want to do the cleanup here as well? - doesn't seem correct, check again please
      // _performRoleCleanupCheck().then((_) {
      //   setState(() {});
      // });
    } else {
      debugPrint('Fake Refreshing');
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // ! Let's leave this alone for now and see if we change our mind about cleaning up or keeping this data
  // ! Btw, this is repeated code, see main
  Future<bool> _performRoleCleanupCheck() async {
    // remove roles set in the past
    final List<String> postsToRemove = [];
    for (final roleEntry in widget.selectedUser.roles!) {
      if (_appContext.eventHeads.any((e) => e.id == roleEntry['postID'])) {
        final post = _appContext.getPostHead(roleEntry['postID']);
        if (post.eventDate!.add(const Duration(days: 1)).isBefore(DateTime.now())) {
          postsToRemove.add(post.id);
        }
      } else {
        // in the future, the bandwidth of posts might get pretty large where future posts will start to drift away
        // somthing to be mindful of as the app scales forward
        postsToRemove.add(roleEntry['postID']);
      }
    }

    if (postsToRemove.isNotEmpty) {
      debugPrint('removing the following dated roles: $postsToRemove');
      widget.selectedUser.removeRoles(postsToRemove);
      for (final postID in postsToRemove) {
        await _userDBManager.removeUserPostRole(widget.selectedUser.id, postID);
      }
      return true;
    }
    return false;
  }

  void _onPostTap(final EventHead head) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: head))).then((_) {
        setState(() {
          // technically a user can edit a post from here! 🥲
        });
      });

  Future<void> _removePostsFromUser(final List<String> postsToRemove) async {
    if (postsToRemove.isEmpty) return;
    debugPrint('deleting the following posts from user roles: $postsToRemove');
    widget.selectedUser.removeRoles(postsToRemove);
    for (final String postId in postsToRemove) {
      await _userDBManager.removeUserPostRole(widget.selectedUser.id, postId);
    }
  }

  Future<void> _removeOldPosts() async {
    final List<String> postsToRemove = widget.selectedUser.posts!
        .where((e) => !_appContext.eventHeads.any((head) => head.id == e['id']))
        .map((e) => e['id'] as String)
        .toList();
    if (postsToRemove.isEmpty) return;
    debugPrint('removing the following posts: $postsToRemove');
    widget.selectedUser.removeAllPosts(postsToRemove);
    await _userDBManager.updatePosts(widget.selectedUser);
  }
}
