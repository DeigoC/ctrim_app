import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ViewEventsHome extends StatefulWidget {
  const ViewEventsHome({super.key});

  @override
  State<ViewEventsHome> createState() => _ViewEventsHomeState();
}

class _ViewEventsHomeState extends State<ViewEventsHome> {
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
        ElevatedButton(
          onPressed: () {
            context.goNamed('add_event');
          },
          child: const Text('Add Event Test'),
        ),
      ],
    );
  }
}
