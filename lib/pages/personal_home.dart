import 'package:ctrim_app/pages/personal/login_page.dart';
import 'package:ctrim_app/utility/app_context.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PersonalHome extends StatefulWidget {
  const PersonalHome({super.key});

  @override
  State<PersonalHome> createState() => _PersonalHomeState();
}

class _PersonalHomeState extends State<PersonalHome> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppContext>(builder: (context, appContext, _) {
      final List<Widget> children = [
        const ListTile(
          title: Text('Bookmarks'),
        )
      ];

      if (appContext.isCurrentUserGuest) {
        children.add(ListTile(
          title: const Text('Log In'),
          leading: const Icon(Icons.login),
          onTap: _onLoginTap,
        ));
      }

      return ListView(
        children: children,
      );
    });
  }

  // * Logic

  void _onLoginTap() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())).then((_) {
      // rebuild in case successful
      setState(() {});
    });
  }
}
