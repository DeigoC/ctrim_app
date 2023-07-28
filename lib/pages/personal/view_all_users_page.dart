import 'package:ctrim_app/pages/personal/register_user_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/utility/dialog_manager.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ViewAllUsersPage extends StatefulWidget {
  const ViewAllUsersPage({super.key});

  @override
  State<ViewAllUsersPage> createState() => _ViewAllUsersPageState();
}

class _ViewAllUsersPageState extends State<ViewAllUsersPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, child) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('View All Users'),
          ),
          floatingActionButton: appContext.currentUser.isAreaAdmin
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.person_add), onPressed: _addUserClick, label: const Text('Register User'))
              : null,
          body: ListView.builder(
              itemCount: appContext.allUsers.length,
              itemBuilder: (_, index) {
                final thisUser = appContext.allUsers[index];
                return ListTile(
                    title: Text(thisUser.fullname),
                    subtitle: Text(thisUser.location),
                    leading: MyUserAvatar(thisUser),
                    onTap: () => DialogManager.showUserProfile(
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
}
