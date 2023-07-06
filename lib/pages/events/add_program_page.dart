import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class AddEventProgramPage extends StatefulWidget {
  const AddEventProgramPage({super.key, required this.eventContext});
  final EventContext eventContext;

  @override
  State<AddEventProgramPage> createState() => _AddEventProgramPageState();
}

class _AddEventProgramPageState extends State<AddEventProgramPage> {
  bool _canSave = false, _forGuests = true;
  final TextEditingController _tecDetail = TextEditingController();
  DateTime? _start, _end;

  @override
  void dispose() {
    _tecDetail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Program'),
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
          title: Text(_start == null ? 'TBD' : _start.toString()),
          subtitle: const Text('Start Time'),
          leading: const Icon(Icons.punch_clock),
          onTap: _onStartTimeTap,
        ),
        ListTile(
          title: Text(_end == null ? 'TBD' : _end.toString()),
          subtitle: const Text('Finish Time'),
          leading: const Icon(Icons.punch_clock),
          onTap: _onEndTimeTap,
        ),
        TextField(
          controller: _tecDetail,
          maxLines: null,
          maxLength: 90,
          decoration: const InputDecoration(label: Text('Description'), hintText: 'What are they doing?'),
          onChanged: _onRequirementsChange,
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
        ElevatedButton.icon(
            onPressed: _canSave ? _onSaveClick : null, icon: const Icon(Icons.save), label: const Text('Save'))
      ],
    );
  }

  // * Logic
  void _onForGuestsChange(bool newState) {
    setState(() {
      _forGuests = newState;
    });
  }

  void _onRequirementsChange(String _) {
    if (_tecDetail.text.trim().isEmpty || _start == null || _end == null && _canSave) {
      setState(() {
        _canSave = false;
      });
    } else if (_tecDetail.text.trim().isNotEmpty && _start != null && _end != null && !_canSave) {
      setState(() {
        _canSave = true;
      });
    }
  }

  void _onStartTimeTap() {
    showTimePicker(
            context: context,
            initialTime: widget.eventContext.head.startTimeOfEvent,
            helpText: 'When does the role start?')
        .then((selectedStartTime) {
      if (selectedStartTime != null) {
        setState(() {
          _start = DateTime(widget.eventContext.head.eventDate!.year, widget.eventContext.head.eventDate!.month,
              widget.eventContext.head.eventDate!.day, selectedStartTime.hour, selectedStartTime.minute);
        });
        _onEndTimeTap();
      }
    });
  }

  void _onEndTimeTap() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start!.add(const Duration(hours: 1))),
      helpText: 'When does the role finish?',
    ).then((selectedEndTime) {
      if (selectedEndTime != null) {
        // TODO check end isn't set before the start!
        setState(() {
          _end = DateTime(widget.eventContext.head.eventDate!.year, widget.eventContext.head.eventDate!.month,
              widget.eventContext.head.eventDate!.day, selectedEndTime.hour, selectedEndTime.minute);
        });
        _onRequirementsChange('');
      }
    });
  }

  void _onSaveClick() {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Save Program Details'),
            content: const Text('Are you sure the details are correct?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                  onPressed: () {
                    _addProgramRoleToEventContext();
                    widget.eventContext.allowSavingOfTheEdit();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save')),
            ],
          );
        });
  }

  void _addProgramRoleToEventContext() {
    widget.eventContext.addProgram({
      'uids': ['1'], // ! Change this!
      'detail': _tecDetail.text.trim(),
      'start': _start!,
      'end': _end!,
      'for_guests': _forGuests,
      'priority': 1, // ! And this
    });
  }
}
