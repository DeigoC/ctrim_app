// import 'package:ctrim_app/pages/welcome_page.dart';
import 'package:ctrim_app/pages/personal/current_user_page.dart';
import 'package:ctrim_app/pages/personal/notification_management_page.dart';
import 'package:flutter/material.dart';
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

// import '../firebase/functions_manager.dart';
import '../firebase/auth_manager.dart';
import '../firebase/db_managers/everyone_db_manager.dart';
import '../utility/app_context.dart';
import '../widgets/user_avatar.dart';
import 'personal/login_page.dart';
import 'personal/view_all_users_page.dart';
import 'personal/view_bookmarked_page.dart';

class PersonalHome extends StatefulWidget {
  const PersonalHome({super.key, required this.appContext});
  final AppContext appContext;

  @override
  State<PersonalHome> createState() => _PersonalHomeState();
}

class _PersonalHomeState extends State<PersonalHome> {
  // final CloudFunctionManager _functionManager = CloudFunctionManager();
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';
  static const String _readmeUrl = 'https://www.craft.me/s/D1p8C4tzitcOwY';

  @override
  Widget build(BuildContext context) {
    // ? this may not be needed cause of the Consumer at the page level (home_page)
    return Consumer<AppContext>(builder: (context, appContext, _) {
      final List<Widget> children = [
        ListTile(
            leading: const Icon(Icons.bookmarks), title: const Text('Bookmarks'), onTap: _onViewBookmarkedPageClick),
        ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Manager'),
            onTap: _onNotificationManagerClick),

        // ! The following are used for testing
        ListTile(
          title: const Text('Starting dialog test'),
          leading: const Icon(Icons.science),
          onTap: () {},
        ),
        // ListTile(
        //   title: const Text('Test Version'),
        //   leading: const Icon(Icons.science),
        //   onTap: _testVersion,
        // ),
        // ListTile(
        //   title: const Text('Who Am I'),
        //   leading: const Icon(Icons.science),
        //   onTap: () {
        //     AuthManager authManager = AuthManager();
        //     authManager.whoAmI();
        //   },
        // ),
        // ListTile(
        //     title: const Text('Send to Topic - Love'),
        //     leading: const Icon(Icons.send_to_mobile),
        //     onTap: () {
        //       // _functionManager.sendMessageToSelectedTokens(
        //       //     tokens: [
        //       //       'dvCfNRzI80t1t1BWCdz--9:APA91bH86KrqzB7e0zUVvl-Yolsj0cntGQNfkd8AN4TfKOzZwSnkPQCBODODJoSc3OAtbS86JmqsHhamf0BPFzRgiC2UUHjn0Hvw_n_SBugKPLeEoQ3yZdAmbX-At_aTLAXUZXRdshU0',
        //       //       'dnH1XfQFQn-tS8DZwYXw9e:APA91bE6jOjOAlw4K-AiAnIcY5zn_xV4w4zbDaaihjTlVNosR0PhLMy9HHVhDT0LVFaquZeFwtlJRkGtzrMNqkNIoifq6IXaiJw3a3zhq9ah1YRAxIYI-oYP3D_Tqihk6DJ8Wbycz_Ic'
        //       //     ],
        //       //     title: 'Click for Love page',
        //       //     body: "This is to test the FCM feature of opening pages. Let's see how it fairs",
        //       //     iOSImage: 'https://i.pinimg.com/1200x/bb/12/03/bb12038681429c0e313c3001a973ef0f.jpg',
        //       //     androidImage: 'https://i.pinimg.com/1200x/bb/12/03/bb12038681429c0e313c3001a973ef0f.jpg',
        //       //     data: {'InfoPage': 'love'});

        //       _functionManager.sendToTopic(
        //           topic: 'post-1',
        //           title: 'You will look at a post',
        //           body: 'Lets see if this actually works, do we have the option to look at love?',
        //           data: {'PostID': '2'});
        //     }),
        // ListTile(
        //     title: const Text('Send to Topic'),
        //     leading: const Icon(Icons.people_alt),
        //     onTap: () {
        //       _functionManager.sendToTopic(
        //           topic: 'ctrim-belfast',
        //           title: 'This is for BELFAST - Yeahh1!!',
        //           body: "Hopefully this works 🤞, if it does - yeah man! This is for when a new post is uploaded",
        //           data: {'data': 'nothing for this topic'});
        //     }),
      ];

      if (!appContext.isCurrentUserGuest) {
        children.insert(
            0,
            Column(
              children: [
                const SizedBox(height: 8),
                ListTile(
                    title: Text('Hi, ${appContext.currentUser.forname}'),
                    subtitle: const Text('Change your image here!'),
                    leading: MyUserAvatar(appContext.currentUser),
                    onTap: _onUserProfileClick),
                const Divider(),
              ],
            ));
        children.addAll([
          ListTile(
              title: const Text('Belfast Staff'),
              leading: const Icon(Icons.people),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllUsersPage()))),
          ListTile(
            title: const Text('Readme'),
            leading: const Icon(Icons.info),
            onTap: () => launchUrlString(_readmeUrl),
          ),
        ]);
      }

