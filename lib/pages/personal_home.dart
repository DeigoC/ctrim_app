import 'package:ctrim_app/firebase/functions_manager.dart';
import 'package:ctrim_app/pages/personal/login_page.dart';
import 'package:ctrim_app/pages/personal/view_bookmarked_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PersonalHome extends StatefulWidget {
  const PersonalHome({super.key, required this.appContext});
  final AppContext appContext;

  @override
  State<PersonalHome> createState() => _PersonalHomeState();
}

class _PersonalHomeState extends State<PersonalHome> {
  final CloudFunctionManager _functionManager = CloudFunctionManager();
  static const String _ctrimLogo = 'assets/images/ctrim_logo.png';

  @override
  Widget build(BuildContext context) {
    // ? this may not be needed cause of the Consumer at the page level (home_page)
    return Consumer<AppContext>(builder: (context, appContext, _) {
      final List<Widget> children = [
        ListTile(
          leading: const Icon(Icons.bookmarks),
          title: const Text('Bookmarks'),
          onTap: _onViewBookmarkedPageClick,
        ),

        // ! The following is used for testing
        // ListTile(
        //   title: const Text('Test button'),
        //   leading: const Icon(Icons.science),
        //   onTap: () {
        //     showDialog(
        //         context: context,
        //         barrierDismissible: false,
        //         builder: (_) => Dialog(
        //                 child: SingleChildScrollView(
        //                     child: Padding(
        //               padding: const EdgeInsets.symmetric(vertical: 16.0),
        //               child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        //                 const Padding(
        //                   padding: EdgeInsets.symmetric(horizontal: 24.0),
        //                   child: Text('Welcome! 👋',
        //                       style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold), textAlign: TextAlign.start),
        //                 ),
        //                 const SizedBox(height: 16),
        //                 const Padding(
        //                   padding: EdgeInsets.symmetric(horizontal: 24.0),
        //                   child: Text('Please allow notifications to keep up with the latest from CTRIM!',
        //                       textAlign: TextAlign.start, style: TextStyle(fontSize: 16)),
        //                 ),
        //                 const SizedBox(height: 8),
        //                 Align(
        //                     alignment: Alignment.centerRight,
        //                     child: Padding(
        //                         padding: const EdgeInsets.only(right: 16.0),
        //                         child: TextButton(
        //                             onPressed: () => Navigator.pop(_),
        //                             child: const Text('Ok', style: TextStyle(fontSize: 16)))))
        //               ]),
        //             ))));
        //   },
        // )
        // ListTile(
        //     title: const Text('Hello World Function'),
        //     leading: const Icon(Icons.waving_hand),
        //     onTap: () {
        //       _functionManager.helloWorld();
        //     }),
        ListTile(
            title: const Text('Send to Devices'),
            leading: const Icon(Icons.send_to_mobile),
            onTap: () {
              _functionManager.sendMessageToSelectedTokens(
                  tokens: [
                    'eF5nlLtxRUuF2OiviXBMzA:APA91bEu0nqzIOq-PTjLgTMbdrfKQdJ0XmOsDfko38JQUMUBoutImDdWye0NpnPtZSrHoQuyDqaM9L5k7jz5OQmDSjdKDt3GoBXJPuXPIjfcT7w-gi6MCzQXQ0RK5BAVDuVAxlXY7FiQ',
                    'eVllv6fBU0DqgD3sLEyG2F:APA91bGErvuBAOHp5lf__nH5OlypJvUVWk1chWJawmM33kzKA5JYjx7N2U0o46zSRafVRUGdv527P6fi7vKsuG-lxeHqeO1h_iv091pQF75W2Gpu6KnscM76wnkS7ud41e4CmP-Vr3sh'
                  ],
                  title: 'This is a test title',
                  body: "Hopefully this works 🤞, if it does - yeah man! Otherwise, that's unfortuante!",
                  data: {'data': 'nothing for all devices'});
            }),
        ListTile(
            title: const Text('Send to Topic'),
            leading: const Icon(Icons.people_alt),
            onTap: () {
              _functionManager.sendToTopic(
                  topic: 'ctrim-belfast',
                  title: 'This is for BELFAST - Yeahh1!!',
                  body: "Hopefully this works 🤞, if it does - yeah man! This is for when a new post is uploaded",
                  data: {'data': 'nothing for this topic'});
            }),
      ];

      if (appContext.isCurrentUserGuest) {
        children.add(ListTile(
          title: const Text('Log In'),
          leading: const Icon(Icons.login),
          onTap: () => _onLoginTap(appContext),
        ));
      }

      return CustomScrollView(
        slivers: [
          SliverAppBar(
              title: const Text('Personal'),
              centerTitle: false,
              leading: appContext.isCurrentUserGuest
                  ? Image.asset(_ctrimLogo, fit: BoxFit.contain, height: kToolbarHeight)
                  : null),
          SliverList(delegate: SliverChildListDelegate(children))
        ],
      );
    });
  }

  // * Logic

  void _onLoginTap(AppContext appContext) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())).then((_) {
      widget.appContext.rebuildPlease();
    });
  }

  void _onViewBookmarkedPageClick() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewBookmarksPage()));
  }
}
