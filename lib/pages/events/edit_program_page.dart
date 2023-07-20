import 'package:ctrim_app/utility/event_context.dart';
import 'package:flutter/material.dart';
import '../../utility/dialog_manager.dart';

class EditEventProgramPage extends StatefulWidget {
  const EditEventProgramPage({super.key, required this.eventContext, required this.programEntry});
  final EventContext eventContext;
  final Map<String, dynamic> programEntry;

  @override
  State<EditEventProgramPage> createState() => _EditEventProgramPageState();
}

class _EditEventProgramPageState extends State<EditEventProgramPage> {
  // static final DateFormat _timeFormat = DateFormat('HH:mm');
  late final TextEditingController _tecDetail, _tecTitle;
  // late final AppContext _appContext;
  late final List<String> _selectedUsers;

  late DateTime _start, _end;
  bool _canSave = false, _forGuests = true, _isSaved = false;

  @override
  void initState() {
    _forGuests = widget.programEntry['for_guests'];
    _start = widget.programEntry['start'] as DateTime;
    _end = widget.programEntry['end'] as DateTime;
    _tecDetail = TextEditingController(text: widget.programEntry['detail']);
    _tecTitle = TextEditingController(text: widget.programEntry['title']);
    _selectedUsers = List<String>.from(widget.programEntry['uids']);
    // ! Remember priority and UIDs
    super.initState();
  }

  @override
  void dispose() {
    _tecTitle.dispose();
    _tecDetail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _isSaved ? () async => true : () => DialogManager.discardChanges(context: context),
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
          controller: _tecTitle,
          maxLength: 48,
          decoration: const InputDecoration(
            label: Text('Title*'),
            hintText: 'What is this?',
          ),
          onChanged: (_) => _hasAnythingChanged(),
        ),
        TextField(
          controller: _tecDetail,
          maxLines: null,
          maxLength: 128,
          decoration: const InputDecoration(label: Text('Detail'), hintText: 'Go into more detail'),
          onChanged: (_) => _hasAnythingChanged(),
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
            onPressed: _canSave ? _onSaveClick : null, icon: const Icon(Icons.save), label: const Text('Update')),
      ],
    );
  }

  // * Logic
  void _onForGuestsChange(bool newState) {
    setState(() {
      _forGuests = newState;
    });
    _hasAnythingChanged();
  }

  void _hasAnythingChanged() {
    if (_canSave &&
        (_start.compareTo(widget.programEntry['start'] as DateTime) == 0 &&
            _end.compareTo(widget.programEntry['end'] as DateTime) == 0 &&
            _tecDetail.text.trim().compareTo(widget.programEntry['detail']) == 0 &&
            (_tecTitle.text.trim().compareTo(widget.programEntry['title']) == 0 && _tecTitle.text.trim().isNotEmpty)) &&
        _forGuests != widget.programEntry['for_guests'] &&
        _selectedUsers.toString().compareTo(widget.programEntry['uids']) == 0) {
      setState(() {
        _canSave = false;
      });
    } else if (!_canSave) {
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
        _hasAnythingChanged();
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
        _hasAnythingChanged();
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
                    _saveAllChanges();
                    widget.eventContext.allowSavingOfTheEdit();
                    _isSaved = true;
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save')),
            ],
          );
        });
  }

  void _saveAllChanges() {
    widget.programEntry['detail'] = _tecDetail.text.trim();
  }
}
