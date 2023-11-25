import 'package:ctrim_app/models/user.dart';
import 'package:ctrim_app/pages/personal/register_user_page.dart';
import 'package:ctrim_app/pages/personal/view_user_roles_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// for now it's for all users since they will only be from Belfast
// we should look to share either this whole page or make it adapt to view
// locations of people at a time in the future.
class ViewAllUsersPage extends StatefulWidget {
  const ViewAllUsersPage({super.key});

  @override
  State<ViewAllUsersPage> createState() => _ViewAllUsersPageState();
}

class _ViewAllUsersPageState extends State<ViewAllUsersPage> {
  @override
  Widget build(BuildContext context) {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 7 : 0;

    return Consumer<AppContext>(builder: (context, appContext, child) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Belfast Church Volunteers'),
          ),
          floatingActionButton: appContext.currentUser.isAreaAdmin
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.person_add), onPressed: _addUserClick, label: const Text('Register User'))
              : null,
          body: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
              itemCount: appContext.allUsers.length,
              itemBuilder: (_, index) {
                final thisUser = appContext.allUsers[index];
                return ListTile(
                    title: Text(thisUser.fullname),
                    leading: MyUserAvatar(thisUser),
                    onTap: () => _onUserTap(thisUser),
                    onLongPress: () => DialogManager.showUserProfile(
                        selectedUser: thisUser,
                        context: context,
                        currentUserAdmin: appContext.currentUser.isAreaAdmin));
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
}
