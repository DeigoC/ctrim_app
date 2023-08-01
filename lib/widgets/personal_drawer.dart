import 'package:ctrim_app/firebase/db_managers/user_contact_db_manager.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:ctrim_app/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/auth_manager.dart';
import '../pages/personal/view_all_users_page.dart';

class PersonalDrawer extends StatelessWidget {
  const PersonalDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (_, appContext, __) {
      final currentUser = appContext.currentUser;
      return Drawer(
        child: ListView(
          children: [
            Image.asset('assets/images/ctrim_logo.png'),
            const Divider(),
            ListTile(
              title: Text('Hi, ${currentUser.forname}'),
              leading: MyUserAvatar(currentUser),
            ),
            const Divider(),
            ListTile(
              title: const Text('View Users'),
              leading: const Icon(Icons.people),
              onTap: () => _onViewAllUserTap(context),
            ),
            ListTile(
              title: const Text('Log out'),
              leading: const Icon(Icons.logout),
              onTap: () => _confirmLogout(context, appContext),
            ),
          ],
        ),
      );
    });
  }

  void _onViewAllUserTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllUsersPage()));
  }

  void _confirmLogout(BuildContext context, AppContext appContext) async {
    showDialog(
        context: context,
        builder: (logcontext) {
          return AlertDialog(
            title: const Text('Sign out'),
            content: const Text('Are you sure you want to continue?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                  onPressed: () {
                    _logout(appContext).then((_) {
                      Navigator.of(logcontext).pop();
                    });
                  },
                  child: const Text('Sign out')),
            ],
          );
        });
  }

  Future<void> _logout(AppContext appContext) async {
    final AuthManager authManager = AuthManager();
    final UserContactDBManager userContactDBManager = UserContactDBManager();
    // TODO remove the device token from UserContacts

    // Provider.of<AppContext>(context, listen: false).clearCreds();
    // Provider.of<AppContext>(context, listen: false).setUserToGuest();
    await userContactDBManager.removeTokenFromUser(appContext.currentUser.id, appContext.dataManager.token);
    appContext.dataManager.clearCreds();
    appContext.setUserToGuest();
    appContext.rebuildPlease();

    await authManager.signOut();
  }
}
