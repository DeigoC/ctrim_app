import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ViewEventsHomePage extends StatefulWidget {
  const ViewEventsHomePage({super.key});

  @override
  State<ViewEventsHomePage> createState() => _ViewEventsHomePageState();
}

class _ViewEventsHomePageState extends State<ViewEventsHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('View Events'),
        ElevatedButton(
          onPressed: () {
            context.goNamed('edit_body');
          },
          child: const Text('To Edit Event Body'),
        ),
        ElevatedButton(
          onPressed: () {
            context.goNamed('view_event');
          },
          child: const Text('View Post Test'),
        ),
      ],
    );
  }
}
