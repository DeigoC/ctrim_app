import 'package:ctrim_app/pages/personal/view_my_posts_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../firebase/auth_manager.dart';
import '../firebase/db_managers/everyone_db_manager.dart';
import '../utility/app_context.dart';
import '../widgets/user_avatar.dart';
import 'personal/attending_sunday_info_page.dart';
import 'personal/current_user_page.dart';
import 'personal/login_page.dart';
import 'personal/notification_management_page.dart';
import 'personal/view_all_users_page.dart';
import 'personal/view_user_roles_page.dart';

class PersonalHome extends StatefulWidget {
  const PersonalHome({super.key, required this.appContext});
  final AppContext appContext;

  @override
  State<PersonalHome> createState() => _PersonalHomeState();
}

class _PersonalHomeState extends State<PersonalHome> {
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  static const String _readmeUrl = 'https://www.craft.me/s/D1p8C4tzitcOwY';

  @override
  Widget build(BuildContext context) {
    final double webHorizontalPadding =
        MediaQuery.of(context).size.width >= 768 ? MediaQuery.of(context).size.width / 5 : 0;

    // ? this may not be needed cause of the Consumer at the page level (home_page)
    return Consumer<AppContext>(builder: (context, appContext, _) {
      final List<Widget> children = [
        ListTile(
          leading: const Icon(Icons.church),
          title: const Text('Attending Sunday Service'),
          onTap: _onAttendingSundayServiceClick,
        ),
      ];

      if (!kIsWeb) {
        children.add(ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Push Notifications'),
            onTap: _onNotificationManagerClick));
      }

      if (!appContext.isCurrentUserGuest) {
        children.insert(
            0,
            Column(
              children: [
                const SizedBox(height: 8),
                ListTile(
                    title: Text('Hi, ${appContext.currentUser.forname}'),
                    leading: MyUserAvatar(appContext.currentUser),
                    onTap: kIsWeb ? null : _onUserProfileClick),
                const Divider(indent: 16, endIndent: 16)
              ],
            ));
        children.addAll([
          ListTile(
            title: const Text('My Schedule'),
            leading: const Icon(Icons.checklist),
            trailing: (appContext.currentUser.roles != null && appContext.currentUser.roles!.isNotEmpty)
                ? Text('(${appContext.currentUser.roles!.length.toString()})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red))
                : null,
            onTap: _onViewTasksClick,
          ),
          ListTile(
            title: const Text('My Posts'),
            leading: const Icon(Icons.list_alt),
            onTap: _onOpenPostsClick,
          ),
          ListTile(
              title: const Text('Belfast Church Volunteers'),
              leading: const Icon(Icons.people),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllUsersPage()))),
          ListTile(
            title: const Text('Readme'),
            leading: const Icon(Icons.info_outline),
            onTap: () => launchUrlString(_readmeUrl),
          ),
        ]);
      }

      if (kIsWeb) {
        children.addAll([
          ListTile(
            title: const Text('Account Deletion Request'),
            leading: const Icon(Icons.no_accounts_rounded),
            onTap: () => launchUrlString('https://ctrim-account-removal.web.app'),
          ),
        ]);
      }

      children.addAll([
        ListTile(
          title: const Text('Privacy Policy'),
          leading: const Icon(Icons.privacy_tip),
          onTap: () => launchUrlString('https://www.freeprivacypolicy.com/live/fca9721d-4812-408f-b30b-56811f3f651b'),
        ),
        ListTile(
          title: const Text('Terms and Conditions'),
          leading: const Icon(Icons.contact_page),
          onTap: () => launchUrlString('https://ctrim-terms-and-conditions.web.app'),
        ),
        ListTile(title: const Text('Log out'), leading: const Icon(Icons.logout), onTap: _onLogoutClick)
      ]);

      return CustomScrollView(
        slivers: [
          SliverAppBar(
              title: const Text('Personal'),
              centerTitle: false,
              leading: Image.asset(_ctrimLogo, fit: BoxFit.contain, height: kToolbarHeight)),
          SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: webHorizontalPadding),
              sliver: SliverList(delegate: SliverChildListDelegate(children)))
        ],
      );
    });
  }

  // * Logic
  void _onLogoutClick() {
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
                    widget.appContext.analytics.logEvent(name: 'logout');
                    _logout();
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage())).then((_) {
                      setState(() {});
                    });
                  },
                  child: const Text('Sign out')),
            ],
          );
        });
  }

  Future<void> _logout() async {
    final AuthManager authManager = AuthManager();
    final EveryoneDBManager everyoneDBManager = EveryoneDBManager();
    debugPrint('token to remove is ${widget.appContext.sharedPref.fcmToken}');
    await everyoneDBManager.removeTokenForAuthID(authManager.currentAuthUID, widget.appContext.sharedPref.fcmToken);
    widget.appContext.sharedPref.clearCreds();
    widget.appContext.setUserToGuest();
    widget.appContext.rebuildPlease();
    widget.appContext.sharedPref.setLoggedOut(true);
    await authManager.signOut();
  }

  void _onViewTasksClick() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ViewUserRolesPage(
                  selectedUser: widget.appContext.currentUser,
                  allowPostView: true,
                )));
  }

  void _onNotificationManagerClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationManagementPage()));
  }

  void _onAttendingSundayServiceClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendingSundayServicePage()));
  }

  void _onUserProfileClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrentUserPage())).then((_) {
      setState(() {
        // update incase user has changed their image
      });
    });
  }

  void _onOpenPostsClick() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ViewMyPostsPage()));
  }
}
