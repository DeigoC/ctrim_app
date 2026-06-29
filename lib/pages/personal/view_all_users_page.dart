import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/pages/personal/edit_user_page.dart';
import 'package:ctrim_app/pages/personal/register_user_page.dart';
import 'package:ctrim_app/pages/personal/view_user_roles_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/widgets/app_search_bar.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utility/responsive_layout.dart';

// for now it's for all users since they will only be from Belfast
// we should look to share either this whole page or make it adapt to view
// locations of people at a time in the future.
class ViewAllUsersPage extends StatefulWidget {
  const ViewAllUsersPage({super.key});

  @override
  State<ViewAllUsersPage> createState() => _ViewAllUsersPageState();
}

class _ViewAllUsersPageState extends State<ViewAllUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double webHorizontalPadding =
        ResponsiveLayout.horizontalGutter(MediaQuery.sizeOf(context).width, narrowPadding: 0);

    return Consumer<AppContext>(builder: (context, appContext, child) {
      final filteredUsers = _searchQuery.isEmpty
          ? appContext.allUsers
          : appContext.allUsers
              .where((user) => user.fullname.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

      return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? AppSearchBar(
                    controller: _searchController,
                    hintText: 'Search users...',
                    inAppBar: true,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  )
                : const Text('Belfast Volunteers'),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
            ],
          ),
          floatingActionButton: appContext.currentUser.isAreaAdmin
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.person_add), onPressed: _addUserClick, label: const Text('Register User'))
              : null,
          body: filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty ? 'No users found' : 'No users match "${_searchQuery}"',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
                  itemCount: filteredUsers.length,
                  itemBuilder: (_, index) {
                    final thisUser = filteredUsers[index];
                    return ListTile(
                        title: Text(thisUser.fullname),
                        leading: MyUserAvatar(thisUser),
                        onTap: () => _onUserTap(thisUser),
                        onLongPress: appContext.currentUser.isAreaAdmin ? () => _navigateToEditUser(thisUser) : null);
                  }));
    });
  }

  // * Logic
  void _addUserClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterUserPage())).then((value) {
      // ? Is this needed?
      setState(() {});
    });
  }

  void _onUserTap(final User selectedUser) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewUserRolesPage(
                  selectedUser: selectedUser,
                  allowPostView: true,
                )));
  }

  void _navigateToEditUser(final User selectedUser) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditUserPage(user: selectedUser),
      ),
    );

    // Refresh the list if the user was updated
    if (result == true) {
      setState(() {});
    }
  }
}
