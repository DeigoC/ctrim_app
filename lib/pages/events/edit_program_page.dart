import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class EditEventProgramPage extends StatefulWidget {
  const EditEventProgramPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<EditEventProgramPage> createState() => _EditEventProgramPageState();
}

class _EditEventProgramPageState extends State<EditEventProgramPage> {
  bool _canSave = false, _forGuests = true;
  final TextEditingController _tecDetail = TextEditingController();

  @override
  void dispose() {
    _tecDetail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Program'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const Text('User selection (hard coded to 1)'),
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.person_add), label: const Text('Assign Members')),
        ListTile(
          title: const Text('<Start time>'),
          subtitle: const Text('Start Time'),
          leading: const Icon(Icons.punch_clock),
          onTap: () {},
        ),
        ListTile(
          title: const Text('<End time>'),
          subtitle: const Text('Finish Time'),
          leading: const Icon(Icons.punch_clock),
          onTap: () {},
        ),
        TextField(
          controller: _tecDetail,
          maxLines: null,
          maxLength: 90,
          decoration: const InputDecoration(label: Text('Description'), hintText: 'What are they doing?'),
          onChanged: (value) {},
        ),
        SwitchListTile(
          value: _forGuests,
          onChanged: _onForGuestsChange,
          title: const Text('For Guests'),
          subtitle: const Text('Is this something guests should see?'),
        ),
        ListTile(
          title: const Text('Priority: 1'),
          subtitle: const Text('Should this be viewed higher than others of the same start time?'),
          trailing: const Icon(Icons.edit),
          onTap: () {},
        ),
        const SizedBox(
          height: 16,
        ),
        ElevatedButton.icon(onPressed: _canSave ? () {} : null, icon: const Icon(Icons.save), label: const Text('Save'))
      ],
    );
  }

  // * Logic
  void _onForGuestsChange(bool newState) {
    setState(() {
      _forGuests = newState;
    });
  }
}
