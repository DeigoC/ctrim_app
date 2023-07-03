import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class AddProgramTab extends StatefulWidget {
  const AddProgramTab({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddProgramTab> createState() => _AddProgramTabState();
}

class _AddProgramTabState extends State<AddProgramTab> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      const Text('Event Date is N/A'),
      ElevatedButton(onPressed: () {}, child: const Text('Change Date')),
      SwitchListTile(
        value: widget.eventContext.programDetails.allDay,
        onChanged: widget.eventContext.head.eventDate == null ? null : (value) => {},
        title: const Text('All Day'),
      )
    ];

    // only add the rest once it's been declared that this is an event via the event date
    if (widget.eventContext.head.eventDate != null) {
      // TODO add the rest of the program details + role assignment
    }

    return ListView(
      children: children,
    );
  }
}
