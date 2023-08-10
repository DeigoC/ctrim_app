import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/personal/view_all_users_page.dart';
import '../utility/app_context.dart';
import 'user_avatar.dart';

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
          ],
        ),
      );
    });
  }

  void _onViewAllUserTap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllUsersPage()));
  }
}
