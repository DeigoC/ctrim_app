import 'package:ctrim_app/firebase/db_managers/event_db_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/event/event_head.dart';

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
        ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewEventsHomeTest()));
          },
          child: const Text('Fetch and load Event Head'),
        ),
      ],
    );
  }
}

// ! This is to test the fundamental fetching of posts
class ViewEventsHomeTest extends StatefulWidget {
  const ViewEventsHomeTest({super.key});

  @override
  State<ViewEventsHomeTest> createState() => ViewEventsHomeTestState();
}

class ViewEventsHomeTestState extends State<ViewEventsHomeTest> {
  final EventHeadDBManager _eventHeadDBManager = EventHeadDBManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Post page'),
      ),
      body: _buildFBBody(),
    );
  }

  Widget _buildFBBody() {
    return FutureBuilder(
        future: _eventHeadDBManager.fetchEventHeads(),
        builder: (_, snap) {
          Widget result = const Center(
            child: CircularProgressIndicator(),
          );

          if (snap.hasData) {
            result = _buildBodyWithData(snap.data!);
          } else if (snap.hasError) {
            result = const Center(
              child: Text('Something went wrong!'),
            );
          }

          return result;
        });
  }

  Widget _buildBodyWithData(List<EventHead> data) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (_, index) {
          final EventHead thisHead = data[index];
          return ListTile(
            title: Text(thisHead.title),
            subtitle: Text(thisHead.subtitle),
            onTap: () {
              context.goNamed('view_event', extra: thisHead);
            },
          );
        });
  }
}
