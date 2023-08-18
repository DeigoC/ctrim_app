import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:ctrim_app/firebase/db_managers/user_db_manager.dart';
import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewUserRolesPage extends StatefulWidget {
  const ViewUserRolesPage({super.key, required this.selectedUser});
  final User selectedUser;

  @override
  State<ViewUserRolesPage> createState() => _ViewUserRolesPageState();
}

class _ViewUserRolesPageState extends State<ViewUserRolesPage> {
  late final AppContext _appContext;
  final UserDBManager _userDBManager = UserDBManager();

  @override
  void initState() {
    _appContext = Provider.of<AppContext>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(), appBar: AppBar(title: const Text('User Roles')));
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
      return const Center(child: Text('No roles assigned, yet! 😎'));
    }

    return ListView.builder(
        itemCount: roleConterPerPost.length,
        itemBuilder: (_, index) {
          final postID = roleConterPerPost.keys.elementAt(index);
          return _buildTile(postID, roleConterPerPost[postID]!);
        });
  }

  Widget _buildTile(final String postID, final int roleCount) {
    if (_appContext.eventHeads.any((e) => e.id == postID)) {
      return _buildTileWithData(postID, roleCount);
    }

    final EventHeadDBManager eventHeadDBManager = EventHeadDBManager();
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
    return ListTile(leading: Text('$roleCount role${roleCount == 1 ? '' : 's'}'), title: Text(postHead.title));
  }
}
