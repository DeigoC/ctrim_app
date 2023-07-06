import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';

class EditEventProgramPage extends StatefulWidget {
  const EditEventProgramPage({super.key, required this.eventContext, required this.programEntry});
  final EventContext eventContext;
  final Map<String, dynamic> programEntry;

  @override
  State<EditEventProgramPage> createState() => _EditEventProgramPageState();
}

class _EditEventProgramPageState extends State<EditEventProgramPage> {
  bool _forGuests = true;
  late final TextEditingController _tecDetail;
  late DateTime _start, _end;

  @override
  void initState() {
    _forGuests = widget.programEntry['for_guests'];
    _start = widget.programEntry['start'] as DateTime;
    _end = widget.programEntry['end'] as DateTime;
    _tecDetail = TextEditingController(text: widget.programEntry['detail']);
    // ! Remember priority and UIDs
    super.initState();
  }

  @override
  void dispose() {
    _tecDetail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // i just realised a potential issue, technically a user can edit the program to be different
        // then manually revert the changes back after which the 'save' button would still be enabled :(
        // this user can perform a false update and has the ability to post a log and update all who are
        // following the post...
        if (_hasAnythingChanged()) {
          _saveAllChanges();
          widget.eventContext.allowSavingOfTheEdit();
          debugPrint('Something has changed with the programs');
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Program'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const Text('User selection (hard coded to 1)'),
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.person_add), label: const Text('Assign Members')),
        ListTile(
          title: Text(_start.toString()),
          subtitle: const Text('Start Time'),
          leading: const Icon(Icons.punch_clock),
          onTap: _onStartTimeTap,
        ),
        ListTile(
          title: Text(_end.toString()),
          subtitle: const Text('Finish Time'),
          leading: const Icon(Icons.punch_clock),
          onTap: _onEndTimeTap,
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
      ],
    );
  }

  // * Logic
  void _onForGuestsChange(bool newState) {
    setState(() {
      _forGuests = newState;
    });
  }

  bool _hasAnythingChanged() {
    return _start.compareTo(widget.programEntry['start'] as DateTime) != 0 ||
        _end.compareTo(widget.programEntry['end'] as DateTime) != 0 ||
        _tecDetail.text.trim().compareTo(widget.programEntry['detail']) != 0;
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
      initialTime: TimeOfDay.fromDateTime(_start.add(const Duration(hours: 1))),
      helpText: 'When does the role finish?',
    ).then((selectedEndTime) {
      if (selectedEndTime != null) {
        // TODO check end isn't set before the start!
        setState(() {
          _end = DateTime(widget.eventContext.head.eventDate!.year, widget.eventContext.head.eventDate!.month,
              widget.eventContext.head.eventDate!.day, selectedEndTime.hour, selectedEndTime.minute);
        });
      }
    });
  }

  void _saveAllChanges() {
    widget.programEntry['detail'] = _tecDetail.text.trim();
  }
}
