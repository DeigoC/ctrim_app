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
        )
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
