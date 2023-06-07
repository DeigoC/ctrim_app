import 'package:ctrim_app/pages/events/edit_body_page.dart';
import 'package:flutter/material.dart';

class ViewEventsHomePage extends StatefulWidget {
  const ViewEventsHomePage({super.key});

  @override
  State<ViewEventsHomePage> createState() => _ViewEventsHomePageState();
}

class _ViewEventsHomePageState extends State<ViewEventsHomePage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('View Events'),
        ElevatedButton(
          onPressed: () {
            Navigator.restorablePushNamed(context, EditBodyPage.routeName);
          },
          child: const Text('To Edit Event Body'),
        )
      ],
    );
  }
}