      children.addAll([
        // ListTile(
        //   title: const Text('Readme'),
        //   leading: const Icon(Icons.info),
        //   onTap: () => launchUrlString('https://pub.dev/packages/url_launcher'),
        // ),
        ListTile(title: const Text('Log out'), leading: const Icon(Icons.logout), onTap: _onLogoutClick)
      ]);

      return CustomScrollView(
        slivers: [
          SliverAppBar(
              title: const Text('Personal'),
              centerTitle: false,
              leading: Image.asset(_ctrimLogo, fit: BoxFit.contain, height: kToolbarHeight)),
          SliverList(delegate: SliverChildListDelegate(children))
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

  void _onViewBookmarkedPageClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewBookmarksPage()));
  }

  void _onNotificationManagerClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationManagementPage()));
  }

  void _onUserProfileClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrentUserPage())).then((_) {
      setState(() {
        // update incase user has changed their image
      });
    });
  }

  // void _testVersion() async {
  //   final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //   final String version = packageInfo.version;
  //   debugPrint('version is $version');

  //   String testStr1 = '6-$version';
  //   String testStr2 = '6';

  //   final split1 = testStr1.split('-');
  //   final split2 = testStr2.split('-');
  //   debugPrint('split 1 is $split1');
  //   debugPrint('split 2 is $split2');

  //   debugPrint('now is ${DateTime.now().millisecondsSinceEpoch}');
  // }

  // Future<bool> _showFCMTest() async {
  //   const String imageUrl = 'https://i.pinimg.com/1200x/bb/12/03/bb12038681429c0e313c3001a973ef0f.jpg';

  //   bool result = false;

  //   final List<Widget> buttonChildren = [
  //     TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok', style: TextStyle(fontSize: 16)))
  //   ];

  //   buttonChildren.add(TextButton(
  //       onPressed: () {
  //         result = true;
  //         Navigator.of(context).pop();
  //       },
  //       child: const Text('Show More', style: TextStyle(fontSize: 16))));

  //   await showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) {
  //         return Dialog(
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //             child: SingleChildScrollView(
  //                 child:
  //                     Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
  //               Container(
  //                   foregroundDecoration: const BoxDecoration(
  //                       borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
  //                       image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.fill)),
  //                   child: Padding(
  //                       padding: const EdgeInsets.all(8.0),
  //                       child: Image.network(imageUrl) // so jank lol! It works though
  //                       )),
  //               const SizedBox(height: 16),
  //               const Padding(
  //                   padding: EdgeInsets.symmetric(horizontal: 24.0),
  //                   child: Text('This here is the title', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
  //               const SizedBox(height: 8),
  //               const Padding(
  //                   padding: EdgeInsets.symmetric(horizontal: 24.0),
  //                   child: Text('And this here is the subtitle, will be shorter than usual.',
  //                       style: TextStyle(fontSize: 16))),
  //               const SizedBox(height: 8),
  //               Padding(
  //                 padding: const EdgeInsets.only(right: 16.0),
  //                 child: Row(mainAxisAlignment: MainAxisAlignment.end, children: buttonChildren),
  //               ),
  //               const SizedBox(height: 16)
  //             ])));
  //       });

  //   return result;
  // }
}
