import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class EditEventDetailsPage extends StatefulWidget {
  const EditEventDetailsPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditEventDetailsPage> createState() => _EditEventDetailsPageState();
}

class _EditEventDetailsPageState extends State<EditEventDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Details'),
      ),
    );
  }
}
