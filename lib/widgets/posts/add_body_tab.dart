import 'package:flutter/material.dart';
import '../../utility/event_context.dart';
import 'view_post_body.dart';

class AddBodyTab extends StatelessWidget {
  const AddBodyTab({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text('Edit Body')),
        ViewPostBody(eventContext: eventContext),
      ],
    );
  }
}
