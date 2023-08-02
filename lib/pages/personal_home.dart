import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../firebase/functions_manager.dart';
import '../utility/app_context.dart';
import 'personal/login_page.dart';
import 'personal/view_bookmarked_page.dart';

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

        // ! The following are used for testing
        // ListTile(
        //   title: const Text('Testing dialogs'),
        //   leading: const Icon(Icons.science),
        //   onTap: () => _showFCMTest().then((result) => debugPrint('Result is $result')),
        // )
        ListTile(
            title: const Text('Send to Devices'),
            leading: const Icon(Icons.send_to_mobile),
            onTap: () {
              _functionManager.sendMessageToSelectedTokens(
                  tokens: [
                    'dvCfNRzI80t1t1BWCdz--9:APA91bH86KrqzB7e0zUVvl-Yolsj0cntGQNfkd8AN4TfKOzZwSnkPQCBODODJoSc3OAtbS86JmqsHhamf0BPFzRgiC2UUHjn0Hvw_n_SBugKPLeEoQ3yZdAmbX-At_aTLAXUZXRdshU0',
                    'dnH1XfQFQn-tS8DZwYXw9e:APA91bE6jOjOAlw4K-AiAnIcY5zn_xV4w4zbDaaihjTlVNosR0PhLMy9HHVhDT0LVFaquZeFwtlJRkGtzrMNqkNIoifq6IXaiJw3a3zhq9ah1YRAxIYI-oYP3D_Tqihk6DJ8Wbycz_Ic'
                  ],
                  title: 'Click for Love page',
                  body: "This is to test the FCM feature of opening pages. Let's see how it fairs",
                  iOSImage: 'https://i.pinimg.com/1200x/bb/12/03/bb12038681429c0e313c3001a973ef0f.jpg',
                  androidImage: 'https://i.pinimg.com/1200x/bb/12/03/bb12038681429c0e313c3001a973ef0f.jpg',
                  data: {'InfoPage': 'love'});
            }),
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
