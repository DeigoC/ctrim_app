import 'package:ctrim_app/pages/personal/login_page.dart';
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
  @override
  Widget build(BuildContext context) {
    // ? this may not be needed cause of the Consumer at the page level (home_page)
    return Consumer<AppContext>(builder: (context, appContext, _) {
      final List<Widget> children = [
        const ListTile(
          leading: Icon(Icons.bookmarks),
          title: Text('Bookmarks'),
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
          const SliverAppBar(
            title: Text('Profile'),
          ),
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
}
