import 'package:ctrim_app/models/event_body.dart';
import 'package:ctrim_app/models/event_role.dart';
import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ViewEventsHomePage extends StatefulWidget {
  const ViewEventsHomePage({super.key});

  @override
  State<ViewEventsHomePage> createState() => _ViewEventsHomePageState();
}

class _ViewEventsHomePageState extends State<ViewEventsHomePage> {
  late final EventContext _eventContext;

  @override
  void initState() {
    _eventContext = EventContext(eventBody: EventBody('[{"insert":"Hello, time to start writing!\n"}]'));
    _eventContext.addManyRoles([
      EventRole(
          id: '1',
          title: 'Role 1',
          startTime: DateTime.now(),
          finishTime: DateTime.now().add(const Duration(minutes: 20))),
      EventRole(
          id: '2',
          title: 'Role 2',
          startTime: DateTime.now(),
          finishTime: DateTime.now().add(const Duration(minutes: 35))),
      EventRole(
          id: '3',
          title: 'Role 3',
          startTime: DateTime.now().add(const Duration(hours: 1)),
          finishTime: DateTime.now().add(const Duration(hours: 1, minutes: 20))),
      EventRole(
          id: '4',
          title: 'Role 4',
          startTime: DateTime.now().add(const Duration(minutes: 30)),
          finishTime: DateTime.now().add(const Duration(minutes: 45))),
    ]);
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
            context.goNamed('view_all_programs', extra: _eventContext);
          },
          child: const Text('To View All Programs'),
        ),
      ],
    );
  }
}
