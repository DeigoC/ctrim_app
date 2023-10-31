import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../firebase/db_managers/event_db_manager.dart';
import '../../firebase/db_managers/user_db_manager.dart';
import '../../models/event/event_head.dart';
import '../../models/user.dart';
import '../../utility/app_context.dart';
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
  static final DateFormat _eventDateFormat = DateFormat('d MMM');

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);

    // pre-emptively cleanup
    if (widget.selectedUser.roles != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performRoleCleanupCheck().then((removedOldStuff) {
          setState(() {
            // cleanup complete
            if (removedOldStuff) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cleaned up tasks'), behavior: SnackBarBehavior.floating));
            }
          });
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(), appBar: AppBar(title: Text("${widget.selectedUser.forname}'s Tasks")));
  }

  Widget _buildBody() {
    return widget.selectedUser.roles == null ? _buildFBBody() : _buildBodyWithData();
  }

  Widget _buildFBBody() {
    debugPrint('fetching roles');
    return FutureBuilder(
        future: _userDBManager.fetchUserRoles(widget.selectedUser.id),
        builder: (_, snap) {
          Widget result = const Center(child: CircularProgressIndicator());

          if (snap.hasData) {
            widget.selectedUser.setRoles(snap.data!);
            result = _buildBodyWithData();

            // in the chance we're looking at some other person's roles
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _performRoleCleanupCheck().then((_) {
                setState(() {});
              });
            });
          } else if (snap.hasError) {
            debugPrint('something with fetching roles: ${snap.error}');
            result = const Center(child: Text('Something went wrong!'));
          }

          return result;
        });
  }

  Widget _buildBodyWithData() {
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
              onPressed: () => _refreshRoles().then((_) => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refresh Complete!'), behavior: SnackBarBehavior.floating))),
              label: const Text('Refresh'),
              icon: const Icon(Icons.refresh),
            )
          ]);
    }

    final sortedPostIDs = roleConterPerPost.keys.toList();
    debugPrint('pre sort: $sortedPostIDs');
    sortedPostIDs
        .sort((a, b) => _appContext.getPostHead(a).eventDate!.compareTo(_appContext.getPostHead(b).eventDate!));
    debugPrint('post sort: $sortedPostIDs');

    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 0;

    return RefreshIndicator(
      onRefresh: () => _refreshRoles().then((_) => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Refresh Complete!'), behavior: SnackBarBehavior.floating))),
      child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
          itemCount: sortedPostIDs.length,
          itemBuilder: (_, index) {
            final postID = sortedPostIDs[index];
            return _buildTile(postID, roleConterPerPost[postID]!);
          }),
    );
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
    return ListTile(
        leading: const Icon(Icons.event),
        trailing: Text(_eventDateFormat.format(postHead.eventDate!)),
        subtitle: Text('$roleCount task${roleCount == 1 ? '' : 's'}'),
        onTap: widget.allowPostView ? () => _onPostTap(postHead) : null,
        title: Text(postHead.title, maxLines: 2, overflow: TextOverflow.ellipsis));
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

  void _onPostTap(EventHead head) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ViewEventPage(eventHead: head))).then((_) {
        setState(() {
          // technically a user can edit a post from here! 🥲
        });
      });
}
